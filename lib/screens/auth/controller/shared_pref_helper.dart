// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';

// class SharedPrefsHelper {
//   // Singleton instance
//   static final SharedPrefsHelper _instance = SharedPrefsHelper._privateConstructor();
//   factory SharedPrefsHelper() => _instance;
//   SharedPrefsHelper._privateConstructor();

//   // Keys for SharedPreferences
//   static const String _userDataKey = 'user_data';
//   static const String _rememberUserKey = 'remember_user';
//   static const String _loginTimestampKey = 'login_timestamp';
//   static const String _tokenExpiryKey = 'token_expiry';
//   static const String _accessTokenKey = 'access_token';
//   static const String _profileImageUrlKey = 'profile_image_url';
//   static const String _fullNameKey = 'full_name';
//   static const String _emailKey = 'email';

//   // Basic string operations
//   Future<void> saveString(String key, String value) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString(key, value);
//       print("✅ Saved [$key] = $value");
//     } catch (e) {
//       print('Error saving string [$key]: $e');
//       rethrow;
//     }
//   }

//   Future<String?> getString(String key) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final value = prefs.getString(key);
//       print("📥 Loaded [$key] = $value");
//       return value;
//     } catch (e) {
//       print('Error getting string [$key]: $e');
//       return null;
//     }
//   }

//   // User-specific chat storage
//   String _getUserChatKey(String userId) => "chat_sessions_$userId";
//   String _getUserCurrentSessionKey(String userId) => "current_session_$userId";

//   Future<void> saveUserChatSessions(String userId, Map<String, dynamic> sessions) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_getUserChatKey(userId), jsonEncode(sessions));
//   }

//   Future<Map<String, dynamic>> getUserChatSessions(String userId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final stored = prefs.getString(_getUserChatKey(userId));
//     if (stored != null) {
//       return jsonDecode(stored);
//     }
//     return {};
//   }

//   Future<void> saveUserCurrentSession(String userId, String sessionId) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_getUserCurrentSessionKey(userId), sessionId);
//   }

//   Future<String?> getUserCurrentSession(String userId) async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_getUserCurrentSessionKey(userId));
//   }

//   // ✅ KEEP ONLY ONE clearUserChatData METHOD - REMOVE THE DUPLICATE AT THE BOTTOM
//   Future<void> clearUserChatData(String userId) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_getUserChatKey(userId));
//     await prefs.remove(_getUserCurrentSessionKey(userId));
//     print('🗑️ Cleared chat data for user: $userId');
//   }

//   // User data management
//   Future<void> saveUserBasicInfo(String name, String email) async {
//     await saveString(_fullNameKey, name);
//     await saveString(_emailKey, email);
//     print('👤 User basic info saved: $name, $email');
//   }

//   // Token management
//   Future<void> saveAccessToken(String token) async {
//     await saveString(_accessTokenKey, token);
//   }

//   Future<String?> getAccessToken() async {
//     return await getString(_accessTokenKey);
//   }

//   // Authentication management
//   Future<void> setRememberUser(bool remember) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setBool(_rememberUserKey, remember);
//       print('🔐 Remember user preference set to: $remember');
//     } catch (e) {
//       print('Error setting remember user preference: $e');
//       rethrow;
//     }
//   }

//   Future<bool> rememberUser() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       return prefs.getBool(_rememberUserKey) ?? false;
//     } catch (e) {
//       print('Error getting remember user preference: $e');
//       return false;
//     }
//   }

//   Future<void> saveLoginTimestamp() async {
//     final prefs = await SharedPreferences.getInstance();
//     final now = DateTime.now().millisecondsSinceEpoch;
//     await prefs.setInt(_loginTimestampKey, now);
//     print('✅ Login timestamp saved: $now');
//   }

//   Future<int?> getLoginTimestamp() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getInt(_loginTimestampKey);
//   }

//   Future<void> saveTokenExpiry() async {
//     final prefs = await SharedPreferences.getInstance();
//     final expiry = DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch;
//     await prefs.setInt(_tokenExpiryKey, expiry);
//     print('✅ Token expiry saved: $expiry (30 days from now)');
//   }

//   Future<bool> isTokenValid() async {
//     final prefs = await SharedPreferences.getInstance();
//     final expiry = prefs.getInt(_tokenExpiryKey);
    
//     if (expiry == null) return false;
    
//     final now = DateTime.now().millisecondsSinceEpoch;
//     final isValid = now < expiry;
    
//     print('🔐 Token validity check: now=$now, expiry=$expiry, valid=$isValid');
//     return isValid;
//   }

//   // Enhanced login check
//   Future<bool> isUserLoggedIn() async {
//     try {
//       // Check if user wants to be remembered
//       final rememberMe = await rememberUser();
//       if (!rememberMe) {
//         print('🔐 Remember me is disabled');
//         return false;
//       }

//       // Check if token is still valid (within 30 days)
//       final tokenValid = await isTokenValid();
//       if (!tokenValid) {
//         print('🔐 Token expired or not found');
//         await clearAuthData();
//         return false;
//       }

//       // Check if we have basic user data
//       final email = await getString(_emailKey);
//       final hasUserData = email != null && email.isNotEmpty;
      
//       print('🔐 Login status: rememberMe=$rememberMe, tokenValid=$tokenValid, hasUserData=$hasUserData');
      
//       return hasUserData;
//     } catch (e) {
//       print('Error checking login status: $e');
//       return false;
//     }
//   }

//   // Clear all data (logout)
//   Future<void> clearAllData() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
      
//       // Clear all relevant keys
//       await prefs.remove(_fullNameKey);
//       await prefs.remove(_emailKey);
//       await prefs.remove(_profileImageUrlKey);
//       await prefs.remove(_accessTokenKey);
//       await prefs.remove(_userDataKey);
//       await prefs.remove(_loginTimestampKey);
//       await prefs.remove(_tokenExpiryKey);
//       await prefs.remove(_rememberUserKey);
      
//       print('✅ All user data cleared from SharedPreferences');
//     } catch (e) {
//       print('Error clearing user data: $e');
//       rethrow;
//     }
//   }

//   Future<void> clearAuthData() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_loginTimestampKey);
//     await prefs.remove(_tokenExpiryKey);
//     await prefs.remove(_accessTokenKey);
//     print('✅ Auth data cleared');
//   }

//   Future<void> saveProfileImageUrl(String imageUrl) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString("profile_image_url", imageUrl);
//       print('💾 Profile image URL saved to SharedPreferences: $imageUrl');
      
//       // Verify the save
//       final verify = prefs.getString("profile_image_url");
//       print('🔍 Save verification: $verify');
//     } catch (e) {
//       print('❌ Error saving profile image URL: $e');
//       rethrow;
//     }
//   }

//   Future<String?> getProfileImageUrl() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final url = prefs.getString("profile_image_url");
//       print('💾 Profile image URL loaded from SharedPreferences: ${url ?? "None"}');
//       return url;
//     } catch (e) {
//       print('❌ Error loading profile image URL: $e');
//       return null;
//     }
//   }

//   // User ID management
//   Future<void> saveUserId(String userId) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString("user_id", userId);
//     print('💾 User ID saved: $userId');
//   }

//   Future<String?> getUserId() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString("user_id");
//   }

//   // Clear user data on logout with remember me option
//   Future<void> clearUserDataOnLogout(bool rememberMe) async {
//     final prefs = await SharedPreferences.getInstance();
    
//     if (!rememberMe) {
//       // Clear everything including user ID
//       await prefs.remove("user_id");
//       await prefs.remove("access_token");
//       await prefs.remove("token_type");
//       await prefs.remove("full_name");
//       await prefs.remove("email");
//       await prefs.remove("profile_image_url");
//       await prefs.remove("first_name");
//       await prefs.remove("last_name");
//       await prefs.remove("phone_number");
//       await prefs.setBool("remember_user", false);
//       print('🗑️ All user data cleared (remember me disabled)');
//     } else {
//       // Keep user ID but clear auth tokens
//       await prefs.remove("access_token");
//       await prefs.remove("token_type");
//       print('🔐 Auth tokens cleared, user ID preserved (remember me enabled)');
//     }
//   }

//   Future<bool> getRememberUser() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool("remember_user") ?? false;
//   }

// // Add this method to your SharedPrefsHelper if it doesn't exist
// Future<void> saveTokenType(String tokenType) async {
//   await saveString('token_type', tokenType);
// }

// Future<String?> getTokenType() async {
//   return await getString('token_type');
// }
//   // Add this method to clear user profile data specifically
//   Future<void> clearUserProfileData() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove("full_name");
//     await prefs.remove("email");
//     await prefs.remove("profile_image_url");
//     await prefs.remove("first_name");
//     await prefs.remove("last_name");
//     await prefs.remove("phone_number");
//     print('✅ User profile data cleared');
//   }
// }











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

  // 🔥 NEW: User ID management for current session
  Future<void> saveCurrentUserId(String userId) async {
    await saveString("current_user_id", userId);
    print('💾 Current user ID saved: $userId');
  }

  Future<String?> getCurrentUserId() async {
    return await getString("current_user_id");
  }

  Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("current_user_id");
    print('🗑️ Current user ID cleared');
  }

  // 🔥 NEW: User-specific chat storage keys and methods
  String _getUserChatKey(String userId) => "chat_sessions_$userId";
  String _getUserCurrentSessionKey(String userId) => "current_session_$userId";

  Future<void> saveUserChatSessions(String userId, Map<String, dynamic> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getUserChatKey(userId), jsonEncode(sessions));
    print('💾 Chat sessions saved for user: $userId (${sessions.length} sessions)');
  }

  Future<Map<String, dynamic>> getUserChatSessions(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_getUserChatKey(userId));
    if (stored != null) {
      try {
        final sessions = jsonDecode(stored);
        print('📥 Loaded chat sessions for user: $userId (${sessions.length} sessions)');
        return sessions;
      } catch (e) {
        print('❌ Error parsing chat sessions for user $userId: $e');
      }
    }
    print('📥 No chat sessions found for user: $userId');
    return {};
  }

  Future<void> saveUserCurrentSession(String userId, String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getUserCurrentSessionKey(userId), sessionId);
    print('💾 Current session saved for user: $userId -> $sessionId');
  }

  Future<String?> getUserCurrentSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString(_getUserCurrentSessionKey(userId));
    print('📥 Current session for user $userId: $sessionId');
    return sessionId;
  }

  Future<void> clearUserChatData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getUserChatKey(userId));
    await prefs.remove(_getUserCurrentSessionKey(userId));
    print('🗑️ Chat data cleared for user: $userId');
  }

  Future<List<String>> getAllUserIdsWithChats() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final userIds = keys
        .where((key) => key.startsWith('chat_sessions_'))
        .map((key) => key.replaceFirst('chat_sessions_', ''))
        .toList();
    print('👥 Users with chat sessions: $userIds');
    return userIds;
  }

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

  Future<void> saveTokenType(String tokenType) async {
    await saveString('token_type', tokenType);
  }

  Future<String?> getTokenType() async {
    return await getString('token_type');
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

  // 🔥 UPDATED: Clear all data (logout) - Now handles user-specific chat data
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = await getCurrentUserId();
      
      // Clear chat data for current user if exists
      if (currentUserId != null) {
        await clearUserChatData(currentUserId);
      }
      
      // Clear all relevant keys
      await prefs.remove(_fullNameKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_profileImageUrlKey);
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_userDataKey);
      await prefs.remove(_loginTimestampKey);
      await prefs.remove(_tokenExpiryKey);
      await prefs.remove(_rememberUserKey);
      await prefs.remove("user_id");
      await prefs.remove("current_user_id");
      await prefs.remove("token_type");
      await prefs.remove("first_name");
      await prefs.remove("last_name");
      await prefs.remove("phone_number");
      
      print('✅ All user data cleared from SharedPreferences');
    } catch (e) {
      print('Error clearing user data: $e');
      rethrow;
    }
  }

  // 🔥 UPDATED: Clear auth data - Now includes token_type
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginTimestampKey);
    await prefs.remove(_tokenExpiryKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove("token_type");
    print('✅ Auth data cleared');
  }

  // 🔥 NEW: Enhanced logout method with user context
  Future<void> logoutUser(bool rememberMe) async {
    final currentUserId = await getCurrentUserId();
    
    if (!rememberMe) {
      // Clear everything including user-specific chats
      if (currentUserId != null) {
        await clearUserChatData(currentUserId);
      }
      await clearAllData();
      print('🗑️ Complete logout - all data cleared');
    } else {
      // Keep user ID and chat data, clear only auth tokens
      await clearAuthData();
      print('🔐 Partial logout - auth tokens cleared, user data preserved');
    }
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

  // User ID management
  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_id", userId);
    print('💾 User ID saved: $userId');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_id");
  }

  // Clear user data on logout with remember me option
  Future<void> clearUserDataOnLogout(bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = await getCurrentUserId();
    
    if (!rememberMe) {
      // Clear everything including user-specific chats
      if (currentUserId != null) {
        await clearUserChatData(currentUserId);
      }
      
      // Clear user data
      await prefs.remove("user_id");
      await prefs.remove("access_token");
      await prefs.remove("token_type");
      await prefs.remove("full_name");
      await prefs.remove("email");
      await prefs.remove("profile_image_url");
      await prefs.remove("first_name");
      await prefs.remove("last_name");
      await prefs.remove("phone_number");
      await prefs.setBool("remember_user", false);
      await prefs.remove("current_user_id");
      print('🗑️ All user data cleared (remember me disabled)');
    } else {
      // Keep user ID but clear auth tokens
      await prefs.remove("access_token");
      await prefs.remove("token_type");
      print('🔐 Auth tokens cleared, user ID preserved (remember me enabled)');
    }
  }

  Future<bool> getRememberUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("remember_user") ?? false;
  }

  // Clear user profile data specifically
  Future<void> clearUserProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("full_name");
    await prefs.remove("email");
    await prefs.remove("profile_image_url");
    await prefs.remove("first_name");
    await prefs.remove("last_name");
    await prefs.remove("phone_number");
    print('✅ User profile data cleared');
  }

  // 🔥 NEW: Check if user has existing chat sessions
  Future<bool> hasUserChatSessions(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSessions = prefs.containsKey(_getUserChatKey(userId));
    print('🔍 User $userId has chat sessions: $hasSessions');
    return hasSessions;
  }

  // 🔥 NEW: Migrate old chat sessions to user-specific storage (if needed)
  Future<void> migrateOldChatSessions(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final oldKey = 'all_chat_sessions';
    
    if (prefs.containsKey(oldKey)) {
      final oldSessions = prefs.getString(oldKey);
      if (oldSessions != null) {
        await prefs.setString(_getUserChatKey(userId), oldSessions);
        await prefs.remove(oldKey);
        print('🔄 Migrated old chat sessions to user-specific storage for user: $userId');
      }
    }
  }
  // Add to SharedPrefsHelper class
Future<void> debugSaveCurrentUserId(String userId) async {
  print('=== SAVING CURRENT USER ID ===');
  print('Before save - current_user_id: ${await getCurrentUserId()}');
  print('Before save - user_id: ${await getString("user_id")}');
  
  await saveCurrentUserId(userId);
  
  print('After save - current_user_id: ${await getCurrentUserId()}');
  print('After save - user_id: ${await getString("user_id")}');
  print('==============================');
}
}















