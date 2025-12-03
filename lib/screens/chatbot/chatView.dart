import 'dart:convert';
import 'dart:io';
import 'package:fixibot_app/constants/appConfig.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
import 'package:fixibot_app/screens/chatbot/chatHistoryParent.dart';
import 'package:fixibot_app/screens/chatbot/provider/chatManagerProvider.dart';
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
import 'package:fixibot_app/widgets/customAppBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
// 🔥 Voice & Permission Imports
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Keys to store/retrieve persistent data - NOW USER-SPECIFIC
String getSessionsKey(String userId) => "all_chat_sessions_$userId";
String getCurrentSessionKey(String userId) => "current_session_id_$userId";

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
  
  // 🔥 Voice & Language State
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isSpeaking = false;
  
  // Language Mapping (Display Name -> Locale ID)
  final Map<String, String> _languages = {
    'English': 'en-US',
    'Urdu': 'ur-PK',
    'Hindi': 'hi-IN',
    'Punjabi': 'pa-PK',
    'Sindhi': 'sd-PK',  // Sindhi (Pakistan)
    // 'Pashto': 'ps-PK',  // Pashto (Pakistan)
    // 'Punjabi': 'pa-IN', 
  };
  String _selectedLanguage = 'English'; // Default

  final baseUrl = AppConfig.baseUrl;

  // Auth & session
  String? _accessToken;
  String? _tokenType;
  String? _sessionId;
  String? _currentUserId;

  // UI / chat state
  File? _selectedImage;
  Map<String, dynamic>? _selectedVehicle;
  bool _isProcessing = false;

  /// All sessions are stored here
  Map<String, List<Map<String, dynamic>>> _allSessions = {};
  String? _activeSessionId;
  void _checkAvailableLocales() async {
    bool available = await _speech.initialize();
    if (available) {
      var locales = await _speech.locales();
      print("\n=== AVAILABLE SPEECH LOCALES ===");
      for (var locale in locales) {
        print("Name: ${locale.name}, ID: ${locale.localeId}");
      }
      print("================================\n");
    } else {
      print("Speech recognition not available");
    }
  }
  @override
  void initState() {
    super.initState();
    _initializeChatScreen();
    _initVoiceFeatures(); // 🔥 Initialize Voice
    _checkAvailableLocales();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speech.cancel();
    super.dispose();
  }

  // 🔥 Initialize STT and TTS
  void _initVoiceFeatures() async {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();

    // Default setup
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    
    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
    });
  }

  // 🔥 Handle Language Change (Update TTS Accent)
  void _onLanguageChanged(String lang) async {
    setState(() {
      _selectedLanguage = lang;
    });
    String localeId = _languages[lang] ?? 'en-US';
    
    // Check if the language is actually available on the device
    bool isAvailable = await _flutterTts.isLanguageAvailable(localeId);
    
    if (isAvailable) {
      await _flutterTts.setLanguage(localeId);
      print("🗣️ Language switched to: $lang ($localeId)");
    } else {
      Get.snackbar(
        "Voice Not Supported", 
        "Your device does not have a text-to-speech voice for $lang.",
        backgroundColor: Colors.orange,
        colorText: Colors.white
      );
      // Fallback to English or keep previous
      await _flutterTts.setLanguage("en-US");
    }
  }

  // 🔥 Start Listening (Mic Button)
  void _listen() async {
    if (!_isListening) {
      // Request microphone permission
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        Get.snackbar("Permission Denied", "Microphone access is required.");
        return;
      }

      bool available = await _speech.initialize(
        onStatus: (status) => print('STT Status: $status'),
        onError: (val) => print('STT Error: $val'),
      );

      if (available) {
        setState(() => _isListening = true);
        String localeId = _languages[_selectedLanguage] ?? 'en-US';
        
        _speech.listen(
          onResult: (val) {
            setState(() {
              _controller.text = val.recognizedWords;
            });
          },
          localeId: localeId, // 🔥 Critical: Listen in selected language
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // 🔥 Text-to-Speech Logic
  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
       // Clean text (remove markdown like ** or ###) before speaking
       String cleanText = text.replaceAll('*', '').replaceAll('#', '');
       await _flutterTts.speak(cleanText);
    }
  }

  Future<void> _initializeChatScreen() async {
    await vehicleController.fetchUserVehicles();
    await _initAuth();
    _startFreshSession();
  }

  /* ----------------- User-Specific Session Management ------------------ */

  Future<void> _loadSessions() async {
    if (_currentUserId == null) return;
    
    final sp = await SharedPreferences.getInstance();
    final stored = sp.getString(getSessionsKey(_currentUserId!));
    // final currentId = sp.getString(getCurrentSessionKey(_currentUserId!)); // Unused

    if (stored != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(stored);
        _allSessions = decoded.map(
            (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v as List)));
        print('📥 Loaded ${_allSessions.length} sessions for user: $_currentUserId');
      } catch (e) {
        print('❌ Error loading sessions: $e');
        _allSessions = {};
      }
    } else {
      _allSessions = {};
    }

    _startFreshSession();
  }

  Future<void> _saveSessions() async {
    if (_currentUserId == null) return;
    
    final sp = await SharedPreferences.getInstance();
    await sp.setString(getSessionsKey(_currentUserId!), jsonEncode(_allSessions));
    if (_activeSessionId != null) {
      await sp.setString(getCurrentSessionKey(_currentUserId!), _activeSessionId!);
    }
    print('💾 Saved ${_allSessions.length} sessions for user: $_currentUserId');
  }

  void _startFreshSession() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _allSessions[newId] = [];
      _activeSessionId = newId;
      _selectedVehicle = null; 
      _selectedImage = null; 
    });
    print('🆕 Started fresh session: $newId for user: $_currentUserId');
  }

  void _startNewLocalSession() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    _allSessions[newId] = [];
    _activeSessionId = newId;
  }

  Future<void> _startNewChat() async {
    setState(() {
      _startNewLocalSession();
      _selectedVehicle = null; 
    });
    await _saveSessions();
  }

  // ... [Keep onDelete, _initAuth, _deepDebugAuth, _manualAuthFix, _startServerSession, _getSessionIdForVehicle, _createNewSessionForVehicle, _activateVehicleSession, _getVehicleIcon, _saveToChatManager AS THEY WERE] ...
  // NOTE: I am condensing these existing methods to save space, but you should keep them exactly as they were in your original file.
  
  Future<void> onDelete(String sessionId) async { /* Your existing code */ }
  Future<void> _initAuth() async { /* Your existing code */ 
      // ... (The implementation you provided) ...
      // Make sure you call _startServerSession at the end like before
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      _tokenType = prefs.getString('token_type');
      _currentUserId = prefs.getString('user_id');
      if(_accessToken != null && _tokenType != null) await _startServerSession();
  }
  Future<void> _manualAuthFix() async { /* Your existing code */ }
  
  Future<void> _startServerSession() async {
    try {
      if (_accessToken == null || _tokenType == null) return;
      final authHeader = "$_tokenType $_accessToken";
      
      final response = await http.post(
        Uri.parse("$baseUrl/chat/start"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": authHeader,
        },
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _sessionId = data["session_id"];
      } 
    } catch (e) { print("Session Error: $e"); }
  }

  Future<void> _activateVehicleSession(String vehicleId) async {
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      setState(() => _activeSessionId = newId);
      _allSessions[newId] = [];
  }

  Future<void> _saveToChatManager(String sessionId, Map<String, dynamic> message, String chatTitle) async {
      if (Get.isRegistered<ChatManagerProvider>()) {
        Get.find<ChatManagerProvider>().addMessageToSession(sessionId, message);
      }
  }
  
  IconData _getVehicleIcon(Map<String, dynamic> vehicle) {
    return Icons.directions_car; // Simplified for brevity, use your switch case
  }

  // -----------------------------------------------------------------------

  Future<void> sendMessage() async {
    if (_accessToken == null || _tokenType == null) {
      Get.snackbar("Authentication Missing", "Please log in again");
      await _initAuth();
      return;
    }
    
    if (_selectedVehicle == null) {
      Get.snackbar("Select Vehicle", "Please choose a vehicle", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }
    
    final text = _controller.text.trim();
    final vehicleId = _selectedVehicle!["_id"];

    if (text.isEmpty && _selectedImage == null) {
      return;
    }

    if (_activeSessionId == null) {
      await _activateVehicleSession(vehicleId);
    }

    final userText = text;
    final userImage = _selectedImage;

    // Clear input & Stop Listening
    setState(() {
      _controller.clear();
      _selectedImage = null;
      _isProcessing = true;
      _isListening = false; 
    });
    _speech.stop();

    // Create user message
    final userMessage = {
      "text": userText,
      "formattedText": _formatMessageForDisplay(userText), 
      "isSent": true,
      "vehicleId": vehicleId,
      "brand": _selectedVehicle?['brand'],
      "model": _selectedVehicle?['model'],
      "timestamp": DateTime.now().toIso8601String(),
    };

    if (userImage != null) {
      userMessage["imagePath"] = userImage.path;
      userMessage["hasImage"] = true;
    }

    setState(() {
      _allSessions[_activeSessionId]!.add(userMessage);
    });
    await _saveSessions();
    await _saveToChatManager(_activeSessionId!, userMessage, 'New Chat');

    try {
      final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/chat/message"));
      
      final authHeader = "$_tokenType $_accessToken";
      request.headers["Authorization"] = authHeader;
      request.headers["Accept"] = "application/json";

      if (_sessionId != null) {
        request.fields["session_id"] = _sessionId!;
      }
      
      if (userText.isNotEmpty) {
        request.fields["message"] = userText;
      } else {
        request.fields["message"] = "Analyze this vehicle image";
      }

      // 🔥 SEND LANGUAGE PARAMETER TO BACKEND (Sandwich Step 1)
      request.fields["language"] = _selectedLanguage;
      
      request.fields["vehicle_json"] = json.encode(_selectedVehicle);

      if (userImage != null) {
        final fileExtension = userImage.path.split('.').last.toLowerCase();
        final mimeType = _getMimeType(fileExtension);
        final multipartFile = await http.MultipartFile.fromPath(
          'image', 
          userImage.path,
          contentType: MediaType('image', mimeType),
          filename: 'image.$fileExtension'
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send().timeout(Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        // 🔥 Handle Sandwich Response
        // 'response' is the Translated Text (e.g. Urdu)
        // 'english_response' is the original English
        String reply = "";
        if (decoded.containsKey("response")) {
          reply = decoded["response"]; 
        } else {
           reply = _extractReplyFromResponse(decoded);
        }

        final botMessage = {
          "text": reply,
          "formattedText": _formatMessageForDisplay(reply), 
          "isSent": false,
          "timestamp": DateTime.now().toIso8601String(),
          "isImageAnalysis": userImage != null,
        };

        setState(() {
          _allSessions[_activeSessionId]!.add(botMessage);
        });
        await _saveSessions();
        await _saveToChatManager(_activeSessionId!, botMessage, decoded["chat_title"] ?? 'New Chat');

        // 🔥 AUTO-SPEAK RESPONSE
        await _speak(reply);

      } else {
        print('Server Error: ${response.body}');
        _handleErrorResponse("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print('Network Error: $e');
      _handleErrorResponse("Network error: $e");
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // ... [Keep _formatMessageForDisplay, _extractReplyFromResponse, _getMimeType, _formatCVResponse, _handleValidationError, _handleErrorResponse, _pickImage AS IS] ...
  // Copied basic implementation for completeness
  String _formatMessageForDisplay(String text) {
    return text.replaceAll('**', '').replaceAll('###', '• ');
  }
  
  String _extractReplyFromResponse(Map<String, dynamic> response) {
    return response['response'] ?? response['reply'] ?? response['message'] ?? "Done";
  }

  String _getMimeType(String ext) => ext == 'png' ? 'png' : 'jpeg';
  
  void _handleErrorResponse(String error) {
      setState(() {
         _allSessions[_activeSessionId]!.add({
             "text": "Error: $error", "isSent": false, "isError": true
         });
      });
  }

  Future<void> _pickImage() async {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) setState(() => _selectedImage = File(file.path));
  }

  // 🔥 NEW: Language Chips Widget
  Widget _buildLanguageChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: _languages.keys.map((lang) {
          final isSelected = _selectedLanguage == lang;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(lang),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.mainColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              selected: isSelected,
              selectedColor: AppColors.mainColor,
              backgroundColor: Colors.white,
              side: BorderSide(color: AppColors.mainColor.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (bool selected) {
                if (selected) _onLanguageChanged(lang);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // 🔥 UPDATED: Message Bubble with Audio Icon
  Widget _buildMessageBubble(Map<String, dynamic> m) {
    final isUser = m["isSent"] == true;
    final hasImage = m["hasImage"] == true;
    final isError = m["isError"] == true;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isError 
            ? Colors.orange.shade100
            : isUser 
              ? AppColors.mainColor 
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage && m.containsKey("imagePath"))
               Padding(
                 padding: const EdgeInsets.only(bottom: 8.0),
                 child: Image.file(File(m["imagePath"]), height: 150, width: double.infinity, fit: BoxFit.cover),
               ),
            
            if (m.containsKey("text"))
               _buildRichTextMessage(m["text"].toString(), isUser: isUser, isError: isError),

            // 🔥 Audio Replay Button for Bot
            if (!isUser && !isError)
              GestureDetector(
                onTap: () => _speak(m["text"].toString()),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up_rounded, size: 16, color: Colors.black54),
                      SizedBox(width: 4),
                      Text("Listen", style: TextStyle(fontSize: 10, color: Colors.black54))
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildRichTextMessage(String text, {bool isUser = false, bool isError = false, bool isCVAnalysis = false}) {
     // Keep your existing rich text logic implementation here
     return Text(text, style: TextStyle(color: isUser ? Colors.white : Colors.black87));
  }

  @override
  Widget build(BuildContext context) {
    final messages = _activeSessionId != null ? _allSessions[_activeSessionId] ?? [] : [];

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: CustomAppBar(
        title: "FixiBot",
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.secondaryColor),
            onPressed: () => Get.to(ChatHistoryParentWidget()),
          ),
          IconButton(
            icon: const Icon(Icons.add_comment, color: AppColors.secondaryColor),
            onPressed: _startNewChat,
          ),
          IconButton(
            icon: const Icon(Icons.build, color: AppColors.secondaryColor),
            onPressed: _manualAuthFix,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Vehicle Selection
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(
              "Select the vehicle to resolve an issue:",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.mainColor,
              ),
            ),
          ),

          // Vehicle Chips
          Obx(() {
            final vehicles = vehicleController.userVehicles;
            if (vehicles.isEmpty) return const SizedBox(height: 50, child: Center(child: Text("No vehicles")));
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: vehicles.map((v) {
                  final selected = _selectedVehicle != null && _selectedVehicle!["_id"] == v["_id"];
                  return GestureDetector(
                    onTap: () async {
                      setState(() => _selectedVehicle = Map.from(v));
                      await _activateVehicleSession(v["_id"]);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.mainColor : AppColors.secondaryColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.directions_car, size: 16, color: selected ? Colors.white : AppColors.mainColor),
                          const SizedBox(width: 6),
                          Text("${v['brand']} ${v['model']}",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: selected ? Colors.white : AppColors.mainColor,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),

          // 2. 🔥 Language Chips (New)
          _buildLanguageChips(),

          // 3. Chat Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (_, i) => _buildMessageBubble(messages[i]),
            ),
          ),

          // 4. Loading Indicator
          if (_isProcessing)
             Padding(
               padding: const EdgeInsets.all(8.0),
               child: LinearProgressIndicator(color: AppColors.mainColor, backgroundColor: Colors.white),
             ),

          // 5. Input Area (Updated with Mic)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isListening ? Colors.red : AppColors.mainColor.withOpacity(0.4),
                        width: _isListening ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         // Image Preview Logic (Visual only)
                         if (_selectedImage != null)
                            Padding(padding: EdgeInsets.all(8), child: Icon(Icons.image, color: AppColors.mainColor)),
                            
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.camera_alt_rounded, color: AppColors.mainColor),
                              onPressed: _pickImage,
                            ),
                            Flexible(
                              child: TextField(
                                controller: _controller,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  // 🔥 Change hint text based on state
                                  hintText: _isListening ? "Listening..." : "Type or speak...",
                                  hintStyle: TextStyle(
                                    color: _isListening ? Colors.red : Colors.grey
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                ),
                                minLines: 1,
                                maxLines: 4,
                              ),
                            ),
                            // 🔥 Mic Button
                            GestureDetector(
                              onTap: _listen,
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  _isListening ? Icons.mic : Icons.mic_none_rounded,
                                  color: _isListening ? Colors.red : AppColors.mainColor,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send_rounded, color: AppColors.mainColor),
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








// import 'dart:convert';
// import 'dart:io';
// import 'package:fixibot_app/constants/appConfig.dart';
// import 'package:fixibot_app/constants/app_colors.dart';
// import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
// import 'package:fixibot_app/screens/chatbot/chatHistoryParent.dart';
// import 'package:fixibot_app/screens/chatbot/chatviewHistory.dart';
// import 'package:fixibot_app/screens/chatbot/provider/chatManagerProvider.dart';
// import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
// import 'package:fixibot_app/widgets/customAppBar.dart';
// import 'package:fixibot_app/widgets/wrapper.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// /// Keys to store/retrieve persistent data - NOW USER-SPECIFIC
// String getSessionsKey(String userId) => "all_chat_sessions_$userId";
// String getCurrentSessionKey(String userId) => "current_session_id_$userId";

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
//   final ChatManagerProvider _chatManager = Get.find<ChatManagerProvider>();
//   final baseUrl = AppConfig.baseUrl;

//   // Auth & session
//   String? _accessToken;
//   String? _tokenType;
//   String? _sessionId;
//   String? _currentUserId;

//   // UI / chat state
//   File? _selectedImage;
//   Map<String, dynamic>? _selectedVehicle;
//   bool _isProcessing = false;

//   /// All sessions are stored here:
//   /// key = sessionId, value = list of message maps
//   Map<String, List<Map<String, dynamic>>> _allSessions = {};
//   String? _activeSessionId;

//   @override
//   void initState() {
//     super.initState();
//     _initializeChatScreen();
//   }

//   Future<void> _initializeChatScreen() async {
//     await vehicleController.fetchUserVehicles();
//     await _initAuth();
//     // Don't load sessions automatically - start fresh every time
//     _startFreshSession();
//   }

//   /* ----------------- User-Specific Session Management ------------------ */

//   Future<void> _loadSessions() async {
//     if (_currentUserId == null) return;
    
//     final sp = await SharedPreferences.getInstance();
//     final stored = sp.getString(getSessionsKey(_currentUserId!));
//     final currentId = sp.getString(getCurrentSessionKey(_currentUserId!));

//     if (stored != null) {
//       try {
//         final Map<String, dynamic> decoded = jsonDecode(stored);
//         _allSessions = decoded.map(
//             (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v as List)));
//         print('📥 Loaded ${_allSessions.length} sessions for user: $_currentUserId');
//       } catch (e) {
//         print('❌ Error loading sessions: $e');
//         _allSessions = {};
//       }
//     } else {
//       _allSessions = {};
//     }

//     // 🔥 CRITICAL FIX: Don't automatically restore last session
//     // Always start with a fresh session when opening chat screen
//     _startFreshSession();
//   }

//   Future<void> _saveSessions() async {
//     if (_currentUserId == null) return;
    
//     final sp = await SharedPreferences.getInstance();
//     await sp.setString(getSessionsKey(_currentUserId!), jsonEncode(_allSessions));
//     if (_activeSessionId != null) {
//       await sp.setString(getCurrentSessionKey(_currentUserId!), _activeSessionId!);
//     }
//     print('💾 Saved ${_allSessions.length} sessions for user: $_currentUserId');
//   }

//   void _startFreshSession() {
//     // Always create a new session when opening the chat screen
//     final newId = DateTime.now().millisecondsSinceEpoch.toString();
//     setState(() {
//       _allSessions[newId] = [];
//       _activeSessionId = newId;
//       _selectedVehicle = null; // Reset vehicle selection
//       _selectedImage = null; // Reset any selected image
//     });
//     print('🆕 Started fresh session: $newId for user: $_currentUserId');
//   }

//   void _startNewLocalSession() {
//     final newId = DateTime.now().millisecondsSinceEpoch.toString();
//     _allSessions[newId] = [];
//     _activeSessionId = newId;
//   }

//   Future<void> _startNewChat() async {
//     setState(() {
//       _startNewLocalSession();
//       _selectedVehicle = null; // Reset vehicle when starting new chat
//     });
//     await _saveSessions();
//   }

//   // Delete a session
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
    
//     // Also delete from ChatManagerProvider
//     try {
//       if (Get.isRegistered<ChatManagerProvider>()) {
//         final chatManager = Get.find<ChatManagerProvider>();
//         if (chatManager.sessionExists(sessionId)) {
//           chatManager.deleteSession(sessionId);
//           print('✅ Session deleted from ChatManagerProvider: $sessionId');
//         }
//       }
//     } catch (e) {
//       print('❌ Error deleting from ChatManagerProvider: $e');
//     }
//   }

//   /* ----------------- Backend Auth/Session ------------------ */

//   Future<void> _initAuth() async {
//     try {
//       print('🔄 Starting authentication initialization...');
      
//       // Get all auth data at once to avoid timing issues
//       final prefs = await SharedPreferences.getInstance();
//       _accessToken = prefs.getString('access_token');
//       _tokenType = prefs.getString('token_type');
//       _currentUserId = prefs.getString('user_id');
      
//       print('🔐 Chatbot Auth Check:');
//       print('   User ID: ${_currentUserId ?? "❌ NULL"}');
//       print('   Access Token: ${_accessToken != null ? "✅ EXISTS" : "❌ MISSING"}');
//       print('   Token Type: ${_tokenType ?? "❌ NULL"}');
      
//       // 🔥 ENHANCED AUTO-FIX: Check for common authentication issues
//       bool needsFix = false;
      
//       // Fix 1: Missing token_type but has access_token (Google user issue)
//       if (_accessToken != null && _accessToken!.isNotEmpty && (_tokenType == null || _tokenType!.isEmpty)) {
//         print('🛠️ Auto-fixing missing token_type for Google user...');
//         await prefs.setString('token_type', 'bearer');
//         _tokenType = 'bearer';
//         needsFix = true;
//         print('✅ Fixed: token_type set to "bearer"');
//       }
      
//       // Fix 2: Check if access_token is valid (not empty string)
//       if (_accessToken != null && _accessToken!.isEmpty) {
//         print('🛠️ Auto-fixing empty access_token...');
//         _accessToken = null;
//         needsFix = true;
//         print('✅ Fixed: cleared empty access_token');
//       }
      
//       // Fix 3: Check if user_id exists but auth tokens are missing
//       if (_currentUserId != null && (_accessToken == null || _tokenType == null)) {
//         print('🛠️ User ID exists but auth tokens missing - checking for stored data...');
//         // Try to get email to see if user was logged in
//         final userEmail = prefs.getString('email');
//         if (userEmail != null) {
//           print('   Found user email: $userEmail - but tokens are missing');
//           needsFix = true;
//         }
//       }
      
//       if (needsFix) {
//         Get.snackbar(
//           "Authentication Updated", 
//           "Chatbot is now ready to use!",
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//           duration: Duration(seconds: 3),
//         );
//       }
      
//       // 🔥 ENHANCED VALIDATION: Check if we have everything needed
//       final hasValidAuth = _accessToken != null && 
//                           _accessToken!.isNotEmpty && 
//                           _tokenType != null && 
//                           _tokenType!.isNotEmpty &&
//                           _currentUserId != null;
      
//       if (!hasValidAuth) {
//         print('❌ INCOMPLETE AUTHENTICATION DATA:');
//         print('   Access Token: ${_accessToken ?? "NULL"}');
//         print('   Token Type: ${_tokenType ?? "NULL"}');
//         print('   User ID: ${_currentUserId ?? "NULL"}');
        
//         // Show detailed error message
//         String errorMessage = "Missing authentication data:\n";
//         if (_accessToken == null) errorMessage += "• Access Token\n";
//         if (_tokenType == null) errorMessage += "• Token Type\n";
//         if (_currentUserId == null) errorMessage += "• User ID\n";
        
//         Get.snackbar(
//           "Authentication Required", 
//           errorMessage,
//           backgroundColor: Colors.redAccent, 
//           colorText: Colors.white,
//           duration: Duration(seconds: 8),
//           isDismissible: true,
//         );
        
//         await _deepDebugAuth();
//         return;
//       }
      
//       print('✅ Authentication validated successfully');
//       print('   Final Auth Header: "$_tokenType $_accessToken"');
      
//       await _startServerSession();
      
//     } catch (e) {
//       print('❌ CRITICAL ERROR in _initAuth: $e');
//       Get.snackbar(
//         "Authentication Error", 
//         "Failed to initialize authentication: $e",
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         duration: Duration(seconds: 5),
//       );
//     }
//   }

//   /// 🔥 NEW: Deep authentication debugging
//   Future<void> _deepDebugAuth() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
      
//       print('\n=== 🔍 DEEP AUTH DEBUG ===');
      
//       // Check all stored authentication data
//       final allKeys = prefs.getKeys();
//       final authKeys = allKeys.where((key) => 
//         key.contains('token') || 
//         key.contains('user') || 
//         key.contains('auth') || 
//         key.contains('email') ||
//         key.contains('login')
//       ).toList();
      
//       print('📋 Found auth-related keys: $authKeys');
      
//       for (final key in authKeys) {
//         final value = prefs.get(key);
//         print('   $key: $value');
//       }
      
//       // Test the actual authorization header
//       final accessToken = prefs.getString('access_token');
//       final tokenType = prefs.getString('token_type') ?? 'bearer';
//       final authHeader = "$tokenType $accessToken";
      
//       print('🔑 Authorization Header: "$authHeader"');
//       print('📏 Header Length: ${authHeader.length}');
      
//       // Check if this looks like a valid JWT token
//       if (accessToken != null) {
//         final parts = accessToken.split('.');
//         if (parts.length == 3) {
//           print('✅ Access Token appears to be valid JWT');
//         } else {
//           print('⚠️ Access Token does not look like standard JWT');
//         }
//       }
      
//       print('=== END DEEP DEBUG ===\n');
      
//     } catch (e) {
//       print('❌ Error in deep debug: $e');
//     }
//   }

//   /// 🔥 NEW: Manual authentication fix for users
//   Future<void> _manualAuthFix() async {
//     try {
//       print('🛠️ Starting manual authentication fix...');
      
//       final prefs = await SharedPreferences.getInstance();
      
//       // Get current state
//       final currentAccessToken = prefs.getString('access_token');
//       final currentTokenType = prefs.getString('token_type');
//       final currentUserId = prefs.getString('user_id');
//       final userEmail = prefs.getString('email');
      
//       print('📊 Current State:');
//       print('   Access Token: ${currentAccessToken != null ? "EXISTS" : "NULL"}');
//       print('   Token Type: ${currentTokenType ?? "NULL"}');
//       print('   User ID: ${currentUserId ?? "NULL"}');
//       print('   Email: ${userEmail ?? "NULL"}');
      
//       bool fixedSomething = false;
      
//       // Fix 1: Ensure token_type exists
//       if (currentAccessToken != null && currentAccessToken.isNotEmpty && 
//           (currentTokenType == null || currentTokenType.isEmpty)) {
//         await prefs.setString('token_type', 'bearer');
//         print('✅ Fixed: Set token_type to "bearer"');
//         fixedSomething = true;
//       }
      
//       // Fix 2: Check if we have user data but no tokens (logged out state)
//       if (userEmail != null && currentAccessToken == null) {
//         print('⚠️ User email found but no access token - user may be logged out');
//         Get.snackbar(
//           "Login Required",
//           "Please log in again to use the chatbot",
//           backgroundColor: Colors.orange,
//           colorText: Colors.white,
//         );
//       }
      
//       if (fixedSomething) {
//         // Reload auth state
//         _accessToken = prefs.getString('access_token');
//         _tokenType = prefs.getString('token_type');
//         _currentUserId = prefs.getString('user_id');
        
//         Get.snackbar(
//           "Authentication Fixed",
//           "Try using the chatbot now",
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//         );
        
//         // Try to start server session again
//         await _startServerSession();
//       } else {
//         Get.snackbar(
//           "No Fix Needed",
//           "Authentication data looks correct",
//           backgroundColor: Colors.blue,
//           colorText: Colors.white,
//         );
//       }
      
//     } catch (e) {
//       print('❌ Error in manual auth fix: $e');
//       Get.snackbar(
//         "Fix Failed",
//         "Please try logging out and back in",
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }

//   Future<void> _startServerSession() async {
//     try {
//       print('🚀 Starting server chat session...');
      
//       if (_accessToken == null || _tokenType == null) {
//         print('❌ Cannot start server session: Missing auth tokens');
//         return;
//       }
      
//       final authHeader = "$_tokenType $_accessToken";
//       print('   Using Auth Header: $authHeader');
      
//       final response = await http.post(
//         Uri.parse("$baseUrl/chat/start"),
//         headers: {
//           "Content-Type": "application/json",
//           "accept": "application/json",
//           "Authorization": authHeader,
//         },
//       ).timeout(Duration(seconds: 10));
      
//       print('📡 Server session response: ${response.statusCode}');
      
//       if (response.statusCode == 201) {
//         final data = json.decode(response.body);
//         _sessionId = data["session_id"];
//         print("✅ Server chat session started: $_sessionId");
//       } else {
//         print("❌ Server session failed: ${response.statusCode} - ${response.body}");
        
//         // Show specific error based on status code
//         if (response.statusCode == 401) {
//           Get.snackbar(
//             "Session Expired",
//             "Please log in again",
//             backgroundColor: Colors.red,
//             colorText: Colors.white,
//           );
//         } else if (response.statusCode == 403) {
//           Get.snackbar(
//             "Access Denied",
//             "You don't have permission to use chatbot",
//             backgroundColor: Colors.red,
//             colorText: Colors.white,
//           );
//         }
//       }
//     } catch (e) {
//       print("❌ Server session error: $e");
//       Get.snackbar(
//         "Connection Issue",
//         "Could not start chat session. Please check your connection.",
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//       );
//     }
//   }

//   /* ----------------- Per-Vehicle Session Logic ------------------ */

//   Future<String?> _getSessionIdForVehicle(String vehicleId) async {
//     if (_currentUserId == null) return null;
    
//     final sp = await SharedPreferences.getInstance();
//     final stored = sp.getString(getSessionsKey(_currentUserId!));
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
//     final newId = DateTime.now().millisecondsSinceEpoch.toString();
//     _allSessions[newId] = [];
//     _activeSessionId = newId;
//     await _saveSessions();
//     return newId;
//   }

//   Future<void> _activateVehicleSession(String vehicleId) async {
//     String? sessionId = await _getSessionIdForVehicle(vehicleId);
//     if (sessionId == null) {
//       sessionId = await _createNewSessionForVehicle(vehicleId);
//     }
//     setState(() => _activeSessionId = sessionId);
//     final sp = await SharedPreferences.getInstance();
//     await sp.setString(getCurrentSessionKey(_currentUserId!), sessionId!);
//   }

//   // Get correct vehicle icon based on category
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

//   Future<void> _saveToChatManager(String sessionId, Map<String, dynamic> message, String chatTitle) async {
//     try {
//       if (!Get.isRegistered<ChatManagerProvider>()) {
//         print('❌ ChatManagerProvider not registered');
//         return;
//       }

//       final chatManager = Get.find<ChatManagerProvider>();
      
//       if (!chatManager.isInitialized) {
//         print('❌ ChatManagerProvider not initialized, trying to initialize...');
        
//         final userId = await _prefs.getCurrentUserId();
//         if (userId != null) {
//           await chatManager.initializeForUser(userId);
//           print('✅ ChatManagerProvider initialized in chat screen');
//         } else {
//           print('❌ No user ID found for ChatManagerProvider initialization');
//           return;
//         }
//       }

//       // ENHANCED: Add formatted text to the message
//       final enhancedMessage = Map<String, dynamic>.from(message);
//       if (message.containsKey('text') && message['text'] is String) {
//         enhancedMessage['formattedText'] = _formatMessageForDisplay(message['text']);
//       }

//       if (!chatManager.sessionExists(sessionId)) {
//         chatManager.createSession(
//           id: sessionId,
//           title: chatTitle,
//           firstMessage: enhancedMessage['formattedText']?.toString() ?? enhancedMessage['text']?.toString() ?? 'New chat',
//         );
//         print('✅ Created new session in ChatManagerProvider: $sessionId');
//       } else {
//         chatManager.addMessageToSession(sessionId, enhancedMessage);
//         print('✅ Added message to existing session in ChatManagerProvider: $sessionId');
//       }

//       print('💾 Message saved to ChatManagerProvider: ${enhancedMessage['text']}');
//       print('💾 Formatted text: ${enhancedMessage['formattedText']}');

//     } catch (e) {
//       print('❌ Error saving to ChatManagerProvider: $e');
//     }
//   }

//   Future<void> sendMessage() async {
//     // 🔥 ENHANCED: Check authentication before sending message
//     if (_accessToken == null || _tokenType == null) {
//       Get.snackbar(
//         "Authentication Missing",
//         "Please log in again to use chatbot",
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       await _initAuth(); // Try to re-initialize auth
//       return;
//     }
    
//     if (_selectedVehicle == null) {
//       Get.snackbar(
//         "Select Vehicle",
//         "Please choose a vehicle",
//         backgroundColor: Colors.redAccent,
//         colorText: Colors.white,
//       );
//       return;
//     }
    
//     final text = _controller.text.trim();
//     final vehicleId = _selectedVehicle!["_id"];

//     // Validate input
//     if (text.isEmpty && _selectedImage == null) {
//       Get.snackbar(
//         "Empty Message",
//         "Please enter a message or select an image",
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//       );
//       return;
//     }

//     // Ensure session exists
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

//     // Create user message
//     final userMessage = {
//       "text": userText,
//       "formattedText": _formatMessageForDisplay(userText), 
//       "isSent": true,
//       "vehicleId": vehicleId,
//       "brand": _selectedVehicle?['brand'],
//       "model": _selectedVehicle?['model'],
//       "timestamp": DateTime.now().toIso8601String(),
//     };

//     // Add image path to message if image exists
//     if (userImage != null) {
//       userMessage["imagePath"] = userImage.path;
//       userMessage["hasImage"] = true;
//     }

//     // 🔥 CRITICAL: Save to BOTH systems
//     // 1. Save to local SharedPreferences (your existing system)
//     setState(() {
//       _allSessions[_activeSessionId]!.add(userMessage);
//     });
//     await _saveSessions();

//     // 2. Save to ChatManagerProvider (for chat history)
//     await _saveToChatManager(_activeSessionId!, userMessage, 'New Chat');

//     // Send to backend with enhanced error handling
//     try {
//       final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/chat/message"));
      
//       // Add headers with enhanced auth validation
//       final authHeader = "$_tokenType $_accessToken";
//       request.headers["Authorization"] = authHeader;
//       request.headers["Accept"] = "application/json";

//       print('📤 Sending chat message with auth: $authHeader');

//       // Add session and message data
//       if (_sessionId != null) {
//         request.fields["session_id"] = _sessionId!;
//       }
      
//       // ✅ CRITICAL FIX: Always send message field with proper context
//       if (userText.isNotEmpty) {
//         request.fields["message"] = userText;
//       } else {
//         // If only image is sent, provide context for CV model
//         request.fields["message"] = "Analyze this vehicle image for any visible issues, damage, or maintenance needs";
//       }
      
//       // ✅ ENHANCED: Send vehicle data as proper JSON
//       request.fields["vehicle_json"] = json.encode(_selectedVehicle);

//       print('📤 Chat message details:');
//       print('   Message: ${request.fields["message"]}');
//       print('   Vehicle: ${_selectedVehicle!['brand']} ${_selectedVehicle!['model']}');
//       print('   Has Image: ${userImage != null}');
//       print('   Session ID: $_sessionId');

//       // ✅ ENHANCED: Add image with proper field name and handling
//       if (userImage != null) {
//         print('📸 Adding image to request: ${userImage.path}');
        
//         // Get file extension and mime type
//         final fileExtension = userImage.path.split('.').last.toLowerCase();
//         final mimeType = _getMimeType(fileExtension);
        
//         // ✅ CRITICAL: Use the exact field name expected by FastAPI - 'image'
//         final multipartFile = await http.MultipartFile.fromPath(
//           'image', // This MUST be 'image' to match FastAPI parameter
//           userImage.path,
//           contentType: MediaType('image', mimeType),
//           filename: 'vehicle_${_selectedVehicle!['brand']}_${_selectedVehicle!['model']}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
//         );
//         request.files.add(multipartFile);
        
//         final fileSize = userImage.lengthSync();
//         print('   Image details: ${fileSize ~/ 1024} KB, type: $mimeType');
//         print('   Field name: image');
//       }

//       // Send request with timeout
//       print('🚀 Sending request to backend...');
//       final streamedResponse = await request.send().timeout(Duration(seconds: 30));
//       final response = await http.Response.fromStream(streamedResponse);

//       print('📥 Response received:');
//       print('   Status: ${response.statusCode}');
//       print('   Body: ${response.body}');

//       if (response.statusCode == 200) {
//         try {
//           final decoded = json.decode(response.body);
//           print('   Response keys: ${decoded.keys}');
          
//           // ✅ ENHANCED: Handle different response formats
//           String reply;
//           if (decoded.containsKey("reply")) {
//             reply = decoded["reply"];
//           } else if (decoded.containsKey("message")) {
//             reply = decoded["message"];
//           } else if (decoded.containsKey("response")) {
//             reply = decoded["response"];
//           } else if (decoded.containsKey("analysis")) {
//             reply = decoded["analysis"];
//           } else {
//             // If no specific field found, try to get the first string value
//             reply = _extractReplyFromResponse(decoded);
//           }

//           // Create bot message
//           final botMessage = {
//             "text": reply, // Raw text with ** and ###
//             "formattedText": _formatMessageForDisplay(reply), // Formatted text without markdown
//             "isSent": false,
//             "timestamp": DateTime.now().toIso8601String(),
//             "isImageAnalysis": userImage != null,
//             "cvAnalysis": userImage != null,
//           };

//           // 🔥 CRITICAL: Save bot response to BOTH systems
//           // 1. Save to local SharedPreferences
//           setState(() {
//             _allSessions[_activeSessionId]!.add(botMessage);
//           });
//           await _saveSessions();

//           // 2. Save to ChatManagerProvider
//           await _saveToChatManager(_activeSessionId!, botMessage, decoded["chat_title"] ?? 'New Chat');
          
//           // Show success for image analysis
//           if (userImage != null) {
//             Get.snackbar(
//               "Image Analysis Complete",
//               "FixiBot has processed your vehicle image",
//               backgroundColor: Colors.green,
//               colorText: Colors.white,
//               duration: Duration(seconds: 3),
//             );
//           }
          
//         } catch (e) {
//           print('❌ JSON parsing error: $e');
//           print('   Raw response: ${response.body}');
//           _handleErrorResponse("Failed to parse server response: $e");
//         }
//       } else if (response.statusCode == 401) {
//         // 🔥 ENHANCED: Handle authentication errors specifically
//         _handleErrorResponse("Authentication failed. Please log in again.");
//         await _initAuth(); // Try to re-authenticate
//       } else if (response.statusCode == 422) {
//         // Handle validation errors from FastAPI
//         print('❌ FastAPI Validation Error: ${response.body}');
//         _handleValidationError(response.body);
//       } else if (response.statusCode == 415) {
//         _handleErrorResponse("Unsupported media type. The image format may not be supported.");
//       } else if (response.statusCode == 413) {
//         _handleErrorResponse("Image file too large. Please select a smaller image.");
//       } else {
//         print('❌ Server error: ${response.statusCode}');
//         _handleErrorResponse("Server error: ${response.statusCode}\n${response.body}");
//       }
//     } catch (e) {
//       print('❌ Network error: $e');
//       _handleErrorResponse("Network error: ${e.toString()}");
//     } finally {
//       setState(() {
//         _isProcessing = false;
//       });
//     }
//   }

//   // Add this helper method to format text for display
//   String _formatMessageForDisplay(String text) {
//     if (text.isEmpty) return '';
    
//     String formattedText = text;
    
//     // Remove ** for bold (keep the text, remove the markers)
//     formattedText = formattedText.replaceAll('**', '');
    
//     // Replace ### with bullet points
//     if (formattedText.contains('###')) {
//       formattedText = formattedText.replaceAll('###', '• ');
//     }
    
//     return formattedText;
//   }

//   // Helper method to extract reply from various response formats
//   String _extractReplyFromResponse(Map<String, dynamic> response) {
//     try {
//       // Try to find any string value in the response
//       for (var value in response.values) {
//         if (value is String && value.isNotEmpty) {
//           return value;
//         }
//       }
      
//       // If no string found, return the entire response as string
//       return response.toString();
//     } catch (e) {
//       return "I've processed your request. How can I help you further?";
//     }
//   }

//   String _getMimeType(String fileExtension) {
//     switch (fileExtension) {
//       case 'jpg':
//       case 'jpeg':
//         return 'jpeg';
//       case 'png':
//         return 'png';
//       case 'gif':
//         return 'gif';
//       case 'webp':
//         return 'webp';
//       default:
//         return 'jpeg';
//     }
//   }

//   String _formatCVResponse(dynamic cvAnalysis) {
//     if (cvAnalysis is String) {
//       return cvAnalysis;
//     } else if (cvAnalysis is Map) {
//       final issues = cvAnalysis['issues'] ?? [];
//       final confidence = cvAnalysis['confidence'] ?? 0.0;
//       final recommendations = cvAnalysis['recommendations'] ?? [];
      
//       String response = "🔍 **Vehicle Image Analysis Complete**\n\n";
      
//       if (issues.isNotEmpty) {
//         response += "**Detected Issues:**\n";
//         for (var issue in issues) {
//           response += "• $issue\n";
//         }
//       } else {
//         response += "✅ No major issues detected.\n";
//       }
      
//       if (recommendations.isNotEmpty) {
//         response += "\n**Recommendations:**\n";
//         for (var rec in recommendations) {
//           response += "• $rec\n";
//         }
//       }
      
//       response += "\n_Confidence: ${(confidence * 100).toStringAsFixed(1)}%_";
//       return response;
//     }
    
//     return "I've analyzed your vehicle image. Please describe any specific concerns you have.";
//   }

//   void _handleValidationError(String errorBody) {
//     try {
//       final decoded = json.decode(errorBody);
//       final details = decoded['detail'];
//       String errorMessage = "Validation error: ";
      
//       if (details is List) {
//         for (var detail in details) {
//           errorMessage += "${detail['msg']} (${detail['loc']}); ";
//         }
//       } else {
//         errorMessage += "Invalid request format";
//       }
      
//       _handleErrorResponse(errorMessage);
//     } catch (e) {
//       _handleErrorResponse("Request validation failed: $errorBody");
//     }
//   }

//   void _handleErrorResponse(String error) {
//     print('❌ Chat error: $error');
    
//     setState(() {
//       _allSessions[_activeSessionId]!.add({
//         "text": "⚠️ **FixiBot Error**\n\nI encountered an issue while processing your request.\n\n**Error Details:** $error\n\nPlease try again or contact support if the problem persists.",
//         "isSent": false,
//         "isError": true,
//         "timestamp": DateTime.now().toIso8601String(),
//       });
//     });
    
//     Get.snackbar(
//       "Processing Error",
//       "Failed to process your message",
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//       duration: Duration(seconds: 5),
//     );
//   }

//   Future<void> _pickImage() async {
//     try {
//       final XFile? file = await _picker.pickImage(
//         source: ImageSource.gallery, 
//         imageQuality: 85,
//         maxWidth: 1200,
//         maxHeight: 1200,
//       );
      
//       if (file != null) {
//         final imageFile = File(file.path);
        
//         // Validate file size (max 5MB)
//         final fileSize = await imageFile.length();
//         if (fileSize > 5 * 1024 * 1024) {
//           Get.snackbar(
//             "File Too Large",
//             "Please select an image smaller than 5MB",
//             backgroundColor: Colors.orange,
//             colorText: Colors.white,
//           );
//           return;
//         }
        
//         setState(() => _selectedImage = imageFile);
        
//         // Auto-focus on text input after image selection
//         FocusScope.of(context).requestFocus(FocusNode());
//         Future.delayed(Duration(milliseconds: 100), () {
//           FocusScope.of(context).requestFocus(FocusNode());
//         });
        
//         print('📸 Image selected: ${file.path} (${fileSize ~/ 1024} KB)');
//       }
//     } catch (e) {
//       print('❌ Image picker error: $e');
//       Get.snackbar(
//         "Error",
//         "Failed to pick image: ${e.toString()}",
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }

//   /* ----------------- UI ------------------ */

//   Widget _buildMessageBubble(Map<String, dynamic> m) {
//     final isUser = m["isSent"] == true;
//     final hasImage = m["hasImage"] == true;
//     final isError = m["isError"] == true;
//     final isCVAnalysis = m["cvAnalysis"] == true;
    
//     return Align(
//       alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: isError 
//             ? Colors.orange.shade100
//             : isCVAnalysis
//               ? Colors.blue.shade50
//               : isUser 
//                 ? AppColors.mainColor 
//                 : Colors.grey.shade300,
//           borderRadius: BorderRadius.circular(12),
//           border: isError 
//             ? Border.all(color: Colors.orange)
//             : isCVAnalysis
//               ? Border.all(color: Colors.blue.shade200)
//               : null,
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Display image if message has one
//             if (hasImage && m.containsKey("imagePath"))
//               Column(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: Image.file(
//                       File(m["imagePath"]),
//                       width: 200,
//                       height: 150,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) {
//                         return Container(
//                           width: 200,
//                           height: 150,
//                           color: Colors.grey.shade200,
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.broken_image, color: Colors.grey, size: 40),
//                               SizedBox(height: 8),
//                               Text("Image not available", style: TextStyle(fontSize: 10)),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                 ],
//               ),
            
//             // Display text message with rich text formatting
//             if (m.containsKey("text") && m["text"].toString().isNotEmpty)
//               Padding(
//                 padding: EdgeInsets.only(top: hasImage ? 4 : 0),
//                 child: _buildRichTextMessage(
//                   m["text"].toString(),
//                   isUser: isUser,
//                   isError: isError,
//                   isCVAnalysis: isCVAnalysis,
//                 ),
//               ),
            
//             // Show analysis type indicator
//             if ((isCVAnalysis || m["isImageAnalysis"] == true) && !isUser)
//               Padding(
//                 padding: const EdgeInsets.only(top: 8),
//                 child: Row(
//                   children: [
//                     Icon(
//                       isCVAnalysis ? Icons.analytics : Icons.photo_library, 
//                       size: 12, 
//                       color: isCVAnalysis ? Colors.blue : Colors.green
//                     ),
//                     SizedBox(width: 4),
//                     Text(
//                       isCVAnalysis ? "CV Analysis" : "Image Analysis",
//                       style: TextStyle(
//                         fontSize: 10,
//                         color: isCVAnalysis ? Colors.blue : Colors.green,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRichTextMessage(String text, {bool isUser = false, bool isError = false, bool isCVAnalysis = false}) {
//     final textColor = isError 
//       ? Colors.orange.shade900
//       : isCVAnalysis
//         ? Colors.blue.shade900
//         : isUser 
//           ? Colors.white 
//           : Colors.black87;

//     final baseStyle = TextStyle(
//       color: textColor,
//       fontSize: 14,
//       fontWeight: isError || isCVAnalysis ? FontWeight.w600 : FontWeight.normal,
//       height: 1.4,
//     );

//     final boldStyle = TextStyle(
//       color: textColor,
//       fontSize: 14,
//       fontWeight: FontWeight.bold,
//       height: 1.4,
//     );

//     // If text contains ### for bullet points, use Column with multiple widgets
//     if (text.contains('###')) {
//       return _buildBulletPoints(text, textColor: textColor, baseStyle: baseStyle, boldStyle: boldStyle);
//     }

//     // Simple and reliable parsing for bold text
//     final List<TextSpan> spans = [];
//     final parts = text.split('**');
    
//     for (int i = 0; i < parts.length; i++) {
//       // Even indices are normal text, odd indices are bold text
//       final isBold = i % 2 == 1;
//       if (parts[i].isNotEmpty) {
//         spans.add(TextSpan(
//           text: parts[i],
//           style: isBold ? boldStyle : baseStyle,
//         ));
//       }
//     }

//     return RichText(
//       text: TextSpan(children: spans),
//     );
//   }

//   Widget _buildBulletPoints(String text, {required Color textColor, required TextStyle baseStyle, required TextStyle boldStyle}) {
//     final lines = text.split('\n');
//     final List<Widget> bulletWidgets = [];

//     for (final line in lines) {
//       if (line.trim().startsWith('###')) {
//         // This is a bullet point line
//         final bulletText = line.replaceFirst('###', '').trim();
        
//         // Parse bold text within the bullet point
//         final List<TextSpan> bulletSpans = [];
//         final bulletParts = bulletText.split('**');
        
//         for (int i = 0; i < bulletParts.length; i++) {
//           final isBold = i % 2 == 1;
//           if (bulletParts[i].isNotEmpty) {
//             bulletSpans.add(TextSpan(
//               text: bulletParts[i],
//               style: isBold ? boldStyle : baseStyle,
//             ));
//           }
//         }

//         bulletWidgets.add(
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 2.0),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(top: 2.0, right: 8.0),
//                   child: Icon(
//                     Icons.arrow_forward_ios,
//                     size: 12,
//                     color: textColor,
//                   ),
//                 ),
//                 Expanded(
//                   child: RichText(
//                     text: TextSpan(children: bulletSpans),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       } else if (line.trim().isNotEmpty) {
//         // Regular text line (not a bullet point)
//         final List<TextSpan> regularSpans = [];
//         final regularParts = line.split('**');
        
//         for (int i = 0; i < regularParts.length; i++) {
//           final isBold = i % 2 == 1;
//           if (regularParts[i].isNotEmpty) {
//             regularSpans.add(TextSpan(
//               text: regularParts[i],
//               style: isBold ? boldStyle : baseStyle,
//             ));
//           }
//         }

//         bulletWidgets.add(
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 2.0),
//             child: RichText(
//               text: TextSpan(children: regularSpans),
//             ),
//           ),
//         );
//       } else {
//         // Empty line - add some spacing
//         bulletWidgets.add(const SizedBox(height: 4.0));
//       }
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: bulletWidgets,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final messages = _activeSessionId != null ? _allSessions[_activeSessionId] ?? [] : [];

//     return Scaffold(
//       backgroundColor: AppColors.secondaryColor,
//       appBar: CustomAppBar(
//         title: "FixiBot",
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.history, color: AppColors.secondaryColor),
//             onPressed: () {
//               Get.to(ChatHistoryParentWidget());
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.add_comment, color: AppColors.secondaryColor),
//             tooltip: "New Chat",
//             onPressed: _startNewChat,
//           ),
//           // 🔥 ADDED: Debug button for authentication issues
//           IconButton(
//             icon: const Icon(Icons.build, color: AppColors.secondaryColor),
//             tooltip: "Fix Authentication",
//             onPressed: _manualAuthFix,
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

//           // Chat messages with loading indicator
//           Expanded(
//             child: Column(
//               children: [
//                 // Messages list
//                 Expanded(
//                   child: ListView.builder(
//                     padding: const EdgeInsets.all(10),
//                     itemCount: messages.length,
//                     itemBuilder: (_, i) => _buildMessageBubble(messages[i]),
//                   ),
//                 ),
                
//                 // Loading indicator
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
//                     padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
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
//                                             setState(() => _selectedVehicle = null);
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
// }







//greaaatttt
// import 'dart:convert';
// import 'dart:io';
// import 'package:fixibot_app/constants/appConfig.dart';
// import 'package:fixibot_app/constants/app_colors.dart';
// import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
// import 'package:fixibot_app/screens/chatbot/chatHistoryParent.dart';
// import 'package:fixibot_app/screens/chatbot/chatviewHistory.dart';
// import 'package:fixibot_app/screens/chatbot/provider/chatManagerProvider.dart';
// import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
// import 'package:fixibot_app/widgets/customAppBar.dart';
// import 'package:fixibot_app/widgets/wrapper.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// /// Keys to store/retrieve persistent data - NOW USER-SPECIFIC
// String getSessionsKey(String userId) => "all_chat_sessions_$userId";
// String getCurrentSessionKey(String userId) => "current_session_id_$userId";

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
//   final ChatManagerProvider _chatManager = Get.find<ChatManagerProvider>();
//   final baseUrl = AppConfig.baseUrl;

//   // Auth & session
//   String? _accessToken;
//   String? _tokenType;
//   String? _sessionId;
//   String? _currentUserId;

//   // UI / chat state
//   File? _selectedImage;
//   Map<String, dynamic>? _selectedVehicle;
//   bool _isProcessing = false;

//   /// All sessions are stored here:
//   /// key = sessionId, value = list of message maps
//   Map<String, List<Map<String, dynamic>>> _allSessions = {};
//   String? _activeSessionId;

//   @override
//   void initState() {
//     super.initState();
//     _initializeChatScreen();
//   }

//   Future<void> _initializeChatScreen() async {
//     await vehicleController.fetchUserVehicles();
//     await _initAuth();
//     // Don't load sessions automatically - start fresh every time
//     _startFreshSession();
//   }

//   /* ----------------- User-Specific Session Management ------------------ */

//   Future<void> _loadSessions() async {
//     if (_currentUserId == null) return;
    
//     final sp = await SharedPreferences.getInstance();
//     final stored = sp.getString(getSessionsKey(_currentUserId!));
//     final currentId = sp.getString(getCurrentSessionKey(_currentUserId!));

//     if (stored != null) {
//       try {
//         final Map<String, dynamic> decoded = jsonDecode(stored);
//         _allSessions = decoded.map(
//             (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v as List)));
//         print('📥 Loaded ${_allSessions.length} sessions for user: $_currentUserId');
//       } catch (e) {
//         print('❌ Error loading sessions: $e');
//         _allSessions = {};
//       }
//     } else {
//       _allSessions = {};
//     }

//     // 🔥 CRITICAL FIX: Don't automatically restore last session
//     // Always start with a fresh session when opening chat screen
//     _startFreshSession();
//   }

//   Future<void> _saveSessions() async {
//     if (_currentUserId == null) return;
    
//     final sp = await SharedPreferences.getInstance();
//     await sp.setString(getSessionsKey(_currentUserId!), jsonEncode(_allSessions));
//     if (_activeSessionId != null) {
//       await sp.setString(getCurrentSessionKey(_currentUserId!), _activeSessionId!);
//     }
//     print('💾 Saved ${_allSessions.length} sessions for user: $_currentUserId');
//   }

//   void _startFreshSession() {
//     // Always create a new session when opening the chat screen
//     final newId = DateTime.now().millisecondsSinceEpoch.toString();
//     setState(() {
//       _allSessions[newId] = [];
//       _activeSessionId = newId;
//       _selectedVehicle = null; // Reset vehicle selection
//       _selectedImage = null; // Reset any selected image
//     });
//     print('🆕 Started fresh session: $newId for user: $_currentUserId');
//   }

//   void _startNewLocalSession() {
//     final newId = DateTime.now().millisecondsSinceEpoch.toString();
//     _allSessions[newId] = [];
//     _activeSessionId = newId;
//   }

//   Future<void> _startNewChat() async {
//     setState(() {
//       _startNewLocalSession();
//       _selectedVehicle = null; // Reset vehicle when starting new chat
//     });
//     await _saveSessions();
//   }

//   // Delete a session
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
    
//     // Also delete from ChatManagerProvider
//     try {
//       if (Get.isRegistered<ChatManagerProvider>()) {
//         final chatManager = Get.find<ChatManagerProvider>();
//         if (chatManager.sessionExists(sessionId)) {
//           chatManager.deleteSession(sessionId);
//           print('✅ Session deleted from ChatManagerProvider: $sessionId');
//         }
//       }
//     } catch (e) {
//       print('❌ Error deleting from ChatManagerProvider: $e');
//     }
//   }

//   /* ----------------- Backend Auth/Session ------------------ */

//   Future<void> _initAuth() async {
//     _accessToken = await _prefs.getString("access_token");
//     _tokenType = await _prefs.getString("token_type");
//     _currentUserId = await _prefs.getCurrentUserId();
    
//     print('🔐 Chatbot Auth Check:');
//     print('   User ID: ${_currentUserId ?? "❌ NULL"}');
//     print('   Access Token: ${_accessToken != null ? "✅" : "❌"}');
//     print('   Token Type: ${_tokenType ?? "NULL"}');
    
//     // AUTO-FIX: If token_type is missing but access_token exists (Google user issue)
//     if (_accessToken != null && _accessToken!.isNotEmpty && (_tokenType == null || _tokenType!.isEmpty)) {
//       print('🛠️ Auto-fixing missing token_type for Google user...');
//       await _prefs.saveString('token_type', 'bearer');
//       _tokenType = 'bearer';
//       print('✅ Auto-fixed: token_type set to "bearer"');
      
//       Get.snackbar(
//         "Ready!", 
//         "Chatbot authentication completed",
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//         duration: Duration(seconds: 2),
//       );
//     }
    
//     if (_accessToken == null || _tokenType == null || _currentUserId == null) {
//       Get.snackbar(
//         "Authentication Required", 
//         "Please login again to use chatbot",
//         backgroundColor: Colors.redAccent, 
//         colorText: Colors.white,
//         duration: Duration(seconds: 5),
//       );
//       await _debugChatbotAuth();
//       return;
//     }
    
//     await _startServerSession();
//   }

//   Future<void> _debugChatbotAuth() async {
//     final prefs = await SharedPreferences.getInstance();
    
//     print('=== CHATBOT AUTH DEBUG ===');
//     print('User ID: ${await _prefs.getCurrentUserId() ?? "❌ NULL"}');
//     print('Access Token: ${prefs.getString('access_token') != null ? "✅ EXISTS" : "❌ MISSING"}');
//     print('Token Type: ${prefs.getString('token_type') ?? "❌ NULL"}');
//     print('Email: ${prefs.getString('email') ?? "❌ NULL"}');
    
//     final hasAccessToken = prefs.getString('access_token') != null;
//     final hasTokenType = prefs.getString('token_type') != null;
//     final hasUserId = await _prefs.getCurrentUserId() != null;
    
//     print('Chatbot Ready: ${hasAccessToken && hasTokenType && hasUserId}');
//     print('==========================');
    
//     if (!hasAccessToken || !hasTokenType || !hasUserId) {
//       Get.snackbar(
//         "Auth Issue", 
//         "Missing authentication data for chatbot",
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//       );
//     }
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

//   /* ----------------- Per-Vehicle Session Logic ------------------ */

//   Future<String?> _getSessionIdForVehicle(String vehicleId) async {
//     if (_currentUserId == null) return null;
    
//     final sp = await SharedPreferences.getInstance();
//     final stored = sp.getString(getSessionsKey(_currentUserId!));
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
//     final newId = DateTime.now().millisecondsSinceEpoch.toString();
//     _allSessions[newId] = [];
//     _activeSessionId = newId;
//     await _saveSessions();
//     return newId;
//   }

//   Future<void> _activateVehicleSession(String vehicleId) async {
//     String? sessionId = await _getSessionIdForVehicle(vehicleId);
//     if (sessionId == null) {
//       sessionId = await _createNewSessionForVehicle(vehicleId);
//     }
//     setState(() => _activeSessionId = sessionId);
//     final sp = await SharedPreferences.getInstance();
//     await sp.setString(getCurrentSessionKey(_currentUserId!), sessionId!);
//   }

//   // Get correct vehicle icon based on category
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

//   // // Helper method to save messages to ChatManagerProvider
//   // Future<void> _saveToChatManager(String sessionId, Map<String, dynamic> message, String chatTitle) async {
//   //   try {
//   //     if (!Get.isRegistered<ChatManagerProvider>()) {
//   //       print('❌ ChatManagerProvider not registered');
//   //       return;
//   //     }

//   //     final chatManager = Get.find<ChatManagerProvider>();
      
//   //     if (!chatManager.isInitialized) {
//   //       print('❌ ChatManagerProvider not initialized, trying to initialize...');
        
//   //       final userId = await _prefs.getCurrentUserId();
//   //       if (userId != null) {
//   //         await chatManager.initializeForUser(userId);
//   //         print('✅ ChatManagerProvider initialized in chat screen');
//   //       } else {
//   //         print('❌ No user ID found for ChatManagerProvider initialization');
//   //         return;
//   //       }
//   //     }

//   //     if (!chatManager.sessionExists(sessionId)) {
//   //       chatManager.createSession(
//   //         id: sessionId,
//   //         title: chatTitle,
//   //         firstMessage: message['text']?.toString() ?? 'New chat',
//   //       );
//   //       print('✅ Created new session in ChatManagerProvider: $sessionId');
//   //     } else {
//   //       chatManager.addMessageToSession(sessionId, message);
//   //       print('✅ Added message to existing session in ChatManagerProvider: $sessionId');
//   //     }

//   //     print('💾 Message saved to ChatManagerProvider: ${message['text']}');

//   //   } catch (e) {
//   //     print('❌ Error saving to ChatManagerProvider: $e');
//   //   }
//   // }

// Future<void> _saveToChatManager(String sessionId, Map<String, dynamic> message, String chatTitle) async {
//   try {
//     if (!Get.isRegistered<ChatManagerProvider>()) {
//       print('❌ ChatManagerProvider not registered');
//       return;
//     }

//     final chatManager = Get.find<ChatManagerProvider>();
    
//     if (!chatManager.isInitialized) {
//       print('❌ ChatManagerProvider not initialized, trying to initialize...');
      
//       final userId = await _prefs.getCurrentUserId();
//       if (userId != null) {
//         await chatManager.initializeForUser(userId);
//         print('✅ ChatManagerProvider initialized in chat screen');
//       } else {
//         print('❌ No user ID found for ChatManagerProvider initialization');
//         return;
//       }
//     }

//     // ENHANCED: Add formatted text to the message
//     final enhancedMessage = Map<String, dynamic>.from(message);
//     if (message.containsKey('text') && message['text'] is String) {
//       enhancedMessage['formattedText'] = _formatMessageForDisplay(message['text']);
//     }

//     if (!chatManager.sessionExists(sessionId)) {
//       chatManager.createSession(
//         id: sessionId,
//         title: chatTitle,
//         firstMessage: enhancedMessage['formattedText']?.toString() ?? enhancedMessage['text']?.toString() ?? 'New chat',
//       );
//       print('✅ Created new session in ChatManagerProvider: $sessionId');
//     } else {
//       chatManager.addMessageToSession(sessionId, enhancedMessage);
//       print('✅ Added message to existing session in ChatManagerProvider: $sessionId');
//     }

//     print('💾 Message saved to ChatManagerProvider: ${enhancedMessage['text']}');
//     print('💾 Formatted text: ${enhancedMessage['formattedText']}');

//   } catch (e) {
//     print('❌ Error saving to ChatManagerProvider: $e');
//   }
// }

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
    
//     final text = _controller.text.trim();
//     final vehicleId = _selectedVehicle!["_id"];

//     // Validate input
//     if (text.isEmpty && _selectedImage == null) {
//       Get.snackbar(
//         "Empty Message",
//         "Please enter a message or select an image",
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//       );
//       return;
//     }

//     // Ensure session exists
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

//     // Create user message
//     final userMessage = {
//       "text": userText,
//       "formattedText": _formatMessageForDisplay(userText), 
//       "isSent": true,
//       "vehicleId": vehicleId,
//       "brand": _selectedVehicle?['brand'],
//       "model": _selectedVehicle?['model'],
//       "timestamp": DateTime.now().toIso8601String(),
//     };

//     // Add image path to message if image exists
//     if (userImage != null) {
//       userMessage["imagePath"] = userImage.path;
//       userMessage["hasImage"] = true;
//     }

//     // 🔥 CRITICAL: Save to BOTH systems
//     // 1. Save to local SharedPreferences (your existing system)
//     setState(() {
//       _allSessions[_activeSessionId]!.add(userMessage);
//     });
//     await _saveSessions();

//     // 2. Save to ChatManagerProvider (for chat history)
//     await _saveToChatManager(_activeSessionId!, userMessage, 'New Chat');

//     // Send to backend with enhanced error handling
//     try {
//       final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/chat/message"));
      
//       // Add headers
//       request.headers["Authorization"] = "$_tokenType $_accessToken";
//       request.headers["Accept"] = "application/json";

//       // Add session and message data
//       if (_sessionId != null) {
//         request.fields["session_id"] = _sessionId!;
//       }
      
//       // ✅ CRITICAL FIX: Always send message field with proper context
//       if (userText.isNotEmpty) {
//         request.fields["message"] = userText;
//       } else {
//         // If only image is sent, provide context for CV model
//         request.fields["message"] = "Analyze this vehicle image for any visible issues, damage, or maintenance needs";
//       }
      
//       // ✅ ENHANCED: Send vehicle data as proper JSON
//       request.fields["vehicle_json"] = json.encode(_selectedVehicle);

//       print('📤 Sending chat message:');
//       print('   Message: ${request.fields["message"]}');
//       print('   Vehicle: ${_selectedVehicle!['brand']} ${_selectedVehicle!['model']}');
//       print('   Has Image: ${userImage != null}');
//       print('   Session ID: $_sessionId');

//       // ✅ ENHANCED: Add image with proper field name and handling
//       if (userImage != null) {
//         print('📸 Adding image to request: ${userImage.path}');
        
//         // Get file extension and mime type
//         final fileExtension = userImage.path.split('.').last.toLowerCase();
//         final mimeType = _getMimeType(fileExtension);
        
//         // ✅ CRITICAL: Use the exact field name expected by FastAPI - 'image'
//         final multipartFile = await http.MultipartFile.fromPath(
//           'image', // This MUST be 'image' to match FastAPI parameter
//           userImage.path,
//           contentType: MediaType('image', mimeType),
//           filename: 'vehicle_${_selectedVehicle!['brand']}_${_selectedVehicle!['model']}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
//         );
//         request.files.add(multipartFile);
        
//         final fileSize = userImage.lengthSync();
//         print('   Image details: ${fileSize ~/ 1024} KB, type: $mimeType');
//         print('   Field name: image');
//       }

//       // Send request with timeout
//       print('🚀 Sending request to backend...');
//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);

//       print('📥 Response received:');
//       print('   Status: ${response.statusCode}');
//       print('   Body: ${response.body}');

//       if (response.statusCode == 200) {
//         try {
//           final decoded = json.decode(response.body);
//           print('   Response keys: ${decoded.keys}');
          
//           // ✅ ENHANCED: Handle different response formats
//           String reply;
//           if (decoded.containsKey("reply")) {
//             reply = decoded["reply"];
//           } else if (decoded.containsKey("message")) {
//             reply = decoded["message"];
//           } else if (decoded.containsKey("response")) {
//             reply = decoded["response"];
//           } else if (decoded.containsKey("analysis")) {
//             reply = decoded["analysis"];
//           } else {
//             // If no specific field found, try to get the first string value
//             reply = _extractReplyFromResponse(decoded);
//           }

//           // Create bot message
//           // final botMessage = {
//           //   "text": reply,
//           //   "isSent": false,
//           //   "timestamp": DateTime.now().toIso8601String(),
//           //   "isImageAnalysis": userImage != null,
//           //   "cvAnalysis": userImage != null,
//           // };

//           // In sendMessage() method, when creating the bot message:
// final botMessage = {
//   "text": reply, // Raw text with ** and ###
//   "formattedText": _formatMessageForDisplay(reply), // Formatted text without markdown
//   "isSent": false,
//   "timestamp": DateTime.now().toIso8601String(),
//   "isImageAnalysis": userImage != null,
//   "cvAnalysis": userImage != null,
// };



//           // 🔥 CRITICAL: Save bot response to BOTH systems
//           // 1. Save to local SharedPreferences
//           setState(() {
//             _allSessions[_activeSessionId]!.add(botMessage);
//           });
//           await _saveSessions();

//           // 2. Save to ChatManagerProvider
//           await _saveToChatManager(_activeSessionId!, botMessage, decoded["chat_title"] ?? 'New Chat');
          
//           // Show success for image analysis
//           if (userImage != null) {
//             Get.snackbar(
//               "Image Analysis Complete",
//               "FixiBot has processed your vehicle image",
//               backgroundColor: Colors.green,
//               colorText: Colors.white,
//               duration: Duration(seconds: 3),
//             );
//           }
          
//         } catch (e) {
//           print('❌ JSON parsing error: $e');
//           print('   Raw response: ${response.body}');
//           _handleErrorResponse("Failed to parse server response: $e");
//         }
//       } else if (response.statusCode == 422) {
//         // Handle validation errors from FastAPI
//         print('❌ FastAPI Validation Error: ${response.body}');
//         _handleValidationError(response.body);
//       } else if (response.statusCode == 415) {
//         _handleErrorResponse("Unsupported media type. The image format may not be supported.");
//       } else if (response.statusCode == 413) {
//         _handleErrorResponse("Image file too large. Please select a smaller image.");
//       } else {
//         print('❌ Server error: ${response.statusCode}');
//         _handleErrorResponse("Server error: ${response.statusCode}\n${response.body}");
//       }
//     } catch (e) {
//       print('❌ Network error: $e');
//       _handleErrorResponse("Network error: ${e.toString()}");
//     } finally {
//       setState(() {
//         _isProcessing = false;
//       });
//     }
//   }
// // Add this helper method to format text for display
// String _formatMessageForDisplay(String text) {
//   if (text.isEmpty) return '';
  
//   String formattedText = text;
  
//   // Remove ** for bold (keep the text, remove the markers)
//   formattedText = formattedText.replaceAll('**', '');
  
//   // Replace ### with bullet points
//   if (formattedText.contains('###')) {
//     formattedText = formattedText.replaceAll('###', '• ');
//   }
  
//   return formattedText;
// }
//   // Helper method to extract reply from various response formats
//   String _extractReplyFromResponse(Map<String, dynamic> response) {
//     try {
//       // Try to find any string value in the response
//       for (var value in response.values) {
//         if (value is String && value.isNotEmpty) {
//           return value;
//         }
//       }
      
//       // If no string found, return the entire response as string
//       return response.toString();
//     } catch (e) {
//       return "I've processed your request. How can I help you further?";
//     }
//   }

//   String _getMimeType(String fileExtension) {
//     switch (fileExtension) {
//       case 'jpg':
//       case 'jpeg':
//         return 'jpeg';
//       case 'png':
//         return 'png';
//       case 'gif':
//         return 'gif';
//       case 'webp':
//         return 'webp';
//       default:
//         return 'jpeg';
//     }
//   }

//   String _formatCVResponse(dynamic cvAnalysis) {
//     if (cvAnalysis is String) {
//       return cvAnalysis;
//     } else if (cvAnalysis is Map) {
//       final issues = cvAnalysis['issues'] ?? [];
//       final confidence = cvAnalysis['confidence'] ?? 0.0;
//       final recommendations = cvAnalysis['recommendations'] ?? [];
      
//       String response = "🔍 **Vehicle Image Analysis Complete**\n\n";
      
//       if (issues.isNotEmpty) {
//         response += "**Detected Issues:**\n";
//         for (var issue in issues) {
//           response += "• $issue\n";
//         }
//       } else {
//         response += "✅ No major issues detected.\n";
//       }
      
//       if (recommendations.isNotEmpty) {
//         response += "\n**Recommendations:**\n";
//         for (var rec in recommendations) {
//           response += "• $rec\n";
//         }
//       }
      
//       response += "\n_Confidence: ${(confidence * 100).toStringAsFixed(1)}%_";
//       return response;
//     }
    
//     return "I've analyzed your vehicle image. Please describe any specific concerns you have.";
//   }

//   void _handleValidationError(String errorBody) {
//     try {
//       final decoded = json.decode(errorBody);
//       final details = decoded['detail'];
//       String errorMessage = "Validation error: ";
      
//       if (details is List) {
//         for (var detail in details) {
//           errorMessage += "${detail['msg']} (${detail['loc']}); ";
//         }
//       } else {
//         errorMessage += "Invalid request format";
//       }
      
//       _handleErrorResponse(errorMessage);
//     } catch (e) {
//       _handleErrorResponse("Request validation failed: $errorBody");
//     }
//   }

//   void _handleErrorResponse(String error) {
//     print('❌ Chat error: $error');
    
//     setState(() {
//       _allSessions[_activeSessionId]!.add({
//         "text": "⚠️ **FixiBot Error**\n\nI encountered an issue while processing your request.\n\n**Error Details:** $error\n\nPlease try again or contact support if the problem persists.",
//         "isSent": false,
//         "isError": true,
//         "timestamp": DateTime.now().toIso8601String(),
//       });
//     });
    
//     Get.snackbar(
//       "Processing Error",
//       "Failed to process your message",
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//       duration: Duration(seconds: 5),
//     );
//   }

//   Future<void> _pickImage() async {
//     try {
//       final XFile? file = await _picker.pickImage(
//         source: ImageSource.gallery, 
//         imageQuality: 85,
//         maxWidth: 1200,
//         maxHeight: 1200,
//       );
      
//       if (file != null) {
//         final imageFile = File(file.path);
        
//         // Validate file size (max 5MB)
//         final fileSize = await imageFile.length();
//         if (fileSize > 5 * 1024 * 1024) {
//           Get.snackbar(
//             "File Too Large",
//             "Please select an image smaller than 5MB",
//             backgroundColor: Colors.orange,
//             colorText: Colors.white,
//           );
//           return;
//         }
        
//         setState(() => _selectedImage = imageFile);
        
//         // Auto-focus on text input after image selection
//         FocusScope.of(context).requestFocus(FocusNode());
//         Future.delayed(Duration(milliseconds: 100), () {
//           FocusScope.of(context).requestFocus(FocusNode());
//         });
        
//         print('📸 Image selected: ${file.path} (${fileSize ~/ 1024} KB)');
//       }
//     } catch (e) {
//       print('❌ Image picker error: $e');
//       Get.snackbar(
//         "Error",
//         "Failed to pick image: ${e.toString()}",
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }

//   /* ----------------- UI ------------------ */

// Widget _buildMessageBubble(Map<String, dynamic> m) {
//   final isUser = m["isSent"] == true;
//   final hasImage = m["hasImage"] == true;
//   final isError = m["isError"] == true;
//   final isCVAnalysis = m["cvAnalysis"] == true;
  
//   return Align(
//     alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//     child: Container(
//       margin: const EdgeInsets.symmetric(vertical: 4),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: isError 
//           ? Colors.orange.shade100
//           : isCVAnalysis
//             ? Colors.blue.shade50
//             : isUser 
//               ? AppColors.mainColor 
//               : Colors.grey.shade300,
//         borderRadius: BorderRadius.circular(12),
//         border: isError 
//           ? Border.all(color: Colors.orange)
//           : isCVAnalysis
//             ? Border.all(color: Colors.blue.shade200)
//             : null,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Display image if message has one
//           if (hasImage && m.containsKey("imagePath"))
//             Column(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: Image.file(
//                     File(m["imagePath"]),
//                     width: 200,
//                     height: 150,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Container(
//                         width: 200,
//                         height: 150,
//                         color: Colors.grey.shade200,
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.broken_image, color: Colors.grey, size: 40),
//                             SizedBox(height: 8),
//                             Text("Image not available", style: TextStyle(fontSize: 10)),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//                 SizedBox(height: 8),
//               ],
//             ),
          
//           // Display text message with rich text formatting
//           if (m.containsKey("text") && m["text"].toString().isNotEmpty)
//             Padding(
//               padding: EdgeInsets.only(top: hasImage ? 4 : 0),
//               child: _buildRichTextMessage(
//                 m["text"].toString(),
//                 isUser: isUser,
//                 isError: isError,
//                 isCVAnalysis: isCVAnalysis,
//               ),
//             ),
          
//           // Show analysis type indicator
//           if ((isCVAnalysis || m["isImageAnalysis"] == true) && !isUser)
//             Padding(
//               padding: const EdgeInsets.only(top: 8),
//               child: Row(
//                 children: [
//                   Icon(
//                     isCVAnalysis ? Icons.analytics : Icons.photo_library, 
//                     size: 12, 
//                     color: isCVAnalysis ? Colors.blue : Colors.green
//                   ),
//                   SizedBox(width: 4),
//                   Text(
//                     isCVAnalysis ? "CV Analysis" : "Image Analysis",
//                     style: TextStyle(
//                       fontSize: 10,
//                       color: isCVAnalysis ? Colors.blue : Colors.green,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     ),
//   );


// }

// Widget _buildRichTextMessage(String text, {bool isUser = false, bool isError = false, bool isCVAnalysis = false}) {
//   final textColor = isError 
//     ? Colors.orange.shade900
//     : isCVAnalysis
//       ? Colors.blue.shade900
//       : isUser 
//         ? Colors.white 
//         : Colors.black87;

//   final baseStyle = TextStyle(
//     color: textColor,
//     fontSize: 14,
//     fontWeight: isError || isCVAnalysis ? FontWeight.w600 : FontWeight.normal,
//     height: 1.4,
//   );

//   final boldStyle = TextStyle(
//     color: textColor,
//     fontSize: 14,
//     fontWeight: FontWeight.bold,
//     height: 1.4,
//   );

//   // If text contains ### for bullet points, use Column with multiple widgets
//   if (text.contains('###')) {
//     return _buildBulletPoints(text, textColor: textColor, baseStyle: baseStyle, boldStyle: boldStyle);
//   }

//   // Simple and reliable parsing for bold text
//   final List<TextSpan> spans = [];
//   final parts = text.split('**');
  
//   for (int i = 0; i < parts.length; i++) {
//     // Even indices are normal text, odd indices are bold text
//     final isBold = i % 2 == 1;
//     if (parts[i].isNotEmpty) {
//       spans.add(TextSpan(
//         text: parts[i],
//         style: isBold ? boldStyle : baseStyle,
//       ));
//     }
//   }

//   return RichText(
//     text: TextSpan(children: spans),
//   );
// }

// Widget _buildBulletPoints(String text, {required Color textColor, required TextStyle baseStyle, required TextStyle boldStyle}) {
//   final lines = text.split('\n');
//   final List<Widget> bulletWidgets = [];

//   for (final line in lines) {
//     if (line.trim().startsWith('###')) {
//       // This is a bullet point line
//       final bulletText = line.replaceFirst('###', '').trim();
      
//       // Parse bold text within the bullet point
//       final List<TextSpan> bulletSpans = [];
//       final bulletParts = bulletText.split('**');
      
//       for (int i = 0; i < bulletParts.length; i++) {
//         final isBold = i % 2 == 1;
//         if (bulletParts[i].isNotEmpty) {
//           bulletSpans.add(TextSpan(
//             text: bulletParts[i],
//             style: isBold ? boldStyle : baseStyle,
//           ));
//         }
//       }

//       bulletWidgets.add(
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 2.0),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(top: 2.0, right: 8.0),
//                 child: Icon(
//                   Icons.arrow_forward_ios,
//                   size: 12,
//                   color: textColor,
//                 ),
//               ),
//               Expanded(
//                 child: RichText(
//                   text: TextSpan(children: bulletSpans),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     } else if (line.trim().isNotEmpty) {
//       // Regular text line (not a bullet point)
//       final List<TextSpan> regularSpans = [];
//       final regularParts = line.split('**');
      
//       for (int i = 0; i < regularParts.length; i++) {
//         final isBold = i % 2 == 1;
//         if (regularParts[i].isNotEmpty) {
//           regularSpans.add(TextSpan(
//             text: regularParts[i],
//             style: isBold ? boldStyle : baseStyle,
//           ));
//         }
//       }

//       bulletWidgets.add(
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 2.0),
//           child: RichText(
//             text: TextSpan(children: regularSpans),
//           ),
//         ),
//       );
//     } else {
//       // Empty line - add some spacing
//       bulletWidgets.add(const SizedBox(height: 4.0));
//     }
//   }

//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: bulletWidgets,
//   );
// }
// // Widget _buildRichTextMessage(String text, {bool isUser = false, bool isError = false, bool isCVAnalysis = false}) {
// //   final textColor = isError 
// //     ? Colors.orange.shade900
// //     : isCVAnalysis
// //       ? Colors.blue.shade900
// //       : isUser 
// //         ? Colors.white 
// //         : Colors.black87;

// //   final baseStyle = TextStyle(
// //     color: textColor,
// //     fontSize: 14,
// //     fontWeight: isError || isCVAnalysis ? FontWeight.w600 : FontWeight.normal,
// //   );

// //   final boldStyle = TextStyle(
// //     color: textColor,
// //     fontSize: 14,
// //     fontWeight: FontWeight.bold,
// //   );

// //   // Simple and reliable parsing
// //   final List<TextSpan> spans = [];
// //   final parts = text.split('**');
  
// //   for (int i = 0; i < parts.length; i++) {
// //     // Even indices are normal text, odd indices are bold text
// //     final isBold = i % 2 == 1;
// //     if (parts[i].isNotEmpty) {
// //       spans.add(TextSpan(
// //         text: parts[i],
// //         style: isBold ? boldStyle : baseStyle,
// //       ));
// //     }
// //   }

// //   return RichText(
// //     text: TextSpan(children: spans),
// //   );
// // }


//   // Widget _buildMessageBubble(Map<String, dynamic> m) {
//   //   final isUser = m["isSent"] == true;
//   //   final hasImage = m["hasImage"] == true;
//   //   final isError = m["isError"] == true;
//   //   final isCVAnalysis = m["cvAnalysis"] == true;
    
//   //   return Align(
//   //     alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//   //     child: Container(
//   //       margin: const EdgeInsets.symmetric(vertical: 4),
//   //       padding: const EdgeInsets.all(12),
//   //       decoration: BoxDecoration(
//   //         color: isError 
//   //           ? Colors.orange.shade100
//   //           : isCVAnalysis
//   //             ? Colors.blue.shade50
//   //             : isUser 
//   //               ? AppColors.mainColor 
//   //               : Colors.grey.shade300,
//   //         borderRadius: BorderRadius.circular(12),
//   //         border: isError 
//   //           ? Border.all(color: Colors.orange)
//   //           : isCVAnalysis
//   //             ? Border.all(color: Colors.blue.shade200)
//   //             : null,
//   //       ),
//   //       child: Column(
//   //         crossAxisAlignment: CrossAxisAlignment.start,
//   //         children: [
//   //           // Display image if message has one
//   //           if (hasImage && m.containsKey("imagePath"))
//   //             Column(
//   //               children: [
//   //                 ClipRRect(
//   //                   borderRadius: BorderRadius.circular(8),
//   //                   child: Image.file(
//   //                     File(m["imagePath"]),
//   //                     width: 200,
//   //                     height: 150,
//   //                     fit: BoxFit.cover,
//   //                     errorBuilder: (context, error, stackTrace) {
//   //                       return Container(
//   //                         width: 200,
//   //                         height: 150,
//   //                         color: Colors.grey.shade200,
//   //                         child: Column(
//   //                           mainAxisAlignment: MainAxisAlignment.center,
//   //                           children: [
//   //                             Icon(Icons.broken_image, color: Colors.grey, size: 40),
//   //                             SizedBox(height: 8),
//   //                             Text("Image not available", style: TextStyle(fontSize: 10)),
//   //                           ],
//   //                         ),
//   //                       );
//   //                     },
//   //                   ),
//   //                 ),
//   //                 SizedBox(height: 8),
//   //               ],
//   //             ),
            
//   //           // Display text message
//   //           if (m.containsKey("text") && m["text"].toString().isNotEmpty)
//   //             Padding(
//   //               padding: EdgeInsets.only(top: hasImage ? 4 : 0),
//   //               child: SelectableText(
//   //                 m["text"],
//   //                 style: TextStyle(
//   //                   color: isError 
//   //                     ? Colors.orange.shade900
//   //                     : isCVAnalysis
//   //                       ? Colors.blue.shade900
//   //                       : isUser 
//   //                         ? Colors.white 
//   //                         : Colors.black87,
//   //                   fontWeight: isError || isCVAnalysis ? FontWeight.w600 : FontWeight.normal,
//   //                 ),
//   //               ),
//   //             ),
            
//   //           // Show analysis type indicator
//   //           if ((isCVAnalysis || m["isImageAnalysis"] == true) && !isUser)
//   //             Padding(
//   //               padding: const EdgeInsets.only(top: 8),
//   //               child: Row(
//   //                 children: [
//   //                   Icon(
//   //                     isCVAnalysis ? Icons.analytics : Icons.photo_library, 
//   //                     size: 12, 
//   //                     color: isCVAnalysis ? Colors.blue : Colors.green
//   //                   ),
//   //                   SizedBox(width: 4),
//   //                   Text(
//   //                     isCVAnalysis ? "CV Analysis" : "Image Analysis",
//   //                     style: TextStyle(
//   //                       fontSize: 10,
//   //                       color: isCVAnalysis ? Colors.blue : Colors.green,
//   //                       fontWeight: FontWeight.w500,
//   //                     ),
//   //                   ),
//   //                 ],
//   //               ),
//   //             ),
//   //         ],
//   //       ),
//   //     ),
//   //   );
//   // }

//   @override
//   Widget build(BuildContext context) {
//     final messages = _activeSessionId != null ? _allSessions[_activeSessionId] ?? [] : [];

//     return Scaffold(
//       backgroundColor: AppColors.secondaryColor,
//       appBar: CustomAppBar(
//         title: "FixiBot",
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.history, color: AppColors.secondaryColor),
//             onPressed: () {
//               Get.to(ChatHistoryParentWidget());
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.add_comment, color: AppColors.secondaryColor),
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

//           // Chat messages with loading indicator
//           Expanded(
//             child: Column(
//               children: [
//                 // Messages list
//                 Expanded(
//                   child: ListView.builder(
//                     padding: const EdgeInsets.all(10),
//                     itemCount: messages.length,
//                     itemBuilder: (_, i) => _buildMessageBubble(messages[i]),
//                   ),
//                 ),
                
//                 // Loading indicator
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
//                     padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
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
//                                             setState(() => _selectedVehicle = null);
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
// }










///perfff
// import 'dart:convert';
// import 'dart:io';
// import 'package:fixibot_app/constants/appConfig.dart';
// import 'package:fixibot_app/constants/app_colors.dart';
// import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
// import 'package:fixibot_app/screens/chatbot/chatHistoryParent.dart';
// import 'package:fixibot_app/screens/chatbot/chatviewHistory.dart';
// import 'package:fixibot_app/screens/chatbot/provider/chatManagerProvider.dart';
// import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
// import 'package:fixibot_app/widgets/customAppBar.dart';
// import 'package:fixibot_app/widgets/wrapper.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
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
//     final ChatManagerProvider _chatManager = Get.find<ChatManagerProvider>();
//   final baseUrl = AppConfig.baseUrl;

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

//   @override
//   void initState() {
//     super.initState();
//     vehicleController.fetchUserVehicles();
//     _initAuth();
//     _loadSessions();
//   }

//   /* ----------------- Persistent Sessions ------------------ */

//   Future<void> _loadSessions() async {
//     final sp = await SharedPreferences.getInstance();
//     final stored = sp.getString(kSessionsKey);
//     final currentId = sp.getString(kCurrentSessionKey);

//     if (stored != null) {
//       final Map<String, dynamic> decoded = jsonDecode(stored);
//       _allSessions = decoded.map(
//           (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v as List)));
//     }

//     if (currentId != null && _allSessions.containsKey(currentId)) {
//       _activeSessionId = currentId;
//     } else {
//       _startNewLocalSession();
//     }
//     setState(() {});
//   }

//   Future<void> _saveSessions() async {
//     final sp = await SharedPreferences.getInstance();
//     await sp.setString(kSessionsKey, jsonEncode(_allSessions));
//     if (_activeSessionId != null) {
//       await sp.setString(kCurrentSessionKey, _activeSessionId!);
//     }
//   }

//   void _startNewLocalSession() {
//     final newId = DateTime.now().millisecondsSinceEpoch.toString();
//     _allSessions[newId] = [];
//     _activeSessionId = newId;
//   }

//   Future<void> _startNewChat() async {
//     setState(() {
//       _startNewLocalSession();
//     });
//     await _saveSessions();
//   }

//   // Delete a session
//   // Update the delete method
// Future<void> onDelete(String sessionId) async {
//   setState(() {
//     _allSessions.remove(sessionId);
//     if (_activeSessionId == sessionId) {
//       if (_allSessions.isEmpty) {
//         _startNewLocalSession();
//       } else {
//         _activeSessionId = _allSessions.keys.first;
//       }
//     }
//   });
//   await _saveSessions();
  
//   // Also delete from ChatManagerProvider
//   try {
//     if (Get.isRegistered<ChatManagerProvider>()) {
//       final chatManager = Get.find<ChatManagerProvider>();
//       // 🔥 FIXED: Use the correct method name - sessionExists
//       if (chatManager.sessionExists(sessionId)) {
//         chatManager.deleteSession(sessionId);
//         print('✅ Session deleted from ChatManagerProvider: $sessionId');
//       }
//     }
//   } catch (e) {
//     print('❌ Error deleting from ChatManagerProvider: $e');
//   }
// }

//   /* ----------------- Backend Auth/Session ------------------ */

//   Future<void> _initAuth() async {
//     _accessToken = await _prefs.getString("access_token");
//     _tokenType = await _prefs.getString("token_type");
    
//     print('🔐 Chatbot Auth Check:');
//     print('   Access Token: ${_accessToken != null ? "✅" : "❌"}');
//     print('   Token Type: ${_tokenType ?? "NULL"}');
    
//     // AUTO-FIX: If token_type is missing but access_token exists (Google user issue)
//     if (_accessToken != null && _accessToken!.isNotEmpty && (_tokenType == null || _tokenType!.isEmpty)) {
//       print('🛠️ Auto-fixing missing token_type for Google user...');
//       await _prefs.saveString('token_type', 'bearer');
//       _tokenType = 'bearer';
//       print('✅ Auto-fixed: token_type set to "bearer"');
      
//       Get.snackbar(
//         "Ready!", 
//         "Chatbot authentication completed",
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//         duration: Duration(seconds: 2),
//       );
//     }
    
//     if (_accessToken == null || _tokenType == null) {
//       Get.snackbar(
//         "Authentication Required", 
//         "Please login again to use chatbot",
//         backgroundColor: Colors.redAccent, 
//         colorText: Colors.white,
//         duration: Duration(seconds: 5),
//       );
//       await _debugChatbotAuth();
//       return;
//     }
    
//     await _startServerSession();
//   }

//   Future<void> _debugChatbotAuth() async {
//     final prefs = await SharedPreferences.getInstance();
    
//     print('=== CHATBOT AUTH DEBUG ===');
//     print('Access Token: ${prefs.getString('access_token') != null ? "✅ EXISTS" : "❌ MISSING"}');
//     print('Token Type: ${prefs.getString('token_type') ?? "❌ NULL"}');
//     print('User ID: ${prefs.getString('user_id') ?? "❌ NULL"}');
//     print('Email: ${prefs.getString('email') ?? "❌ NULL"}');
    
//     final hasAccessToken = prefs.getString('access_token') != null;
//     final hasTokenType = prefs.getString('token_type') != null;
//     final hasUserId = prefs.getString('user_id') != null;
    
//     print('Chatbot Ready: ${hasAccessToken && hasTokenType && hasUserId}');
//     print('==========================');
    
//     if (!hasAccessToken || !hasTokenType) {
//       Get.snackbar(
//         "Auth Issue", 
//         "Missing authentication data for chatbot",
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//       );
//     }
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

//   /* ----------------- Per-Vehicle Session Logic ------------------ */

//   Future<String?> _getSessionIdForVehicle(String vehicleId) async {
//     final sp = await SharedPreferences.getInstance();
//     final stored = sp.getString(kSessionsKey);
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
//     final newId = DateTime.now().millisecondsSinceEpoch.toString();
//     _allSessions[newId] = [];
//     _activeSessionId = newId;
//     await _saveSessions();
//     return newId;
//   }

//   Future<void> _activateVehicleSession(String vehicleId) async {
//     String? sessionId = await _getSessionIdForVehicle(vehicleId);
//     if (sessionId == null) {
//       sessionId = await _createNewSessionForVehicle(vehicleId);
//     }
//     setState(() => _activeSessionId = sessionId);
//     final sp = await SharedPreferences.getInstance();
//     await sp.setString(kCurrentSessionKey, sessionId);
//   }

//   // Get correct vehicle icon based on category
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


// // Helper method to save messages to ChatManagerProvider
// Future<void> _saveToChatManager(String sessionId, Map<String, dynamic> message, String chatTitle) async {
//   try {
//     // Check if ChatManagerProvider is available and initialized
//     if (!Get.isRegistered<ChatManagerProvider>()) {
//       print('❌ ChatManagerProvider not registered');
//       return;
//     }

//     final chatManager = Get.find<ChatManagerProvider>();
    
//     if (!chatManager.isInitialized) {
//       print('❌ ChatManagerProvider not initialized, trying to initialize...');
      
//       // Try to initialize with current user
//       final userId = await _prefs.getCurrentUserId();
//       if (userId != null) {
//         await chatManager.initializeForUser(userId);
//         print('✅ ChatManagerProvider initialized in chat screen');
//       } else {
//         print('❌ No user ID found for ChatManagerProvider initialization');
//         return;
//       }
//     }

//     // 🔥 FIXED: Use the correct method name - sessionExists
//     if (!chatManager.sessionExists(sessionId)) {
//       // Create new session
//       chatManager.createSession(
//         id: sessionId,
//         title: chatTitle,
//         firstMessage: message['text']?.toString() ?? 'New chat',
//       );
//       print('✅ Created new session in ChatManagerProvider: $sessionId');
//     } else {
//       // Add message to existing session
//       chatManager.addMessageToSession(sessionId, message);
//       print('✅ Added message to existing session in ChatManagerProvider: $sessionId');
//     }

//     print('💾 Message saved to ChatManagerProvider: ${message['text']}');

//   } catch (e) {
//     print('❌ Error saving to ChatManagerProvider: $e');
//   }
// }
// Future<void> sendMessage() async {
//   if (_selectedVehicle == null) {
//     Get.snackbar(
//       "Select Vehicle",
//       "Please choose a vehicle",
//       backgroundColor: Colors.redAccent,
//       colorText: Colors.white,
//     );
//     return;
//   }
  
//   final text = _controller.text.trim();
//   final vehicleId = _selectedVehicle!["_id"];

//   // Validate input
//   if (text.isEmpty && _selectedImage == null) {
//     Get.snackbar(
//       "Empty Message",
//       "Please enter a message or select an image",
//       backgroundColor: Colors.orange,
//       colorText: Colors.white,
//     );
//     return;
//   }

//   // Ensure session exists
//   if (_activeSessionId == null) {
//     await _activateVehicleSession(vehicleId);
//   }

//   // Store user input temporarily
//   final userText = text;
//   final userImage = _selectedImage;

//   // Clear input immediately and show loader
//   setState(() {
//     _controller.clear();
//     _selectedImage = null;
//     _isProcessing = true;
//   });

//   // Create user message
//   final userMessage = {
//     "text": userText,
//     "isSent": true,
//     "vehicleId": vehicleId,
//     "brand": _selectedVehicle?['brand'],
//     "model": _selectedVehicle?['model'],
//     "timestamp": DateTime.now().toIso8601String(),
//   };

//   // Add image path to message if image exists
//   if (userImage != null) {
//     userMessage["imagePath"] = userImage.path;
//     userMessage["hasImage"] = true;
//   }

//   // 🔥 CRITICAL: Save to BOTH systems
//   // 1. Save to local SharedPreferences (your existing system)
//   setState(() {
//     _allSessions[_activeSessionId]!.add(userMessage);
//   });
//   await _saveSessions();

//   // 2. Save to ChatManagerProvider (for chat history)
//   await _saveToChatManager(_activeSessionId!, userMessage, 'New Chat');

//   // Send to backend with enhanced error handling
//   try {
//     final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/chat/message"));
    
//     // Add headers
//     request.headers["Authorization"] = "$_tokenType $_accessToken";
//     request.headers["Accept"] = "application/json";

//     // Add session and message data
//     if (_sessionId != null) {
//       request.fields["session_id"] = _sessionId!;
//     }
    
//     // ✅ CRITICAL FIX: Always send message field with proper context
//     if (userText.isNotEmpty) {
//       request.fields["message"] = userText;
//     } else {
//       // If only image is sent, provide context for CV model
//       request.fields["message"] = "Analyze this vehicle image for any visible issues, damage, or maintenance needs";
//     }
    
//     // ✅ ENHANCED: Send vehicle data as proper JSON
//     request.fields["vehicle_json"] = json.encode(_selectedVehicle);

//     print('📤 Sending chat message:');
//     print('   Message: ${request.fields["message"]}');
//     print('   Vehicle: ${_selectedVehicle!['brand']} ${_selectedVehicle!['model']}');
//     print('   Has Image: ${userImage != null}');
//     print('   Session ID: $_sessionId');

//     // ✅ ENHANCED: Add image with proper field name and handling
//     if (userImage != null) {
//       print('📸 Adding image to request: ${userImage.path}');
      
//       // Get file extension and mime type
//       final fileExtension = userImage.path.split('.').last.toLowerCase();
//       final mimeType = _getMimeType(fileExtension);
      
//       // ✅ CRITICAL: Use the exact field name expected by FastAPI - 'image'
//       final multipartFile = await http.MultipartFile.fromPath(
//         'image', // This MUST be 'image' to match FastAPI parameter
//         userImage.path,
//         contentType: MediaType('image', mimeType),
//         filename: 'vehicle_${_selectedVehicle!['brand']}_${_selectedVehicle!['model']}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
//       );
//       request.files.add(multipartFile);
      
//       final fileSize = userImage.lengthSync();
//       print('   Image details: ${fileSize ~/ 1024} KB, type: $mimeType');
//       print('   Field name: image');
//     }

//     // Send request with timeout
//     print('🚀 Sending request to backend...');
//     final streamedResponse = await request.send();
//     final response = await http.Response.fromStream(streamedResponse);

//     print('📥 Response received:');
//     print('   Status: ${response.statusCode}');
//     print('   Body: ${response.body}');

//     if (response.statusCode == 200) {
//       try {
//         final decoded = json.decode(response.body);
//         print('   Response keys: ${decoded.keys}');
        
//         // ✅ ENHANCED: Handle different response formats
//         String reply;
//         if (decoded.containsKey("reply")) {
//           reply = decoded["reply"];
//         } else if (decoded.containsKey("message")) {
//           reply = decoded["message"];
//         } else if (decoded.containsKey("response")) {
//           reply = decoded["response"];
//         } else if (decoded.containsKey("analysis")) {
//           reply = decoded["analysis"];
//         } else {
//           // If no specific field found, try to get the first string value
//           reply = _extractReplyFromResponse(decoded);
//         }

//         // Create bot message
//         final botMessage = {
//           "text": reply,
//           "isSent": false,
//           "timestamp": DateTime.now().toIso8601String(),
//           "isImageAnalysis": userImage != null,
//           "cvAnalysis": userImage != null,
//         };

//         // 🔥 CRITICAL: Save bot response to BOTH systems
//         // 1. Save to local SharedPreferences
//         setState(() {
//           _allSessions[_activeSessionId]!.add(botMessage);
//         });
//         await _saveSessions();

//         // 2. Save to ChatManagerProvider
//         await _saveToChatManager(_activeSessionId!, botMessage, decoded["chat_title"] ?? 'New Chat');
        
//         // Show success for image analysis
//         if (userImage != null) {
//           Get.snackbar(
//             "Image Analysis Complete",
//             "FixiBot has processed your vehicle image",
//             backgroundColor: Colors.green,
//             colorText: Colors.white,
//             duration: Duration(seconds: 3),
//           );
//         }
        
//       } catch (e) {
//         print('❌ JSON parsing error: $e');
//         print('   Raw response: ${response.body}');
//         _handleErrorResponse("Failed to parse server response: $e");
//       }
//     } else if (response.statusCode == 422) {
//       // Handle validation errors from FastAPI
//       print('❌ FastAPI Validation Error: ${response.body}');
//       _handleValidationError(response.body);
//     } else if (response.statusCode == 415) {
//       _handleErrorResponse("Unsupported media type. The image format may not be supported.");
//     } else if (response.statusCode == 413) {
//       _handleErrorResponse("Image file too large. Please select a smaller image.");
//     } else {
//       print('❌ Server error: ${response.statusCode}');
//       _handleErrorResponse("Server error: ${response.statusCode}\n${response.body}");
//     }
//   } catch (e) {
//     print('❌ Network error: $e');
//     _handleErrorResponse("Network error: ${e.toString()}");
//   } finally {
//     setState(() {
//       _isProcessing = false;
//     });
//   }
// }

// // Helper method to extract reply from various response formats
// String _extractReplyFromResponse(Map<String, dynamic> response) {
//   try {
//     // Try to find any string value in the response
//     for (var value in response.values) {
//       if (value is String && value.isNotEmpty) {
//         return value;
//       }
//     }
    
//     // If no string found, return the entire response as string
//     return response.toString();
//   } catch (e) {
//     return "I've processed your request. How can I help you further?";
//   }
// }


//   String _getMimeType(String fileExtension) {
//     switch (fileExtension) {
//       case 'jpg':
//       case 'jpeg':
//         return 'jpeg';
//       case 'png':
//         return 'png';
//       case 'gif':
//         return 'gif';
//       case 'webp':
//         return 'webp';
//       default:
//         return 'jpeg';
//     }
//   }

//   String _formatCVResponse(dynamic cvAnalysis) {
//     if (cvAnalysis is String) {
//       return cvAnalysis;
//     } else if (cvAnalysis is Map) {
//       final issues = cvAnalysis['issues'] ?? [];
//       final confidence = cvAnalysis['confidence'] ?? 0.0;
//       final recommendations = cvAnalysis['recommendations'] ?? [];
      
//       String response = "🔍 **Vehicle Image Analysis Complete**\n\n";
      
//       if (issues.isNotEmpty) {
//         response += "**Detected Issues:**\n";
//         for (var issue in issues) {
//           response += "• $issue\n";
//         }
//       } else {
//         response += "✅ No major issues detected.\n";
//       }
      
//       if (recommendations.isNotEmpty) {
//         response += "\n**Recommendations:**\n";
//         for (var rec in recommendations) {
//           response += "• $rec\n";
//         }
//       }
      
//       response += "\n_Confidence: ${(confidence * 100).toStringAsFixed(1)}%_";
//       return response;
//     }
    
//     return "I've analyzed your vehicle image. Please describe any specific concerns you have.";
//   }

//   void _handleValidationError(String errorBody) {
//     try {
//       final decoded = json.decode(errorBody);
//       final details = decoded['detail'];
//       String errorMessage = "Validation error: ";
      
//       if (details is List) {
//         for (var detail in details) {
//           errorMessage += "${detail['msg']} (${detail['loc']}); ";
//         }
//       } else {
//         errorMessage += "Invalid request format";
//       }
      
//       _handleErrorResponse(errorMessage);
//     } catch (e) {
//       _handleErrorResponse("Request validation failed: $errorBody");
//     }
//   }

//   void _handleErrorResponse(String error) {
//     print('❌ Chat error: $error');
    
//     setState(() {
//       _allSessions[_activeSessionId]!.add({
//         "text": "⚠️ **FixiBot Error**\n\nI encountered an issue while processing your request.\n\n**Error Details:** $error\n\nPlease try again or contact support if the problem persists.",
//         "isSent": false,
//         "isError": true,
//         "timestamp": DateTime.now().toIso8601String(),
//       });
//     });
    
//     Get.snackbar(
//       "Processing Error",
//       "Failed to process your message",
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//       duration: Duration(seconds: 5),
//     );
//   }

//   Future<void> _pickImage() async {
//     try {
//       final XFile? file = await _picker.pickImage(
//         source: ImageSource.gallery, 
//         imageQuality: 85,
//         maxWidth: 1200,
//         maxHeight: 1200,
//       );
      
//       if (file != null) {
//         final imageFile = File(file.path);
        
//         // Validate file size (max 5MB)
//         final fileSize = await imageFile.length();
//         if (fileSize > 5 * 1024 * 1024) {
//           Get.snackbar(
//             "File Too Large",
//             "Please select an image smaller than 5MB",
//             backgroundColor: Colors.orange,
//             colorText: Colors.white,
//           );
//           return;
//         }
        
//         setState(() => _selectedImage = imageFile);
        
//         // Auto-focus on text input after image selection
//         FocusScope.of(context).requestFocus(FocusNode());
//         Future.delayed(Duration(milliseconds: 100), () {
//           FocusScope.of(context).requestFocus(FocusNode());
//         });
        
//         print('📸 Image selected: ${file.path} (${fileSize ~/ 1024} KB)');
//       }
//     } catch (e) {
//       print('❌ Image picker error: $e');
//       Get.snackbar(
//         "Error",
//         "Failed to pick image: ${e.toString()}",
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }

//   /* ----------------- UI ------------------ */

//   Widget _buildMessageBubble(Map<String, dynamic> m) {
//     final isUser = m["isSent"] == true;
//     final hasImage = m["hasImage"] == true;
//     final isError = m["isError"] == true;
//     final isCVAnalysis = m["cvAnalysis"] == true;
    
//     return Align(
//       alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: isError 
//             ? Colors.orange.shade100
//             : isCVAnalysis
//               ? Colors.blue.shade50
//               : isUser 
//                 ? AppColors.mainColor 
//                 : Colors.grey.shade300,
//           borderRadius: BorderRadius.circular(12),
//           border: isError 
//             ? Border.all(color: Colors.orange)
//             : isCVAnalysis
//               ? Border.all(color: Colors.blue.shade200)
//               : null,
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Display image if message has one
//             if (hasImage && m.containsKey("imagePath"))
//               Column(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: Image.file(
//                       File(m["imagePath"]),
//                       width: 200,
//                       height: 150,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) {
//                         return Container(
//                           width: 200,
//                           height: 150,
//                           color: Colors.grey.shade200,
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.broken_image, color: Colors.grey, size: 40),
//                               SizedBox(height: 8),
//                               Text("Image not available", style: TextStyle(fontSize: 10)),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                 ],
//               ),
            
//             // Display text message
//             if (m.containsKey("text") && m["text"].toString().isNotEmpty)
//               Padding(
//                 padding: EdgeInsets.only(top: hasImage ? 4 : 0),
//                 child: SelectableText(
//                   m["text"],
//                   style: TextStyle(
//                     color: isError 
//                       ? Colors.orange.shade900
//                       : isCVAnalysis
//                         ? Colors.blue.shade900
//                         : isUser 
//                           ? Colors.white 
//                           : Colors.black87,
//                     fontWeight: isError || isCVAnalysis ? FontWeight.w600 : FontWeight.normal,
//                   ),
//                 ),
//               ),
            
//             // Show analysis type indicator
//             if ((isCVAnalysis || m["isImageAnalysis"] == true) && !isUser)
//               Padding(
//                 padding: const EdgeInsets.only(top: 8),
//                 child: Row(
//                   children: [
//                     Icon(
//                       isCVAnalysis ? Icons.analytics : Icons.photo_library, 
//                       size: 12, 
//                       color: isCVAnalysis ? Colors.blue : Colors.green
//                     ),
//                     SizedBox(width: 4),
//                     Text(
//                       isCVAnalysis ? "CV Analysis" : "Image Analysis",
//                       style: TextStyle(
//                         fontSize: 10,
//                         color: isCVAnalysis ? Colors.blue : Colors.green,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final messages = _activeSessionId != null ? _allSessions[_activeSessionId] ?? [] : [];

//     return Scaffold(
//       backgroundColor: AppColors.secondaryColor,
//       appBar: CustomAppBar(
//         title: "FixiBot",
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.history, color: AppColors.secondaryColor),
//             onPressed: () {
//               // Get.to(ChatHistoryScreen(
//               //   sessions: _allSessions,
//               //   onOpenSession: (id) async {
//               //     setState(() => _activeSessionId = id);
//               //     final sp = await SharedPreferences.getInstance();
//               //     await sp.setString(kCurrentSessionKey, id);
//               //   },
//               //   onDeleteSession: (id) => onDelete(id),
//               // ));
//               Get.to(ChatHistoryParentWidget());
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.add_comment, color: AppColors.secondaryColor),
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

//           // Chat messages with loading indicator
//           Expanded(
//             child: Column(
//               children: [
//                 // Messages list
//                 Expanded(
//                   child: ListView.builder(
//                     padding: const EdgeInsets.all(10),
//                     itemCount: messages.length,
//                     itemBuilder: (_, i) => _buildMessageBubble(messages[i]),
//                   ),
//                 ),
                
//                 // Loading indicator
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
//                     padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
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
//                                             setState(() => _selectedVehicle = null);
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
// }















//text based perfect
// import 'dart:convert';
// import 'dart:io';
// import 'package:fixibot_app/constants/appConfig.dart';
// import 'package:fixibot_app/constants/app_colors.dart';
// import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
// import 'package:fixibot_app/screens/chatbot/chatviewHistory.dart';
// import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
// import 'package:fixibot_app/widgets/customAppBar.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:fixibot_app/screens/auth/controller/google_sign_in_helper.dart';

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
// final baseUrl  = AppConfig.baseUrl;


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

//   @override
//   void initState() {
//     super.initState();
//     vehicleController.fetchUserVehicles();
//     _initAuth();
//     _loadSessions();
//   }

//   /* ----------------- Persistent Sessions ------------------ */

//   Future<void> _loadSessions() async {
//     final sp = await SharedPreferences.getInstance();
//     final stored = sp.getString(kSessionsKey);
//     final currentId = sp.getString(kCurrentSessionKey);

//     if (stored != null) {
//       final Map<String, dynamic> decoded = jsonDecode(stored);
//       _allSessions = decoded.map(
//           (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v as List)));
//     }

//     if (currentId != null && _allSessions.containsKey(currentId)) {
//       _activeSessionId = currentId;
//     } else {
//       _startNewLocalSession();
//     }
//     setState(() {});
//   }

//   Future<void> _saveSessions() async {
//     final sp = await SharedPreferences.getInstance();
//     await sp.setString(kSessionsKey, jsonEncode(_allSessions));
//     if (_activeSessionId != null) {
//       await sp.setString(kCurrentSessionKey, _activeSessionId!);
//     }
//   }

//   void _startNewLocalSession() {
//     final newId = DateTime.now().millisecondsSinceEpoch.toString();
//     _allSessions[newId] = [];
//     _activeSessionId = newId;
//   }

//   Future<void> _startNewChat() async {
//     setState(() {
//       _startNewLocalSession();
//     });
//     await _saveSessions();
//   }

//   // Delete a session
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
//   }




//   /* ----------------- Backend Auth/Session ------------------ */

// Future<void> _initAuth() async {
//   _accessToken = await _prefs.getString("access_token");
//   _tokenType = await _prefs.getString("token_type");
  
//   print('🔐 Chatbot Auth Check:');
//   print('   Access Token: ${_accessToken != null ? "✅" : "❌"}');
//   print('   Token Type: ${_tokenType ?? "NULL"}');
  
//   // ✅ AUTO-FIX: If token_type is missing but access_token exists (Google user issue)
//   if (_accessToken != null && _accessToken!.isNotEmpty && (_tokenType == null || _tokenType!.isEmpty)) {
//     print('🛠️ Auto-fixing missing token_type for Google user...');
//     await _prefs.saveString('token_type', 'bearer');
//     _tokenType = 'bearer'; // Update local variable
//     print('✅ Auto-fixed: token_type set to "bearer"');
    
//     Get.snackbar(
//       "Ready!", 
//       "Chatbot authentication completed",
//       backgroundColor: Colors.green,
//       colorText: Colors.white,
//       duration: Duration(seconds: 2),
//     );
//   }
  
//   if (_accessToken == null || _tokenType == null) {
//     Get.snackbar(
//       "Authentication Required", 
//       "Please login again to use chatbot",
//       backgroundColor: Colors.redAccent, 
//       colorText: Colors.white,
//       duration: Duration(seconds: 5),
//     );
    
//     // ✅ DEBUG: Show what's missing
//     await debugChatbotAuth();
//     return;
//   }
  
//   await _startServerSession();
// }


// // Future<void> _initAuth() async {
// //   _accessToken = await _prefs.getString("access_token");
// //   _tokenType = await _prefs.getString("token_type");
  
// //   print('🔐 Chatbot Auth Check:');
// //   print('   Access Token: ${_accessToken != null ? "✅" : "❌"}');
// //   print('   Token Type: ${_tokenType ?? "NULL"}');
  
// //   if (_accessToken == null || _tokenType == null) {
// //     Get.snackbar(
// //       "Authentication Required", 
// //       "Please login again to use chatbot",
// //       backgroundColor: Colors.redAccent, 
// //       colorText: Colors.white,
// //       duration: Duration(seconds: 5),
// //     );
    
// //     // ✅ DEBUG: Show what's missing
// //     await debugChatbotAuth();
// //     return;
// //   }
  
// //   await _startServerSession();
// // }


// // Add this to your GoogleSignInController or any controller
// Future<void> debugChatbotAuth() async {
//   final prefs = await SharedPreferences.getInstance();
  
//   print('=== CHATBOT AUTH DEBUG ===');
//   print('Access Token: ${prefs.getString('access_token') != null ? "✅ EXISTS" : "❌ MISSING"}');
//   print('Token Type: ${prefs.getString('token_type') ?? "❌ NULL"}');
//   print('User ID: ${prefs.getString('user_id') ?? "❌ NULL"}');
//   print('Email: ${prefs.getString('email') ?? "❌ NULL"}');
  
//   // Check if chatbot requirements are met
//   final hasAccessToken = prefs.getString('access_token') != null;
//   final hasTokenType = prefs.getString('token_type') != null;
//   final hasUserId = prefs.getString('user_id') != null;
  
//   print('Chatbot Ready: ${hasAccessToken && hasTokenType && hasUserId}');
//   print('==========================');
  
//   // Show user-friendly message
//   if (!hasAccessToken || !hasTokenType) {
//     Get.snackbar(
//       "Auth Issue", 
//       "Missing authentication data for chatbot",
//       backgroundColor: Colors.orange,
//       colorText: Colors.white,
//     );
//   }
// }
//   // Future<void> _initAuth() async {
//   //   _accessToken = await _prefs.getString("access_token");
//   //   _tokenType = await _prefs.getString("token_type");
//   //   if (_accessToken == null || _tokenType == null) {
//   //     Get.snackbar("Error", "Authentication required",
//   //         backgroundColor: Colors.redAccent, colorText: Colors.white);
//   //     return;
//   //   }
//   //   await _startServerSession();
//   // }

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

//   /* ----------------- Per-Vehicle Session Logic ------------------ */

//   Future<String?> _getSessionIdForVehicle(String vehicleId) async {
//     final sp = await SharedPreferences.getInstance();
//     final stored = sp.getString(kSessionsKey);
//     if (stored == null) return null;

//     final Map<String, dynamic> decoded = jsonDecode(stored);
//     for (var entry in decoded.entries) {
//       final sessionMessages =
//           List<Map<String, dynamic>>.from(entry.value as List);
//       if (sessionMessages.any((m) => m["vehicleId"] == vehicleId)) {
//         return entry.key;
//       }
//     }
//     return null;
//   }

//   Future<String> _createNewSessionForVehicle(String vehicleId) async {
//     final newId = DateTime.now().millisecondsSinceEpoch.toString();
//     _allSessions[newId] = [];
//     _activeSessionId = newId;
//     await _saveSessions();
//     return newId;
//   }

//   Future<void> _activateVehicleSession(String vehicleId) async {
//     String? sessionId = await _getSessionIdForVehicle(vehicleId);
//     if (sessionId == null) {
//       sessionId = await _createNewSessionForVehicle(vehicleId);
//     }
//     setState(() => _activeSessionId = sessionId);
//     final sp = await SharedPreferences.getInstance();
//     await sp.setString(kCurrentSessionKey, sessionId);
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


// /* ----------------- Enhanced Message Handling ------------------ */

// Future<void> sendMessage() async {
//   if (_selectedVehicle == null) {
//     Get.snackbar(
//       "Select Vehicle",
//       "Please choose a vehicle",
//       backgroundColor: Colors.redAccent,
//       colorText: Colors.white,
//     );
//     return;
//   }
  
//   final text = _controller.text.trim();
//   final vehicleId = _selectedVehicle!["_id"];

//   // Validate input
//   if (text.isEmpty && _selectedImage == null) {
//     Get.snackbar(
//       "Empty Message",
//       "Please enter a message or select an image",
//       backgroundColor: Colors.orange,
//       colorText: Colors.white,
//     );
//     return;
//   }

//   // Ensure session exists
//   if (_activeSessionId == null) {
//     await _activateVehicleSession(vehicleId);
//   }

//   // Store user input temporarily
//   final userText = text;
//   final userImage = _selectedImage;

//   // Clear input immediately and show loader
//   setState(() {
//     _controller.clear();
//     _selectedImage = null;
//     _isProcessing = true;
//   });

//   // Add user message locally with image preview
//   final userMessage = {
//     "text": userText,
//     "isSent": true,
//     "vehicleId": vehicleId,
//     "brand": _selectedVehicle?['brand'],
//     "model": _selectedVehicle?['model'],
//     "timestamp": DateTime.now().toIso8601String(),
//   };

//   // Add image path to message if image exists
//   if (userImage != null) {
//     userMessage["imagePath"] = userImage.path;
//     userMessage["hasImage"] = true;
//   }

//   setState(() {
//     _allSessions[_activeSessionId]!.add(userMessage);
//   });
//   await _saveSessions();

//   // Send to backend with enhanced error handling
//   try {
//     final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/chat/message"));
    
//     // Add headers
//     request.headers["Authorization"] = "$_tokenType $_accessToken";
//     request.headers["Accept"] = "application/json";

//     // Add session and message data
//     if (_sessionId != null) {
//       request.fields["session_id"] = _sessionId!;
//     }
    
//     // ✅ CRITICAL FIX: Always send message field, even if empty with image
//     request.fields["message"] = userText.isNotEmpty ? userText : "Analyze this vehicle image";
    
//     // ✅ ENHANCED: Send vehicle data as proper JSON
//     request.fields["vehicle_json"] = json.encode(_selectedVehicle);

//     print('📤 Sending chat message:');
//     print('   Message: ${userText.isNotEmpty ? userText : "Image only"}');
//     print('   Vehicle: ${_selectedVehicle!['brand']} ${_selectedVehicle!['model']}');
//     print('   Has Image: ${userImage != null}');
//     print('   Session ID: $_sessionId');

//     // ✅ ENHANCED: Add image with proper metadata
//     if (userImage != null) {
//       print('📸 Adding image to request: ${userImage.path}');
      
//       // Get file extension and mime type
//       final fileExtension = userImage.path.split('.').last.toLowerCase();
//       final mimeType = _getMimeType(fileExtension);
      
//       final multipartFile = await http.MultipartFile.fromPath(
//         'image', // ✅ Field name should match backend expectation
//         userImage.path,
//         contentType: MediaType('image', mimeType),
//         filename: 'vehicle_image_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
//       );
//       request.files.add(multipartFile);
//       print('   Image details: ${userImage.lengthSync()} bytes, type: $mimeType');
//     }

//     // Send request with timeout
//     final response = await request.send().timeout(Duration(seconds: 60));
//     final body = await response.stream.bytesToString();

//     print('📥 Response received:');
//     print('   Status: ${response.statusCode}');
//     print('   Body: $body');

//     if (response.statusCode == 200) {
//       try {
//         final decoded = json.decode(body);
//         final reply = decoded["reply"] ??
//             decoded["message"] ??
//             decoded["response"] ??
//             "I've analyzed your vehicle. How can I help you further?";

//         // Add bot response to chat
//         setState(() {
//           _allSessions[_activeSessionId]!.add({
//             "text": reply,
//             "isSent": false,
//             "timestamp": DateTime.now().toIso8601String(),
//             "isImageAnalysis": userImage != null, // Mark as image analysis response
//           });
//         });
        
//         await _saveSessions();
        
//         // Show success for image analysis
//         if (userImage != null) {
//           Get.snackbar(
//             "Image Analyzed",
//             "FixiBot has processed your vehicle image",
//             backgroundColor: Colors.green,
//             colorText: Colors.white,
//             duration: Duration(seconds: 2),
//           );
//         }
        
//       } catch (e) {
//         print('❌ JSON parsing error: $e');
//         _handleErrorResponse("Failed to parse server response");
//       }
//     } else {
//       _handleErrorResponse("Server error: ${response.statusCode}\n$body");
//     }
//   } catch (e) {
//     print('❌ Network error: $e');
//     _handleErrorResponse("Network error: ${e.toString()}");
//   } finally {
//     // Stop loading regardless of success/error
//     setState(() {
//       _isProcessing = false;
//     });
//   }
// }

// // Helper method to get MIME type
// String _getMimeType(String fileExtension) {
//   switch (fileExtension) {
//     case 'jpg':
//     case 'jpeg':
//       return 'jpeg';
//     case 'png':
//       return 'png';
//     case 'gif':
//       return 'gif';
//     case 'webp':
//       return 'webp';
//     default:
//       return 'jpeg';
//   }
// }

// // Enhanced error handling
// void _handleErrorResponse(String error) {
//   print('❌ Chat error: $error');
  
//   // Add error message to chat
//   setState(() {
//     _allSessions[_activeSessionId]!.add({
//       "text": "⚠️ Sorry, I encountered an error. Please try again.\n\nError: $error",
//       "isSent": false,
//       "isError": true,
//       "timestamp": DateTime.now().toIso8601String(),
//     });
//   });
  
//   Get.snackbar(
//     "Error",
//     "Failed to send message",
//     backgroundColor: Colors.red,
//     colorText: Colors.white,
//     duration: Duration(seconds: 3),
//   );
// }
  
// Future<void> _pickImage() async {
//   try {
//     final XFile? file = await _picker.pickImage(
//       source: ImageSource.gallery, 
//       imageQuality: 85,
//       maxWidth: 1200,
//       maxHeight: 1200,
//     );
    
//     if (file != null) {
//       final imageFile = File(file.path);
      
//       // Validate file size (max 5MB)
//       final fileSize = await imageFile.length();
//       if (fileSize > 5 * 1024 * 1024) {
//         Get.snackbar(
//           "File Too Large",
//           "Please select an image smaller than 5MB",
//           backgroundColor: Colors.orange,
//           colorText: Colors.white,
//         );
//         return;
//       }
      
//       setState(() => _selectedImage = imageFile);
      
//       // Auto-focus on text input after image selection
//       FocusScope.of(context).requestFocus(FocusNode());
//       Future.delayed(Duration(milliseconds: 100), () {
//         FocusScope.of(context).requestFocus(FocusNode());
//       });
      
//       print('📸 Image selected: ${file.path} (${fileSize ~/ 1024} KB)');
//     }
//   } catch (e) {
//     print('❌ Image picker error: $e');
//     Get.snackbar(
//       "Error",
//       "Failed to pick image: ${e.toString()}",
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//     );
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
//           IconButton(
//             icon: const Icon(Icons.history, color: AppColors.secondaryColor),
//             onPressed: () {
//               Get.to(ChatHistoryScreen(
//                 sessions: _allSessions,
//                 onOpenSession: (id) async {
//                   setState(() => _activeSessionId = id);
//                   final sp = await SharedPreferences.getInstance();
//                   await sp.setString(kCurrentSessionKey, id);
//                 },
//                 onDeleteSession: (id) => onDelete(id),
//               ));
//             },
//           ),
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

//           // FIX 1: Vehicle chips with correct icons
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
//                           // FIX 1: Use correct vehicle icon
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

//           // Chat messages with FIX 2: Better loading indicator
//           Expanded(
//             child: Column(
//               children: [
//                 // Messages list
//                 Expanded(
//                   child: ListView.builder(
//                     padding: const EdgeInsets.all(10),
//                     itemCount: messages.length,
//                     // itemBuilder: (_, i) {
//                     //   final m = messages[i];
//                     //   final isUser = m["isSent"] == true;
//                     //   return Align(
//                     //     alignment:
//                     //         isUser ? Alignment.centerRight : Alignment.centerLeft,
//                     //     child: Container(
//                     //       margin: const EdgeInsets.symmetric(vertical: 4),
//                     //       padding: const EdgeInsets.all(10),
//                     //       decoration: BoxDecoration(
//                     //         color:
//                     //             isUser ? AppColors.mainColor : Colors.grey.shade300,
//                     //         borderRadius: BorderRadius.circular(12),
//                     //       ),
//                     //       child: Column(
//                     //         crossAxisAlignment: CrossAxisAlignment.start,
//                     //         children: [
//                     //           if (m.containsKey("imagePath"))
//                     //             ClipRRect(
//                     //               borderRadius: BorderRadius.circular(8),
//                     //               child: Image.file(
//                     //                 File(m["imagePath"]),
//                     //                 width: 150,
//                     //                 height: 150,
//                     //                 fit: BoxFit.cover,
//                     //               ),
//                     //             ),
//                     //           if (m.containsKey("text"))
//                     //             Padding(
//                     //               padding: const EdgeInsets.only(top: 6),
//                     //               child: Text(
//                     //                 m["text"],
//                     //                 style: TextStyle(
//                     //                     color:
//                     //                         isUser ? Colors.white : Colors.black87),
//                     //               ),
//                     //             ),
//                     //         ],
//                     //       ),
//                     //     ),
//                     //   );
//                     // },
//                     // In your ListView.builder, replace the itemBuilder with this enhanced version:
// itemBuilder: (_, i) {
//   final m = messages[i];
//   final isUser = m["isSent"] == true;
//   final hasImage = m["hasImage"] == true;
//   final isError = m["isError"] == true;
  
//   return Align(
//     alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//     child: Container(
//       margin: const EdgeInsets.symmetric(vertical: 4),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: isError 
//           ? Colors.orange.shade100
//           : isUser 
//             ? AppColors.mainColor 
//             : Colors.grey.shade300,
//         borderRadius: BorderRadius.circular(12),
//         border: isError 
//           ? Border.all(color: Colors.orange)
//           : null,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Display image if message has one
//           if (hasImage && m.containsKey("imagePath"))
//             Column(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: Image.file(
//                     File(m["imagePath"]),
//                     width: 200,
//                     height: 150,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Container(
//                         width: 200,
//                         height: 150,
//                         color: Colors.grey.shade200,
//                         child: Icon(Icons.broken_image, color: Colors.grey),
//                       );
//                     },
//                   ),
//                 ),
//                 SizedBox(height: 8),
//               ],
//             ),
          
//           // Display text message
//           if (m.containsKey("text") && m["text"].toString().isNotEmpty)
//             Padding(
//               padding: EdgeInsets.only(top: hasImage ? 4 : 0),
//               child: Text(
//                 m["text"],
//                 style: TextStyle(
//                   color: isError 
//                     ? Colors.orange.shade900
//                     : isUser 
//                       ? Colors.white 
//                       : Colors.black87,
//                   fontWeight: isError ? FontWeight.w600 : FontWeight.normal,
//                 ),
//               ),
//             ),
          
//           // Show image analysis indicator
//           if (m["isImageAnalysis"] == true && !isUser)
//             Padding(
//               padding: const EdgeInsets.only(top: 8),
//               child: Row(
//                 children: [
//                   Icon(Icons.photo_library, size: 12, color: Colors.green),
//                   SizedBox(width: 4),
//                   Text(
//                     "Image Analysis",
//                     style: TextStyle(
//                       fontSize: 10,
//                       color: Colors.green,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     ),
//   );
// }
//                   ),
//                 ),
                
//                 // FIX 2: Improved loading indicator - appears only when processing
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
//                                         // FIX 1: Use correct vehicle icon in selected chip too
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
// }



