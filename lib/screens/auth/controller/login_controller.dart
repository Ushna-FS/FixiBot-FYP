import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixibot_app/screens/auth/controller/google_sign_in_helper.dart';
import 'package:fixibot_app/screens/homeScreen.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this import
import '../../mechanics/view/mechanicsScreen.dart';
import '../view/signup.dart';
import 'shared_pref_helper.dart';

class LoginController extends GetxController {
  final SharedPrefsHelper _sharedPrefs = SharedPrefsHelper();
  var emailController = TextEditingController();
  var passwordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void login() async {
    print('[Login] Function started');
    print('[Login] Email: ${emailController.text.trim()}');
    print('[Login] Password: [hidden]');

    // Validate inputs
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      print('[Login] Validation failed: Empty fields');
      Get.snackbar("Error", "Please fill in all fields",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    print('[Login] Input validation passed');
    isLoading.value = true;
    print('[Login] Loading state set to true');

    try {
      print('[Login] Attempting Firebase authentication');
      final email = emailController.text.trim().toLowerCase();
      final password = passwordController.text.trim();

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('[Login] Authentication successful');

      // Check if email is verified
      if (userCredential.user?.emailVerified == false) {
        print('[Login] Email not verified');

        // Send verification email if not verified
        await userCredential.user?.sendEmailVerification();

        // Sign out the user since email isn't verified
        await FirebaseAuth.instance.signOut();

        Get.snackbar(
          "Email Not Verified",
          "We've sent a new verification link. Then try logging in again.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );

        // Optionally navigate to a verification reminder screen
        // Get.to(() => EmailVerificationScreen(email: email));

        return;
      }

      // Save user data to SharedPreferences
      await _sharedPrefs.saveUserData(email: email);
      print('[Login] User data saved to SharedPreferences');

      print('[Login] Navigating to HomeScreen');
      Get.offAll(const HomeScreen());
    } on FirebaseAuthException catch (e) {
      print('[Login] FirebaseAuthException caught: ${e.code}');
      String message = "Login failed";

      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Try again later.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      } else if (e.code == 'requires-recent-login') {
        message =
            'This operation requires recent authentication. Please log in again.';
      }

      Get.snackbar("Error", message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } catch (e) {
      print('[Login] Unexpected error: $e');
      Get.snackbar("Error", "An unexpected error occurred",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
      print('[Login] Loading state set to false');
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void LogInNavigation() {
    Get.to(const SignupScreen());
  }

  void googleSignIn() async {
    final userCredential = await AuthHelper.signInWithGoogle();
    if (userCredential != null) {
      Get.to(const HomeScreen());
    }
  }
}
