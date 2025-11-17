
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/widgets.dart';
// import 'package:get/get.dart';
// import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart' show MediaType;
// import 'package:shared_preferences/shared_preferences.dart';

// class UserController extends GetxController {
//    final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";
//   var fullName = "Guest".obs;
//   var email = "".obs;
//   var profileImage = Rx<File?>(null); // local picked file
//   var profileImageUrl = "".obs;       // backend hosted url
  
//   final SharedPrefsHelper _prefs = SharedPrefsHelper();
  
//   // Track if profile was updated successfully
//   var isProfileUpdated = false.obs;
//   var isImageUploaded = false.obs;
//   var lastUpdateError = "".obs;

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
      
//       print('🔄 Loading user data from storage...');
//       print('📝 Name: $savedName, Email: $savedEmail');
//       print('🖼️ Image URL from storage: ${savedImageUrl ?? "None"}');
      
//       if (savedName != null && savedName.isNotEmpty) {
//         fullName.value = savedName;
//         print('✅ Name loaded: $savedName');
//       }
      
//       if (savedEmail != null && savedEmail.isNotEmpty) {
//         email.value = savedEmail;
//         print('✅ Email loaded: $savedEmail');
//       }
      
//       if (savedImageUrl != null && savedImageUrl.isNotEmpty) {
//         profileImageUrl.value = savedImageUrl;
//         print('✅ Profile image URL loaded: $savedImageUrl');
//       } else {
//         print('ℹ️ No profile image found in storage');
//       }
      
//     } catch (e) {
//       print('❌ Error loading user data in UserController: $e');
//     }
//   }

//   void updateUser(String name, String mail) {
//     print('👤 Updating user data: $name, $mail');
//     fullName.value = name;
//     email.value = mail;
//     // Save to SharedPreferences
//     _prefs.saveString("full_name", name);
//     _prefs.saveString("email", mail);
//   }

//   void updateProfileImage(File? image) {
//     profileImage.value = image;
//     // Reset upload status when new image is picked
//     isImageUploaded.value = false;
//     print('📸 Local profile image updated: ${image?.path}');
//   }

//   void updateProfileImageUrl(String url) {
//     print('🖼️ Updating profile image URL: $url');
//     profileImageUrl.value = url;
//     profileImage.value = null; // reset local if server URL available
//     // Save to SharedPreferences for persistence
//     _prefs.saveProfileImageUrl(url);
//     isImageUploaded.value = true;
//     print('✅ Profile image URL updated and saved to SharedPreferences');
    
//     // Verify the save
//     _prefs.getProfileImageUrl().then((savedUrl) {
//       print('🔍 Verification - Current URL in controller: $url');
//       print('🔍 Verification - Saved URL in SharedPreferences: $savedUrl');
//     });
//   }

//   void removeProfileImage() {
//     print('🗑️ Removing profile image');
//     profileImage.value = null;
//     profileImageUrl.value = "";
//     // Remove from SharedPreferences
//     _prefs.saveProfileImageUrl("");
//     isImageUploaded.value = false;
//   }

//   // Mark profile as successfully updated
//   void markProfileUpdated() {
//     isProfileUpdated.value = true;
//     lastUpdateError.value = "";
//     print('✅ Profile marked as updated successfully');
//   }

//   // Mark update as failed
//   void markUpdateFailed(String error) {
//     isProfileUpdated.value = false;
//     lastUpdateError.value = error;
//     print('❌ Profile update failed: $error');
//   }

//   // Mark image as uploaded successfully
//   void markImageUploaded() {
//     isImageUploaded.value = true;
//     print('✅ Image marked as uploaded successfully');
//   }

//   // Clear all user data on logout
//   void clearUserData() {
//     print('🚪 Clearing all user data on logout');
//     fullName.value = "Guest";
//     email.value = "";
//     profileImage.value = null;
//     profileImageUrl.value = "";
//     isProfileUpdated.value = false;
//     isImageUploaded.value = false;
//     lastUpdateError.value = "";
//   }

//   // Check if user has a profile image (either local or URL)
//   bool get hasProfileImage {
//     return profileImage.value != null || profileImageUrl.value.isNotEmpty;
//   }

//   // Get the current display image (priority: local > URL)
//   ImageProvider? get displayImage {
//     if (profileImage.value != null) {
//       return FileImage(profileImage.value!);
//     } else if (profileImageUrl.value.isNotEmpty) {
//       return NetworkImage(profileImageUrl.value);
//     }
//     return null;
//   }

//   // Debug method to check current state
//   void debugState() {
//     print('=== UserController Debug ===');
//     print('Name: ${fullName.value}');
//     print('Email: ${email.value}');
//     print('Local Image: ${profileImage.value?.path ?? "None"}');
//     print('Image URL: ${profileImageUrl.value.isNotEmpty ? profileImageUrl.value : "None"}');
//     print('============================');
//   }

//   // Add this method to your UserController class
// Future<bool> uploadProfileImage(File imageFile) async {
//   try {
//     final prefs = await SharedPreferences.getInstance();
//     final accessToken = prefs.getString('access_token');
//     final userId = prefs.getString('user_id');

//     if (accessToken == null || userId == null) {
//       print('❌ No access token or user ID found');
//       return false;
//     }

//     // Create multipart request
//     var request = http.MultipartRequest(
//       'POST', 
//       Uri.parse('$baseUrl/users/upload-profile-image')
//     );
    
//     request.headers['Authorization'] = 'Bearer $accessToken';
//     request.fields['user_id'] = userId;

//     // Add image file
//     request.files.add(
//       await http.MultipartFile.fromPath(
//         'profile_image',
//         imageFile.path,
//         contentType: MediaType('image', 'jpeg'),
//       ),
//     );

//     // Send request
//     final response = await request.send();
    
//     if (response.statusCode == 200) {
//       final responseBody = await response.stream.bytesToString();
//       final data = json.decode(responseBody);
      
//       if (data['image_url'] != null) {
//         // Update the profile image URL with the backend URL
//         updateProfileImageUrl(data['image_url']);
//         markImageUploaded();
//         print('✅ Profile image uploaded successfully: ${data['image_url']}');
//         return true;
//       }
//     }
    
//     print('❌ Failed to upload profile image: ${response.statusCode}');
//     return false;
    
//   } catch (e) {
//     print('❌ Error uploading profile image: $e');
//     return false;
//   }
// }

// void verifyImagePersistence() async {
//   final savedUrl = await _prefs.getProfileImageUrl();
//   print('🔍 Image Persistence Verification:');
//   print('   - Controller URL: ${profileImageUrl.value}');
//   print('   - SharedPreferences URL: $savedUrl');
//   print('   - Local File: ${profileImage.value?.path ?? "None"}');
// }
// }




















import 'dart:convert';
import 'dart:io';
import 'package:fixibot_app/constants/appConfig.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:shared_preferences/shared_preferences.dart';

class UserController extends GetxController {
  final baseUrl  = AppConfig.baseUrl;
  // final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";
  var fullName = "Guest".obs;
  var email = "".obs;
  var profileImage = Rx<File?>(null); // local picked file
  var profileImageUrl = "".obs;       // backend hosted url
  
  final SharedPrefsHelper _prefs = SharedPrefsHelper();
  
  // Track if profile was updated successfully
  var isProfileUpdated = false.obs;
  var isImageUploaded = false.obs;
  var lastUpdateError = "".obs;


  // Add these to your UserController class
var userId = "".obs; // Add user ID observable

@override
Future<void> onInit() async {
  super.onInit();
  await _loadUserData();
}



// In UserController.dart - Update the _loadUserData method
Future<void> _loadUserData() async {
  try {
    final savedName = await _prefs.getString("full_name");
    final savedEmail = await _prefs.getString("email");
    final savedImageUrl = await _prefs.getProfileImageUrl();
    final savedUserId = await _prefs.getString("user_id");
    
    print('🔄 Loading user data from storage...');
    print('📝 Name: $savedName, Email: $savedEmail');
    print('👤 User ID: $savedUserId');
    print('🖼️ Image URL from storage: ${savedImageUrl ?? "None"}');
    
    if (savedName != null && savedName.isNotEmpty) {
      fullName.value = savedName;
      print('✅ Name loaded: $savedName');
    } else {
      print('ℹ️ No name found in storage, using default: Guest');
    }
    
    if (savedEmail != null && savedEmail.isNotEmpty) {
      email.value = savedEmail;
      print('✅ Email loaded: $savedEmail');
    } else {
      print('ℹ️ No email found in storage');
    }
    
    // CRITICAL FIX: Always load user ID if available
    if (savedUserId != null && savedUserId.isNotEmpty) {
      userId.value = savedUserId;
      print('✅ User ID loaded and set: $savedUserId');
    } else {
      print('ℹ️ No user ID found in storage - will be set on next login');
      userId.value = ""; // Ensure it's empty if not found
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

// Update clearUserData to NOT clear user ID if remember me is enabled
Future<void> clearUserData() async {
  print('🚪 Clearing all user data on logout');
  
  final rememberUser = await _prefs.getRememberUser();
  
  // Only clear chat data if user explicitly wants to logout completely
  if (userId.value.isNotEmpty && !rememberUser) {
    await _prefs.clearUserChatData(userId.value);
    print('🗑️ Cleared chat data for user: ${userId.value}');
  }
  
  fullName.value = "Guest";
  email.value = "";
  profileImage.value = null;
  profileImageUrl.value = "";
  isProfileUpdated.value = false;
  isImageUploaded.value = false;
  lastUpdateError.value = "";
  
  // Clear auth data but preserve user ID if remember me is enabled
  await _prefs.clearAuthData();
  
  if (!rememberUser) {
    userId.value = "";
    await _prefs.saveString("user_id", ""); // Clear user ID
    print('🔓 User ID cleared (remember me disabled)');
  } else {
    print('💾 User ID preserved (remember me enabled)');
  }
  
  print('✅ User data cleared (remember me: $rememberUser)');
}


  /// NEW METHOD: Refresh user data from SharedPreferences
  Future<void> refreshUserData() async {
    print('🔄 Refreshing user data from SharedPreferences...');
    await _loadUserData();
  }

  /// NEW METHOD: Update user data after Google Sign-In
//   Future<void> updateUserFromGoogleSignIn(String name, String userEmail, {String? profileImageUrl}) async {
//   print('👤 Updating user data from Google Sign-In: $name, $userEmail');
  
//   // Update observable variables - use different parameter name to avoid conflict
//   fullName.value = name.isNotEmpty ? name : "Google User";
//   email.value = userEmail; // Changed parameter name to userEmail
  
//   if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
//     this.profileImageUrl.value = profileImageUrl;
//     print('🖼️ Google profile image URL set: $profileImageUrl');
//   }
  
//   // Save to SharedPreferences
//   await _prefs.saveUserBasicInfo(name, userEmail); // Use userEmail here too
//   if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
//     await _prefs.saveProfileImageUrl(profileImageUrl);
//   }
  
//   // Set remember user preference
//   await _prefs.setRememberUser(true);
  
//   print('✅ User data updated from Google Sign-In');
//   debugState();
// }


/// NEW METHOD: Update user data after Google Sign-In - ENHANCED
Future<void> updateUserFromGoogleSignIn(String name, String userEmail, {String? profileImageUrl, String? userId}) async {
  print('👤 Updating user data from Google Sign-In: $name, $userEmail');
  
  // Update observable variables
  fullName.value = name.isNotEmpty ? name : "Google User";
  email.value = userEmail;
  
  if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
    this.profileImageUrl.value = profileImageUrl;
    print('🖼️ Google profile image URL set: $profileImageUrl');
  }
  
  // Save to SharedPreferences
  await _prefs.saveUserBasicInfo(name, userEmail);
  
  // ✅ NEW: Save user ID if provided
  if (userId != null && userId.isNotEmpty) {
    await _prefs.saveUserId(userId);
    print('✅ User ID saved from Google Sign-In: $userId');
  }
  
  if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
    await _prefs.saveProfileImageUrl(profileImageUrl);
  }
  
  // Set remember user preference
  await _prefs.setRememberUser(true);
  
  print('✅ User data updated from Google Sign-In');
  debugState();
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
// Add this method to UserController
Future<String?> getUserId() async {
  return await _prefs.getUserId();
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

  // Check if user is logged in (not guest)
  bool get isLoggedIn {
    return fullName.value != "Guest" && email.value.isNotEmpty;
  }

  // Debug method to check current state
  void debugState() {
    print('=== UserController Debug ===');
    print('Name: ${fullName.value}');
    print('Email: ${email.value}');
    print('Local Image: ${profileImage.value?.path ?? "None"}');
    print('Image URL: ${profileImageUrl.value.isNotEmpty ? profileImageUrl.value : "None"}');
    print('Is Logged In: $isLoggedIn');
    print('============================');
  }

  Future<bool> uploadProfileImage(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final userId = prefs.getString('user_id');

      if (accessToken == null || userId == null) {
        print('❌ No access token or user ID found');
        return false;
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/users/upload-profile-image')
      );
      
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.fields['user_id'] = userId;

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // Send request
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);
        
        if (data['image_url'] != null) {
          // Update the profile image URL with the backend URL
          updateProfileImageUrl(data['image_url']);
          markImageUploaded();
          print('✅ Profile image uploaded successfully: ${data['image_url']}');
          return true;
        }
      }
      
      print('❌ Failed to upload profile image: ${response.statusCode}');
      return false;
      
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      return false;
    }
  }
  // Add this method to your UserController class
void setUserId(String id) {
  userId.value = id;
  _prefs.saveString("user_id", id);
  print('✅ User ID set in controller: $id');
}

  void verifyImagePersistence() async {
    final savedUrl = await _prefs.getProfileImageUrl();
    print('🔍 Image Persistence Verification:');
    print('   - Controller URL: ${profileImageUrl.value}');
    print('   - SharedPreferences URL: $savedUrl');
    print('   - Local File: ${profileImage.value?.path ?? "None"}');
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










