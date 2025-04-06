import 'package:fixibot_app/constants/app_colors.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ForgotPasswordController extends GetxController {
  var emailController = TextEditingController();
  var isLoading = false.obs;

  void resetPassword() async {
    if (emailController.text.isEmpty) {
      Get.snackbar("Error", "Please enter your email",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    isLoading.value = true;

    await Future.delayed(Duration(seconds: 2));

    isLoading.value = false;
    Get.snackbar("Success", "Password reset link sent to your email",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.mainColor,
        colorText: Colors.white);
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
