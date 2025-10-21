import 'dart:io';
import 'package:get/get.dart';
import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';

class UserController extends GetxController {
  var fullName = "Guest".obs;
  var email = "".obs;
  var profileImage = Rx<File?>(null); // local picked file
  var profileImageUrl = "".obs;       // backend hosted url (optional)
  
  final SharedPrefsHelper _prefs = SharedPrefsHelper();

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
      
      if (savedName != null) fullName.value = savedName;
      if (savedEmail != null) email.value = savedEmail;
      if (savedImageUrl != null && savedImageUrl.isNotEmpty) {
        profileImageUrl.value = savedImageUrl;
      }
      
      print('👤 UserController loaded: $savedName, $savedEmail');
    } catch (e) {
      print('Error loading user data in UserController: $e');
    }
  }

  void updateUser(String name, String mail) {
    fullName.value = name;
    email.value = mail;
    // Save to SharedPreferences
    _prefs.saveString("full_name", name);
    _prefs.saveString("email", mail);
  }

  void updateProfileImage(File? image) {
    profileImage.value = image;
    profileImageUrl.value = ""; // reset url if local picked
  }

  void updateProfileImageUrl(String url) {
    profileImageUrl.value = url;
    profileImage.value = null; // reset local if server URL available
    // Save to SharedPreferences
    _prefs.saveProfileImageUrl(url);
  }

  void removeProfileImage() {
    profileImage.value = null;
    profileImageUrl.value = "";
    // Remove from SharedPreferences
    _prefs.saveProfileImageUrl("");
  }

  // Clear all user data on logout
  void clearUserData() {
    fullName.value = "Guest";
    email.value = "";
    profileImage.value = null;
    profileImageUrl.value = "";
  }
}









//try
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
//   void _loadUserData() async {
//     final userData = await _prefs.getUserData();
//     if (userData != null) {
//       fullName.value = userData['name'] ?? "Guest";
//       email.value = userData['email'] ?? "";
//       profileImageUrl.value = userData['photoUrl'] ?? "";
//     }
    
//     // Also load individual values as backup
//     final savedName = await _prefs.getString("full_name");
//     final savedEmail = await _prefs.getString("email");
//     final savedImageUrl = await _prefs.getProfileImageUrl();
    
//     if (savedName != null) fullName.value = savedName;
//     if (savedEmail != null) email.value = savedEmail;
//     if (savedImageUrl != null) profileImageUrl.value = savedImageUrl;
//   }

//   void updateUser(String name, String mail) {
//     fullName.value = name;
//     email.value = mail;
//     // Save to SharedPreferences
//     _prefs.saveString("full_name", name);
//     _prefs.saveString("email", mail);
//     _prefs.saveUserDataWithImage(name, mail, profileImageUrl.value);
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
//     _prefs.saveUserDataWithImage(fullName.value, email.value, url);
//   }

//   void removeProfileImage() {
//     profileImage.value = null;
//     profileImageUrl.value = "";
//     // Remove from SharedPreferences
//     _prefs.saveProfileImageUrl("");
//     _prefs.saveUserDataWithImage(fullName.value, email.value, "");
//   }

//   // Clear all user data on logout
//   void clearUserData() {
//     fullName.value = "Guest";
//     email.value = "";
//     profileImage.value = null;
//     profileImageUrl.value = "";
//   }
// }








// perf
// import 'dart:io';
// import 'package:get/get.dart';

// class UserController extends GetxController {
//   var fullName = "Guest".obs;
//   var email = "".obs;
//   var profileImage = Rx<File?>(null); // local picked file
//   var profileImageUrl = "".obs;       // backend hosted url (optional)

//   void updateUser(String name, String mail) {
//     fullName.value = name;
//     email.value = mail;
//   }

//   void updateProfileImage(File? image) {
//     profileImage.value = image;
//     profileImageUrl.value = ""; // reset url if local picked
//   }

//   void updateProfileImageUrl(String url) {
//     profileImageUrl.value = url;
//     profileImage.value = null; // reset local if server URL available
//   }

//   void removeProfileImage() {
//     profileImage.value = null;
//     profileImageUrl.value = "";
//   }
// }
