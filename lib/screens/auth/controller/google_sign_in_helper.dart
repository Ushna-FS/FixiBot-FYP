import 'dart:convert';
import 'package:fixibot_app/routes/app_routes.dart';
import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class GoogleSignInController extends GetxController {
  final _sharedPrefs = SharedPrefsHelper();
  final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";
  final isLoading = false.obs;

  late GoogleSignIn _googleSignIn;

  @override
  void onInit() {
    super.onInit();
    _googleSignIn = GoogleSignIn(
      params: GoogleSignInParams(
        clientId: "322656333921-71gd3s8sckaacb7mj5cshq5ftg48fqjr.apps.googleusercontent.com",
        clientSecret: "YOUR_GOOGLE_CLIENT_SECRET",  // ensure you have it
        redirectPort: 3000,
      ),
    );
  }

  Future<void> _openUrl(Uri url) async {
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception("Could not launch $url");
  }
}

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      final credentials = await _googleSignIn.signIn();
      if (credentials == null) return;

      // You now have an accessToken and ID token in credentials
      final idToken = credentials.idToken;

      final response = await http.post(
        Uri.parse("$baseUrl/auth/google"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _sharedPrefs.saveString("access_token", data["access_token"]);
        await _sharedPrefs.saveString("email", data["email"] ?? "");
        Get.offAllNamed(AppRoutes.home);
      } else {
        throw Exception("Google login failed: ${response.body}");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
