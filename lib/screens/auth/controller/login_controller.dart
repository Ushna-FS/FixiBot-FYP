import 'dart:convert';
import 'package:fixibot_app/constants/appConfig.dart';
import 'package:fixibot_app/screens/chatbot/provider/chatManagerProvider.dart';
import 'package:fixibot_app/screens/profile/controller/userController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  final savePassword = true.obs;

  // API Base URL
  final baseUrl = AppConfig.baseUrl;

  void togglePasswordVisibility() => isPasswordVisible.value = !isPasswordVisible.value;
  void toggleSavePassword() => savePassword.value = !savePassword.value;

  @override
  void onInit() {
    super.onInit();
    _loadSavedCredentials();
  }

  /// Load saved email/password if "Remember Me" was enabled
  Future<void> _loadSavedCredentials() async {
    try {
      final rememberMe = await _sharedPrefs.rememberUser();
      if (rememberMe) {
        final savedEmail = await _sharedPrefs.getString("email");
        if (savedEmail != null && savedEmail.isNotEmpty) {
          emailController.text = savedEmail;
          print('📧 Loaded saved email: $savedEmail');
        }
      }
    } catch (e) {
      print('Error loading saved credentials: $e');
    }
  }

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

      // 🚨 Clear old authentication data
      await _sharedPrefs.clearAuthData();

      // Save token + email
      await _sharedPrefs.saveString("access_token", accessToken);
      await _sharedPrefs.saveString("token_type", tokenType);
      await _sharedPrefs.saveString("email", email);

      // 🔹 Save "Remember Me" preference
      await _sharedPrefs.setRememberUser(savePassword.value);
      
      // 🔹 Save login timestamp and token expiry (30 days)
      if (savePassword.value) {
        await _sharedPrefs.saveLoginTimestamp();
        await _sharedPrefs.saveTokenExpiry();
        print('✅ User will stay logged in for 30 days');
      }

      // 🔹 Fetch current user profile
      await _fetchUserProfile(accessToken, tokenType);

      _showSuccess("Login successful!");
      
      // ✅ CHECK: Is this a new user who just completed signup?
      final bool isNewUser = await _checkIfNewUser();
      
      if (isNewUser) {
        // New user after signup → Show User Journey
        Get.offAllNamed(AppRoutes.userJourney);
        // Mark that user has seen the journey
        await _markUserJourneySeen();
      } else {
        // Returning user → Go directly to Home
        Get.offAllNamed(AppRoutes.home);
      }
      
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

/// Check if this is a new user who just completed signup
Future<bool> _checkIfNewUser() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if user has completed the journey before
    final hasSeenJourney = prefs.getBool('has_seen_user_journey') ?? false;
    
    // Check if this is a fresh signup (user just verified OTP)
    final isFreshSignup = prefs.getBool('is_fresh_signup') ?? false;
    
    print('🔍 New User Check:');
    print('   - Has seen journey: $hasSeenJourney');
    print('   - Is fresh signup: $isFreshSignup');
    
    // Show journey only if it's a fresh signup AND user hasn't seen it before
    return isFreshSignup && !hasSeenJourney;
  } catch (e) {
    print('❌ Error checking new user status: $e');
    return false; // Default to returning user on error
  }
}

/// Mark that user has seen the user journey
Future<void> _markUserJourneySeen() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_user_journey', true);
    // Clear the fresh signup flag
    await prefs.setBool('is_fresh_signup', false);
    print('✅ User journey marked as seen');
  } catch (e) {
    print('❌ Error marking user journey: $e');
  }
}


  // /// ================== LOGIN ==================
  // Future<void> login() async {
  //   final email = emailController.text.trim();
  //   final password = passwordController.text.trim();

  //   if (email.isEmpty || password.isEmpty) {
  //     _showError("Email and password are required");
  //     return;
  //   }

  //   isLoading.value = true;
  //   try {
  //     final url = Uri.parse("$baseUrl/auth/token");

  //     final response = await http.post(
  //       url,
  //       headers: {"Content-Type": "application/x-www-form-urlencoded"},
  //       body: {
  //         "username": email,
  //         "password": password,
  //       },
  //     );

  //     print("Login API response: ${response.statusCode} -> ${response.body}");

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);

  //       final accessToken = data["access_token"];
  //       final tokenType = data["token_type"];

  //       // 🚨 Clear old authentication data
  //       await _sharedPrefs.clearAuthData();

  //       // Save token + email
  //       await _sharedPrefs.saveString("access_token", accessToken);
  //       await _sharedPrefs.saveString("token_type", tokenType);
  //       await _sharedPrefs.saveString("email", email);

  //       // 🔹 Save "Remember Me" preference
  //       await _sharedPrefs.setRememberUser(savePassword.value);
        
  //       // 🔹 Save login timestamp and token expiry (30 days)
  //       if (savePassword.value) {
  //         await _sharedPrefs.saveLoginTimestamp();
  //         await _sharedPrefs.saveTokenExpiry();
  //         print('✅ User will stay logged in for 30 days');
  //       }

  //       // 🔹 Fetch current user profile
  //       await _fetchUserProfile(accessToken, tokenType);

  //       _showSuccess("Login successful!");
  //       Get.offAllNamed(AppRoutes.userJourney);



  //     } else {
  //       final error = jsonDecode(response.body);
  //       _showError(error["detail"]?.toString() ?? "Login failed");
  //     }
  //   } catch (e) {
  //     print("Login exception: $e");
  //     _showError("Unable to connect to server. Check your network.");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

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
            ? user["email"]
            : "$firstName $lastName".trim();

        final userId = user["_id"] ?? "";
        final profilePicture = user["profile_picture"] ?? "";

        // 🔥 CRITICAL: Save user data to SharedPreferences
        await _sharedPrefs.saveString("user_id", userId);
        await _sharedPrefs.saveString("first_name", firstName);
        await _sharedPrefs.saveString("last_name", lastName);
        await _sharedPrefs.saveString("phone_number", user["phone_number"] ?? "");
        await _sharedPrefs.saveString("full_name", fullName);
        
        // 🔥 CRITICAL: Save current user ID for chat sessions
        await _sharedPrefs.saveCurrentUserId(userId);
        print('✅ Current user ID saved for chat sessions: $userId');

        // 🔥 CRITICAL: Initialize ChatManagerProvider with user ID
        await _initializeChatManager(userId);

        // Save profile image URL if available
        if (profilePicture != null && profilePicture.toString().isNotEmpty) {
          await _sharedPrefs.saveProfileImageUrl(profilePicture.toString());
          print('🖼️ Profile image URL saved from backend: $profilePicture');
        } else {
          print('ℹ️ No profile image found in backend response');
        }

        print("✅ Saved user data:");
        print("   - User ID: $userId");
        print("   - Full Name: $fullName");
        print("   - Profile Image: ${profilePicture ?? "None"}");

        // Update UserController with the user ID and profile image
        final userController = Get.find<UserController>();
        userController.setUserId(userId);
        userController.updateUser(fullName, user["email"] ?? "");

        // Update profile image in UserController if available
        if (profilePicture != null && profilePicture.toString().isNotEmpty) {
          userController.updateProfileImageUrl(profilePicture.toString());
        }

        print("✅ UserController updated with user ID: $userId");

      } else {
        print("❌ Failed to fetch profile: ${response.body}");
      }
    } catch (e) {
      print("Profile fetch exception: $e");
    }
  }

  // Initialize chat manager for the logged-in user
  Future<void> _initializeChatManager(String userId) async {
    try {
      ChatManagerProvider chatManagerProvider;
      if (Get.isRegistered<ChatManagerProvider>()) {
        chatManagerProvider = Get.find<ChatManagerProvider>();
      } else {
        chatManagerProvider = Get.put(ChatManagerProvider());
      }
      
      await chatManagerProvider.initializeForUser(userId);
      print('✅ ChatManagerProvider initialized for user: $userId');
    } catch (e) {
      print('❌ Error initializing chat manager: $e');
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