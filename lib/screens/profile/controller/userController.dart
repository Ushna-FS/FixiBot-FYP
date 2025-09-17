// import 'package:get/get.dart';

// class UserController extends GetxController {
//   var fullName = "Guest".obs;
//   var email = "".obs;

//   void updateUser(String name, String mail) {
//     fullName.value = name;
//     email.value = mail;
//   }
// }

import 'dart:io';
import 'package:get/get.dart';

class UserController extends GetxController {
  var fullName = "Guest".obs;
  var email = "".obs;
  var profileImage = Rx<File?>(null); // local picked file
  var profileImageUrl = "".obs;       // backend hosted url (optional)

  void updateUser(String name, String mail) {
    fullName.value = name;
    email.value = mail;
  }

  void updateProfileImage(File? image) {
    profileImage.value = image;
    profileImageUrl.value = ""; // reset url if local picked
  }

  void updateProfileImageUrl(String url) {
    profileImageUrl.value = url;
    profileImage.value = null; // reset local if server URL available
  }

  void removeProfileImage() {
    profileImage.value = null;
    profileImageUrl.value = "";
  }
}
