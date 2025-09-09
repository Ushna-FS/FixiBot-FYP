import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  // Private constructor
  SharedPrefsHelper._privateConstructor();
  
  // Singleton instance
  static final SharedPrefsHelper _instance = SharedPrefsHelper._privateConstructor();
  
  // Factory constructor to provide the same instance
  factory SharedPrefsHelper() {
    return _instance;
  }

  // Keys for SharedPreferences
  static const String _userDataKey = 'user_data';
  static const String _rememberUserKey = 'remember_user';

  /// Sets whether the user wants to be remembered
  Future<void> setRememberUser(bool remember) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberUserKey, remember);
      
      print('Remember user preference set to: $remember');
    } catch (e) {
      print('Error setting remember user preference: $e');
      rethrow;
    }
  }

  /// Checks if the user has opted to be remembered
  Future<bool> rememberUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberUserKey) ?? false;
    } catch (e) {
      print('Error getting remember user preference: $e');
      return false;
    }
  }

  /// Loads all user data from SharedPreferences
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      if (userDataString != null) {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error loading user data: $e');
      return null;
    }
  }

  /// Gets user email from stored data
  Future<String?> getUserEmail() async {
    final userData = await getUserData();
    return userData?['email'];
  }

  /// Gets username from stored data
  Future<String?> getUserName() async {
    final userData = await getUserData();
    return userData?['name'];
  }

  /// Gets photo URL from stored data
  Future<String?> getUserPhotoUrl() async {
    final userData = await getUserData();
    return userData?['photoUrl'];
  }

  /// Clears all user data from SharedPreferences
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      print('User data cleared from SharedPreferences');
    } catch (e) {
      print('Error clearing user data: $e');
      rethrow;
    }
  }

  /// Checks if user is logged in (has email stored)
  Future<bool> isUserLoggedIn() async {
    final email = await getUserEmail();
    return email != null && email.isNotEmpty;
  }

  /// Save a single string value
Future<void> saveString(String key, String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
  print("✅ Saved [$key] = $value");
}

/// Get a single string value
Future<String?> getString(String key) async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getString(key);
  print("📥 Loaded [$key] = $value");
  return value;
}


}