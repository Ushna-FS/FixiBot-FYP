import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'shared_pref_helper.dart';

class AuthHelper {
  static final SharedPrefsHelper _sharedPrefs = SharedPrefsHelper();

  static Future<UserCredential?> signInWithGoogle() async {
    print('[Google Sign-In] Starting Google sign-in process');

    try {
      print('[Google Sign-In] Attempting to sign in with Google');
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        print('[Google Sign-In] User cancelled Google sign-in');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        final user = userCredential.user!;
        await _sharedPrefs.saveUserData(
          email: user.email ?? '',
          name: user.displayName,
          photoUrl: user.photoURL,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('[Google Sign-In] FirebaseAuthException: ${e.code} - ${e.message}');
      Get.snackbar("Error", "Google sign-in failed: ${e.message}",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return null;
    } catch (e, s) {
      print('[Google Sign-In] Error: $e\n$s');
      Get.snackbar("Error", "An unexpected error occurred during Google sign-in",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return null;
    }
  }
}