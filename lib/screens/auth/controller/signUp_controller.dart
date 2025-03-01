import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../view/login.dart';

class SignupController extends GetxController {
  var usernameController = TextEditingController();
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var confirmPasswordController = TextEditingController();
  var phoneController = TextEditingController();
  
  var isPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;
  var savePassword = false.obs;

  void toggleSavePassword() {
    savePassword.value = !savePassword.value;
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  void signup() {
    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar("Error", "Passwords do not match!",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    Get.to(Login());
  }
  void signInNavigation() {
    Get.to(Login());
  }
  void googleSignIn() {
    // Simulate Google Sign In
    // Get.to(LoginPage());
  }

}
