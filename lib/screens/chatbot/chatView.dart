



import 'dart:io';
import 'package:fixibot_app/widgets/customAppBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/widgets/custom_textField.dart';
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final VehicleController vehicleController = Get.find<VehicleController>();

  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String? _selectedVehicleId; // <-- Vehicle filter
  final Map<String, List<Map<String, dynamic>>> vehicleChats = {}; 
  // Each vehicle has its own chat history

  void sendMessage() {
    if (_selectedVehicleId == null) {
      Get.snackbar("Select Vehicle", "Please choose a vehicle to start chat",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    if (_controller.text.trim().isEmpty && _selectedImage == null) return;

    setState(() {
      vehicleChats.putIfAbsent(_selectedVehicleId!, () => []);
      vehicleChats[_selectedVehicleId!]!.add({
        if (_selectedImage != null) "image": _selectedImage,
        if (_controller.text.trim().isNotEmpty) "text": _controller.text,
        "isSent": true,
      });

      _controller.clear();
      _selectedImage = null;

      // Simulate bot response
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          vehicleChats[_selectedVehicleId!]!.add({
            "text": "Thanks! We'll process your request for this vehicle.",
            "isSent": false,
          });
        });
      });
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
    final chats = vehicleChats[_selectedVehicleId] ?? [];

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
     
       appBar: const CustomAppBar(
    title: "FixiBot",
    actions: const [
          Icon(Icons.file_copy_outlined, color: AppColors.secondaryColor),
        ],
  ),

      body: Column(
        children: [
          // 🔹 Vehicle selection chips
          Obx(() {
            final vehicles = vehicleController.userVehicles;
            if (vehicles.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text("No vehicles added. Please add one first.",
                    style: TextStyle(color:AppColors.mainColor)),
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: vehicles.map((v) {
                  final isSelected = _selectedVehicleId == v["_id"];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVehicleId = v["_id"];
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
                              color:
                                  isSelected ? Colors.white : AppColors.mainColor,
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
                  alignment:
                      isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
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
                                color: isSentByUser ? Colors.white : Colors.black,
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

          // 🔹 Input bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            width: 60,
                            height: 60,
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
                            radius: 10,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: CustomTextField(
                    controller: _controller,
                    hintText: "Type Here",
                    icon: Icons.camera_alt_rounded,
                    onIconPressed: _pickImage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.mainColor),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';

// import 'package:fixibot_app/constants/app_colors.dart';
// import 'package:fixibot_app/constants/app_fontStyles.dart';
// import 'package:fixibot_app/widgets/custom_textField.dart';

// void main() {
//   runApp(const ChatScreen());
// }

// class ChatScreen extends StatelessWidget {
//   const ChatScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: ChatPage(),
//     );
//   }
// }

// class ChatPage extends StatefulWidget {
//   const ChatPage({super.key});

//   @override
//   _ChatPageState createState() => _ChatPageState();
// }

// class _ChatPageState extends State<ChatPage> {
//   final List<Map<String, dynamic>> messages = [
//     {"text": "Hello! My car engine is making weird sounds.", "isSent": true},
//     {"text": "....", "isSent": false},
//   ];

//   final TextEditingController _controller = TextEditingController();
//   final ImagePicker _picker = ImagePicker();
//   File? _selectedImage;

//   void sendMessage() {
//     if (_controller.text.trim().isEmpty && _selectedImage == null) return;

//     setState(() {
//       messages.add({
//         if (_selectedImage != null) "image": _selectedImage,
//         if (_controller.text.trim().isNotEmpty) "text": _controller.text,
//         "isSent": true,
//       });
//       _controller.clear();
//       _selectedImage = null;

//       Future.delayed(const Duration(seconds: 1), () {
//         setState(() {
//           messages.add({
//             "text": "Thanks! We'll process your request soon.",
//             "isSent": false,
//           });
//         });
//       });
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
//     return Scaffold(
//       backgroundColor: AppColors.secondaryColor,
//       appBar: AppBar(
//         elevation: 1,
//         title: Text("FixiBot", style: AppFonts.montserrathomecardText),
//         centerTitle: true,
//         leading: IconButton(
//           onPressed: () => Get.back(),
//           icon: Image.asset('assets/icons/back.png', width: 30, height: 30),
//         ),
//         actions: const [
//           Icon(Icons.file_copy_outlined, color: AppColors.mainColor),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(10),
//               itemCount: messages.length,
//               itemBuilder: (context, index) {
//                 final message = messages[index];
//                 final isSentByUser = message["isSent"] == true;

//                 return Align(
//                   alignment:
//                       isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
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
//                                 color: isSentByUser ? Colors.white : Colors.black,
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
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 if (_selectedImage != null)
//                   Padding(
//                     padding: const EdgeInsets.only(right: 8.0),
//                     child: Stack(
//                       alignment: Alignment.topRight,
//                       children: [
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(8),
//                           child: Image.file(
//                             _selectedImage!,
//                             width: 60,
//                             height: 60,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                         GestureDetector(
//                           onTap: () {
//                             setState(() {
//                               _selectedImage = null;
//                             });
//                           },
//                           child: const CircleAvatar(
//                             radius: 10,
//                             backgroundColor: Colors.black54,
//                             child: Icon(Icons.close, size: 14, color: Colors.white),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 Expanded(
//                   child: CustomTextField(
//                     controller: _controller,
//                     hintText: "Type Here",
//                     icon: Icons.camera_alt_rounded,
//                     onIconPressed: _pickImage,
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send_rounded, color: AppColors.mainColor),
//                   onPressed: sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


