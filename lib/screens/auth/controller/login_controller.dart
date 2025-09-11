import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../routes/app_routes.dart';
import 'shared_pref_helper.dart';

class LoginController extends GetxController {
  final SharedPrefsHelper _sharedPrefs = SharedPrefsHelper();

  // Text controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // State
  final isPasswordVisible = false.obs;
  final isLoading = false.obs;
  final savePassword = false.obs;

  // API Base URL
  final String baseUrl = "http://127.0.0.1:8000";

  void togglePasswordVisibility() =>
      isPasswordVisible.value = !isPasswordVisible.value;
  void toggleSavePassword() => savePassword.value = !savePassword.value;

  /// ================== LOGIN ==================
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Email and password are required");
      return;
    }

    isLoading.value = true;
    try {
      final url = Uri.parse("$baseUrl/auth/token");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "username": email,
          "password": password,
        },
      );

      print("Login API response: ${response.statusCode} -> ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final accessToken = data["access_token"];
        final tokenType = data["token_type"];

        // Save token + email
        await _sharedPrefs.saveString("access_token", accessToken);
        await _sharedPrefs.saveString("token_type", tokenType);
        await _sharedPrefs.saveString("email", email);

        // 🔹 Fetch current user profile
        await _fetchUserProfile(accessToken, tokenType);

        _showSuccess("Login successful!");

        // Navigate to dashboard/home
        Get.offAllNamed(AppRoutes.home);
      } else {
        final error = jsonDecode(response.body);
        _showError(error["detail"]?.toString() ?? "Login failed");
      }
    } catch (e) {
      print("Login exception: $e");
      _showError("Unable to connect to server. Check your network.");
    } finally {
      isLoading.value = false;
    }
  }

Future<void> _fetchUserProfile(String accessToken, String tokenType) async {
  try {
    final url = Uri.parse("$baseUrl/auth/users/me");
    final response = await http.get(
      url,
      headers: {
        "Authorization": "$tokenType $accessToken",
        "Content-Type": "application/json",
      },
    );

    print("Profile API response: ${response.statusCode} -> ${response.body}");

    if (response.statusCode == 200) {
      final user = jsonDecode(response.body);

      final firstName = user["first_name"] ?? "";
      final lastName = user["last_name"] ?? "";
      final fullName = "$firstName $lastName".trim().isEmpty
          ? user["email"] // fallback if name is missing
          : "$firstName $lastName".trim();

      await _sharedPrefs.saveString("user_id", user["_id"] ?? "");
      await _sharedPrefs.saveString("first_name", firstName);
      await _sharedPrefs.saveString("last_name", lastName);
      await _sharedPrefs.saveString("phone_number", user["phone_number"] ?? "");
      await _sharedPrefs.saveString("full_name", fullName);
      print("Saving user_id: ${user["_id"]}");

      print("✅ Saved user full_name: $fullName");
      
    } else {
      print("❌ Failed to fetch profile: ${response.body}");
    }
  } catch (e) {
    print("Profile fetch exception: $e");
  }
  
}

  void _showError(String message) {
    Get.snackbar(
      "Error",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      "Success",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
