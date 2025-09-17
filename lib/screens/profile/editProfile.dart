// import 'dart:convert';
// import 'dart:io';
// import 'package:fixibot_app/screens/profile/controller/userController.dart';
// import 'package:http/http.dart' as http;
// import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
// import 'package:get/get.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import '../../../constants/app_colors.dart';
// import '../../../constants/app_fontStyles.dart';
// import 'package:fixibot_app/widgets/custom_buttons.dart';
// import 'package:fixibot_app/widgets/custom_textField.dart';

// class EditProfile extends StatefulWidget {
//   final String currentName;
//   final String currentEmail;

//   const EditProfile({
//     super.key,
//     required this.currentName,
//     required this.currentEmail,
//   });

//   @override
//   _EditProfileState createState() => _EditProfileState();
// }

// class _EditProfileState extends State<EditProfile> {
//   late TextEditingController nameController;
//   late TextEditingController emailController;
//   final SharedPrefsHelper _prefs = SharedPrefsHelper();
//   final String baseUrl = "http://127.0.0.1:8000";
//    final Rx<File?> image = Rx<File?>(null);

//   @override
//   void initState() {
//     super.initState();
//     nameController = TextEditingController(text: widget.currentName);
//     emailController = TextEditingController(text: widget.currentEmail);
//   }

//   Future<void> pickImage(ImageSource source) async {
//     final picker = ImagePicker();
//     final picked = await picker.pickImage(source: source, imageQuality: 75);
//     if (picked != null) {
//       image.value = File(picked.path);
//     }
//   }

//   Future<void> _saveProfile() async {
//     final fullName = nameController.text.trim();
//     final parts = fullName.split(" ");
//     final firstName = parts.isNotEmpty ? parts.first : "";
//     final lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "";

//     final token = await _prefs.getString("access_token");
//     final url = Uri.parse("$baseUrl/auth/users/me");
//     final request = http.MultipartRequest("PUT", url);

//     request.headers["Authorization"] = "Bearer $token";
//     request.fields["first_name"] = firstName;
//     request.fields["last_name"] = lastName;
//     request.fields["email"] = emailController.text.trim();

//     if (image.value != null) {
//       request.files.add(await http.MultipartFile.fromPath(
//         "profile_picture",
//         image.value!.path,
//       ));
//     }

//     final response = await request.send();
//     final respStr = await response.stream.bytesToString();
//     final userController = Get.find<UserController>();

//     if (response.statusCode == 200) {
//       final updatedUser = json.decode(respStr);

//       // ✅ Save locally
//       await _prefs.saveString(
//           "full_name", "${updatedUser['first_name']} ${updatedUser['last_name']}");
//       await _prefs.saveString("email", updatedUser['email']);

//       // ✅ Update UserController so HomeHeader & Profile refresh immediately
//       userController.updateUser(
//         "${updatedUser['first_name']} ${updatedUser['last_name']}",
//         updatedUser['email'],
//       );

//       // ✅ Navigate back & show success
//       Get.back(result: updatedUser);

//       Get.snackbar(
//         "Profile Updated",
//         "Your profile has been updated successfully.",
//         colorText: Colors.white,
//         backgroundColor: AppColors.minorColor,
//       );
//     } else {
//       print("❌ Error updating: $respStr");
//       Get.snackbar("Error", "Failed to update profile. Try again.");
//     }
//   }

//   void _showImagePickerDialog() {
//     Get.dialog(
//       AlertDialog(
//         title: const Text("Select Image Source"),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Get.back();
//               pickImage(ImageSource.camera);
//             },
//             child: const Text("Camera"),
//           ),
//           TextButton(
//             onPressed: () {
//               Get.back();
//               pickImage(ImageSource.gallery);
//             },
//             child: const Text("Gallery"),
//           ),
//         ],
//       ),
//     );
//   }



//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.secondaryColor,
//       appBar: AppBar(
//         backgroundColor: AppColors.secondaryColor,
//         title: Text("Edit Profile", style: AppFonts.montserrathomecardText),
//         centerTitle: true,
//         leading: IconButton(
//           onPressed: () => Get.back(),
//           icon: Image.asset('assets/icons/back.png', width: 30, height: 30),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
            
//               Obx(() {
//                 return Column(
//                   children: [
//                     Center(
//                         child: CircleAvatar(
//                       radius: 50,
//                       backgroundColor: AppColors.textColor4,
//                       backgroundImage:
//                           image.value != null ? FileImage(image.value!) : null,
//                       child: image.value == null
//                           ? IconButton(
//                               icon: const Icon(Icons.add, size: 30),
//                               color: Colors.white,
//                               onPressed: _showImagePickerDialog,
//                             )
//                           : null,
//                     )
//                     ),
                  
//                     const SizedBox(height: 10),
//                     if (image.value != null)
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: AppColors.mainColor,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                             ),
//                             onPressed: _showImagePickerDialog,
//                             child: const Text("Update"),
//                           ),
//                           const SizedBox(width: 10),
//                           ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.red,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                             ),
//                             onPressed: () => image.value = null,
//                             child: const Text("Remove"),
//                           ),
//                         ],
//                       ),
//                   ],
//                 );
//               }),
//               const SizedBox(height: 20),
//               Text("Name", style: AppFonts.montserratText3),
//               CustomTextField(
//                 controller: nameController,
//                 hintText: "Enter your name",
//                 icon: Icons.person,
//                 keyboardType: TextInputType.name,
//               ),
//               const SizedBox(height: 20),
//               Text("Email", style: AppFonts.montserratText3),
//               CustomTextField(
//                 controller: emailController,
//                 hintText: "Enter your email",
//                 icon: Icons.email,
//                 keyboardType: TextInputType.emailAddress,
//               ),
//               const SizedBox(height: 40),
//               Align(
//                 alignment: Alignment.center,
//                 child: CustomButton(
//                   text: "Save Changes",
//                   onPressed: _saveProfile,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }




import 'dart:convert';
import 'dart:io';
import 'package:fixibot_app/screens/profile/controller/userController.dart';
import 'package:http/http.dart' as http;
import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_fontStyles.dart';
import 'package:fixibot_app/widgets/custom_buttons.dart';
import 'package:fixibot_app/widgets/custom_textField.dart';

class EditProfile extends StatefulWidget {
  final String currentName;
  final String currentEmail;

  const EditProfile({
    super.key,
    required this.currentName,
    required this.currentEmail,
  });

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  final SharedPrefsHelper _prefs = SharedPrefsHelper();
  final String baseUrl = "http://127.0.0.1:8000";

  final UserController userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    emailController = TextEditingController(text: widget.currentEmail);
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75);
    if (picked != null) {
      userController.updateProfileImage(File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    final fullName = nameController.text.trim();
    final parts = fullName.split(" ");
    final firstName = parts.isNotEmpty ? parts.first : "";
    final lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "";

    final token = await _prefs.getString("access_token");
    final url = Uri.parse("$baseUrl/auth/users/me");
    final request = http.MultipartRequest("PUT", url);

    request.headers["Authorization"] = "Bearer $token";
    request.fields["first_name"] = firstName;
    request.fields["last_name"] = lastName;
    request.fields["email"] = emailController.text.trim();

    if (userController.profileImage.value != null) {
      request.files.add(await http.MultipartFile.fromPath(
        "profile_picture",
        userController.profileImage.value!.path,
      ));
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final updatedUser = json.decode(respStr);

      // ✅ Save locally
      await _prefs.saveString(
          "full_name", "${updatedUser['first_name']} ${updatedUser['last_name']}");
      await _prefs.saveString("email", updatedUser['email']);

      // ✅ Update UserController (name & email)
      userController.updateUser(
        "${updatedUser['first_name']} ${updatedUser['last_name']}",
        updatedUser['email'],
      );

      // ✅ If backend gives profile picture URL, update controller
      if (updatedUser['profile_picture_url'] != null) {
        userController.updateProfileImageUrl(updatedUser['profile_picture_url']);
      }

      // ✅ Navigate back & show success
      Get.back(result: updatedUser);

      Get.snackbar(
        "Profile Updated",
        "Your profile has been updated successfully.",
        colorText: Colors.white,
        backgroundColor: AppColors.minorColor,
      );
    } else {
      print("❌ Error updating: $respStr");
      Get.snackbar("Error", "Failed to update profile. Try again.");
    }
  }

  void _showImagePickerDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("Select Image Source"),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              pickImage(ImageSource.camera);
            },
            child: const Text("Camera"),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              pickImage(ImageSource.gallery);
            },
            child: const Text("Gallery"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryColor,
        title: Text("Edit Profile", style: AppFonts.montserrathomecardText),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Image.asset('assets/icons/back.png', width: 30, height: 30),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
                return Column(
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.textColor4,
                        backgroundImage: userController.profileImage.value != null
                            ? FileImage(userController.profileImage.value!)
                            : (userController.profileImageUrl.value.isNotEmpty
                                ? NetworkImage(userController.profileImageUrl.value)
                                    as ImageProvider
                                : null),
                        child: (userController.profileImage.value == null &&
                                userController.profileImageUrl.value.isEmpty)
                            ? IconButton(
                                icon: const Icon(Icons.add, size: 30),
                                color: Colors.white,
                                onPressed: _showImagePickerDialog,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (userController.profileImage.value != null ||
                        userController.profileImageUrl.value.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mainColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: _showImagePickerDialog,
                            child: const Text("Update"),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () => userController.removeProfileImage(),
                            child: const Text("Remove"),
                          ),
                        ],
                      ),
                  ],
                );
              }),
              const SizedBox(height: 20),
              Text("Name", style: AppFonts.montserratText3),
              CustomTextField(
                controller: nameController,
                hintText: "Enter your name",
                icon: Icons.person,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 20),
              Text("Email", style: AppFonts.montserratText3),
              CustomTextField(
                controller: emailController,
                hintText: "Enter your email",
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.center,
                child: CustomButton(
                  text: "Save Changes",
                  onPressed: _saveProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
