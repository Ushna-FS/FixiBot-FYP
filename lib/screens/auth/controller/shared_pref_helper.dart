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
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userPhotoUrlKey = 'user_photo_url';

  /// Saves user data to SharedPreferences
  Future<void> saveUserData({
    required String email,
    String? name,
    String? photoUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_userEmailKey, email),
        if (name != null) prefs.setString(_userNameKey, name),
        if (photoUrl != null) prefs.setString(_userPhotoUrlKey, photoUrl),
      ]);
      print('User data saved to SharedPreferences');
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  /// Loads user email from SharedPreferences
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Loads user name from SharedPreferences
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  /// Loads user photo URL from SharedPreferences
  Future<String?> getUserPhotoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhotoUrlKey);
  }

  /// Clears all user data from SharedPreferences
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_userEmailKey),
        prefs.remove(_userNameKey),
        prefs.remove(_userPhotoUrlKey),
      ]);
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
}