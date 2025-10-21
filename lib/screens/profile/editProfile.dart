import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fixibot_app/screens/profile/controller/userController.dart';
import 'package:fixibot_app/widgets/customAppBar.dart';
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
  final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";

  final UserController userController = Get.find<UserController>();
  
  // Image size validation
  final int maxImageSize = 10 * 1024 * 1024; // 10MB in bytes
  Rx<String?> imageSizeError = Rx<String?>(null);
  Rx<int?> currentImageSize = Rx<int?>(null);

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    emailController = TextEditingController(text: widget.currentEmail);
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      final imageFile = File(picked.path);
      final fileSize = await imageFile.length();
      
      // Check file size
      if (fileSize > maxImageSize) {
        setState(() {
          currentImageSize.value = fileSize;
          imageSizeError.value = "Image size exceeds 10MB limit";
        });
        Get.snackbar(
          "Image Too Large",
          "Please select an image smaller than 10MB",
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
        return;
      }
      
      // Clear any previous errors
      setState(() {
        currentImageSize.value = fileSize;
        imageSizeError.value = null;
      });
      
      userController.updateProfileImage(imageFile);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Future<void> _saveProfile() async {
     print("🔄 ===== SAVE PROFILE BUTTON CLICKED =====");
  print("📱 Image selected: ${userController.profileImage.value != null}");
  print("🚨 Image size error: ${imageSizeError.value}");
  print("💾 Current image size: ${currentImageSize.value != null ? _formatFileSize(currentImageSize.value!) : 'N/A'}");
  
  // Check if there's an image size error
  if (imageSizeError.value != null && userController.profileImage.value != null) {
    print("❌ BLOCKED: Image size exceeds limit - ${imageSizeError.value}");

    // Check if there's an image size error
      Get.snackbar(
        "Image Too Large",
        "Please select a smaller image (max 10MB)",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return;
    }

    final fullName = nameController.text.trim();
    final parts = fullName.split(" ");
    final firstName = parts.isNotEmpty ? parts.first : "";
    final lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "";

    final token = await _prefs.getString("access_token");
    final url = Uri.parse("$baseUrl/auth/users/me");
    final request = http.MultipartRequest("PUT", url);

    // Increase timeout to 60 seconds for large image upload
    request.headers["Authorization"] = "Bearer $token";
    request.fields["first_name"] = firstName;
    request.fields["last_name"] = lastName;
    request.fields["email"] = emailController.text.trim();

    // Add profile image if selected
    if (userController.profileImage.value != null && imageSizeError.value == null) {
      try {
        final imageFile = userController.profileImage.value!;
        final fileSize = await imageFile.length();
        
        // Double-check file size before upload
        if (fileSize > maxImageSize) {
          Get.snackbar(
            "Image Too Large",
            "Please select an image smaller than 10MB",
            colorText: Colors.white,
            backgroundColor: Colors.red,
          );
          return;
        }

        request.files.add(await http.MultipartFile.fromPath(
          "profile_picture",
          imageFile.path,
        ));
        print("✅ Image attached: ${imageFile.path} (${_formatFileSize(fileSize)})");
      } catch (e) {
        print("❌ Error attaching image: $e");
        Get.snackbar("Error", "Failed to attach image. Please try again.");
        return;
      }
    }

    try {
      // Show loading indicator
      Get.dialog(
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Send request with timeout
      final response = await request.send().timeout(
        const Duration(seconds: 60), // Increased to 60 seconds for large files
        onTimeout: () {
          throw TimeoutException("Image upload took too long. Please try again.");
        },
      );

      final respStr = await response.stream.bytesToString();
      print("📡 Response status: ${response.statusCode}");
      print("📡 Response body: $respStr");

      // Close loading dialog
      Get.back();

      if (response.statusCode == 200) {
        final updatedUser = json.decode(respStr);
        print("✅ Profile updated successfully: $updatedUser");

        // Extract the full name properly
        final String updatedFirstName = updatedUser['first_name'] ?? firstName;
        final String updatedLastName = updatedUser['last_name'] ?? lastName;
        final String updatedFullName = "$updatedFirstName $updatedLastName".trim();
        final String updatedEmail = updatedUser['email'] ?? emailController.text.trim();
        
        // ✅ Save locally
        await _prefs.saveString("full_name", updatedFullName);
        await _prefs.saveString("email", updatedEmail);

        // ✅ Update UserController (name & email)
        userController.updateUser(updatedFullName, updatedEmail);

        // ✅ If backend gives profile picture URL, update controller
        if (updatedUser['profile_picture_url'] != null) {
          final imageUrl = updatedUser['profile_picture_url'];
          userController.updateProfileImageUrl(imageUrl);
          await _prefs.saveProfileImageUrl(imageUrl);
          print("✅ Profile image URL saved: $imageUrl");
          
          // Clear the local file since we now have a URL
          userController.updateProfileImage(null);
          // Clear image size info
          setState(() {
            currentImageSize.value = null;
            imageSizeError.value = null;
          });
        } else {
          // If no URL returned but we had a local image, keep it locally
          print("ℹ️ No profile image URL returned from server");
        }

        // ✅ Navigate back & show success
        Get.back(result: updatedUser);

        Get.snackbar(
          "Profile Updated",
          "Your profile has been updated successfully.",
          colorText: Colors.white,
          backgroundColor: AppColors.minorColor,
          duration: const Duration(seconds: 3),
        );
      } else {
        print("❌ Error updating profile. Status: ${response.statusCode}");
        print("❌ Error response: $respStr");
        
        // Try to parse error message
        String errorMessage = "Failed to update profile. Please try again.";
        try {
          final errorJson = json.decode(respStr);
          if (errorJson is Map && errorJson.containsKey('detail')) {
            errorMessage = errorJson['detail'].toString();
          } else if (errorJson is Map && errorJson.containsKey('message')) {
            errorMessage = errorJson['message'].toString();
          } else if (errorJson is Map) {
            // Try to get first error value
            final firstError = errorJson.values.first;
            if (firstError is List) {
              errorMessage = firstError.first.toString();
            } else {
              errorMessage = firstError.toString();
            }
          }
        } catch (e) {
          // If we can't parse the error, use the raw response
          errorMessage = "Server error: ${response.statusCode}";
        }
        
        Get.snackbar(
          "Update Failed",
          errorMessage,
          colorText: Colors.white,
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        );
      }
    } on TimeoutException catch (e) {
      Get.back(); // Close loading dialog
      print("❌ Upload timeout: $e");
      Get.snackbar(
        "Upload Timeout",
        "Image upload took too long. Please try with a smaller image or better network.",
        colorText: Colors.white,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
    } on SocketException catch (e) {
      Get.back(); // Close loading dialog
      print("❌ Network error: $e");
      Get.snackbar(
        "Network Error",
        "Please check your internet connection and try again.",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      print("❌ Unexpected error: $e");
      Get.snackbar(
        "Error",
        "An unexpected error occurred. Please try again.",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    }
  }

  void _showImagePickerDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("Select Image Source"),
        content: const Text("Maximum image size: 10MB"),
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

  void _removeImage() {
    userController.removeProfileImage();
    setState(() {
      currentImageSize.value = null;
      imageSizeError.value = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: CustomAppBar(
        title: "Edit Profile",
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
                    
                    // Image size information and error display
                    const SizedBox(height: 10),
                    Obx(() {
                      if (currentImageSize.value != null) {
                        return Column(
                          children: [
                            Text(
                              "Image size: ${_formatFileSize(currentImageSize.value!)}",
                              style: TextStyle(
                                color: imageSizeError.value != null 
                                    ? Colors.red 
                                    : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (imageSizeError.value != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  imageSizeError.value!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        );
                      }
                      return const SizedBox();
                    }),
                    
                    const SizedBox(height: 10),
                    if (userController.profileImage.value != null ||
                        userController.profileImageUrl.value.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: imageSizeError.value != null 
                                  ? Colors.orange 
                                  : AppColors.mainColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: _showImagePickerDialog,
                            child: Text(
                              imageSizeError.value != null ? "Replace" : "Update",
                              style: TextStyle(
                                color: imageSizeError.value != null 
                                    ? Colors.white 
                                    : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: _removeImage,
                            child: const Text("Remove"),
                          ),
                        ],
                      ),
                  ],
                );
              }),
              
              // Maximum size info
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "Maximum image size: 50MB",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
              
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








//gud
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:fixibot_app/screens/profile/controller/userController.dart';
// import 'package:fixibot_app/widgets/customAppBar.dart';
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
//   final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";

//   final UserController userController = Get.find<UserController>();

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
//       userController.updateProfileImage(File(picked.path));
//     }
//   }

//   Future<void> _saveProfile() async {
//   final fullName = nameController.text.trim();
//   final parts = fullName.split(" ");
//   final firstName = parts.isNotEmpty ? parts.first : "";
//   final lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "";

//   final token = await _prefs.getString("access_token");
//   final url = Uri.parse("$baseUrl/auth/users/me");
//   final request = http.MultipartRequest("PUT", url);

//   // Increase timeout to 30 seconds for image upload
//   request.headers["Authorization"] = "Bearer $token";
//   request.fields["first_name"] = firstName;
//   request.fields["last_name"] = lastName;
//   request.fields["email"] = emailController.text.trim();

//   // Add profile image if selected
//   if (userController.profileImage.value != null) {
//     try {
//       // Compress image if it's too large
//       final imageFile = userController.profileImage.value!;
//       final fileSize = await imageFile.length();
//       final maxSize = 5 * 1024 * 1024; // 5MB
      
//       if (fileSize > maxSize) {
//         Get.snackbar(
//           "Image Too Large",
//           "Please select an image smaller than 5MB",
//           colorText: Colors.white,
//           backgroundColor: Colors.orange,
//         );
//         return;
//       }

//       request.files.add(await http.MultipartFile.fromPath(
//         "profile_picture",
//         imageFile.path,
//       ));
//       print("✅ Image attached: ${imageFile.path} (${fileSize ~/ 1024} KB)");
//     } catch (e) {
//       print("❌ Error attaching image: $e");
//       Get.snackbar("Error", "Failed to attach image. Please try again.");
//       return;
//     }
//   }

//   try {
//     // Show loading indicator
//     Get.dialog(
//       const Center(
//         child: CircularProgressIndicator(),
//       ),
//       barrierDismissible: false,
//     );

//     // Send request with timeout
//     final response = await request.send().timeout(
//       const Duration(seconds: 30),
//       onTimeout: () {
//         throw TimeoutException("Image upload took too long. Please try again.");
//       },
//     );

//     final respStr = await response.stream.bytesToString();
//     print("📡 Response status: ${response.statusCode}");
//     print("📡 Response body: $respStr");

//     // Close loading dialog
//     Get.back();

//     if (response.statusCode == 200) {
//       final updatedUser = json.decode(respStr);
//       print("✅ Profile updated successfully: $updatedUser");

//       // Extract the full name properly
//       final String updatedFirstName = updatedUser['first_name'] ?? firstName;
//       final String updatedLastName = updatedUser['last_name'] ?? lastName;
//       final String updatedFullName = "$updatedFirstName $updatedLastName".trim();
//       final String updatedEmail = updatedUser['email'] ?? emailController.text.trim();
      
//       // ✅ Save locally
//       await _prefs.saveString("full_name", updatedFullName);
//       await _prefs.saveString("email", updatedEmail);

//       // ✅ Update UserController (name & email)
//       userController.updateUser(updatedFullName, updatedEmail);

//       // ✅ If backend gives profile picture URL, update controller
//       if (updatedUser['profile_picture_url'] != null) {
//         final imageUrl = updatedUser['profile_picture_url'];
//         userController.updateProfileImageUrl(imageUrl);
//         await _prefs.saveProfileImageUrl(imageUrl);
//         print("✅ Profile image URL saved: $imageUrl");
        
//         // Clear the local file since we now have a URL
//         userController.updateProfileImage(null);
//       } else {
//         // If no URL returned but we had a local image, keep it locally
//         // This handles cases where backend doesn't return URL immediately
//         print("ℹ️ No profile image URL returned from server");
//       }

//       // ✅ Navigate back & show success
//       Get.back(result: updatedUser);

//       Get.snackbar(
//         "Profile Updated",
//         "Your profile has been updated successfully.",
//         colorText: Colors.white,
//         backgroundColor: AppColors.minorColor,
//         duration: const Duration(seconds: 3),
//       );
//     } else {
//       print("❌ Error updating profile. Status: ${response.statusCode}");
//       print("❌ Error response: $respStr");
      
//       // Try to parse error message
//       String errorMessage = "Failed to update profile. Please try again.";
//       try {
//         final errorJson = json.decode(respStr);
//         if (errorJson is Map && errorJson.containsKey('detail')) {
//           errorMessage = errorJson['detail'].toString();
//         } else if (errorJson is Map && errorJson.containsKey('message')) {
//           errorMessage = errorJson['message'].toString();
//         } else if (errorJson is Map) {
//           // Try to get first error value
//           final firstError = errorJson.values.first;
//           if (firstError is List) {
//             errorMessage = firstError.first.toString();
//           } else {
//             errorMessage = firstError.toString();
//           }
//         }
//       } catch (e) {
//         // If we can't parse the error, use the raw response
//         errorMessage = "Server error: ${response.statusCode}";
//       }
      
//       Get.snackbar(
//         "Update Failed",
//         errorMessage,
//         colorText: Colors.white,
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 4),
//       );
//     }
//   } on TimeoutException catch (e) {
//     Get.back(); // Close loading dialog
//     print("❌ Upload timeout: $e");
//     Get.snackbar(
//       "Upload Timeout",
//       "Image upload took too long. Please try with a smaller image or better network.",
//       colorText: Colors.white,
//       backgroundColor: Colors.red,
//       duration: const Duration(seconds: 5),
//     );
//   } on SocketException catch (e) {
//     Get.back(); // Close loading dialog
//     print("❌ Network error: $e");
//     Get.snackbar(
//       "Network Error",
//       "Please check your internet connection and try again.",
//       colorText: Colors.white,
//       backgroundColor: Colors.red,
//     );
//   } catch (e) {
//     Get.back(); // Close loading dialog
//     print("❌ Unexpected error: $e");
//     Get.snackbar(
//       "Error",
//       "An unexpected error occurred. Please try again.",
//       colorText: Colors.white,
//       backgroundColor: Colors.red,
//     );
//   }
// }


//   // Future<void> _saveProfile() async {
//   //   final fullName = nameController.text.trim();
//   //   final parts = fullName.split(" ");
//   //   final firstName = parts.isNotEmpty ? parts.first : "";
//   //   final lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "";

//   //   final token = await _prefs.getString("access_token");
//   //   final url = Uri.parse("$baseUrl/auth/users/me");
//   //   final request = http.MultipartRequest("PUT", url);

//   //   request.headers["Authorization"] = "Bearer $token";
//   //   request.fields["first_name"] = firstName;
//   //   request.fields["last_name"] = lastName;
//   //   request.fields["email"] = emailController.text.trim();

//   //   if (userController.profileImage.value != null) {
//   //     request.files.add(await http.MultipartFile.fromPath(
//   //       "profile_picture",
//   //       userController.profileImage.value!.path,
//   //     ));
//   //   }

//   //   final response = await request.send();
//   //   final respStr = await response.stream.bytesToString();

//   //   if (response.statusCode == 200) {
//   //     final updatedUser = json.decode(respStr);

//   //     // ✅ Save locally
//   //     await _prefs.saveString(
//   //         "full_name", "${updatedUser['first_name']} ${updatedUser['last_name']}");
//   //     await _prefs.saveString("email", updatedUser['email']);

//   //     // ✅ Update UserController (name & email)
//   //     userController.updateUser(
//   //       "${updatedUser['first_name']} ${updatedUser['last_name']}",
//   //       updatedUser['email'],
//   //     );

//   //     // ✅ If backend gives profile picture URL, update controller
//   //     if (updatedUser['profile_picture_url'] != null) {
//   //       userController.updateProfileImageUrl(updatedUser['profile_picture_url']);
//   //     }

//   //     // ✅ Navigate back & show success
//   //     Get.back(result: updatedUser);

//   //     Get.snackbar(
//   //       "Profile Updated",
//   //       "Your profile has been updated successfully.",
//   //       colorText: Colors.white,
//   //       backgroundColor: AppColors.minorColor,
//   //     );
//   //   } else {
//   //     print("❌ Error updating: $respStr");
//   //     Get.snackbar("Error", "Failed to update profile. Try again.");
//   //   }
//   // }

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
//       appBar: CustomAppBar(
        
//         title: "Notificatons",
        
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
//                       child: CircleAvatar(
//                         radius: 50,
//                         backgroundColor: AppColors.textColor4,
//                         backgroundImage: userController.profileImage.value != null
//                             ? FileImage(userController.profileImage.value!)
//                             : (userController.profileImageUrl.value.isNotEmpty
//                                 ? NetworkImage(userController.profileImageUrl.value)
//                                     as ImageProvider
//                                 : null),
//                         child: (userController.profileImage.value == null &&
//                                 userController.profileImageUrl.value.isEmpty)
//                             ? IconButton(
//                                 icon: const Icon(Icons.add, size: 30),
//                                 color: Colors.white,
//                                 onPressed: _showImagePickerDialog,
//                               )
//                             : null,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     if (userController.profileImage.value != null ||
//                         userController.profileImageUrl.value.isNotEmpty)
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
//                             onPressed: () => userController.removeProfileImage(),
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
