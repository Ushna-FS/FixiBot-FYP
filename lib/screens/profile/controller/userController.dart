
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';

class UserController extends GetxController {
  var fullName = "Guest".obs;
  var email = "".obs;
  var profileImage = Rx<File?>(null); // local picked file
  var profileImageUrl = "".obs;       // backend hosted url
  
  final SharedPrefsHelper _prefs = SharedPrefsHelper();
  
  // Track if profile was updated successfully
  var isProfileUpdated = false.obs;
  var isImageUploaded = false.obs;
  var lastUpdateError = "".obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  // Load user data from SharedPreferences on app start
  Future<void> _loadUserData() async {
    try {
      final savedName = await _prefs.getString("full_name");
      final savedEmail = await _prefs.getString("email");
      final savedImageUrl = await _prefs.getProfileImageUrl();
      
      print('🔄 Loading user data from storage...');
      print('📝 Name: $savedName, Email: $savedEmail');
      print('🖼️ Image URL from storage: ${savedImageUrl ?? "None"}');
      
      if (savedName != null && savedName.isNotEmpty) {
        fullName.value = savedName;
        print('✅ Name loaded: $savedName');
      }
      
      if (savedEmail != null && savedEmail.isNotEmpty) {
        email.value = savedEmail;
        print('✅ Email loaded: $savedEmail');
      }
      
      if (savedImageUrl != null && savedImageUrl.isNotEmpty) {
        profileImageUrl.value = savedImageUrl;
        print('✅ Profile image URL loaded: $savedImageUrl');
      } else {
        print('ℹ️ No profile image found in storage');
      }
      
    } catch (e) {
      print('❌ Error loading user data in UserController: $e');
    }
  }

  void updateUser(String name, String mail) {
    print('👤 Updating user data: $name, $mail');
    fullName.value = name;
    email.value = mail;
    // Save to SharedPreferences
    _prefs.saveString("full_name", name);
    _prefs.saveString("email", mail);
  }

  void updateProfileImage(File? image) {
    profileImage.value = image;
    // Reset upload status when new image is picked
    isImageUploaded.value = false;
    print('📸 Local profile image updated: ${image?.path}');
  }

  void updateProfileImageUrl(String url) {
    print('🖼️ Updating profile image URL: $url');
    profileImageUrl.value = url;
    profileImage.value = null; // reset local if server URL available
    // Save to SharedPreferences for persistence
    _prefs.saveProfileImageUrl(url);
    isImageUploaded.value = true;
    print('✅ Profile image URL updated and saved to SharedPreferences');
    
    // Verify the save
    _prefs.getProfileImageUrl().then((savedUrl) {
      print('🔍 Verification - Current URL in controller: $url');
      print('🔍 Verification - Saved URL in SharedPreferences: $savedUrl');
    });
  }

  void removeProfileImage() {
    print('🗑️ Removing profile image');
    profileImage.value = null;
    profileImageUrl.value = "";
    // Remove from SharedPreferences
    _prefs.saveProfileImageUrl("");
    isImageUploaded.value = false;
  }

  // Mark profile as successfully updated
  void markProfileUpdated() {
    isProfileUpdated.value = true;
    lastUpdateError.value = "";
    print('✅ Profile marked as updated successfully');
  }

  // Mark update as failed
  void markUpdateFailed(String error) {
    isProfileUpdated.value = false;
    lastUpdateError.value = error;
    print('❌ Profile update failed: $error');
  }

  // Mark image as uploaded successfully
  void markImageUploaded() {
    isImageUploaded.value = true;
    print('✅ Image marked as uploaded successfully');
  }

  // Clear all user data on logout
  void clearUserData() {
    print('🚪 Clearing all user data on logout');
    fullName.value = "Guest";
    email.value = "";
    profileImage.value = null;
    profileImageUrl.value = "";
    isProfileUpdated.value = false;
    isImageUploaded.value = false;
    lastUpdateError.value = "";
  }

  // Check if user has a profile image (either local or URL)
  bool get hasProfileImage {
    return profileImage.value != null || profileImageUrl.value.isNotEmpty;
  }

  // Get the current display image (priority: local > URL)
  ImageProvider? get displayImage {
    if (profileImage.value != null) {
      return FileImage(profileImage.value!);
    } else if (profileImageUrl.value.isNotEmpty) {
      return NetworkImage(profileImageUrl.value);
    }
    return null;
  }

  // Debug method to check current state
  void debugState() {
    print('=== UserController Debug ===');
    print('Name: ${fullName.value}');
    print('Email: ${email.value}');
    print('Local Image: ${profileImage.value?.path ?? "None"}');
    print('Image URL: ${profileImageUrl.value.isNotEmpty ? profileImageUrl.value : "None"}');
    print('============================');
  }
}


















//Simplest
// import 'dart:io';
// import 'package:get/get.dart';
// import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';

// class UserController extends GetxController {
//   var fullName = "Guest".obs;
//   var email = "".obs;
//   var profileImage = Rx<File?>(null); // local picked file
//   var profileImageUrl = "".obs;       // backend hosted url (optional)
  
//   final SharedPrefsHelper _prefs = SharedPrefsHelper();

//   @override
//   void onInit() {
//     super.onInit();
//     _loadUserData();
//   }

//   // Load user data from SharedPreferences on app start
//   Future<void> _loadUserData() async {
//     try {
//       final savedName = await _prefs.getString("full_name");
//       final savedEmail = await _prefs.getString("email");
//       final savedImageUrl = await _prefs.getProfileImageUrl();
      
//       if (savedName != null) fullName.value = savedName;
//       if (savedEmail != null) email.value = savedEmail;
//       if (savedImageUrl != null && savedImageUrl.isNotEmpty) {
//         profileImageUrl.value = savedImageUrl;
//       }
      
//       print('👤 UserController loaded: $savedName, $savedEmail');
//     } catch (e) {
//       print('Error loading user data in UserController: $e');
//     }
//   }

//   void updateUser(String name, String mail) {
//     fullName.value = name;
//     email.value = mail;
//     // Save to SharedPreferences
//     _prefs.saveString("full_name", name);
//     _prefs.saveString("email", mail);
//   }

//   void updateProfileImage(File? image) {
//     profileImage.value = image;
//     profileImageUrl.value = ""; // reset url if local picked
//   }

//   void updateProfileImageUrl(String url) {
//     profileImageUrl.value = url;
//     profileImage.value = null; // reset local if server URL available
//     // Save to SharedPreferences
//     _prefs.saveProfileImageUrl(url);
//   }

//   void removeProfileImage() {
//     profileImage.value = null;
//     profileImageUrl.value = "";
//     // Remove from SharedPreferences
//     _prefs.saveProfileImageUrl("");
//   }

//   // Clear all user data on logout
//   void clearUserData() {
//     fullName.value = "Guest";
//     email.value = "";
//     profileImage.value = null;
//     profileImageUrl.value = "";
//   }
// }










