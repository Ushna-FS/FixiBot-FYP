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
  
  // Image size validation - 5MB
  final int maxImageSize = 5 * 1024 * 1024;
  Rx<String?> imageSizeError = Rx<String?>(null);
  Rx<int?> currentImageSize = Rx<int?>(null);
  
  // Track changes
  bool get _hasChanges {
    return nameController.text != widget.currentName ||
        emailController.text != widget.currentEmail ||
        userController.profileImage.value != null;
  }

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    emailController = TextEditingController(text: widget.currentEmail);
    
    // Reset update status when entering edit profile
    userController.isProfileUpdated.value = false;
    userController.isImageUploaded.value = false;
    
    print('🔄 EditProfile initialized with current image: ${userController.profileImageUrl.value.isNotEmpty ? userController.profileImageUrl.value : "None"}');
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      
      if (picked != null) {
        final imageFile = File(picked.path);
        final fileSize = await imageFile.length();
        
        print('📸 Image picked: ${picked.path} (${_formatFileSize(fileSize)})');
        
        // Check file size - 5MB
        if (fileSize > maxImageSize) {
          setState(() {
            currentImageSize.value = fileSize;
            imageSizeError.value = "Image size exceeds 5MB limit";
          });
          Get.snackbar(
            "Image Too Large",
            "Please select an image smaller than 5MB",
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
        print("✅ Image set for upload: ${picked.path}");
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      Get.snackbar(
        "Error",
        "Failed to pick image. Please try again.",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
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
    print("🌐 Existing image URL: ${userController.profileImageUrl.value}");
    print("🚨 Image size error: ${imageSizeError.value}");
    
    // Check if there's an image size error
    if (imageSizeError.value != null && userController.profileImage.value != null) {
      print("❌ BLOCKED: Image size exceeds limit - ${imageSizeError.value}");
      Get.snackbar(
        "Image Too Large",
        "Please select a smaller image (max 5MB)",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return;
    }

    // Check if there are actual changes
    if (!_hasChanges) {
      print("ℹ️ No changes detected");
      Get.snackbar(
        "No Changes",
        "No changes were made to update.",
        colorText: Colors.white,
        backgroundColor: Colors.blue,
      );
      return;
    }

    final fullName = nameController.text.trim();
    final parts = fullName.split(" ");
    final firstName = parts.isNotEmpty ? parts.first : "";
    final lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "";

    final token = await _prefs.getString("access_token");
    if (token == null) {
      Get.snackbar("Error", "Authentication token not found");
      return;
    }

    final url = Uri.parse("$baseUrl/auth/users/me");
    final request = http.MultipartRequest("PUT", url);

    // Set headers and fields
    request.headers["Authorization"] = "Bearer $token";
    request.fields["first_name"] = firstName;
    request.fields["last_name"] = lastName;
    request.fields["email"] = emailController.text.trim();

    // Add profile image if selected and no size error
    File? imageToUpload;
    if (userController.profileImage.value != null && imageSizeError.value == null) {
      imageToUpload = userController.profileImage.value;
    }

    if (imageToUpload != null) {
      try {
        final fileSize = await imageToUpload.length();
        
        // Final file size check before upload
        if (fileSize > maxImageSize) {
          Get.snackbar(
            "Image Too Large",
            "Please select an image smaller than 5MB",
            colorText: Colors.white,
            backgroundColor: Colors.red,
          );
          return;
        }

        request.files.add(await http.MultipartFile.fromPath(
          "profile_picture",
          imageToUpload.path,
        ));
        print("✅ Image attached for upload: ${imageToUpload.path} (${_formatFileSize(fileSize)})");
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
              Text("Updating profile..."),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      print("📡 Sending profile update request...");
      final response = await request.send().timeout(
        const Duration(seconds: 60),
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
        print("✅ Profile updated successfully in backend: $updatedUser");

        // Extract the full name properly
        final String updatedFirstName = updatedUser['first_name'] ?? firstName;
        final String updatedLastName = updatedUser['last_name'] ?? lastName;
        final String updatedFullName = "$updatedFirstName $updatedLastName".trim();
        final String updatedEmail = updatedUser['email'] ?? emailController.text.trim();
        
        // ✅ Save locally ONLY after backend success
        await _prefs.saveString("full_name", updatedFullName);
        await _prefs.saveString("email", updatedEmail);

        // ✅ Update UserController (name & email) ONLY after backend success
        userController.updateUser(updatedFullName, updatedEmail);



// ✅ CRITICAL FIX: Handle profile image URL from backend response
// Backend returns 'profile_picture' not 'profile_picture_url'
if (updatedUser['profile_picture'] != null) {
  final imageUrl = updatedUser['profile_picture'].toString();
  print("✅ Backend returned image URL: $imageUrl");
  
  // Update controller and save to SharedPreferences
  userController.updateProfileImageUrl(imageUrl);
  
  // Clear the local file and image size info
  userController.updateProfileImage(null);
  setState(() {
    currentImageSize.value = null;
    imageSizeError.value = null;
  });
  
  print("🖼️ Profile image successfully saved to persistent storage");
  
  // Verify it's saved
  final savedUrl = await _prefs.getProfileImageUrl();
  print("🔍 Verification - Saved URL in SharedPreferences: $savedUrl");
} else if (imageToUpload != null) {
  // If we uploaded an image but no URL returned, show warning but keep local image
  print("⚠️ Image uploaded but no URL returned from server");
  Get.snackbar(
    "Image Upload Issue",
    "Profile updated but image may not have uploaded correctly.",
    colorText: Colors.white,
    backgroundColor: Colors.orange,
    duration: Duration(seconds: 5),
  );
  // Keep the local image so user can try again
} else {
  // No image was uploaded, just profile data updated
  print("ℹ️ Profile data updated without image changes");
}
        
        // ✅ Mark profile as successfully updated
        userController.markProfileUpdated();

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
        print("❌ Error updating profile in backend. Status: ${response.statusCode}");
        print("❌ Error response: $respStr");
        
        // Mark update as failed
        userController.markUpdateFailed("Server error: ${response.statusCode}");
        
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
      Get.back();
      print("❌ Upload timeout: $e");
      userController.markUpdateFailed("Upload timeout");
      Get.snackbar(
        "Upload Timeout",
        "Image upload took too long. Please try with a smaller image or better network.",
        colorText: Colors.white,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
    } on SocketException catch (e) {
      Get.back();
      print("❌ Network error: $e");
      userController.markUpdateFailed("Network error");
      Get.snackbar(
        "Network Error",
        "Please check your internet connection and try again.",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    } catch (e) {
      Get.back();
      print("❌ Unexpected error: $e");
      userController.markUpdateFailed("Unexpected error: $e");
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
        content: const Text("Maximum image size: 5MB"),
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
    print("🗑️ Profile image removed locally");
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
                      child: Stack(
                        children: [
                          CircleAvatar(
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
                                ? Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          // Add button overlay for users without profile image
                          if (userController.profileImage.value == null && 
                              userController.profileImageUrl.value.isEmpty)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.mainColor,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.add, size: 20),
                                  color: Colors.white,
                                  onPressed: _showImagePickerDialog,
                                ),
                              ),
                            ),
                        ],
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
                              imageSizeError.value != null ? "Replace" : "Change",
                              style: TextStyle(
                                color: Colors.white,
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
                            child: const Text(
                              "Remove",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    // Add button for users without profile image
                    if (userController.profileImage.value == null && 
                        userController.profileImageUrl.value.isEmpty)
                      const SizedBox(height: 10),
                    if (userController.profileImage.value == null && 
                        userController.profileImageUrl.value.isEmpty)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: _showImagePickerDialog,
                        child: const Text(
                          "Add Profile Picture",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                );
              }),
              
              // Maximum size info
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "Maximum image size: 5MB",
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








///attempt
///
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
  
//   // Image size validation - 5MB MAX
//   final int maxImageSize = 5 * 1024 * 1024;
//   Rx<String?> imageSizeError = Rx<String?>(null);
//   Rx<int?> currentImageSize = Rx<int?>(null);
//   Rx<bool> isUploading = Rx<bool>(false);
  
//   // Track original values to detect changes
//   File? _originalImage;
//   String? _originalImageUrl;

//   @override
//   void initState() {
//     super.initState();
//     nameController = TextEditingController(text: widget.currentName);
//     emailController = TextEditingController(text: widget.currentEmail);
    
//     // Store original image state
//     _originalImage = userController.profileImage.value;
//     _originalImageUrl = userController.profileImageUrl.value;
    
//     // Reset update status
//     userController.isProfileUpdated.value = false;
//     userController.isImageUploaded.value = false;
//   }

//   // Check if there are actual changes
//   bool get _hasChanges {
//     final nameChanged = nameController.text != widget.currentName;
//     final emailChanged = emailController.text != widget.currentEmail;
//     final imageChanged = userController.profileImage.value != _originalImage ||
//         (userController.profileImage.value != null && _originalImage == null);
    
//     return nameChanged || emailChanged || imageChanged;
//   }

//   // Check if image was changed
//   bool get _hasImageChanges {
//     return userController.profileImage.value != _originalImage ||
//         (userController.profileImage.value != null && _originalImage == null);
//   }

//   Future<void> pickImage(ImageSource source) async {
//     try {
//       final picker = ImagePicker();
//       final picked = await picker.pickImage(
//         source: source, 
//         imageQuality: 85,
//         maxWidth: 1024,
//         maxHeight: 1024,
//       );
      
//       if (picked != null) {
//         final imageFile = File(picked.path);
//         final fileSize = await imageFile.length();
        
//         // Check file size - MAX 5MB
//         if (fileSize > maxImageSize) {
//           setState(() {
//             currentImageSize.value = fileSize;
//             imageSizeError.value = "Image size exceeds 5MB limit";
//           });
//           Get.snackbar(
//             "Image Too Large",
//             "Please select an image smaller than 5MB",
//             colorText: Colors.white,
//             backgroundColor: Colors.red,
//           );
//           return;
//         }
        
//         // Clear any previous errors and set new image
//         setState(() {
//           currentImageSize.value = fileSize;
//           imageSizeError.value = null;
//         });
        
//         userController.updateProfileImage(imageFile);
//         print("📸 Image picked: ${picked.path} (${_formatFileSize(fileSize)})");
//       }
//     } catch (e) {
//       print("❌ Error picking image: $e");
//       Get.snackbar(
//         "Error",
//         "Failed to pick image. Please try again.",
//         colorText: Colors.white,
//         backgroundColor: Colors.red,
//       );
//     }
//   }

//   String _formatFileSize(int bytes) {
//     if (bytes < 1024) {
//       return '$bytes B';
//     } else if (bytes < 1024 * 1024) {
//       return '${(bytes / 1024).toStringAsFixed(1)} KB';
//     } else {
//       return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
//     }
//   }

//   Future<void> _saveProfile() async {
//     print("🔄 ===== SAVE PROFILE BUTTON CLICKED =====");
//     print("📱 Image selected: ${userController.profileImage.value != null}");
//     print("📏 Image size error: ${imageSizeError.value}");
//     print("💾 Has changes: $_hasChanges");
    
//     // Check if there's an image size error
//     if (imageSizeError.value != null && userController.profileImage.value != null) {
//       print("❌ BLOCKED: Image size exceeds limit");
//       Get.snackbar(
//         "Image Too Large",
//         "Please select a smaller image (max 5MB)",
//         colorText: Colors.white,
//         backgroundColor: Colors.red,
//       );
//       return;
//     }

//     // Check if there are actual changes
//     if (!_hasChanges) {
//       print("ℹ️ No changes detected");
//       Get.snackbar(
//         "No Changes",
//         "No changes were made to update.",
//         colorText: Colors.white,
//         backgroundColor: Colors.blue,
//       );
//       return;
//     }

//     final fullName = nameController.text.trim();
//     final parts = fullName.split(" ");
//     final firstName = parts.isNotEmpty ? parts.first : "";
//     final lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "";

//     final token = await _prefs.getString("access_token");
//     if (token == null) {
//       Get.snackbar(
//         "Authentication Error",
//         "Please login again",
//         colorText: Colors.white,
//         backgroundColor: Colors.red,
//       );
//       return;
//     }

//     final url = Uri.parse("$baseUrl/auth/users/me");
//     final request = http.MultipartRequest("PUT", url);

//     // Set headers and fields
//     request.headers["Authorization"] = "Bearer $token";
//     request.fields["first_name"] = firstName;
//     request.fields["last_name"] = lastName;
//     request.fields["email"] = emailController.text.trim();

//     // Handle image upload - only if changed and no size error
//     File? imageToUpload;
//     if (_hasImageChanges && 
//         userController.profileImage.value != null && 
//         imageSizeError.value == null) {
//       imageToUpload = userController.profileImage.value;
//     }

//     if (imageToUpload != null) {
//       try {
//         final fileSize = await imageToUpload.length();
        
//         // Final file size check before upload
//         if (fileSize > maxImageSize) {
//           Get.snackbar(
//             "Image Too Large",
//             "Please select an image smaller than 5MB",
//             colorText: Colors.white,
//             backgroundColor: Colors.red,
//           );
//           return;
//         }

//         request.files.add(await http.MultipartFile.fromPath(
//           "profile_picture",
//           imageToUpload.path,
//         ));
//         print("✅ Image attached for upload: ${_formatFileSize(fileSize)}");
//       } catch (e) {
//         print("❌ Error attaching image: $e");
//         Get.snackbar("Error", "Failed to attach image. Please try again.");
//         return;
//       }
//     }

//     // Set uploading state
//     isUploading.value = true;

//     try {
//       // Show loading indicator
//       Get.dialog(
//         const Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(height: 16),
//               Text("Updating profile..."),
//             ],
//           ),
//         ),
//         barrierDismissible: false,
//       );

//       print("📡 Sending profile update request...");
//       final response = await request.send().timeout(
//         const Duration(seconds: 60),
//         onTimeout: () {
//           throw TimeoutException("Image upload took too long. Please try again.");
//         },
//       );

//       final respStr = await response.stream.bytesToString();
//       print("📡 Response status: ${response.statusCode}");
//       print("📡 Response body: $respStr");

//       // Close loading dialog
//       Get.back();

//       if (response.statusCode == 200) {
//         final updatedUser = json.decode(respStr);
//         print("✅ Profile updated successfully in backend");
        
//         // Extract updated data
//         final String updatedFirstName = updatedUser['first_name'] ?? firstName;
//         final String updatedLastName = updatedUser['last_name'] ?? lastName;
//         final String updatedFullName = "$updatedFirstName $updatedLastName".trim();
//         final String updatedEmail = updatedUser['email'] ?? emailController.text.trim();
        
//         // ✅ Save locally ONLY after backend success
//         await _prefs.saveString("full_name", updatedFullName);
//         await _prefs.saveString("email", updatedEmail);

//         // ✅ Update UserController (name & email) ONLY after backend success
//         userController.updateUser(updatedFullName, updatedEmail);

//         // ✅ Handle profile image URL from backend response
//         if (updatedUser['profile_picture_url'] != null) {
//           final imageUrl = updatedUser['profile_picture_url'];
//           print("✅ Backend returned profile image URL: $imageUrl");
          
//           // Update controller with the URL from backend
//           userController.updateProfileImageUrl(imageUrl);
          
//           // Clear local file since we now have URL from backend
//           userController.updateProfileImage(null);
          
//           // Clear image size info
//           setState(() {
//             currentImageSize.value = null;
//             imageSizeError.value = null;
//           });
          
//           // Mark image as uploaded successfully
//           userController.markImageUploaded();
//         } else if (imageToUpload != null) {
//           // If we uploaded an image but no URL returned, show warning but keep changes
//           print("⚠️ Image uploaded but no URL returned from server");
          
//           // Keep the local image so user can try again
//           // Don't update the URL, keep the local file for retry
          
//           Get.snackbar(
//             "Partial Success",
//             "Profile updated but image upload may have failed. Please try updating image again.",
//             colorText: Colors.white,
//             backgroundColor: Colors.orange,
//             duration: const Duration(seconds: 5),
//           );
//         }

//         // ✅ Mark profile as successfully updated
//         userController.markProfileUpdated();

//         // ✅ Navigate back & show success
//         Get.back(result: updatedUser);

//         Get.snackbar(
//           "Profile Updated",
//           "Your profile has been updated successfully.",
//           colorText: Colors.white,
//           backgroundColor: AppColors.minorColor,
//           duration: const Duration(seconds: 3),
//         );
        
//       } else {
//         print("❌ Error updating profile in backend. Status: ${response.statusCode}");
//         print("❌ Error response: $respStr");
        
//         // Mark update as failed
//         userController.markUpdateFailed("Server error: ${response.statusCode}");
        
//         // Parse error message
//         String errorMessage = "Failed to update profile. Please try again.";
//         try {
//           final errorJson = json.decode(respStr);
//           if (errorJson is Map && errorJson.containsKey('detail')) {
//             errorMessage = errorJson['detail'].toString();
//           } else if (errorJson is Map && errorJson.containsKey('message')) {
//             errorMessage = errorJson['message'].toString();
//           } else if (errorJson is Map) {
//             // Try to get first error value
//             final firstError = errorJson.values.first;
//             if (firstError is List) {
//               errorMessage = firstError.first.toString();
//             } else {
//               errorMessage = firstError.toString();
//             }
//           }
//         } catch (e) {
//           errorMessage = "Server error: ${response.statusCode}";
//         }
        
//         Get.snackbar(
//           "Update Failed",
//           errorMessage,
//           colorText: Colors.white,
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 4),
//         );
//       }
//     } on TimeoutException catch (e) {
//       Get.back();
//       print("❌ Upload timeout: $e");
//       userController.markUpdateFailed("Upload timeout");
//       Get.snackbar(
//         "Upload Timeout",
//         "Image upload took too long. Please try with a smaller image or better network.",
//         colorText: Colors.white,
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 5),
//       );
//     } on SocketException catch (e) {
//       Get.back();
//       print("❌ Network error: $e");
//       userController.markUpdateFailed("Network error");
//       Get.snackbar(
//         "Network Error",
//         "Please check your internet connection and try again.",
//         colorText: Colors.white,
//         backgroundColor: Colors.red,
//       );
//     } catch (e) {
//       Get.back();
//       print("❌ Unexpected error: $e");
//       userController.markUpdateFailed("Unexpected error: $e");
//       Get.snackbar(
//         "Error",
//         "An unexpected error occurred. Please try again.",
//         colorText: Colors.white,
//         backgroundColor: Colors.red,
//       );
//     } finally {
//       isUploading.value = false;
//     }
//   }

//   void _showImagePickerDialog() {
//     Get.dialog(
//       AlertDialog(
//         title: const Text("Select Image Source"),
//         content: const Text("Maximum image size: 5MB"),
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

//   void _removeImage() {
//     userController.removeProfileImage();
//     setState(() {
//       currentImageSize.value = null;
//       imageSizeError.value = null;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.secondaryColor,
//       appBar: CustomAppBar(
//         title: "Edit Profile",
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
//                       child: Stack(
//                         children: [
//                           CircleAvatar(
//                             radius: 50,
//                             backgroundColor: AppColors.textColor4,
//                             backgroundImage: _getProfileImage(),
//                             child: _getProfileImage() == null
//                                 ? const Icon(Icons.person, size: 40, color: Colors.white)
//                                 : null,
//                           ),
//                           if (isUploading.value)
//                             Positioned.fill(
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   color: Colors.black54,
//                                   borderRadius: BorderRadius.circular(50),
//                                 ),
//                                 child: const Center(
//                                   child: CircularProgressIndicator(
//                                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
                    
//                     // Image size information and error display
//                     const SizedBox(height: 10),
//                     Obx(() {
//                       if (currentImageSize.value != null) {
//                         return Column(
//                           children: [
//                             Text(
//                               "Image size: ${_formatFileSize(currentImageSize.value!)}",
//                               style: TextStyle(
//                                 color: imageSizeError.value != null 
//                                     ? Colors.red 
//                                     : Colors.green,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                             if (imageSizeError.value != null)
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 4.0),
//                                 child: Text(
//                                   imageSizeError.value!,
//                                   style: const TextStyle(
//                                     color: Colors.red,
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                   textAlign: TextAlign.center,
//                                 ),
//                               ),
//                           ],
//                         );
//                       }
//                       return const SizedBox();
//                     }),
                    
//                     const SizedBox(height: 10),
//                     if (userController.profileImage.value != null ||
//                         userController.profileImageUrl.value.isNotEmpty)
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: imageSizeError.value != null 
//                                   ? Colors.orange 
//                                   : AppColors.mainColor,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                             ),
//                             onPressed: isUploading.value ? null : _showImagePickerDialog,
//                             child: Text(
//                               imageSizeError.value != null ? "Replace" : "Update",
//                               style: const TextStyle(
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.red,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                             ),
//                             onPressed: isUploading.value ? null : _removeImage,
//                             child: const Text(
//                               "Remove",
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ),
//                         ],
//                       ),
//                   ],
//                 );
//               }),
              
//               // Maximum size info
//               const SizedBox(height: 10),
//               const Center(
//                 child: Text(
//                   "Maximum image size: 5MB",
//                   style: TextStyle(
//                     color: Colors.grey,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
              
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
//                 child: Obx(() {
//                   return CustomButton(
//                     text: isUploading.value ? "Updating..." : "Save Changes",
//                     onPressed: isUploading.value ? null : _saveProfile,
//                   );
//                 }),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   ImageProvider? _getProfileImage() {
//     if (userController.profileImage.value != null) {
//       return FileImage(userController.profileImage.value!);
//     } else if (userController.profileImageUrl.value.isNotEmpty) {
//       return NetworkImage(userController.profileImageUrl.value);
//     }
//     return null;
//   }
// }




















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
