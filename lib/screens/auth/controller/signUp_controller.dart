import 'dart:async';
import 'dart:convert';
import 'package:fixibot_app/constants/appConfig.dart';
import 'package:fixibot_app/routes/app_routes.dart';
import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
import 'package:fixibot_app/screens/chatbot/provider/chatManagerProvider.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:email_validator/email_validator.dart';

class SignupController extends GetxController {
  final SharedPrefsHelper _sharedPrefs = SharedPrefsHelper();

  // Text controllers
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  // Observables
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final savePassword = false.obs;
  final isLoading = false.obs;
  final canResendEmail = true.obs;
  final cooldownSeconds = 0.obs;

  //  final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";
final baseUrl  = AppConfig.baseUrl;

  Timer? _cooldownTimer;

  /// Show snackbar errors
  void showError(String message) {
    Get.snackbar(
      "Error",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void showSuccess(String message) {
    Get.snackbar(
      "Success",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

Future<void> _initializeChatManager(String userId) async {
  try {
    ChatManagerProvider chatManagerProvider;
    if (Get.isRegistered<ChatManagerProvider>()) {
      chatManagerProvider = Get.find<ChatManagerProvider>();
    } else {
      chatManagerProvider = Get.put(ChatManagerProvider());
    }
    
    await chatManagerProvider.initializeForUser(userId);
    print('✅ ChatManagerProvider initialized for new user: $userId');
  } catch (e) {
    print('❌ Error initializing chat manager: $e');
  }
}
  /// Prevent double submission: if already loading, ignore
  Future<void> signup() async {
    if (isLoading.value) return; // guard against double taps

    final email = emailController.text.toLowerCase().trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final username = usernameController.text.trim();
    final phone = phoneController.text.trim();

    // Validation (caller/view should also validate form; we keep checks here as well)
    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      showError("Username, email and password are required");
      return;
    }
    if (!EmailValidator.validate(email)) {
      showError("Please enter a valid email");
      return;
    }
    if (password != confirmPassword) {
      showError("Passwords do not match!");
      return;
    }
    if (password.length < 6) {
      showError("Password must be at least 6 characters");
      return;
    }
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{6,}$').hasMatch(password)) {
      showError("Password must contain at least one letter and one number");
      return;
    }

    isLoading.value = true;
    try {
      final url = Uri.parse("$baseUrl/auth/register");

      final body = {
        "email": email,
        "first_name": username.split(" ").first,
        "last_name": username.contains(" ") ? username.split(" ").last : "",
        "password": password,
        "role": "user"
      };

      if (phone.isNotEmpty) {
        body["phone_number"] = phone;
      }

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("Signup API response: ${response.statusCode} -> ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
  final data = jsonDecode(response.body);
 final userId = data["_id"] ?? "";
  
  // Save user data...
  await _sharedPrefs.saveCurrentUserId(userId); // 🔥 CRITICAL
  
  // 🔥 INITIALIZE CHAT MANAGER
  await _initializeChatManager(userId);
  
  showSuccess("Registration successful! Please verify your email.");
  Get.offNamed(AppRoutes.otp, arguments: {"email": email});
  // 🚨 Clear old data
  await _sharedPrefs.clearAllData();

  // Save new signup data
  await _sharedPrefs.saveString("user_id", data["_id"] ?? "");
  await _sharedPrefs.saveString("email", data["email"] ?? "");
  await _sharedPrefs.saveString("first_name", data["first_name"] ?? "");
  await _sharedPrefs.saveString("last_name", data["last_name"] ?? "");
  await _sharedPrefs.saveString("phone_number", data["phone_number"] ?? "");

  final fullName =
      "${data["first_name"] ?? ""} ${data["last_name"] ?? ""}".trim();
  await _sharedPrefs.saveString("full_name", fullName);

  showSuccess("Registration successful! Please verify your email.");
  Get.offNamed(AppRoutes.otp, arguments: {"email": email});
}

       else {
        final error = jsonDecode(response.body);
        showError(error["detail"]?.toString() ?? "Signup failed");
      }
    } catch (e) {
      print("Signup exception: $e");
      showError("Unable to connect to server. Check your network.");
    } finally {
      isLoading.value = false;
    }
  }

  

  void _startCooldown() {
    canResendEmail.value = false;
    cooldownSeconds.value = 30; // 30s cooldown

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (cooldownSeconds.value > 0) {
        cooldownSeconds.value--;
      } else {
        canResendEmail.value = true;
        timer.cancel();
      }
    });
  }

  void signInNavigation() => Get.offAllNamed(AppRoutes.login);

  @override
  void onClose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    otpController.dispose();
    _cooldownTimer?.cancel();
    super.onClose();
  }
}