import 'dart:async';
import 'dart:convert';
import 'package:fixibot_app/routes/app_routes.dart';
import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
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

  // API Base URL
  final String baseUrl = "http://127.0.0.1:8000";

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

  /// ================== SIGNUP ==================
  Future<void> signup() async {
    final email = emailController.text.toLowerCase().trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final username = usernameController.text.trim();
    final phone = phoneController.text.trim();

    // Validation
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

        // Save all user info locally
        await _sharedPrefs.saveString("user_id", data["_id"]);
        await _sharedPrefs.saveString("email", data["email"]);
        await _sharedPrefs.saveString("first_name", data["first_name"]);
        await _sharedPrefs.saveString("last_name", data["last_name"]);
        await _sharedPrefs.saveString(
            "phone_number", data["phone_number"] ?? "");

        // Save full name for Home header
        final fullName =
            "${data["first_name"] ?? ""} ${data["last_name"] ?? ""}".trim();
        await _sharedPrefs.saveString("full_name", fullName);

        showSuccess("Registration successful! Please verify your email.");

        // 🔹 Navigate to OTP screen and pass email
        Get.offNamed(AppRoutes.otp, arguments: {"email": email});
      } else {
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







///latest


// import 'dart:async';
// import 'dart:convert';
// import 'package:fixibot_app/routes/app_routes.dart';
// import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
// import 'package:get/get.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:email_validator/email_validator.dart';

// class SignupController extends GetxController {
//   final SharedPrefsHelper _sharedPrefs = SharedPrefsHelper();

//   // Text controllers
//   final usernameController = TextEditingController();
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();
//   final confirmPasswordController = TextEditingController();
//   final phoneController = TextEditingController();
//   final otpController = TextEditingController();

//   // Observables
//   final isPasswordVisible = false.obs;
//   final isConfirmPasswordVisible = false.obs;
//   final savePassword = false.obs;
//   final isLoading = false.obs;
//   final canResendEmail = true.obs;
//   final cooldownSeconds = 0.obs;

//   // API Base URL
//   final String baseUrl = "http://127.0.0.1:8000";

//   Timer? _cooldownTimer;

//   /// Show snackbar errors
//   void showError(String message) {
//     Get.snackbar(
//       "Error",
//       message,
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//     );
//   }

//   void showSuccess(String message) {
//     Get.snackbar(
//       "Success",
//       message,
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.green,
//       colorText: Colors.white,
//     );
//   }

//   /// Toggle states
//   void toggleSavePassword() => savePassword.value = !savePassword.value;
//   void togglePasswordVisibility() =>
//       isPasswordVisible.value = !isPasswordVisible.value;
//   void toggleConfirmPasswordVisibility() =>
//       isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

//   /// ================== SIGNUP ==================
//   Future<void> signup() async {
//     final email = emailController.text.toLowerCase().trim();
//     final password = passwordController.text.trim();
//     final confirmPassword = confirmPasswordController.text.trim();
//     final username = usernameController.text.trim();
//     final phone = phoneController.text.trim();

//     // Validation
//     if (email.isEmpty || password.isEmpty || username.isEmpty) {
//       showError("Username, email and password are required");
//       return;
//     }
//     if (!EmailValidator.validate(email)) {
//       showError("Please enter a valid email");
//       return;
//     }
//     if (password != confirmPassword) {
//       showError("Passwords do not match!");
//       return;
//     }
//     if (password.length < 6) {
//       showError("Password must be at least 6 characters");
//       return;
//     }
//     if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{6,}$').hasMatch(password)) {
//       showError("Password must contain at least one letter and one number");
//       return;
//     }

//     isLoading.value = true;
//     try {
//       final url = Uri.parse("$baseUrl/auth/register");

//       final body = {
//         "email": email,
//         "first_name": username.split(" ").first,
//         "last_name": username.contains(" ") ? username.split(" ").last : "",
//         "password": password,
//         "role": "user"
//       };

//       if (phone.isNotEmpty) {
//         body["phone_number"] = phone;
//       }

//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(body),
//       );

//       print("Signup API response: ${response.statusCode} -> ${response.body}");

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final data = jsonDecode(response.body);

//         await _sharedPrefs.saveString("user_id", data["_id"]);
//         await _sharedPrefs.saveString("email", data["email"]);
//         await _sharedPrefs.saveString("first_name", data["first_name"]);
//         await _sharedPrefs.saveString("last_name", data["last_name"]);
//         await _sharedPrefs.saveString(
//             "phone_number", data["phone_number"] ?? "");

//         showSuccess("Registration successful! Please verify your email.");

       

//         // 🔹 Navigate to OTP screen and pass email
//       Get.offNamed(AppRoutes.otp, arguments: {"email": email});

//       } else {
//         final error = jsonDecode(response.body);
//         showError(error["detail"]?.toString() ?? "Signup failed");
//       }
//     } catch (e) {
//       print("Signup exception: $e");
//       showError("Unable to connect to server. Check your network.");
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// ================== VERIFY EMAIL ==================
//   // Future<void> verifyEmailWithOtp() async {
//   //   final email = emailController.text.trim();
//   //   final otp = otpController.text.trim();

//   //   if (otp.isEmpty) {
//   //     showError("Please enter the OTP");
//   //     return;
//   //   }

//   //   isLoading.value = true;
//   //   try {
//   //     final url = Uri.parse("$baseUrl/auth/verify-email");
//   //     final body = {"email": email, "otp": otp};

//   //     final response = await http.post(
//   //       url,
//   //       headers: {"Content-Type": "application/json"},
//   //       body: jsonEncode(body),
//   //     );

//   //     print("Verify API response: ${response.statusCode} -> ${response.body}");

//   //     if (response.statusCode == 200) {
//   //       showSuccess("Email verified successfully!");
//   //       Get.offAllNamed(AppRoutes.login);
//   //     } else {
//   //       final error = jsonDecode(response.body);
//   //       showError(error["detail"]?.toString() ?? "Verification failed");
//   //     }
//   //   } catch (e) {
//   //     print("Verify exception: $e");
//   //     showError("Unable to connect to server.");
//   //   } finally {
//   //     isLoading.value = false;
//   //   }
//   // }

//   /// ================== RESEND VERIFICATION ==================
//   // Future<void> resendVerificationEmail() async {
//   //   final email = emailController.text.trim();

//   //   if (email.isEmpty) {
//   //     showError("Email not found. Please sign up again.");
//   //     return;
//   //   }

//   //   try {
//   //     final url = Uri.parse("$baseUrl/auth/resend-verification?email=$email");
//   //     final response = await http.post(url);

//   //     print("Resend API response: ${response.statusCode} -> ${response.body}");

//   //     if (response.statusCode == 200) {
//   //       showSuccess("Verification email resent!");
//   //       _startCooldown();
//   //     } else {
//   //       final error = jsonDecode(response.body);
//   //       showError(error["detail"]?.toString() ?? "Failed to resend email");
//   //     }
//   //   } catch (e) {
//   //     print("Resend exception: $e");
//   //     showError("Unable to connect to server.");
//   //   }
//   // }

//   /// Cooldown for resend
//   void _startCooldown() {
//     canResendEmail.value = false;
//     cooldownSeconds.value = 30; // 30s cooldown

//     _cooldownTimer?.cancel();
//     _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (cooldownSeconds.value > 0) {
//         cooldownSeconds.value--;
//       } else {
//         canResendEmail.value = true;
//         timer.cancel();
//       }
//     });
//   }

//   /// Navigate to login
//   void signInNavigation() => Get.offAllNamed(AppRoutes.login);

//   @override
//   void onClose() {
//     usernameController.dispose();
//     emailController.dispose();
//     passwordController.dispose();
//     confirmPasswordController.dispose();
//     phoneController.dispose();
//     otpController.dispose();
//     _cooldownTimer?.cancel();
//     super.onClose();
//   }
// }


