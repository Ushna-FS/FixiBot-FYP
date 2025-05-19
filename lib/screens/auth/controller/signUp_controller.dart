import 'dart:async';

import 'package:fixibot_app/screens/auth/controller/google_sign_in_helper.dart';
import 'package:fixibot_app/screens/auth/view/verificationScreen.dart';
import 'package:fixibot_app/screens/homeScreen.dart';
import 'package:fixibot_app/screens/otp/view/otpScreen.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:email_validator/email_validator.dart';

import '../../userJourney.dart';
import '../view/login.dart';
import 'shared_pref_helper.dart';

class SignupController extends GetxController {
  final SharedPrefsHelper _sharedPrefs = SharedPrefsHelper();
  // Text controllers
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();

  // Observables
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final savePassword = false.obs;
  final isLoading = false.obs;
  final canResendEmail = true.obs;
  final cooldownSeconds = 30.obs;
  Timer? _resendTimer;

  // Helper method for showing errors
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

  // Toggle methods
  void toggleSavePassword() => savePassword.value = !savePassword.value;
  void togglePasswordVisibility() =>
      isPasswordVisible.value = !isPasswordVisible.value;
  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

  Future<void> resendVerificationEmail() async {
    if (!canResendEmail.value) return;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.emailVerified) {
        isLoading.value = true;
        await user.sendEmailVerification();

        showSuccess("Verification email resent to ${user.email}");

        // Start cooldown
        canResendEmail.value = false;
        cooldownSeconds.value = 30;
        _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (cooldownSeconds.value > 0) {
            cooldownSeconds.value--;
          } else {
            timer.cancel();
            canResendEmail.value = true;
          }
        });
      } else {
        showError("No unverified user found");
      }
    } catch (e) {
      showError("Failed to resend verification email");
    } finally {
      isLoading.value = false;
    }
  }

  // Signup method
  Future<void> signup() async {
    print('Signup function started');

    final email = emailController.text.toLowerCase().trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    print('Email: $email');
    print('Password: [hidden]'); // Don't log actual passwords in production
    print('Confirm Password: [hidden]');

    // Validation
    if (email.isEmpty || password.isEmpty) {
      print('Validation failed: Empty email or password');
      showError("Email and password cannot be empty");
      return;
    }

    if (!EmailValidator.validate(email)) {
      print('Validation failed: Invalid email format');
      showError("Please enter a valid email");
      return;
    }

    if (password != confirmPassword) {
      print('Validation failed: Passwords do not match');
      showError("Passwords do not match!");
      return;
    }

    if (password.length < 6) {
      print('Validation failed: Password too short');
      showError("Password must be at least 6 characters");
      return;
    }

    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{6,}$').hasMatch(password)) {
      print('Validation failed: Password complexity requirements not met');
      showError("Password must contain at least one letter and one number");
      return;
    }

    print('All validations passed');
    isLoading.value = true;
    print('Loading state set to true');

    try {
      print('Attempting to create user with Firebase Auth');
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('User created successfully. UID: ${userCredential.user?.uid}');

      // Send email verification
      print('Sending email verification');
      await userCredential.user?.sendEmailVerification();
      print('Email verification sent');

      // Store additional user data if needed
      print('Updating display name');
      await userCredential.user
          ?.updateDisplayName(usernameController.text.trim());
      print('Display name updated');

      print('Navigating to VerificationSentScreen');
      Get.off(() => const VerificationSentScreen());
      print('Navigation complete');
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException caught: ${e.code}');
      String errorMessage = "Signup failed. Please try again.";

      if (e.code == 'email-already-in-use') {
        errorMessage = "This email is already registered.";
      } else if (e.code == 'weak-password') {
        errorMessage = "The password is too weak.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address is invalid.";
      }

      print('Showing error to user: $errorMessage');
      showError(errorMessage);
    } catch (e) {
      print('Unexpected error: $e');
      showError("An unexpected error occurred");
    } finally {
      isLoading.value = false;
      print('Loading state set to false');
    }
  }

  // Navigation methods
  void signInNavigation() => Get.offAll(() => Login());

  // Google Sign-In method
  void googleSignIn() async {
    final userCredential = await AuthHelper.signInWithGoogle();
    if (userCredential != null) {
      Get.to(const HomeScreen());
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.onClose();
  }

}
