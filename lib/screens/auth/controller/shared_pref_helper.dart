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
  static const String _loginTimestampKey = 'login_timestamp';
  static const String _tokenExpiryKey = 'token_expiry';

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

  /// Save login timestamp (when user logs in)
  Future<void> saveLoginTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_loginTimestampKey, now);
    print('✅ Login timestamp saved: $now');
  }

  /// Get login timestamp
  Future<int?> getLoginTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_loginTimestampKey);
  }

  /// Save token expiry (30 days from login)
  Future<void> saveTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final expiry = DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch;
    await prefs.setInt(_tokenExpiryKey, expiry);
    print('✅ Token expiry saved: $expiry (30 days from now)');
  }

  /// Check if token is still valid (within 30 days)
  Future<bool> isTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final expiry = prefs.getInt(_tokenExpiryKey);
    
    if (expiry == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final isValid = now < expiry;
    
    print('🔐 Token validity check: now=$now, expiry=$expiry, valid=$isValid');
    return isValid;
  }

  /// Clear all authentication data (on logout)
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginTimestampKey);
    await prefs.remove(_tokenExpiryKey);
    await prefs.remove(_rememberUserKey);
    print('✅ Auth data cleared');
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
      await clearAuthData(); // Also clear auth data
      print('User data cleared from SharedPreferences');
    } catch (e) {
      print('Error clearing user data: $e');
      rethrow;
    }
  }

  /// Enhanced login check - checks token validity and remember me preference
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
        await clearAuthData(); // Clear expired auth data
        return false;
      }

      // Check if we have basic user data
      final email = await getString("email");
      final hasUserData = email != null && email.isNotEmpty;
      
      print('🔐 Login status: rememberMe=$rememberMe, tokenValid=$tokenValid, hasUserData=$hasUserData');
      
      return hasUserData;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
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

  Future<void> saveProfileImageUrl(String imageUrl) async {
    await saveString("profile_image_url", imageUrl);
  }

  /// Get profile image URL
  Future<String?> getProfileImageUrl() async {
    return await getString("profile_image_url");
  }

  /// Save complete user data including profile image
  Future<void> saveUserDataWithImage(String name, String email, String? imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'name': name,
      'email': email,
      'photoUrl': imageUrl ?? '',
    };
    await prefs.setString(_userDataKey, jsonEncode(userData));
    print('✅ User data with image saved');
  }
}













//perff
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';

// class SharedPrefsHelper {
//   // Private constructor
//   SharedPrefsHelper._privateConstructor();
  
//   // Singleton instance
//   static final SharedPrefsHelper _instance = SharedPrefsHelper._privateConstructor();
  
//   // Factory constructor to provide the same instance
//   factory SharedPrefsHelper() {
//     return _instance;
//   }

  
//   // Keys for SharedPreferences
//   static const String _userDataKey = 'user_data';
//   static const String _rememberUserKey = 'remember_user';

//   /// Sets whether the user wants to be remembered
//   Future<void> setRememberUser(bool remember) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setBool(_rememberUserKey, remember);
      
//       print('Remember user preference set to: $remember');
//     } catch (e) {
//       print('Error setting remember user preference: $e');
//       rethrow;
//     }
//   }

//   /// Checks if the user has opted to be remembered
//   Future<bool> rememberUser() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       return prefs.getBool(_rememberUserKey) ?? false;
//     } catch (e) {
//       print('Error getting remember user preference: $e');
//       return false;
//     }
//   }

//   /// Loads all user data from SharedPreferences
//   Future<Map<String, dynamic>?> getUserData() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userDataString = prefs.getString(_userDataKey);
//       if (userDataString != null) {
//         return jsonDecode(userDataString) as Map<String, dynamic>;
//       }
//       return null;
//     } catch (e) {
//       print('Error loading user data: $e');
//       return null;
//     }
//   }

//   /// Gets user email from stored data
//   Future<String?> getUserEmail() async {
//     final userData = await getUserData();
//     return userData?['email'];
//   }

//   /// Gets username from stored data
//   Future<String?> getUserName() async {
//     final userData = await getUserData();
//     return userData?['name'];
//   }

//   /// Gets photo URL from stored data
//   Future<String?> getUserPhotoUrl() async {
//     final userData = await getUserData();
//     return userData?['photoUrl'];
//   }

//   /// Clears all user data from SharedPreferences
//   Future<void> clearUserData() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove(_userDataKey);
//       print('User data cleared from SharedPreferences');
//     } catch (e) {
//       print('Error clearing user data: $e');
//       rethrow;
//     }
//   }

//   /// Checks if user is logged in (has email stored)
//   Future<bool> isUserLoggedIn() async {
//     final email = await getUserEmail();
//     return email != null && email.isNotEmpty;
//   }

//   /// Save a single string value
// Future<void> saveString(String key, String value) async {
//   final prefs = await SharedPreferences.getInstance();
//   await prefs.setString(key, value);
//   print("✅ Saved [$key] = $value");
// }

// /// Get a single string value
// Future<String?> getString(String key) async {
//   final prefs = await SharedPreferences.getInstance();
//   final value = prefs.getString(key);
//   print("📥 Loaded [$key] = $value");
//   return value;
// }
// Future<void> saveProfileImageUrl(String imageUrl) async {
//   await saveString("profile_image_url", imageUrl);
// }

// /// Get profile image URL
// Future<String?> getProfileImageUrl() async {
//   return await getString("profile_image_url");
// }

// /// Save complete user data including profile image
// Future<void> saveUserDataWithImage(String name, String email, String? imageUrl) async {
//   final prefs = await SharedPreferences.getInstance();
//   final userData = {
//     'name': name,
//     'email': email,
//     'photoUrl': imageUrl ?? '',
//   };
//   await prefs.setString(_userDataKey, jsonEncode(userData));
//   print('✅ User data with image saved');
// }

// }