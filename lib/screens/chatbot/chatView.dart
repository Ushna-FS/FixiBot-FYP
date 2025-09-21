// latesttttt
import 'dart:io';
import 'package:fixibot_app/widgets/customAppBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fixibot_app/constants/app_colors.dart';
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
  String? _selectedVehicleId;
  final Map<String, List<Map<String, dynamic>>> vehicleChats = {};

  @override
  void initState() {
    super.initState();
    vehicleController.fetchUserVehicles();
  }

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
    final screenWidth = MediaQuery.of(context).size.width;

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
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      // 👇 let Row handle the available width
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.mainColor.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Row 1: Vehicle chip OR Image preview
              if (_selectedVehicleId != null || _selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(left:4,top: 8, bottom: 6),
                  child: Row(
                    children: [
                      if (_selectedVehicleId != null)
                        Obx(() {
                          final vehicle =
                              vehicleController.userVehicles.firstWhere(
                            (v) => v["_id"] == _selectedVehicleId,
                            orElse: () => {},
                          );
                          if (vehicle.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Container(
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
                                    size: 14, color: AppColors.mainColor),
                                const SizedBox(width: 4),
                                Text(
                                  "${vehicle['brand']} ${vehicle['model']}",
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
                                      _selectedVehicleId = null;
                                    });
                                  },
                                  child: const Icon(Icons.close,
                                      size: 14, color: Colors.redAccent),
                                ),
                              ],
                            ),
                          );
                        }),

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

              // ✅ Row 2: Text input + camera + send
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt_rounded,
                        color: AppColors.mainColor),
                    onPressed: _pickImage,
                  ),
                  Flexible(
                    flex: 2, // 👈 controls how wide the input is
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Type your message...",
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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


// import 'dart:io';
// import 'package:fixibot_app/widgets/customAppBar.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:fixibot_app/constants/app_colors.dart';
// import 'package:fixibot_app/constants/app_fontStyles.dart';
// import 'package:fixibot_app/widgets/custom_textField.dart';
// import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';

// class ChatScreen extends StatefulWidget {
//   const ChatScreen({super.key});

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final VehicleController vehicleController = Get.find<VehicleController>();

//   final TextEditingController _controller = TextEditingController();
//   final ImagePicker _picker = ImagePicker();

//   File? _selectedImage;
//   String? _selectedVehicleId; // <-- Vehicle filter
//   final Map<String, List<Map<String, dynamic>>> vehicleChats = {}; 

//   @override
//   void initState() {
//     super.initState();
//     vehicleController.fetchUserVehicles(); // 🔥 load vehicles here
//   }


//   void sendMessage() {
//     if (_selectedVehicleId == null) {
//       Get.snackbar("Select Vehicle", "Please choose a vehicle to start chat",
//           backgroundColor: Colors.redAccent, colorText: Colors.white);
//       return;
//     }

//     if (_controller.text.trim().isEmpty && _selectedImage == null) return;

//     setState(() {
//       vehicleChats.putIfAbsent(_selectedVehicleId!, () => []);
//       vehicleChats[_selectedVehicleId!]!.add({
//         if (_selectedImage != null) "image": _selectedImage,
//         if (_controller.text.trim().isNotEmpty) "text": _controller.text,
//         "isSent": true,
//       });

//       _controller.clear();
//       _selectedImage = null;

//       // Simulate bot response
//       Future.delayed(const Duration(seconds: 1), () {
//         setState(() {
//           vehicleChats[_selectedVehicleId!]!.add({
//             "text": "Thanks! We'll process your request for this vehicle.",
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
//     final chats = vehicleChats[_selectedVehicleId] ?? [];

//     return Scaffold(
//       backgroundColor: AppColors.secondaryColor,
     
//        appBar: const CustomAppBar(
//     title: "FixiBot",
//     actions: const [
//           Icon(Icons.file_copy_outlined, color: AppColors.secondaryColor),
//         ],
//   ),

//       body: Column(
//         children: [
//           Padding(
//   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//   child: Text(
//     "Please select the vehicle you’d like to resolve an issue for:",
//     style: TextStyle(
//       fontSize: 14,
//       fontWeight: FontWeight.w500,
//       color: AppColors.mainColor,
//     ),
//   ),
// ),

//           // 🔹 Vehicle selection chips
//           Obx(() {
//             final vehicles = vehicleController.userVehicles;
//             if (vehicles.isEmpty) {
//               return const Padding(
//                 padding: EdgeInsets.all(12.0),
//                 child: Text("No vehicles added. Please add one first.",
//                     style: TextStyle(color:AppColors.mainColor)),
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
//                         _selectedVehicleId = v["_id"];
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
//                               color:
//                                   isSelected ? Colors.white : AppColors.mainColor,
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

// //           Padding(
// //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
// //   child: Row(
// //     crossAxisAlignment: CrossAxisAlignment.end,
// //     children: [
// //   Expanded(
// //   child: Builder(builder: (_) {
// //     String hint = "Type your message";
// //     if (_selectedVehicleId != null) {
// //       final vehicle = vehicleController.userVehicles.firstWhere(
// //         (v) => v["_id"] == _selectedVehicleId,
// //         orElse: () => {},
// //       );
// //       if (vehicle.isNotEmpty) {
// //         hint = "${vehicle['brand']} ${vehicle['model']} • Type your message";
// //       }
// //     }
// //     return CustomTextField(
// //       controller: _controller,
// //       hintText: hint,
// //       icon: Icons.camera_alt_rounded,
// //       onIconPressed: _pickImage,
// //     );
// //   }),
// // ),

// //       // Selected image preview (if any)
// //       if (_selectedImage != null)
// //         Padding(
// //           padding: const EdgeInsets.only(right: 8.0),
// //           child: Stack(
// //             alignment: Alignment.topRight,
// //             children: [
// //               ClipRRect(
// //                 borderRadius: BorderRadius.circular(8),
// //                 child: Image.file(
// //                   _selectedImage!,
// //                   width: 60,
// //                   height: 60,
// //                   fit: BoxFit.cover,
// //                 ),
// //               ),
// //               GestureDetector(
// //                 onTap: () {
// //                   setState(() {
// //                     _selectedImage = null;
// //                   });
// //                 },
// //                 child: const CircleAvatar(
// //                   radius: 10,
// //                   backgroundColor: Colors.black54,
// //                   child: Icon(Icons.close, size: 14, color: Colors.white),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),

     
// //       IconButton(
// //         icon: const Icon(Icons.send_rounded, color: AppColors.mainColor),
// //         onPressed: sendMessage,
// //       ),
// //     ],
// //   ),
// // ),

// Padding(
//   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//   child: Row(
//     crossAxisAlignment: CrossAxisAlignment.end,
//     children: [
//       Expanded(
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(25),
//             border: Border.all(color: AppColors.mainColor.withOpacity(0.4)),
//           ),
//           child: Row(
//             children: [
//               // ✅ Small image preview inside input
//               if (_selectedImage != null)
//                 Stack(
//                   alignment: Alignment.topRight,
//                   children: [
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(6),
//                       child: Image.file(
//                         _selectedImage!,
//                         width: 40,
//                         height: 40,
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                     GestureDetector(
//                       onTap: () {
//                         setState(() {
//                           _selectedImage = null;
//                         });
//                       },
//                       child: const CircleAvatar(
//                         radius: 8,
//                         backgroundColor: Colors.black54,
//                         child: Icon(Icons.close, size: 12, color: Colors.white),
//                       ),
//                     ),
//                   ],
//                 ),

//               // spacing if image exists
//               if (_selectedImage != null) const SizedBox(width: 8),

//               // ✅ Vehicle chip inside input
//               if (_selectedVehicleId != null)
//                 Obx(() {
//                   final vehicle = vehicleController.userVehicles.firstWhere(
//                     (v) => v["_id"] == _selectedVehicleId,
//                     orElse: () => {},
//                   );
//                   if (vehicle.isEmpty) return const SizedBox.shrink();

//                   return Container(
//                     margin: const EdgeInsets.only(right: 8),
//                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: AppColors.mainSwatch.shade100,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(Icons.directions_car, size: 14, color: AppColors.mainColor),
//                         const SizedBox(width: 4),
//                         Text(
//                           "${vehicle['brand']} ${vehicle['model']}",
//                           style: const TextStyle(fontSize: 12, color: AppColors.mainColor, fontWeight: FontWeight.w500),
//                         ),
//                         const SizedBox(width: 4),
//                         GestureDetector(
//                           onTap: () {
//                             setState(() {
//                               _selectedVehicleId = null;
//                             });
//                           },
//                           child: const Icon(Icons.close, size: 14, color: Colors.redAccent),
//                         ),
//                       ],
//                     ),
//                   );
//                 }),

//               // ✅ TextField expands
//               Expanded(
//                 child: TextField(
//                   controller: _controller,
//                   decoration: const InputDecoration(
//                     border: InputBorder.none,
//                     hintText: "Type your message...",
//                   ),
//                   minLines: 1,
//                   maxLines: 4, // expands when multi-line
//                 ),
//               ),

//               // Camera icon
//               IconButton(
//                 icon: const Icon(Icons.camera_alt_rounded, color: AppColors.mainColor),
//                 onPressed: _pickImage,
//               ),
//             ],
//           ),
//         ),
//       ),

//       const SizedBox(width: 8),

//       // Send button
//       IconButton(
//         icon: const Icon(Icons.send_rounded, color: AppColors.mainColor),
//         onPressed: sendMessage,
//       ),
//     ],
//   ),
// )

//         ],
//       ),
//     );
//   }
// }




