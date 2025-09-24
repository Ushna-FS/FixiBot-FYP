import 'dart:io';
import 'dart:convert';
import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
import 'package:fixibot_app/widgets/customAppBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final VehicleController vehicleController = Get.find<VehicleController>();
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final String baseUrl = "http://127.0.0.1:8000";

  final SharedPrefsHelper _prefs = SharedPrefsHelper();

  File? _selectedImage;
  Map<String, dynamic>? _selectedVehicle; // 🔹 store full vehicle JSON
  String? _sessionId;
  final Map<String, List<Map<String, dynamic>>> vehicleChats = {};

  String? _accessToken;
  String? _tokenType;

  @override
  void initState() {
    super.initState();
    vehicleController.fetchUserVehicles();
    _initAuthAndSession();
  }

  /// 🔹 Initialize token + start session
  Future<void> _initAuthAndSession() async {
    _accessToken = await _prefs.getString("access_token");
    _tokenType = await _prefs.getString("token_type");

    if (_accessToken == null || _tokenType == null) {
      Get.snackbar("Error", "Authentication required. Please login again.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    await _startChatSession();
  }

  /// 🔹 Start chat session with backend
  Future<void> _startChatSession() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/chat/start"),
        headers: {
          "Content-Type": "application/json",
          "accept": "application/json",
          "Authorization": "$_tokenType $_accessToken",
        },
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        setState(() {
          _sessionId = data["session_id"];
        });
        debugPrint("✅ Chat session started: $_sessionId");
      } else if (response.statusCode == 401) {
        Get.snackbar("Unauthorized", "Session expired. Please login again.",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
        debugPrint("❌ Unauthorized: ${response.body}");
      } else {
        debugPrint("❌ Failed to start session: ${response.statusCode} -> ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Error starting chat session: $e");
      Get.snackbar("Error", "Unable to connect to server.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  /// 🔹 Send message (text + optional image + full vehicle JSON)
  Future<void> sendMessage() async {
    if (_sessionId == null) {
      Get.snackbar("Error", "Chat session not started");
      return;
    }

    if (_selectedVehicle == null) {
      Get.snackbar("Select Vehicle", "Please choose a vehicle to start chat",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    if (_controller.text.trim().isEmpty && _selectedImage == null) return;

    // Add user message locally
    setState(() {
      final vehicleId = _selectedVehicle!["_id"];
      vehicleChats.putIfAbsent(vehicleId, () => []);
      vehicleChats[vehicleId]!.add({
        if (_selectedImage != null) "image": _selectedImage,
        if (_controller.text.trim().isNotEmpty) "text": _controller.text,
        "isSent": true,
      });
    });


    try {
        var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/chat/message"),
      );

      request.headers["Authorization"] = "$_tokenType $_accessToken";

      request.fields["session_id"] = _sessionId!;
      if (_controller.text.trim().isNotEmpty) {
        request.fields["message"] = _controller.text.trim();
      }

      // 🔹 Send full vehicle JSON, not just vehicle_id
      request.fields["vehicle_json"] = json.encode(_selectedVehicle);

      if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          "image",
          _selectedImage!.path,
        ));
      }

  final response = await request.send();
  final responseBody = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    final botReply = json.decode(responseBody);

    // Try multiple possible keys, fallback to raw body
    final replyText = botReply["reply"] ??
                      botReply["message"] ??
                      botReply["response"] ??
                      responseBody;

    setState(() {
      final vehicleId = _selectedVehicle!["_id"];
      vehicleChats[vehicleId]!.add({
        "text": replyText,
        "isSent": false,
      });
    });
  } else if (response.statusCode == 401) {
    Get.snackbar("Unauthorized", "Session expired. Please login again.",
        backgroundColor: Colors.redAccent, colorText: Colors.white);
    debugPrint("❌ Unauthorized: $responseBody");
  } else {
    debugPrint("❌ Message failed: ${response.statusCode} -> $responseBody");
  }
} catch (e) {
  debugPrint("⚠️ Error sending message: $e");
  Get.snackbar("Error", "Failed to send message.",
      backgroundColor: Colors.redAccent, colorText: Colors.white);
}


    // Reset input
    _controller.clear();
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleId = _selectedVehicle?["_id"];
    final chats = vehicleId != null ? (vehicleChats[vehicleId] ?? []) : [];

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: const CustomAppBar(
        title: "FixiBot",
        actions: [
          Icon(Icons.file_copy_outlined, color: AppColors.secondaryColor),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              "Please select the vehicle you’d like to resolve an issue for:",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.mainColor,
              ),
            ),
          ),

          // 🔹 Vehicle selection chips
          Obx(() {
            final vehicles = vehicleController.userVehicles;
            if (vehicles.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text("No vehicles added. Please add one first.",
                    style: TextStyle(color: AppColors.mainColor)),
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: vehicles.map((v) {
                  final isSelected =
                      _selectedVehicle != null && _selectedVehicle!["_id"] == v["_id"];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVehicle = Map<String, dynamic>.from(v); // 🔹 store full JSON
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.mainColor
                            : AppColors.secondaryColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.directions_car,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.mainColor),
                          const SizedBox(width: 6),
                          Text(
                            "${v['brand']} ${v['model']}",
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.mainColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),

          // 🔹 Chat messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final message = chats[index];
                final isSentByUser = message["isSent"] == true;

                return Align(
                  alignment: isSentByUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSentByUser
                          ? AppColors.mainColor
                          : AppColors.mainSwatch.shade100,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: isSentByUser
                            ? const Radius.circular(15)
                            : const Radius.circular(0),
                        bottomRight: isSentByUser
                            ? const Radius.circular(0)
                            : const Radius.circular(15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.containsKey("image"))
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              message["image"],
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        if (message.containsKey("text"))
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              message["text"],
                              style: TextStyle(
                                color: isSentByUser
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 🔹 Input section
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
                          color: AppColors.mainColor.withOpacity(0.4)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ Vehicle chip OR Image preview
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
                                        const Icon(Icons.directions_car,
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
                                            setState(() {
                                              _selectedVehicle = null;
                                            });
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
                                          setState(() {
                                            _selectedImage = null;
                                          });
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

                        // ✅ Text input + camera + send
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
                              icon: const Icon(Icons.send_rounded,
                                  color: AppColors.mainColor),
                              onPressed: sendMessage,
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






//sesId

// import 'dart:io';
// import 'dart:convert';
// import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
// import 'package:fixibot_app/widgets/customAppBar.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:fixibot_app/constants/app_colors.dart';
// import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
// import 'package:http/http.dart' as http;


// class ChatScreen extends StatefulWidget {
//   const ChatScreen({super.key});

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final VehicleController vehicleController = Get.find<VehicleController>();
//   final TextEditingController _controller = TextEditingController();
//   final ImagePicker _picker = ImagePicker();
//   final String baseUrl = "http://127.0.0.1:8000";

//   final SharedPrefsHelper _prefs = SharedPrefsHelper();

//   File? _selectedImage;
//   String? _selectedVehicleId;
//   String? _sessionId; // 🔹 store chat session id
//   final Map<String, List<Map<String, dynamic>>> vehicleChats = {};

//   String? _accessToken;
//   String? _tokenType;

//   @override
//   void initState() {
//     super.initState();
//     vehicleController.fetchUserVehicles();
//     _initAuthAndSession();
//   }

//   /// 🔹 Initialize token + start session
//   Future<void> _initAuthAndSession() async {
//     _accessToken = await _prefs.getString("access_token");
//     _tokenType = await _prefs.getString("token_type");

//     if (_accessToken == null || _tokenType == null) {
//       Get.snackbar("Error", "Authentication required. Please login again.",
//           backgroundColor: Colors.redAccent, colorText: Colors.white);
//       return;
//     }

//     await _startChatSession();
//   }

//   /// 🔹 Start chat session with backend
//   Future<void> _startChatSession() async {
//     try {
//       final response = await http.post(
//         Uri.parse("$baseUrl/chat/start"),
//         headers: {
//           "Content-Type": "application/json",
//           "accept": "application/json",
//           "Authorization": "$_tokenType $_accessToken",
//         },
//       );

//       if (response.statusCode == 201) {
//         final data = json.decode(response.body);
//         setState(() {
//           _sessionId = data["session_id"];
//         });
//         debugPrint("✅ Chat session started: $_sessionId");
//       } else if (response.statusCode == 401) {
//         Get.snackbar("Unauthorized", "Session expired. Please login again.",
//             backgroundColor: Colors.redAccent, colorText: Colors.white);
//         debugPrint("❌ Unauthorized: ${response.body}");
//       } else {
//         debugPrint("❌ Failed to start session: ${response.statusCode} -> ${response.body}");
//       }
//     } catch (e) {
//       debugPrint("⚠️ Error starting chat session: $e");
//       Get.snackbar("Error", "Unable to connect to server.",
//           backgroundColor: Colors.redAccent, colorText: Colors.white);
//     }
//   }

//   /// 🔹 Send message (text + optional image + vehicle)
//   Future<void> sendMessage() async {
//     if (_sessionId == null) {
//       Get.snackbar("Error", "Chat session not started");
//       return;
//     }

//     if (_selectedVehicleId == null) {
//       Get.snackbar("Select Vehicle", "Please choose a vehicle to start chat",
//           backgroundColor: Colors.redAccent, colorText: Colors.white);
//       return;
//     }

//     if (_controller.text.trim().isEmpty && _selectedImage == null) return;

//     // Add user message locally
//     setState(() {
//       vehicleChats.putIfAbsent(_selectedVehicleId!, () => []);
//       vehicleChats[_selectedVehicleId!]!.add({
//         if (_selectedImage != null) "image": _selectedImage,
//         if (_controller.text.trim().isNotEmpty) "text": _controller.text,
//         "isSent": true,
//       });
//     });

//     try {
//       var request = http.MultipartRequest(
//         "POST",
//         Uri.parse("$baseUrl/chat/message"),
//       );

//       request.headers["Authorization"] = "$_tokenType $_accessToken";

//       request.fields["session_id"] = _sessionId!;
//       if (_controller.text.trim().isNotEmpty) {
//         request.fields["message"] = _controller.text.trim();
//       }
//       request.fields["vehicle_json"] =
//           json.encode({"vehicle_id": _selectedVehicleId});

//       if (_selectedImage != null) {
//         request.files.add(await http.MultipartFile.fromPath(
//           "image",
//           _selectedImage!.path,
//         ));
//       }

//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();

//       if (response.statusCode == 200) {
//         final botReply = json.decode(responseBody);
//         setState(() {
//           vehicleChats[_selectedVehicleId!]!.add({
//             "text": botReply["reply"] ?? "No response",
//             "isSent": false,
//           });
//         });
//       } else if (response.statusCode == 401) {
//         Get.snackbar("Unauthorized", "Session expired. Please login again.",
//             backgroundColor: Colors.redAccent, colorText: Colors.white);
//         debugPrint("❌ Unauthorized: $responseBody");
//       } else {
//         debugPrint("❌ Message failed: ${response.statusCode} -> $responseBody");
//       }
//     } catch (e) {
//       debugPrint("⚠️ Error sending message: $e");
//       Get.snackbar("Error", "Failed to send message.",
//           backgroundColor: Colors.redAccent, colorText: Colors.white);
//     }

//     // Reset input
//     _controller.clear();
//     setState(() {
//       _selectedImage = null;
//     });
//   }

//   Future<void> _pickImage() async {
//     final XFile? pickedFile = await _picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 80,
//     );

//     if (pickedFile != null) {
//       setState(() {
//         _selectedImage = File(pickedFile.path);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final chats = vehicleChats[_selectedVehicleId] ?? [];

//     return Scaffold(
//       backgroundColor: AppColors.secondaryColor,
//       appBar: const CustomAppBar(
//         title: "FixiBot",
//         actions: [
//           Icon(Icons.file_copy_outlined, color: AppColors.secondaryColor),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             child: Text(
//               "Please select the vehicle you’d like to resolve an issue for:",
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: AppColors.mainColor,
//               ),
//             ),
//           ),

//           // 🔹 Vehicle selection chips
//           Obx(() {
//             final vehicles = vehicleController.userVehicles;
//             if (vehicles.isEmpty) {
//               return const Padding(
//                 padding: EdgeInsets.all(12.0),
//                 child: Text("No vehicles added. Please add one first.",
//                     style: TextStyle(color: AppColors.mainColor)),
//               );
//             }
//             return SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//               child: Row(
//                 children: vehicles.map((v) {
//                   final isSelected = _selectedVehicleId == v["_id"];
//                   return GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         _selectedVehicleId = v["_id"]; // likr hee the vehicle selected by user , than whole json should go with chat message as required in backend not only vehicle id
//                       });
//                     },
//                     child: Container(
//                       margin: const EdgeInsets.only(right: 8),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 14, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: isSelected
//                             ? AppColors.mainColor
//                             : AppColors.secondaryColor,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(color: Colors.white),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.directions_car,
//                               size: 16,
//                               color: isSelected
//                                   ? Colors.white
//                                   : AppColors.mainColor),
//                           const SizedBox(width: 6),
//                           Text(
//                             "${v['brand']} ${v['model']}",
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: isSelected
//                                   ? Colors.white
//                                   : AppColors.mainColor,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             );
//           }),

//           // 🔹 Chat messages
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(10),
//               itemCount: chats.length,
//               itemBuilder: (context, index) {
//                 final message = chats[index];
//                 final isSentByUser = message["isSent"] == true;

//                 return Align(
//                   alignment: isSentByUser
//                       ? Alignment.centerRight
//                       : Alignment.centerLeft,
//                   child: Container(
//                     margin:
//                         const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: isSentByUser
//                           ? AppColors.mainColor
//                           : AppColors.mainSwatch.shade100,
//                       borderRadius: BorderRadius.only(
//                         topLeft: const Radius.circular(15),
//                         topRight: const Radius.circular(15),
//                         bottomLeft: isSentByUser
//                             ? const Radius.circular(15)
//                             : const Radius.circular(0),
//                         bottomRight: isSentByUser
//                             ? const Radius.circular(0)
//                             : const Radius.circular(15),
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         if (message.containsKey("image"))
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(8),
//                             child: Image.file(
//                               message["image"],
//                               width: 150,
//                               height: 150,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         if (message.containsKey("text"))
//                           Padding(
//                             padding: const EdgeInsets.only(top: 8.0),
//                             child: Text(
//                               message["text"],
//                               style: TextStyle(
//                                 color: isSentByUser
//                                     ? Colors.white
//                                     : Colors.black,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),

//           // 🔹 Input section
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
//                           color: AppColors.mainColor.withOpacity(0.4)),
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // ✅ Vehicle chip OR Image preview
//                         if (_selectedVehicleId != null || _selectedImage != null)
//                           Padding(
//                             padding: const EdgeInsets.only(
//                                 left: 4, top: 8, bottom: 6),
//                             child: Row(
//                               children: [
//                                 if (_selectedVehicleId != null)
//                                   Obx(() {
//                                     final vehicle = vehicleController
//                                         .userVehicles
//                                         .firstWhere(
//                                           (v) =>
//                                               v["_id"] == _selectedVehicleId,
//                                           orElse: () => {},
//                                         );
//                                     if (vehicle.isEmpty) {
//                                       return const SizedBox.shrink();
//                                     }
//                                     return Container(
//                                       margin: const EdgeInsets.only(right: 8),
//                                       padding: const EdgeInsets.symmetric(
//                                           horizontal: 10, vertical: 6),
//                                       decoration: BoxDecoration(
//                                         color: AppColors.mainSwatch.shade100,
//                                         borderRadius: BorderRadius.circular(20),
//                                       ),
//                                       child: Row(
//                                         mainAxisSize: MainAxisSize.min,
//                                         children: [
//                                           const Icon(Icons.directions_car,
//                                               size: 14,
//                                               color: AppColors.mainColor),
//                                           const SizedBox(width: 4),
//                                           Text(
//                                             "${vehicle['brand']} ${vehicle['model']}",
//                                             style: const TextStyle(
//                                               fontSize: 12,
//                                               color: AppColors.mainColor,
//                                               fontWeight: FontWeight.w500,
//                                             ),
//                                           ),
//                                           const SizedBox(width: 4),
//                                           GestureDetector(
//                                             onTap: () {
//                                               setState(() {
//                                                 _selectedVehicleId = null;
//                                               });
//                                             },
//                                             child: const Icon(Icons.close,
//                                                 size: 14,
//                                                 color: Colors.redAccent),
//                                           ),
//                                         ],
//                                       ),
//                                     );
//                                   }),

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
//                                           setState(() {
//                                             _selectedImage = null;
//                                           });
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

//                         // ✅ Text input + camera + send
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
//                               icon: const Icon(Icons.send_rounded,
//                                   color: AppColors.mainColor),
//                               onPressed: sendMessage,
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
