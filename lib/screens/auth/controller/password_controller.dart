import 'dart:convert';
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
   final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";


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


/////cccc
///

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import '../../../constants/app_colors.dart';

// class ForgotPasswordController extends GetxController {
//   final emailController = TextEditingController();
//   final otpController = TextEditingController();
//   final passwordController = TextEditingController();

//   var isLoading = false.obs;

//   final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev"; // adjust for backend

//   /// Step 1 → Request reset link
//   Future<void> resetPassword() async {
//     final email = emailController.text.trim();
//     if (email.isEmpty) {
//       Get.snackbar("Error", "Please enter your email",
//           backgroundColor: AppColors.minorColor, colorText: Colors.white);
//       return;
//     }

//     try {
//       isLoading.value = true;
//       final url = Uri.parse("$baseUrl/auth/password-reset");
//       final response = await http.post(url, body: {"email": email});

//       if (response.statusCode == 200) {
//         Get.snackbar("Success", "Reset code sent to your email",
//             backgroundColor: Colors.green, colorText: Colors.white);

//         // Navigate to confirm screen
//         Get.toNamed("/password-reset-confirm", arguments: {"email": email});
//       } else {
//         final data = json.decode(response.body);
//         Get.snackbar("Error", data["detail"] ?? "Reset failed",
//             backgroundColor: Colors.red, colorText: Colors.white);
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Something went wrong: $e",
//           backgroundColor: Colors.red, colorText: Colors.white);
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// Step 2 → Confirm reset with OTP
//   Future<void> confirmReset() async {
//     final email = Get.arguments["email"];
//     final otp = otpController.text.trim();
//     final newPassword = passwordController.text.trim();

//     if (otp.isEmpty || newPassword.isEmpty) {
//       Get.snackbar("Error", "OTP and new password are required",
//           backgroundColor: Colors.red, colorText: Colors.white);
//       return;
//     }

//     try {
//       isLoading.value = true;
//       final url = Uri.parse("$baseUrl/auth/password-reset/confirm");
//       final response = await http.post(url, body: {
//         "email": email,
//         "otp": otp,
//         "new_password": newPassword,
//       });

//       if (response.statusCode == 200) {
//         Get.snackbar("Success", "Password reset successful",
//             backgroundColor: Colors.green, colorText: Colors.white);
//         Get.offAllNamed("/login"); // go back to login
//       } else {
//         final data = json.decode(response.body);
//         Get.snackbar("Error", data["detail"] ?? "Reset failed",
//             backgroundColor: Colors.red, colorText: Colors.white);
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Something went wrong: $e",
//           backgroundColor: Colors.red, colorText: Colors.white);
//     } finally {
//       isLoading.value = false;
//     }
//   }
// }
