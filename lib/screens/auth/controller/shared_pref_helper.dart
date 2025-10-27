import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  // Singleton instance
  static final SharedPrefsHelper _instance = SharedPrefsHelper._privateConstructor();
  factory SharedPrefsHelper() => _instance;
  SharedPrefsHelper._privateConstructor();

  // Keys for SharedPreferences
  static const String _userDataKey = 'user_data';
  static const String _rememberUserKey = 'remember_user';
  static const String _loginTimestampKey = 'login_timestamp';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _accessTokenKey = 'access_token';
  static const String _profileImageUrlKey = 'profile_image_url';
  static const String _fullNameKey = 'full_name';
  static const String _emailKey = 'email';

  // Basic string operations
  Future<void> saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      print("✅ Saved [$key] = $value");
    } catch (e) {
      print('Error saving string [$key]: $e');
      rethrow;
    }
  }

  Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(key);
      print("📥 Loaded [$key] = $value");
      return value;
    } catch (e) {
      print('Error getting string [$key]: $e');
      return null;
    }
  }

  // // Profile image management
  // Future<void> saveProfileImageUrl(String imageUrl) async {
  //   await saveString(_profileImageUrlKey, imageUrl);
  //   print('🖼️ Profile image URL saved: $imageUrl');
  // }


  // User data management
  Future<void> saveUserBasicInfo(String name, String email) async {
    await saveString(_fullNameKey, name);
    await saveString(_emailKey, email);
    print('👤 User basic info saved: $name, $email');
  }

  // Token management
  Future<void> saveAccessToken(String token) async {
    await saveString(_accessTokenKey, token);
  }

  Future<String?> getAccessToken() async {
    return await getString(_accessTokenKey);
  }

  // Authentication management
  Future<void> setRememberUser(bool remember) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberUserKey, remember);
      print('🔐 Remember user preference set to: $remember');
    } catch (e) {
      print('Error setting remember user preference: $e');
      rethrow;
    }
  }

  Future<bool> rememberUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberUserKey) ?? false;
    } catch (e) {
      print('Error getting remember user preference: $e');
      return false;
    }
  }

  Future<void> saveLoginTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_loginTimestampKey, now);
    print('✅ Login timestamp saved: $now');
  }

  Future<int?> getLoginTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_loginTimestampKey);
  }

  Future<void> saveTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final expiry = DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch;
    await prefs.setInt(_tokenExpiryKey, expiry);
    print('✅ Token expiry saved: $expiry (30 days from now)');
  }

  Future<bool> isTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final expiry = prefs.getInt(_tokenExpiryKey);
    
    if (expiry == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final isValid = now < expiry;
    
    print('🔐 Token validity check: now=$now, expiry=$expiry, valid=$isValid');
    return isValid;
  }

  // Enhanced login check
  Future<bool> isUserLoggedIn() async {
    try {
      // Check if user wants to be remembered
      final rememberMe = await rememberUser();
      if (!rememberMe) {
        print('🔐 Remember me is disabled');
        return false;
      }

      // Check if token is still valid (within 30 days)
      final tokenValid = await isTokenValid();
      if (!tokenValid) {
        print('🔐 Token expired or not found');
        await clearAuthData();
        return false;
      }

      // Check if we have basic user data
      final email = await getString(_emailKey);
      final hasUserData = email != null && email.isNotEmpty;
      
      print('🔐 Login status: rememberMe=$rememberMe, tokenValid=$tokenValid, hasUserData=$hasUserData');
      
      return hasUserData;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Clear all data (logout)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all relevant keys
      await prefs.remove(_fullNameKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_profileImageUrlKey);
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_userDataKey);
      await prefs.remove(_loginTimestampKey);
      await prefs.remove(_tokenExpiryKey);
      await prefs.remove(_rememberUserKey);
      
      print('✅ All user data cleared from SharedPreferences');
    } catch (e) {
      print('Error clearing user data: $e');
      rethrow;
    }
  }

  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginTimestampKey);
    await prefs.remove(_tokenExpiryKey);
    await prefs.remove(_accessTokenKey);
    print('✅ Auth data cleared');

  }

Future<void> saveProfileImageUrl(String imageUrl) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("profile_image_url", imageUrl);
    print('💾 Profile image URL saved to SharedPreferences: $imageUrl');
    
    // Verify the save
    final verify = prefs.getString("profile_image_url");
    print('🔍 Save verification: $verify');
  } catch (e) {
    print('❌ Error saving profile image URL: $e');
    rethrow;
  }
}

Future<String?> getProfileImageUrl() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString("profile_image_url");
    print('💾 Profile image URL loaded from SharedPreferences: ${url ?? "None"}');
    return url;
  } catch (e) {
    print('❌ Error loading profile image URL: $e');
    return null;
  }
}



// Enhanced user data clearing
Future<void> clearUserProfileData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear only profile-related data, keep auth tokens if needed
    await prefs.remove(_fullNameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_profileImageUrlKey);
    
    print('✅ User profile data cleared from SharedPreferences');
  } catch (e) {
    print('Error clearing user profile data: $e');
    rethrow;
  }
}

}

















