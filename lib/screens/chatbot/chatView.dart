import 'dart:convert';
import 'dart:io';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
import 'package:fixibot_app/screens/chatbot/chatviewHistory.dart';
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
import 'package:fixibot_app/widgets/customAppBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys to store/retrieve persistent data
const String kSessionsKey = "all_chat_sessions";
const String kCurrentSessionKey = "current_session_id";

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final VehicleController vehicleController = Get.find<VehicleController>();
  final SharedPrefsHelper _prefs = SharedPrefsHelper();
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";

  // Auth & session
  String? _accessToken;
  String? _tokenType;
  String? _sessionId;

  // UI / chat state
  File? _selectedImage;
  Map<String, dynamic>? _selectedVehicle;
  bool _isProcessing = false;

  /// All sessions are stored here:
  /// key = sessionId, value = list of message maps
  Map<String, List<Map<String, dynamic>>> _allSessions = {};
  String? _activeSessionId;

  @override
  void initState() {
    super.initState();
    vehicleController.fetchUserVehicles();
    _initAuth();
    _loadSessions();
  }

  /* ----------------- Persistent Sessions ------------------ */

  Future<void> _loadSessions() async {
    final sp = await SharedPreferences.getInstance();
    final stored = sp.getString(kSessionsKey);
    final currentId = sp.getString(kCurrentSessionKey);

    if (stored != null) {
      final Map<String, dynamic> decoded = jsonDecode(stored);
      _allSessions = decoded.map(
          (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v as List)));
    }

    if (currentId != null && _allSessions.containsKey(currentId)) {
      _activeSessionId = currentId;
    } else {
      _startNewLocalSession();
    }
    setState(() {});
  }

  Future<void> _saveSessions() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(kSessionsKey, jsonEncode(_allSessions));
    if (_activeSessionId != null) {
      await sp.setString(kCurrentSessionKey, _activeSessionId!);
    }
  }

  void _startNewLocalSession() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    _allSessions[newId] = [];
    _activeSessionId = newId;
  }

  Future<void> _startNewChat() async {
    setState(() {
      _startNewLocalSession();
    });
    await _saveSessions();
  }

  // Delete a session
  Future<void> onDelete(String sessionId) async {
    setState(() {
      _allSessions.remove(sessionId);
      if (_activeSessionId == sessionId) {
        if (_allSessions.isEmpty) {
          _startNewLocalSession();
        } else {
          _activeSessionId = _allSessions.keys.first;
        }
      }
    });
    await _saveSessions();
  }

  /* ----------------- Backend Auth/Session ------------------ */

  Future<void> _initAuth() async {
    _accessToken = await _prefs.getString("access_token");
    _tokenType = await _prefs.getString("token_type");
    if (_accessToken == null || _tokenType == null) {
      Get.snackbar("Error", "Authentication required",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }
    await _startServerSession();
  }

  Future<void> _startServerSession() async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/chat/start"),
        headers: {
          "Content-Type": "application/json",
          "accept": "application/json",
          "Authorization": "$_tokenType $_accessToken",
        },
      );
      if (res.statusCode == 201) {
        final data = json.decode(res.body);
        _sessionId = data["session_id"];
        debugPrint("Server chat session started: $_sessionId");
      }
    } catch (e) {
      debugPrint("Server session error: $e");
    }
  }

  /* ----------------- Per-Vehicle Session Logic ------------------ */

  Future<String?> _getSessionIdForVehicle(String vehicleId) async {
    final sp = await SharedPreferences.getInstance();
    final stored = sp.getString(kSessionsKey);
    if (stored == null) return null;

    final Map<String, dynamic> decoded = jsonDecode(stored);
    for (var entry in decoded.entries) {
      final sessionMessages =
          List<Map<String, dynamic>>.from(entry.value as List);
      if (sessionMessages.any((m) => m["vehicleId"] == vehicleId)) {
        return entry.key;
      }
    }
    return null;
  }

  Future<String> _createNewSessionForVehicle(String vehicleId) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    _allSessions[newId] = [];
    _activeSessionId = newId;
    await _saveSessions();
    return newId;
  }

  Future<void> _activateVehicleSession(String vehicleId) async {
    String? sessionId = await _getSessionIdForVehicle(vehicleId);
    if (sessionId == null) {
      sessionId = await _createNewSessionForVehicle(vehicleId);
    }
    setState(() => _activeSessionId = sessionId);
    final sp = await SharedPreferences.getInstance();
    await sp.setString(kCurrentSessionKey, sessionId);
  }

  // FIX 1: Get correct vehicle icon based on category
  IconData _getVehicleIcon(Map<String, dynamic> vehicle) {
    final category = vehicle['category']?.toString().toLowerCase() ?? '';
    
    switch (category) {
      case 'car':
        return Icons.directions_car;
      case 'motorcycle':
      case 'bike':
        return Icons.motorcycle;
      case 'truck':
        return Icons.local_shipping;
      case 'suv':
        return Icons.airport_shuttle;
      default:
        return Icons.directions_car;
    }
  }

  /* ----------------- Message Handling ------------------ */

  Future<void> sendMessage() async {
    if (_selectedVehicle == null) {
      Get.snackbar(
        "Select Vehicle",
        "Please choose a vehicle",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }
    if (_controller.text.trim().isEmpty && _selectedImage == null) return;

    final text = _controller.text.trim();
    final vehicleId = _selectedVehicle!["_id"];

    if (_activeSessionId == null) {
      await _activateVehicleSession(vehicleId);
    }

    // Store user input temporarily
    final userText = text;
    final userImage = _selectedImage;

    // Clear input immediately and show loader
    setState(() {
      _controller.clear();
      _selectedImage = null;
      _isProcessing = true;
    });

    // Add user message locally
    setState(() {
      _allSessions[_activeSessionId]!.add({
        "text": userText,
        "isSent": true,
        "vehicleId": vehicleId,
        "brand": _selectedVehicle?['brand'],
        "model": _selectedVehicle?['model'],
        "timestamp": DateTime.now().toIso8601String(),
      });
    });
    await _saveSessions();

    // Send to backend
    try {
      final request =
          http.MultipartRequest("POST", Uri.parse("$baseUrl/chat/message"));
      request.headers["Authorization"] = "$_tokenType $_accessToken";

      if (_sessionId != null) request.fields["session_id"] = _sessionId!;
      if (userText.isNotEmpty) request.fields["message"] = userText;
      request.fields["vehicle_json"] = json.encode(_selectedVehicle);

      if (userImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath("image", userImage.path),
        );
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();
      print(response.statusCode);
      if (response.statusCode == 200) {
        final decoded = json.decode(body);
        final reply = decoded["reply"] ??
            decoded["message"] ??
            decoded["response"] ??
            body;

        setState(() {
          _allSessions[_activeSessionId]!.add({
            "text": reply,
            "isSent": false,
            "timestamp": DateTime.now().toIso8601String(),
          });
        });
        await _saveSessions();
      } else {
        debugPrint("❌ Message failed: ${response.statusCode} -> ${body} -> ${response} ");
      }
    } catch (e) {
      debugPrint("⚠️ Error sending message: $e");
    } finally {
      // Stop loading regardless of success/error
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _selectedImage = File(file.path));
  }

  /* ----------------- UI ------------------ */

  @override
  Widget build(BuildContext context) {
    final messages =
        _activeSessionId != null ? _allSessions[_activeSessionId] ?? [] : [];

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: CustomAppBar(
        title: "FixiBot",
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.secondaryColor),
            onPressed: () {
              Get.to(ChatHistoryScreen(
                sessions: _allSessions,
                onOpenSession: (id) async {
                  setState(() => _activeSessionId = id);
                  final sp = await SharedPreferences.getInstance();
                  await sp.setString(kCurrentSessionKey, id);
                },
                onDeleteSession: (id) => onDelete(id),
              ));
            },
          ),
          IconButton(
            icon:
                const Icon(Icons.add_comment, color: AppColors.secondaryColor),
            tooltip: "New Chat",
            onPressed: _startNewChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              "Select the vehicle to resolve an issue:",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.mainColor,
              ),
            ),
          ),

          // FIX 1: Vehicle chips with correct icons
          Obx(() {
            final vehicles = vehicleController.userVehicles;
            if (vehicles.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text("No vehicles added.",
                    style: TextStyle(color: AppColors.mainColor)),
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: vehicles.map((v) {
                  final selected = _selectedVehicle != null &&
                      _selectedVehicle!["_id"] == v["_id"];
                  return GestureDetector(
                    onTap: () async {
                      setState(() => _selectedVehicle = Map.from(v));
                      await _activateVehicleSession(v["_id"]);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.mainColor
                            : AppColors.secondaryColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Row(
                        children: [
                          // FIX 1: Use correct vehicle icon
                          Icon(_getVehicleIcon(v),
                              size: 16,
                              color: selected
                                  ? Colors.white
                                  : AppColors.mainColor),
                          const SizedBox(width: 6),
                          Text("${v['brand']} ${v['model']}",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.mainColor,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),

          // Chat messages with FIX 2: Better loading indicator
          Expanded(
            child: Column(
              children: [
                // Messages list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final m = messages[i];
                      final isUser = m["isSent"] == true;
                      return Align(
                        alignment:
                            isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                isUser ? AppColors.mainColor : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (m.containsKey("imagePath"))
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(m["imagePath"]),
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (m.containsKey("text"))
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    m["text"],
                                    style: TextStyle(
                                        color:
                                            isUser ? Colors.white : Colors.black87),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // FIX 2: Improved loading indicator - appears only when processing
                if (_isProcessing)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.mainColor),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "FixiBot is thinking...",
                          style: TextStyle(
                            color: AppColors.mainColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Chat input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.mainColor.withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vehicle chip or Image preview
                        if (_selectedVehicle != null || _selectedImage != null)
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 4, top: 8, bottom: 6),
                            child: Row(
                              children: [
                                if (_selectedVehicle != null)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.mainSwatch.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // FIX 1: Use correct vehicle icon in selected chip too
                                        Icon(_getVehicleIcon(_selectedVehicle!),
                                            size: 14,
                                            color: AppColors.mainColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${_selectedVehicle!['brand']} ${_selectedVehicle!['model']}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.mainColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () {
                                            setState(
                                                () => _selectedVehicle = null);
                                            _activeSessionId = null;
                                          },
                                          child: const Icon(Icons.close,
                                              size: 14,
                                              color: Colors.redAccent),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_selectedImage != null)
                                  Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.file(
                                          _selectedImage!,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() => _selectedImage = null);
                                        },
                                        child: const CircleAvatar(
                                          radius: 8,
                                          backgroundColor: Colors.black54,
                                          child: Icon(Icons.close,
                                              size: 12, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        // Text input row
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.camera_alt_rounded,
                                  color: AppColors.mainColor),
                              onPressed: _pickImage,
                            ),
                            Flexible(
                              flex: 2,
                              child: TextField(
                                controller: _controller,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Type your message...",
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 8),
                                ),
                                minLines: 1,
                                maxLines: 4,
                              ),
                            ),
                            IconButton(
                              icon: _isProcessing
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            AppColors.mainColor),
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded,
                                      color: AppColors.mainColor),
                              onPressed: _isProcessing ? null : sendMessage,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}








//user privacy
// import 'dart:convert';
// import 'dart:io';
// import 'package:fixibot_app/constants/app_colors.dart';
// import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
// import 'package:fixibot_app/screens/chatbot/chatviewHistory.dart';
// import 'package:fixibot_app/screens/profile/controller/userController.dart';
// import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
// import 'package:fixibot_app/widgets/customAppBar.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// /// Keys to store/retrieve persistent data
// const String kSessionsKey = "all_chat_sessions";
// const String kCurrentSessionKey = "current_session_id";

// class ChatScreen extends StatefulWidget {
//   const ChatScreen({super.key});
//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final VehicleController vehicleController = Get.find<VehicleController>();
//   final SharedPrefsHelper _prefs = SharedPrefsHelper();
//   final TextEditingController _controller = TextEditingController();
//   final ImagePicker _picker = ImagePicker();
//   final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";

//   // Auth & session
//   String? _accessToken;
//   String? _tokenType;
//   String? _sessionId;

//   // UI / chat state
//   File? _selectedImage;
//   Map<String, dynamic>? _selectedVehicle;
//   bool _isProcessing = false;

//   /// All sessions are stored here:
//   /// key = sessionId, value = list of message maps
//   Map<String, List<Map<String, dynamic>>> _allSessions = {};
//   String? _activeSessionId;

//   // @override
//   // void initState() {
//   //   super.initState();
//   //   vehicleController.fetchUserVehicles();
//   //   _initAuth();
  
//   // _loadSessions().then((_) {
//   //   _debugSessions(); // Add this line
//   // });
//   // }


// @override
// void initState() {
//   super.initState();
//   vehicleController.fetchUserVehicles();
//   _initAuth();
  
//   // Delay session loading to ensure UserController is initialized
//   WidgetsBinding.instance.addPostFrameCallback((_) async {
//     await _loadSessions();
    
//     // If no sessions loaded, try to recover them
//     if (_allSessions.isEmpty) {
//       await _recoverSessions();
//     }
    
//     _debugSessions();
//   });
// }


//   /* ----------------- User-Specific Session Management ------------------ */

//   Future<void> _loadSessions() async {
//     // Get current user ID from UserController
//     final userController = Get.find<UserController>();
//     final currentUserId = userController.userId.value;
    
//     if (currentUserId.isEmpty) {
//       print('❌ No user ID found, cannot load sessions');
//       _startNewLocalSession();
//       return;
//     }

//     final sp = await SharedPreferences.getInstance();
//     final userSessionsKey = "chat_sessions_$currentUserId";
//     final userCurrentSessionKey = "current_session_$currentUserId";
    
//     final stored = sp.getString(userSessionsKey);
//     final currentId = sp.getString(userCurrentSessionKey);

//     if (stored != null) {
//       final Map<String, dynamic> decoded = jsonDecode(stored);
//       _allSessions = decoded.map(
//           (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v as List)));
//       print('✅ Loaded ${_allSessions.length} sessions for user: $currentUserId');
//     } else {
//       print('ℹ️ No existing sessions found for user: $currentUserId');
//     }

//     if (currentId != null && _allSessions.containsKey(currentId)) {
//       _activeSessionId = currentId;
//       print('✅ Restored active session: $_activeSessionId');
//     } else {
//       _startNewLocalSession();
//       print('🆕 Started new session for user: $currentUserId');
//     }
//     setState(() {});
//   }

//   Future<void> _saveSessions() async {
//     final userController = Get.find<UserController>();
//     final currentUserId = userController.userId.value;
    
//     if (currentUserId.isEmpty) {
//       print('❌ No user ID found, cannot save sessions');
//       return;
//     }

//     final sp = await SharedPreferences.getInstance();
//     final userSessionsKey = "chat_sessions_$currentUserId";
//     final userCurrentSessionKey = "current_session_$currentUserId";
    
//     await sp.setString(userSessionsKey, jsonEncode(_allSessions));
//     if (_activeSessionId != null) {
//       await sp.setString(userCurrentSessionKey, _activeSessionId!);
//     }
//     print('💾 Saved ${_allSessions.length} sessions for user: $currentUserId');
//   }

//   void _startNewLocalSession() {
//     final userController = Get.find<UserController>();
//     final currentUserId = userController.userId.value;
//     final newId = "${DateTime.now().millisecondsSinceEpoch}_${currentUserId.isNotEmpty ? currentUserId : 'unknown'}";
//     _allSessions[newId] = [];
//     _activeSessionId = newId;
//     print('🆕 Created new session: $newId');
//   }

//   // Delete a session - update to use user-specific storage
//   Future<void> onDelete(String sessionId) async {
//     setState(() {
//       _allSessions.remove(sessionId);
//       if (_activeSessionId == sessionId) {
//         if (_allSessions.isEmpty) {
//           _startNewLocalSession();
//         } else {
//           _activeSessionId = _allSessions.keys.first;
//         }
//       }
//     });
//     await _saveSessions();
//     print('🗑️ Deleted session: $sessionId');
//   }

//   Future<String?> _getSessionIdForVehicle(String vehicleId) async {
//     final userController = Get.find<UserController>();
//     final currentUserId = userController.userId.value;
    
//     if (currentUserId.isEmpty) return null;

//     final sp = await SharedPreferences.getInstance();
//     final userSessionsKey = "chat_sessions_$currentUserId";
//     final stored = sp.getString(userSessionsKey);
    
//     if (stored == null) return null;

//     final Map<String, dynamic> decoded = jsonDecode(stored);
//     for (var entry in decoded.entries) {
//       final sessionMessages = List<Map<String, dynamic>>.from(entry.value as List);
//       if (sessionMessages.any((m) => m["vehicleId"] == vehicleId)) {
//         return entry.key;
//       }
//     }
//     return null;
//   }

//   Future<String> _createNewSessionForVehicle(String vehicleId) async {
//     final userController = Get.find<UserController>();
//     final currentUserId = userController.userId.value;
//     final newId = "${DateTime.now().millisecondsSinceEpoch}_${currentUserId.isNotEmpty ? currentUserId : 'unknown'}";
    
//     _allSessions[newId] = [];
//     _activeSessionId = newId;
//     await _saveSessions();
//     return newId;
//   }

//   Future<void> _activateVehicleSession(String vehicleId) async {
//     final userController = Get.find<UserController>();
//     final currentUserId = userController.userId.value;
    
//     if (currentUserId.isEmpty) {
//       print('❌ No user ID found for vehicle session');
//       return;
//     }
    
//     String? sessionId = await _getSessionIdForVehicle(vehicleId);
//     if (sessionId == null) {
//       sessionId = await _createNewSessionForVehicle(vehicleId);
//     }
//     setState(() => _activeSessionId = sessionId);
//     await _saveSessions();
//     print('🚗 Activated vehicle session: $sessionId for user: $currentUserId');
//   }

//   /* ----------------- Backend Auth/Session ------------------ */

//   Future<void> _initAuth() async {
//     _accessToken = await _prefs.getString("access_token");
//     _tokenType = await _prefs.getString("token_type");
//     if (_accessToken == null || _tokenType == null) {
//       Get.snackbar("Error", "Authentication required",
//           backgroundColor: Colors.redAccent, colorText: Colors.white);
//       return;
//     }
//     await _startServerSession();
//   }

//   Future<void> _startServerSession() async {
//     try {
//       final res = await http.post(
//         Uri.parse("$baseUrl/chat/start"),
//         headers: {
//           "Content-Type": "application/json",
//           "accept": "application/json",
//           "Authorization": "$_tokenType $_accessToken",
//         },
//       );
//       if (res.statusCode == 201) {
//         final data = json.decode(res.body);
//         _sessionId = data["session_id"];
//         debugPrint("Server chat session started: $_sessionId");
//       }
//     } catch (e) {
//       debugPrint("Server session error: $e");
//     }
//   }

//   // FIX 1: Get correct vehicle icon based on category
//   IconData _getVehicleIcon(Map<String, dynamic> vehicle) {
//     final category = vehicle['category']?.toString().toLowerCase() ?? '';
    
//     switch (category) {
//       case 'car':
//         return Icons.directions_car;
//       case 'motorcycle':
//       case 'bike':
//         return Icons.motorcycle;
//       case 'truck':
//         return Icons.local_shipping;
//       case 'suv':
//         return Icons.airport_shuttle;
//       default:
//         return Icons.directions_car;
//     }
//   }

//   /* ----------------- Message Handling ------------------ */

//   Future<void> sendMessage() async {
//     if (_selectedVehicle == null) {
//       Get.snackbar(
//         "Select Vehicle",
//         "Please choose a vehicle",
//         backgroundColor: Colors.redAccent,
//         colorText: Colors.white,
//       );
//       return;
//     }
//     if (_controller.text.trim().isEmpty && _selectedImage == null) return;

//     final text = _controller.text.trim();
//     final vehicleId = _selectedVehicle!["_id"];

//     if (_activeSessionId == null) {
//       await _activateVehicleSession(vehicleId);
//     }

//     // Store user input temporarily
//     final userText = text;
//     final userImage = _selectedImage;

//     // Clear input immediately and show loader
//     setState(() {
//       _controller.clear();
//       _selectedImage = null;
//       _isProcessing = true;
//     });

//     // Add user message locally
//     setState(() {
//       _allSessions[_activeSessionId]!.add({
//         "text": userText,
//         "isSent": true,
//         "vehicleId": vehicleId,
//         "brand": _selectedVehicle?['brand'],
//         "model": _selectedVehicle?['model'],
//         "timestamp": DateTime.now().toIso8601String(),
//       });
//     });
//     await _saveSessions();

//     // Send to backend
//     try {
//       final request =
//           http.MultipartRequest("POST", Uri.parse("$baseUrl/chat/message"));
//       request.headers["Authorization"] = "$_tokenType $_accessToken";

//       if (_sessionId != null) request.fields["session_id"] = _sessionId!;
//       if (userText.isNotEmpty) request.fields["message"] = userText;
//       request.fields["vehicle_json"] = json.encode(_selectedVehicle);

//       if (userImage != null) {
//         request.files.add(
//           await http.MultipartFile.fromPath("image", userImage.path),
//         );
//       }

//       final response = await request.send();
//       final body = await response.stream.bytesToString();
//       print(response.statusCode);
//       if (response.statusCode == 200) {
//         final decoded = json.decode(body);
//         final reply = decoded["reply"] ??
//             decoded["message"] ??
//             decoded["response"] ??
//             body;

//         setState(() {
//           _allSessions[_activeSessionId]!.add({
//             "text": reply,
//             "isSent": false,
//             "timestamp": DateTime.now().toIso8601String(),
//           });
//         });
//         await _saveSessions();
//       } else {
//         debugPrint("❌ Message failed: ${response.statusCode} -> ${body} -> ${response} ");
//       }
//     } catch (e) {
//       debugPrint("⚠️ Error sending message: $e");
//     } finally {
//       // Stop loading regardless of success/error
//       setState(() {
//         _isProcessing = false;
//       });
//     }
//   }

//   Future<void> _pickImage() async {
//     final XFile? file =
//         await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
//     if (file != null) setState(() => _selectedImage = File(file.path));
//   }

//   // Add this method to ChatScreen class
// void _debugSessions() {
//   final userController = Get.find<UserController>();
//   final currentUserId = userController.userId.value;
  
//   print('=== CHAT SESSIONS DEBUG ===');
//   print('Current User ID: $currentUserId');
//   print('Total Sessions Loaded: ${_allSessions.length}');
  
//   _allSessions.forEach((sessionId, messages) {
//     print('Session: $sessionId');
//     print('  - Messages: ${messages.length}');
//     if (messages.isNotEmpty) {
//       print('  - First Message: ${messages.first['text']}');
//       print('  - Last Message: ${messages.last['text']}');
//     }
//   });
//   print('===========================');
// }
// // In ChatScreen.dart - Add this method and update initState
// Future<void> _recoverSessions() async {
//   final userController = Get.find<UserController>();
//   final currentUserId = userController.userId.value;
  
//   if (currentUserId.isEmpty) {
//     print('❌ No user ID available for session recovery');
//     return;
//   }
  
//   print('🔄 Attempting to recover sessions for user: $currentUserId');
  
//   final sp = await SharedPreferences.getInstance();
//   final userSessionsKey = "chat_sessions_$currentUserId";
//   final stored = sp.getString(userSessionsKey);
  
//   if (stored != null) {
//     final Map<String, dynamic> decoded = jsonDecode(stored);
//     _allSessions = decoded.map(
//         (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v as List)));
//     print('✅ Recovered ${_allSessions.length} sessions for user: $currentUserId');
    
//     // Try to restore the last active session
//     final userCurrentSessionKey = "current_session_$currentUserId";
//     final currentId = sp.getString(userCurrentSessionKey);
    
//     if (currentId != null && _allSessions.containsKey(currentId)) {
//       _activeSessionId = currentId;
//       print('✅ Restored active session: $_activeSessionId');
//     } else if (_allSessions.isNotEmpty) {
//       _activeSessionId = _allSessions.keys.last;
//       print('✅ Using latest session: $_activeSessionId');
//     }
    
//     setState(() {});
//   } else {
//     print('ℹ️ No sessions found to recover for user: $currentUserId');
//   }
// }

//   /* ----------------- UI ------------------ */

//   @override
//   Widget build(BuildContext context) {
//     final messages =
//         _activeSessionId != null ? _allSessions[_activeSessionId] ?? [] : [];

//     return Scaffold(
//       backgroundColor: AppColors.secondaryColor,
//       appBar: CustomAppBar(
//         title: "FixiBot",
//         actions: [
//           // IconButton(
//           //   icon: const Icon(Icons.history, color: AppColors.secondaryColor),
//           //   onPressed: () {
//           //     Get.to(ChatHistoryScreen(
//           //       sessions: _allSessions,
//           //       onOpenSession: (id) async {
//           //         setState(() => _activeSessionId = id);
//           //         final userController = Get.find<UserController>();
//           //         final currentUserId = userController.userId.value;
                  
//           //         if (currentUserId.isNotEmpty) {
//           //           final sp = await SharedPreferences.getInstance();
//           //           final userCurrentSessionKey = "current_session_$currentUserId";
//           //           await sp.setString(userCurrentSessionKey, id);
//           //         }
//           //       },
//           //       onDeleteSession: (id) => onDelete(id),
//           //     ));
//           //   },
//           // ),

//           // In ChatScreen.dart - Update the history button onPressed
// IconButton(
//   icon: const Icon(Icons.history, color: AppColors.secondaryColor),
//   onPressed: () async {
//     // Reload sessions to ensure we have the latest data
//     await _loadSessions();
//     _debugSessions();

//     Get.to(ChatHistoryScreen(
//       sessions: _allSessions,
//       onOpenSession: (id) async {
//         setState(() => _activeSessionId = id);
//         final userController = Get.find<UserController>();
//         final currentUserId = userController.userId.value;
        
//         if (currentUserId.isNotEmpty) {
//           final sp = await SharedPreferences.getInstance();
//           final userCurrentSessionKey = "current_session_$currentUserId";
//           await sp.setString(userCurrentSessionKey, id);
//         }
//       },
//       onDeleteSession: (id) => onDelete(id),
//     ));
//   },
// ),
//           IconButton(
//             icon:
//                 const Icon(Icons.add_comment, color: AppColors.secondaryColor),
//             tooltip: "New Chat",
//             onPressed: _startNewChat,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8),
//             child: Text(
//               "Select the vehicle to resolve an issue:",
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: AppColors.mainColor,
//               ),
//             ),
//           ),

//           // Vehicle chips with correct icons
//           Obx(() {
//             final vehicles = vehicleController.userVehicles;
//             if (vehicles.isEmpty) {
//               return const Padding(
//                 padding: EdgeInsets.all(12.0),
//                 child: Text("No vehicles added.",
//                     style: TextStyle(color: AppColors.mainColor)),
//               );
//             }
//             return SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//               child: Row(
//                 children: vehicles.map((v) {
//                   final selected = _selectedVehicle != null &&
//                       _selectedVehicle!["_id"] == v["_id"];
//                   return GestureDetector(
//                     onTap: () async {
//                       setState(() => _selectedVehicle = Map.from(v));
//                       await _activateVehicleSession(v["_id"]);
//                     },
//                     child: Container(
//                       margin: const EdgeInsets.only(right: 8),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 14, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: selected
//                             ? AppColors.mainColor
//                             : AppColors.secondaryColor,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(color: Colors.white),
//                       ),
//                       child: Row(
//                         children: [
//                           // Use correct vehicle icon
//                           Icon(_getVehicleIcon(v),
//                               size: 16,
//                               color: selected
//                                   ? Colors.white
//                                   : AppColors.mainColor),
//                           const SizedBox(width: 6),
//                           Text("${v['brand']} ${v['model']}",
//                               style: TextStyle(
//                                   fontSize: 12,
//                                   color: selected
//                                       ? Colors.white
//                                       : AppColors.mainColor,
//                                   fontWeight: FontWeight.w500)),
//                         ],
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             );
//           }),

//           // Chat messages with better loading indicator
//           Expanded(
//             child: Column(
//               children: [
//                 // Messages list
//                 Expanded(
//                   child: ListView.builder(
//                     padding: const EdgeInsets.all(10),
//                     itemCount: messages.length,
//                     itemBuilder: (_, i) {
//                       final m = messages[i];
//                       final isUser = m["isSent"] == true;
//                       return Align(
//                         alignment:
//                             isUser ? Alignment.centerRight : Alignment.centerLeft,
//                         child: Container(
//                           margin: const EdgeInsets.symmetric(vertical: 4),
//                           padding: const EdgeInsets.all(10),
//                           decoration: BoxDecoration(
//                             color:
//                                 isUser ? AppColors.mainColor : Colors.grey.shade300,
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               if (m.containsKey("imagePath"))
//                                 ClipRRect(
//                                   borderRadius: BorderRadius.circular(8),
//                                   child: Image.file(
//                                     File(m["imagePath"]),
//                                     width: 150,
//                                     height: 150,
//                                     fit: BoxFit.cover,
//                                   ),
//                                 ),
//                               if (m.containsKey("text"))
//                                 Padding(
//                                   padding: const EdgeInsets.only(top: 6),
//                                   child: Text(
//                                     m["text"],
//                                     style: TextStyle(
//                                         color:
//                                             isUser ? Colors.white : Colors.black87),
//                                   ),
//                                 ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
                
//                 // Improved loading indicator - appears only when processing
//                 if (_isProcessing)
//                   Container(
//                     padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//                     margin: const EdgeInsets.only(bottom: 10),
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade100,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black12,
//                           blurRadius: 4,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation<Color>(
//                                 AppColors.mainColor),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Text(
//                           "FixiBot is thinking...",
//                           style: TextStyle(
//                             color: AppColors.mainColor,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           // Chat input
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Expanded(
//                   child: Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: AppColors.mainColor.withOpacity(0.4),
//                       ),
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Vehicle chip or Image preview
//                         if (_selectedVehicle != null || _selectedImage != null)
//                           Padding(
//                             padding: const EdgeInsets.only(
//                                 left: 4, top: 8, bottom: 6),
//                             child: Row(
//                               children: [
//                                 if (_selectedVehicle != null)
//                                   Container(
//                                     margin: const EdgeInsets.only(right: 8),
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 10, vertical: 6),
//                                     decoration: BoxDecoration(
//                                       color: AppColors.mainSwatch.shade100,
//                                       borderRadius: BorderRadius.circular(20),
//                                     ),
//                                     child: Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         // Use correct vehicle icon in selected chip too
//                                         Icon(_getVehicleIcon(_selectedVehicle!),
//                                             size: 14,
//                                             color: AppColors.mainColor),
//                                         const SizedBox(width: 4),
//                                         Text(
//                                           "${_selectedVehicle!['brand']} ${_selectedVehicle!['model']}",
//                                           style: const TextStyle(
//                                             fontSize: 12,
//                                             color: AppColors.mainColor,
//                                             fontWeight: FontWeight.w500,
//                                           ),
//                                         ),
//                                         const SizedBox(width: 4),
//                                         GestureDetector(
//                                           onTap: () {
//                                             setState(
//                                                 () => _selectedVehicle = null);
//                                             _activeSessionId = null;
//                                           },
//                                           child: const Icon(Icons.close,
//                                               size: 14,
//                                               color: Colors.redAccent),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 if (_selectedImage != null)
//                                   Stack(
//                                     alignment: Alignment.topRight,
//                                     children: [
//                                       ClipRRect(
//                                         borderRadius: BorderRadius.circular(6),
//                                         child: Image.file(
//                                           _selectedImage!,
//                                           width: 50,
//                                           height: 50,
//                                           fit: BoxFit.cover,
//                                         ),
//                                       ),
//                                       GestureDetector(
//                                         onTap: () {
//                                           setState(() => _selectedImage = null);
//                                         },
//                                         child: const CircleAvatar(
//                                           radius: 8,
//                                           backgroundColor: Colors.black54,
//                                           child: Icon(Icons.close,
//                                               size: 12, color: Colors.white),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                               ],
//                             ),
//                           ),
//                         // Text input row
//                         Row(
//                           children: [
//                             IconButton(
//                               icon: const Icon(Icons.camera_alt_rounded,
//                                   color: AppColors.mainColor),
//                               onPressed: _pickImage,
//                             ),
//                             Flexible(
//                               flex: 2,
//                               child: TextField(
//                                 controller: _controller,
//                                 decoration: const InputDecoration(
//                                   border: InputBorder.none,
//                                   hintText: "Type your message...",
//                                   isDense: true,
//                                   contentPadding: EdgeInsets.symmetric(
//                                       vertical: 8, horizontal: 8),
//                                 ),
//                                 minLines: 1,
//                                 maxLines: 4,
//                               ),
//                             ),
//                             IconButton(
//                               icon: _isProcessing
//                                   ? SizedBox(
//                                       width: 20,
//                                       height: 20,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         valueColor: AlwaysStoppedAnimation<Color>(
//                                             AppColors.mainColor),
//                                       ),
//                                     )
//                                   : const Icon(Icons.send_rounded,
//                                       color: AppColors.mainColor),
//                               onPressed: _isProcessing ? null : sendMessage,
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   // Add this missing method
//   Future<void> _startNewChat() async {
//     setState(() {
//       _startNewLocalSession();
//     });
//     await _saveSessions();
//   }
// }








