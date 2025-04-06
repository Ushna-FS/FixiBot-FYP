import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../mechanics/view/mechanicsScreen.dart';
import '../view/signup.dart';

class LoginController extends GetxController {
  var usernameController = TextEditingController();
  var emailController = TextEditingController();
  var passwordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar("Error", "Please fill in all fields",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }
  }

  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void LogInNavigation() {
    Get.to(SignupScreen());
  }

  void googleLogIn() {
    // Simulate Google Sign In
    // Get.to(LoginPage());
    Get.to(MechanicScreen());
  }
}
