import 'dart:async';
import 'dart:convert';
import 'package:fixibot_app/constants/appConfig.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OtpController extends GetxController {
  final otpController = TextEditingController();
  final isLoading = false.obs;
  final canResend = true.obs;
  final cooldownSeconds = 0.obs;

  // final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";
final baseUrl  = AppConfig.baseUrl;

  Timer? _cooldownTimer;

  void showError(String message) {
    Get.snackbar("Error", message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white);
  }

  void showSuccess(String message) {
    Get.snackbar("Success", message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white);
  }

  /// ✅ Verify Email with OTP
  Future<void> verifyEmailWithOtp(String email) async {
    final otp = otpController.text.trim();
    if (otp.isEmpty) {
      showError("Please enter the OTP");
      return;
    }

    isLoading.value = true;
    try {
      final url = Uri.parse("$baseUrl/auth/verify-email");
      // final body = {"email": email, "otp": otp};
      final body = {"email": email, "otp": otpController.text.trim()};
print("Sending OTP $otp for email $email");


      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("Verify API: ${response.statusCode} -> ${response.body}");

      if (response.statusCode == 200) {
        showSuccess("Email verified successfully!");
        Get.offAllNamed("/login"); // update with AppRoutes.login
      } else {
        final error = jsonDecode(response.body);
        showError(error["detail"]?.toString() ?? "Verification failed");
      }
    } catch (e) {
      showError("Unable to connect to server.");
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ Resend OTP
  Future<void> resendOtp(String email) async {
    if (!canResend.value) return; // ⛔ cooldown active

    try {
      final url = Uri.parse("$baseUrl/auth/resend-verification?email=$email");
      final response = await http.post(url);

      print("Resend API: ${response.statusCode} -> ${response.body}");

      if (response.statusCode == 200) {
        showSuccess("OTP resent successfully!");
        _startCooldown();
      } else {
        final error = jsonDecode(response.body);
        showError(error["detail"]?.toString() ?? "Failed to resend OTP");
      }
    } catch (e) {
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
