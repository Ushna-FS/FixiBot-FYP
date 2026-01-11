import 'dart:async';
import 'dart:convert';
import 'package:fixibot_app/constants/appConfig.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OtpController extends GetxController {
  final otpController = TextEditingController();
  final isLoading = false.obs;
  final canResend = true.obs;
  final cooldownSeconds = 0.obs;
  final isVerified = false.obs; // 🔥 NEW: Track verification state

  final baseUrl = AppConfig.baseUrl;

  Timer? _cooldownTimer;

  void showError(String message) {
    Get.snackbar("Error", message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3));
  }

  void showSuccess(String message) {
    Get.snackbar("Success", message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 3));
  }

  /// ✅ Verify Email with OTP
  Future<void> verifyEmailWithOtp(String email) async {
    // 🔥 FIX: Prevent multiple verification attempts
    if (isLoading.value || isVerified.value) {
      return;
    }
    
    final otp = otpController.text.trim();
    if (otp.isEmpty) {
      showError("Please enter the OTP");
      return;
    }
    
    if (otp.length != 6) {
      showError("OTP must be 6 digits");
      return;
    }

    isLoading.value = true;
    try {
      final url = Uri.parse("$baseUrl/auth/verify-email");
      final body = {"email": email, "otp": otp};
      
      print("🔐 Verifying OTP: $otp for email: $email");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ).timeout(Duration(seconds: 30));

      print("📡 Verify API Response: ${response.statusCode} -> ${response.body}");

      if (response.statusCode == 200) {
        isVerified.value = true;
        showSuccess("Email verified successfully!");
        
        // ✅ MARK: This is a fresh signup - user will see journey after login
        await _markAsFreshSignup();
        
        // 🔥 Clear OTP controller to prevent reuse
        otpController.clear();
        
        // Navigate to login after a short delay
        await Future.delayed(Duration(milliseconds: 1500));
        Get.offAllNamed("/login");
        
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        final error = jsonDecode(response.body);
        final errorMessage = error["detail"]?.toString() ?? 
                            error["message"]?.toString() ?? 
                            "Invalid OTP. Please check and try again.";
        showError(errorMessage);
        
      } else if (response.statusCode == 410) {
        // OTP expired
        showError("OTP has expired. Please request a new one.");
        
      } else if (response.statusCode == 409) {
        // Email already verified
        showError("This email is already verified. Please login.");
        await Future.delayed(Duration(milliseconds: 1500));
        Get.offAllNamed("/login");
        
      } else {
        final error = jsonDecode(response.body);
        showError(error["detail"]?.toString() ?? "Verification failed");
      }
    } on TimeoutException {
      showError("Request timed out. Please check your connection.");
    } catch (e) {
      print("❌ Verification error: $e");
      showError("Unable to connect to server. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  /// Mark that this is a fresh signup (user just verified OTP)
  Future<void> _markAsFreshSignup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_fresh_signup', true);
      print('✅ Marked as fresh signup - user will see journey screens');
    } catch (e) {
      print('❌ Error marking fresh signup: $e');
    }
  }

  /// ✅ Resend OTP
  Future<void> resendOtp(String email) async {
    if (!canResend.value) return; // ⛔ cooldown active

    try {
      // Clear current OTP when requesting new one
      otpController.clear();
      isVerified.value = false;
      
      final url = Uri.parse("$baseUrl/auth/resend-verification?email=$email");
      final response = await http.post(url).timeout(Duration(seconds: 30));

      print("📡 Resend API: ${response.statusCode} -> ${response.body}");

      if (response.statusCode == 200) {
        showSuccess("New OTP sent successfully!");
        _startCooldown();
      } else if (response.statusCode == 409) {
        showError("Email is already verified. Please login.");
      } else {
        final error = jsonDecode(response.body);
        showError(error["detail"]?.toString() ?? "Failed to resend OTP");
      }
    } on TimeoutException {
      showError("Request timed out. Please check your connection.");
    } catch (e) {
      print("❌ Resend error: $e");
      showError("Unable to connect to server.");
    }
  }

  /// cooldown timer
  void _startCooldown() {
    canResend.value = false;
    cooldownSeconds.value = 30; // ⏳ 30 seconds

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (cooldownSeconds.value > 0) {
        cooldownSeconds.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }

  @override
  void onClose() {
    otpController.dispose();
    _cooldownTimer?.cancel();
    super.onClose();
  }
}






// import 'dart:async';
// import 'dart:convert';
// import 'package:fixibot_app/constants/appConfig.dart';
// import 'package:get/get.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class OtpController extends GetxController {
//   final otpController = TextEditingController();
//   final isLoading = false.obs;
//   final canResend = true.obs;
//   final cooldownSeconds = 0.obs;

//   // final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";
// final baseUrl  = AppConfig.baseUrl;

//   Timer? _cooldownTimer;

//   void showError(String message) {
//     Get.snackbar("Error", message,
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white);
//   }

//   void showSuccess(String message) {
//     Get.snackbar("Success", message,
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.green,
//         colorText: Colors.white);
//   }

// /// ✅ Verify Email with OTP
// Future<void> verifyEmailWithOtp(String email) async {
//   final otp = otpController.text.trim();
//   if (otp.isEmpty) {
//     showError("Please enter the OTP");
//     return;
//   }

//   isLoading.value = true;
//   try {
//     final url = Uri.parse("$baseUrl/auth/verify-email");
//     final body = {"email": email, "otp": otpController.text.trim()};
//     print("Sending OTP $otp for email $email");

//     final response = await http.post(
//       url,
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode(body),
//     );

//     print("Verify API: ${response.statusCode} -> ${response.body}");

//     if (response.statusCode == 200) {
//       showSuccess("Email verified successfully!");
      
//       // ✅ MARK: This is a fresh signup - user will see journey after login
//       await _markAsFreshSignup();
      
//       Get.offAllNamed("/login"); // Update with AppRoutes.login
//     } else {
//       final error = jsonDecode(response.body);
//       showError(error["detail"]?.toString() ?? "Verification failed");
//     }
//   } catch (e) {
//     showError("Unable to connect to server.");
//   } finally {
//     isLoading.value = false;
//   }
// }

// /// Mark that this is a fresh signup (user just verified OTP)
// Future<void> _markAsFreshSignup() async {
//   try {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('is_fresh_signup', true);
//     print('✅ Marked as fresh signup - user will see journey screens');
//   } catch (e) {
//     print('❌ Error marking fresh signup: $e');
//   }
// }



// //   /// ✅ Verify Email with OTP
// //   Future<void> verifyEmailWithOtp(String email) async {
// //     final otp = otpController.text.trim();
// //     if (otp.isEmpty) {
// //       showError("Please enter the OTP");
// //       return;
// //     }

// //     isLoading.value = true;
// //     try {
// //       final url = Uri.parse("$baseUrl/auth/verify-email");
// //       // final body = {"email": email, "otp": otp};
// //       final body = {"email": email, "otp": otpController.text.trim()};
// // print("Sending OTP $otp for email $email");


// //       final response = await http.post(
// //         url,
// //         headers: {"Content-Type": "application/json"},
// //         body: jsonEncode(body),
// //       );

// //       print("Verify API: ${response.statusCode} -> ${response.body}");

// //       if (response.statusCode == 200) {
// //         showSuccess("Email verified successfully!");
        
// //         Get.offAllNamed("/login"); // update with AppRoutes.login
// //       } else {
// //         final error = jsonDecode(response.body);
// //         showError(error["detail"]?.toString() ?? "Verification failed");
// //       }
// //     } catch (e) {
// //       showError("Unable to connect to server.");
// //     } finally {
// //       isLoading.value = false;
// //     }
// //   }

//   /// ✅ Resend OTP
//   Future<void> resendOtp(String email) async {
//     if (!canResend.value) return; // ⛔ cooldown active

//     try {
//       final url = Uri.parse("$baseUrl/auth/resend-verification?email=$email");
//       final response = await http.post(url);

//       print("Resend API: ${response.statusCode} -> ${response.body}");

//       if (response.statusCode == 200) {
//         showSuccess("OTP resent successfully!");
//         _startCooldown();
//       } else {
//         final error = jsonDecode(response.body);
//         showError(error["detail"]?.toString() ?? "Failed to resend OTP");
//       }
//     } catch (e) {
//       showError("Unable to connect to server.");
//     }
//   }

//   /// cooldown timer
//   void _startCooldown() {
//     canResend.value = false;
//     cooldownSeconds.value = 30; // ⏳ 30 seconds

//     _cooldownTimer?.cancel();
//     _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (cooldownSeconds.value > 0) {
//         cooldownSeconds.value--;
//       } else {
//         canResend.value = true;
//         timer.cancel();
//       }
//     });
//   }

//   @override
//   void onClose() {
//     otpController.dispose();
//     _cooldownTimer?.cancel();
//     super.onClose();
//   }
// }
