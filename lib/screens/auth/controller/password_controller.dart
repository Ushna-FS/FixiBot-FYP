import 'dart:convert';
import 'package:fixibot_app/constants/appConfig.dart';
import 'package:fixibot_app/screens/auth/view/confirm_forgetPassword.dart' show ConfirmResetScreen;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../constants/app_colors.dart';

class ForgotPasswordController extends GetxController {
  var emailController = TextEditingController();
  var otpController = TextEditingController();
  var newPasswordController = TextEditingController();

  var isLoading = false.obs;
  //  final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";
  final baseUrl  = AppConfig.baseUrl;


  /// 🔹 Extract error message properly
  String _extractErrorMessage(dynamic data) {
    if (data is Map && data["detail"] != null) {
      final detail = data["detail"];

      if (detail is String) {
        return detail; // plain string
      } else if (detail is List && detail.isNotEmpty && detail[0]["msg"] != null) {
        return detail[0]["msg"]; // take msg from first error
      }
    }
    return "Something went wrong. Please try again.";
  }

  /// 🔹 Step 1: Request password reset link
  Future<void> resetPassword() async {
    if (emailController.text.isEmpty) {
      Get.snackbar("Error", "Please enter your email",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    try {
      isLoading.value = true;
      final url = Uri.parse("$baseUrl/auth/password-reset?email=${emailController.text.trim()}");

      final response = await http.post(url);

      isLoading.value = false;
      if (response.statusCode == 200) {
  Get.snackbar("Success", "Password reset link sent to your email",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.mainColor,
      colorText: Colors.white);

  // 🔹 Navigate to ConfirmResetScreen after success
  Future.delayed(const Duration(seconds: 1), () {
    Get.to(() => ConfirmResetScreen());
  });
}

      else {
        final data = json.decode(response.body);
        final errorMsg = _extractErrorMessage(data);
        Get.snackbar("Error", errorMsg,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Something went wrong: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  /// 🔹 Step 2: Confirm password reset with OTP
Future<void> confirmReset() async {
  if (emailController.text.isEmpty ||
      otpController.text.isEmpty ||
      newPasswordController.text.isEmpty) {
    Get.snackbar("Error", "All fields are required",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white);
    return;
  }

  try {
    isLoading.value = true;

    final url = Uri.parse(
      "$baseUrl/auth/password-reset/confirm"
      "?email=${emailController.text.trim()}"
      "&otp=${otpController.text.trim()}"
      "&new_password=${newPasswordController.text.trim()}"
    );

    print("Sending to: $url");

    final response = await http.post(url);

    isLoading.value = false;

    if (response.statusCode == 200) {
      Get.snackbar("Success", "Password has been reset successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.mainColor,
          colorText: Colors.white);
      Get.offAllNamed("/login"); // redirect to login
    } else {
      final data = json.decode(response.body);
      final errorMsg = _extractErrorMessage(data);
      Get.snackbar("Error", errorMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  } catch (e) {
    isLoading.value = false;
    Get.snackbar("Error", "Something went wrong: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white);
  }
}

  @override
  void onClose() {
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    super.onClose();
  }
}
