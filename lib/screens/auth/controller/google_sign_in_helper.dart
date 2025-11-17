import 'dart:convert';
import 'package:fixibot_app/constants/appConfig.dart';
import 'package:fixibot_app/routes/app_routes.dart';
import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
import 'package:fixibot_app/screens/profile/controller/userController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GoogleSignInController extends GetxController {
  final SharedPrefsHelper _sharedPrefs = SharedPrefsHelper();
  final isLoading = false.obs;
  final isLoggedIn = false.obs;

  // Your WebApp Client ID (from Google API Console)
  static const String _serverClientId = 
      "577923430113-5el4v5guab66f4tvmeukhmalfeju0obv.apps.googleusercontent.com";

  final baseUrl  = AppConfig.baseUrl;
  // Your backend base URL
  // static const String _baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";

  late GoogleSignIn _googleSignIn;

  @override
  void onInit() {
    super.onInit();
    _initializeGoogleSignIn();
    _checkExistingLogin();
  }

  /// Initialize Google Sign-In
  void _initializeGoogleSignIn() {
    try {
      _googleSignIn = GoogleSignIn(
        serverClientId: _serverClientId,
        scopes: ['email', 'profile'],
      );
      print("✅ Google Sign-In initialized successfully");
    } catch (e) {
      print("❌ Error initializing Google Sign-In: $e");
    }
  }

  /// Check if user is already logged in
  Future<void> _checkExistingLogin() async {
    try {
      final isUserLoggedIn = await _sharedPrefs.isUserLoggedIn();
      isLoggedIn.value = isUserLoggedIn;
      
      if (isLoggedIn.value) {
        print("✅ User already logged in");
      } else {
        print("🔐 No active session found");
      }
    } catch (e) {
      print("Error checking login status: $e");
    }
  }


  /// Enhanced Main Sign-In Method with fallbacks
Future<void> signInWithGoogle() async {
  try {
    isLoading.value = true;
    print("🔄 Starting Google Sign-In process...");

    // Initialize if needed
    if (_googleSignIn == null) {
      _initializeGoogleSignIn();
    }

    print("1️⃣ Triggering Google sign-in UI...");
    
    // 1. Trigger Google sign-in flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      print("❌ User cancelled Google Sign-In");
      isLoading.value = false;
      return;
    }

    print("✅ Google user obtained: ${googleUser.email}");

    // 2. Get authentication object
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception("Google ID Token was null - authentication failed");
    }

    print("3️⃣ Attempting backend authentication...");
    
    // Try the enhanced method first
    bool success = await _sendTokenToBackendEnhanced(idToken, googleUser);
    
    if (!success) {
      // Fallback to original method
      print("🔄 Falling back to original method...");
      success = await _sendTokenToBackendEnhanced(idToken, googleUser);
    }

    if (success) {
      await _handleSuccessfulLogin(googleUser);
    } else {
      throw Exception("All authentication methods failed");
    }

  } catch (error) {
    print("❌ Error during Google Sign-In: $error");
    
    // More specific error handling
    String errorMessage = "Unable to sign in with Google. Please try again.";
    
    if (error.toString().contains('400')) {
      errorMessage = "Invalid request. Please contact support.";
    } else if (error.toString().contains('422')) {
      errorMessage = "Validation error. Please check your Google account.";
    } else if (error.toString().contains('500')) {
      errorMessage = "Server error. Please try again later.";
    } else if (error.toString().contains('No access token')) {
      errorMessage = "Authentication failed. Please try again.";
    } else if (error.toString().contains('network') || error.toString().contains('SocketException')) {
      errorMessage = "Network error. Please check your internet connection.";
    }
    
    Get.snackbar(
      "Sign In Failed", 
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: Duration(seconds: 5),
    );
  } finally {
    isLoading.value = false;
  }
}

  /// Check if Google Sign-In is supported on this platform
  Future<bool> _checkGoogleSignInSupport() async {
    try {
      // Try to check current user to test if plugin is available
      await _googleSignIn.currentUser;
      return true;
    } catch (e) {
      print("❌ Google Sign-In not supported: $e");
      return false;
    }
  }




/// Handle successful FIRST-TIME sign-up
Future<void> _handleSuccessfulSignUp(GoogleSignInAccount googleUser, {Map<String, dynamic>? userData}) async {
  try {
    print("🎉 Google Sign-Up Successful! First-time user detected");
    print("👤 User: ${googleUser.displayName}");
    print("📧 Email: ${googleUser.email}");

    // Ensure complete user setup
    await _ensureCompleteUserSetup(googleUser, userData);

    isLoggedIn.value = true;
    
    // Final verification
    await _verifyUserSessionCompleteness();
    
    // For first-time users, you can navigate to home or a welcome screen
    Get.offAllNamed(AppRoutes.home);
    
    // Show welcome message for new users
    Get.snackbar(
      "Welcome to Fixibot!", 
      "Your account has been created successfully!",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: Duration(seconds: 4),
    );
    
  } catch (e) {
    print('❌ Error in sign-up handling: $e');
    Get.snackbar(
      "Setup Incomplete", 
      "Please try signing up again",
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  } finally {
    isLoading.value = false;
  }
}



  /// Smart method that handles both sign-up and login
/// Smart method that handles both sign-up and login - CORRECTED VERSION
Future<void> continueWithGoogle() async {
  try {
    isLoading.value = true;
    
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      isLoading.value = false;
      return;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final String? idToken = googleAuth.idToken;
    if (idToken == null) throw Exception("Google authentication failed");

    // Send to backend
    final bool success = await _sendTokenToBackendEnhanced(idToken, googleUser);
    
    if (success) {
      // Check if this is likely a first-time user
      final isFirstTime = await _checkIfFirstTimeUser(googleUser.email);
      
      if (isFirstTime) {
        await _handleSuccessfulSignUp(googleUser); // ✅ Now this method exists
      } else {
        await _handleSuccessfulLogin(googleUser);
      }
    }
    
  } catch (e) {
    print('❌ Error in continueWithGoogle: $e');
    Get.snackbar(
      "Authentication Failed", 
      "Please try again",
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  } finally {
    isLoading.value = false;
  }
}

/// Check if user is signing up for the first time
Future<bool> _checkIfFirstTimeUser(String email) async {
  // You can check local storage or get this info from backend
  final prefs = await SharedPreferences.getInstance();
  final knownUsers = prefs.getStringList('known_users') ?? [];
  
  if (knownUsers.contains(email)) {
    return false; // Returning user
  } else {
    // Add to known users
    knownUsers.add(email);
    await prefs.setStringList('known_users', knownUsers);
    return true; // First time user
  }
}


/// Enhanced user ID extraction that works with MongoDB ObjectId
Future<void> _storeUserIdFromBackend(Map<String, dynamic> userData) async {
  try {
    print('🔍 Extracting user ID from backend response...');
    print('🔍 Full userData: $userData');
    
    // Try multiple possible keys for user ID - MongoDB ObjectId format
    final String? userId = userData['_id'] ?? 
                          userData['id'] ?? 
                          userData['user_id'];
    
    if (userId != null && userId.isNotEmpty) {
      // ✅ Validate if it's a proper MongoDB ObjectId (24-character hex string)
      if (_isValidObjectId(userId)) {
        await _sharedPrefs.saveUserId(userId);
        print("✅ Valid User ID stored: $userId");
      } else {
        print("⚠️ Invalid ObjectId format from backend: $userId");
        // Wait for backend to provide proper ID, don't store invalid one
      }
    } else {
      print("❌ No valid user ID found in backend response");
      print("🔍 Available keys: ${userData.keys}");
      
      // Don't create fallback IDs - wait for proper backend response
      print("⏳ Waiting for backend to provide proper user ID...");
    }
  } catch (e) {
    print("❌ Error storing user ID: $e");
    // Don't create emergency IDs - this causes the 422 error
  }
}

/// Check if string is a valid MongoDB ObjectId (24-character hex string)
bool _isValidObjectId(String id) {
  // MongoDB ObjectId should be 24-character hex string
  final objectIdRegex = RegExp(r'^[a-fA-F0-9]{24}$');
  return objectIdRegex.hasMatch(id);
}


/// Enhanced backend communication that handles user ID properly - CORRECTED VERSION
Future<bool> _sendTokenToBackendEnhanced(String googleIdToken, GoogleSignInAccount googleUser) async {
  final url = Uri.parse("$baseUrl/auth/google");

  try {
    print("📡 Sending enhanced POST request to: $url");
    
    final Map<String, dynamic> payload = {
      "token": googleIdToken,
    };

    print("📦 Payload: ${json.encode(payload)}");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: json.encode(payload),
    ).timeout(Duration(seconds: 30));

    print("📨 Backend response status: ${response.statusCode}");
    print("📨 Backend response body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final String? accessToken = responseData['access_token'];
      final Map<String, dynamic>? userData = responseData['user'];

      if (accessToken == null) {
        throw Exception("No access token received");
      }

      print("✅ Authentication successful");
      
      // ✅ FIX: Store both access token and token type - THIS WAS MISSING
      await _storeAuthTokens(accessToken, responseData);
      
      // Store user data - but be careful about user ID
      if (userData != null) {
        await _storeUserDataFromBackend(userData);
      } else {
        await _storeUserDataFromGoogle(googleUser);
      }

      await _updateUserController(googleUser, userData);
      
      // ✅ Check if we have a valid user ID
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId != null && _isValidObjectId(userId)) {
        print("🎉 Proper User ID received: $userId");
      } else {
        print("⚠️ Waiting for proper User ID from backend...");
      }
      
      return true;
    } else {
      final errorData = json.decode(response.body);
      final errorMsg = errorData['detail'] ?? errorData['message'] ?? errorData['error'] ?? "Unknown error";
      throw Exception("Error ${response.statusCode}: $errorMsg");
    }
  } catch (error) {
    print("❌ Enhanced method error: $error");
    rethrow;
  }
}



// /// Enhanced backend communication that handles user ID properly
// Future<bool> _sendTokenToBackendEnhanced(String googleIdToken, GoogleSignInAccount googleUser) async {
//   final url = Uri.parse("$baseUrl/auth/google");

//   try {
//     print("📡 Sending enhanced POST request to: $url");
    
//     final Map<String, dynamic> payload = {
//       "token": googleIdToken,
//     };

//     print("📦 Payload: ${json.encode(payload)}");

//     final response = await http.post(
//       url,
//       headers: {
//         "Content-Type": "application/json",
//       },
//       body: json.encode(payload),
//     ).timeout(Duration(seconds: 30));

//     print("📨 Backend response status: ${response.statusCode}");
//     print("📨 Backend response body: ${response.body}");

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       final Map<String, dynamic> responseData = json.decode(response.body);
//       final String? accessToken = responseData['access_token'];
//       final Map<String, dynamic>? userData = responseData['user'];

//       if (accessToken == null) {
//         throw Exception("No access token received");
//       }

//       print("✅ Authentication successful");
      
//       // Store access token immediately
//       await _sharedPrefs.saveAccessToken(accessToken);
      
//       // Store user data - but be careful about user ID
//       if (userData != null) {
//         await _storeUserDataFromBackend(userData);
//       } else {
//         await _storeUserDataFromGoogle(googleUser);
//       }

//       await _updateUserController(googleUser, userData);
      
//       // ✅ Check if we have a valid user ID
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getString('user_id');
      
//       if (userId != null && _isValidObjectId(userId)) {
//         print("🎉 Proper User ID received: $userId");
//       } else {
//         print("⚠️ Waiting for proper User ID from backend...");
//         // Don't throw error - user can still use the app
//       }
      
//       return true;
//     } else {
//       final errorData = json.decode(response.body);
//       final errorMsg = errorData['detail'] ?? errorData['message'] ?? errorData['error'] ?? "Unknown error";
//       throw Exception("Error ${response.statusCode}: $errorMsg");
//     }
//   } catch (error) {
//     print("❌ Enhanced method error: $error");
//     rethrow;
//   }
// }



/// Store user data from backend response - UPDATED
Future<void> _storeUserDataFromBackend(Map<String, dynamic> userData) async {
  try {
    final String email = userData['email'] ?? '';
    final String fullName = userData['name'] ?? userData['full_name'] ?? '';
    final String profileImage = userData['picture'] ?? userData['profile_image_url'] ?? '';

    // Save basic user info
    await _sharedPrefs.saveUserBasicInfo(fullName, email);
    
    // Save profile image if available
    if (profileImage.isNotEmpty) {
      await _sharedPrefs.saveProfileImageUrl(profileImage);
    }

    // ✅ NEW: Store user ID from backend
    await _storeUserIdFromBackend(userData);

    // Set remember user preference and timestamps
    await _sharedPrefs.setRememberUser(true);
    await _sharedPrefs.saveLoginTimestamp();
    await _sharedPrefs.saveTokenExpiry();

    print("✅ User data stored from backend response");
  } catch (e) {
    print("Error storing user data from backend: $e");
    rethrow;
  }
}


/// Store user data from Google account (fallback) - UPDATED
Future<void> _storeUserDataFromGoogle(GoogleSignInAccount googleUser) async {
  try {
    // Use Google user data as fallback
    await _sharedPrefs.saveUserBasicInfo(
      googleUser.displayName ?? 'User',
      googleUser.email,
    );

    // Save profile image from Google
    if (googleUser.photoUrl != null) {
      await _sharedPrefs.saveProfileImageUrl(googleUser.photoUrl!);
    }
    
    // Set remember user preference and timestamps
    await _sharedPrefs.setRememberUser(true);
    await _sharedPrefs.saveLoginTimestamp();
    await _sharedPrefs.saveTokenExpiry();

    print("✅ User data stored from Google account (waiting for backend user ID)");
  } catch (e) {
    print("Error storing user data from Google: $e");
    rethrow;
  }
}




/// Verify all required user data is stored
Future<void> _verifyUserSessionCompleteness() async {
  final prefs = await SharedPreferences.getInstance();
  
  final accessToken = prefs.getString('access_token');
  final userId = prefs.getString('user_id');
  final email = prefs.getString('email');
  
  print('✅ Session Verification:');
  print('   Access Token: ${accessToken != null ? "✅" : "❌"}');
  print('   User ID: ${userId != null ? "✅ $userId" : "❌"}');
  print('   Email: ${email != null ? "✅ $email" : "❌"}');
  
  // ❌ REMOVED: Don't create emergency user IDs - wait for backend
  // This prevents 422 errors
  
  if (accessToken == null || accessToken.isEmpty) {
    throw Exception('Authentication failed - no access token');
  }
  
  // Warn if user ID is missing but don't block navigation
  if (userId == null || userId.isEmpty) {
    print('⚠️ User ID not yet available - backend may provide it later');
  }
}


/// Enhanced method to ensure all user data is properly stored
Future<void> _ensureCompleteUserSetup(GoogleSignInAccount googleUser, Map<String, dynamic>? userData) async {
  try {
    print('🔧 Ensuring complete user setup...');
    
    // 1. Store user data
    if (userData != null) {
      await _storeUserDataFromBackend(userData);
    } else {
      await _storeUserDataFromGoogle(googleUser);
    }
    
    // 2. Update UserController
    await _updateUserController(googleUser, userData);
    
    // 3. Verify everything was stored
    await _verifyUserSessionCompleteness();
    
  } catch (e) {
    print('❌ Error in user setup: $e');
    rethrow;
  }
}

/// Handle successful login - ENHANCED VERSION
Future<void> _handleSuccessfulLogin(GoogleSignInAccount googleUser, {Map<String, dynamic>? userData}) async {
  try {
    isLoading.value = true;
    
    print("🎉 Google Sign-In Successful!");
    print("👤 User: ${googleUser.displayName}");
    print("📧 Email: ${googleUser.email}");

    // ✅ ENHANCED: Ensure complete user setup
    await _ensureCompleteUserSetup(googleUser, userData);

    isLoggedIn.value = true;
    
    // ✅ DEBUG: Final verification
    await _verifyUserSessionCompleteness();
    
    // Navigate to home screen
    Get.offAllNamed(AppRoutes.home);
    
    // Show success message
    Get.snackbar(
      "Welcome!", 
      "Signed in as ${googleUser.displayName ?? 'User'}",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
    
  } catch (e) {
    print('❌ Error in successful login handling: $e');
    Get.snackbar(
      "Setup Incomplete", 
      "Please try logging in again",
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  } finally {
    isLoading.value = false;
  }
}

  // Add this method to your GoogleSignInController
Future<void> _updateUserController(GoogleSignInAccount googleUser, Map<String, dynamic>? userData) async {
  try {
    final UserController userController = Get.find<UserController>();
    
    String userName = '';
    String userEmail = googleUser.email;
    String? profileImageUrl;
    
    // Priority: Backend data > Google data > Fallback
    if (userData != null) {
      userName = userData['name'] ?? userData['full_name'] ?? googleUser.displayName ?? 'Google User';
      profileImageUrl = userData['picture'] ?? userData['profile_image_url'] ?? googleUser.photoUrl;
    } else {
      userName = googleUser.displayName ?? 'Google User';
      profileImageUrl = googleUser.photoUrl;
    }
    
    print('👤 Updating UserController with Google data:');
    print('   Name: $userName');
    print('   Email: $userEmail');
    print('   Profile Image: $profileImageUrl');
    
    // Update UserController
    await userController.updateUserFromGoogleSignIn(
      userName, 
      userEmail, 
      profileImageUrl: profileImageUrl
    );
    
  } catch (e) {
    print('❌ Error updating UserController: $e');
  }
}


// Add this method to GoogleSignInController for debugging
Future<void> debugUserData() async {
  final prefs = await SharedPreferences.getInstance();
  print('=== GOOGLE SIGN-IN DEBUG INFO ===');
  print('Access Token: ${prefs.getString('access_token')?.substring(0, 20)}...');
  print('User ID: ${prefs.getString('user_id') ?? "NULL"}');
  print('Email: ${prefs.getString('email') ?? "NULL"}');
  print('Full Name: ${prefs.getString('full_name') ?? "NULL"}');
  
  // Check if we have the minimum required data
  final hasAccessToken = prefs.getString('access_token') != null;
  final hasUserId = prefs.getString('user_id') != null;
  
  print('Has Access Token: $hasAccessToken');
  print('Has User ID: $hasUserId');
  print('Is Properly Logged In: ${hasAccessToken && hasUserId}');
  print('================================');
}

  /// Sign-Out Method
  Future<void> signOut() async {
    try {
      isLoading.value = true;

      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Clear app's local session data
      await _sharedPrefs.clearAuthData();
      await _sharedPrefs.setRememberUser(false);
      
      isLoggedIn.value = false;

      print("✅ User signed out successfully");

      // Show logout message
      Get.snackbar(
        "Signed Out", 
        "You have been signed out successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );

    } catch (error) {
      print("Error during sign-out: $error");
      Get.snackbar(
        "Sign Out Error", 
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Store authentication tokens properly
Future<void> _storeAuthTokens(String accessToken, Map<String, dynamic>? responseData) async {
  try {
    // Store access token
    await _sharedPrefs.saveAccessToken(accessToken);
    
    // ✅ FIX: Store token type (default to 'bearer' if not provided)
    final String tokenType = responseData?['token_type']?.toString().toLowerCase() ?? 'bearer';
    await _sharedPrefs.saveString('token_type', tokenType);
    
    print("✅ Auth tokens stored - Access Token: ${accessToken.substring(0, 20)}..., Token Type: $tokenType");
  } catch (e) {
    print("❌ Error storing auth tokens: $e");
  }
}
}










  // /// Store user data from backend response
  // Future<void> _storeUserDataFromBackend(Map<String, dynamic> userData) async {
  //   try {
  //     final String email = userData['email'] ?? '';
  //     final String fullName = userData['name'] ?? userData['full_name'] ?? '';
  //     final String profileImage = userData['picture'] ?? userData['profile_image_url'] ?? '';

  //     // Save basic user info
  //     await _sharedPrefs.saveUserBasicInfo(fullName, email);
      
  //     // Save profile image if available
  //     if (profileImage.isNotEmpty) {
  //       await _sharedPrefs.saveProfileImageUrl(profileImage);
  //     }

  //     // Set remember user preference and timestamps
  //     await _sharedPrefs.setRememberUser(true);
  //     await _sharedPrefs.saveLoginTimestamp();
  //     await _sharedPrefs.saveTokenExpiry();

  //     print("✅ User data stored from backend response");
  //   } catch (e) {
  //     print("Error storing user data from backend: $e");
  //     rethrow;
  //   }
  // }

// /// Enhanced backend communication with better error handling
// Future<bool> _sendTokenToBackendEnhanced(String googleIdToken, GoogleSignInAccount googleUser) async {
//   final url = Uri.parse("$baseUrl/auth/google");

//   try {
//     print("📡 Sending enhanced POST request to: $url");
    
//     // Prepare the request payload
//     final Map<String, dynamic> payload = {
//       "token": googleIdToken,
//     };

//     print("📦 Payload: ${json.encode(payload)}");

//     final response = await http.post(
//       url,
//       headers: {
//         "Content-Type": "application/json",
//       },
//       body: json.encode(payload),
//     ).timeout(Duration(seconds: 30));

//     print("📨 Backend response status: ${response.statusCode}");
//     print("📨 Backend response body: ${response.body}");

//     // Handle successful response
//     if (response.statusCode == 200 || response.statusCode == 201) {
//       final Map<String, dynamic> responseData = json.decode(response.body);
//       final String? accessToken = responseData['access_token'];
//       final Map<String, dynamic>? userData = responseData['user'];

//       if (accessToken == null) {
//         throw Exception("No access token received");
//       }

//       print("✅ Authentication successful");
      
//       // Store data
//       await _sharedPrefs.saveAccessToken(accessToken);
      
//       if (userData != null) {
//         await _storeUserDataFromBackend(userData);
//       } else {
//         await _storeUserDataFromGoogle(googleUser);
//       }

//       await _updateUserController(googleUser, userData);
      
//       // ✅ DEBUG: Verify everything was stored
//       await debugUserData();
      
//       return true;
//     } else {
//       // Parse and throw detailed error
//       final errorData = json.decode(response.body);
//       final errorMsg = errorData['detail'] ?? errorData['message'] ?? errorData['error'] ?? "Unknown error";
//       throw Exception("Error ${response.statusCode}: $errorMsg");
//     }
//   } catch (error) {
//     print("❌ Enhanced method error: $error");
//     rethrow;
//   }
// }




// /// Alternative method with more user data
// Future<bool> _sendTokenToBackendEnhanced(String googleIdToken, GoogleSignInAccount googleUser) async {
//   final url = Uri.parse("$baseUrl/auth/google");

//   try {
//     print("📡 Sending enhanced POST request to: $url");
    
//     // Prepare the request payload with additional user info
//     final Map<String, dynamic> payload = {
//       "token": googleIdToken,
//       "user_info": {
//         "email": googleUser.email,
//         "name": googleUser.displayName,
//         "photo_url": googleUser.photoUrl,
//       }
//     };

//     print("📦 Enhanced Payload: ${json.encode(payload)}");

//     final response = await http.post(
//       url,
//       headers: {
//         "Content-Type": "application/json",
//       },
//       body: json.encode(payload),
//     ).timeout(Duration(seconds: 30));

//     print("📨 Backend response status: ${response.statusCode}");
//     print("📨 Backend response body: ${response.body}");

//     // Handle successful response
//     if (response.statusCode == 200 || response.statusCode == 201) {
//       final Map<String, dynamic> responseData = json.decode(response.body);
//       final String? accessToken = responseData['access_token'];
//       final Map<String, dynamic>? userData = responseData['user'];

//       if (accessToken == null) {
//         throw Exception("No access token received");
//       }

//       print("✅ Authentication successful");
      
//       // Store data
//       await _sharedPrefs.saveAccessToken(accessToken);
      
//       if (userData != null) {
//         await _storeUserDataFromBackend(userData);
//       } else {
//         await _storeUserDataFromGoogle(googleUser);
//       }

//       await _updateUserController(googleUser, userData);
//       return true;
//     } else {
//       // Parse and throw detailed error
//       final errorData = json.decode(response.body);
//       final errorMsg = errorData['detail'] ?? errorData['message'] ?? errorData['error'] ?? "Unknown error";
//       throw Exception("Error ${response.statusCode}: $errorMsg");
//     }
//   } catch (error) {
//     print("❌ Enhanced method error: $error");
//     rethrow;
//   }
// }



//   /// Store user data from Google account (fallback) - UPDATED
// Future<void> _storeUserDataFromGoogle(GoogleSignInAccount googleUser) async {
//   try {
//     // Use Google user data as fallback
//     await _sharedPrefs.saveUserBasicInfo(
//       googleUser.displayName ?? 'User',
//       googleUser.email,
//     );

//     // Save profile image from Google
//     if (googleUser.photoUrl != null) {
//       await _sharedPrefs.saveProfileImageUrl(googleUser.photoUrl!);
//     }

//     // ✅ NEW: Generate a temporary user ID for Google users
//     // This ensures vehicle operations work until backend provides proper ID
//     final tempUserId = "google_${DateTime.now().millisecondsSinceEpoch}";
//     await _sharedPrefs.saveUserId(tempUserId);
//     print("⚠️ Using temporary user ID for Google user: $tempUserId");

//     // Set remember user preference and timestamps
//     await _sharedPrefs.setRememberUser(true);
//     await _sharedPrefs.saveLoginTimestamp();
//     await _sharedPrefs.saveTokenExpiry();

//     print("✅ User data stored from Google account");
//   } catch (e) {
//     print("Error storing user data from Google: $e");
//     rethrow;
//   }
// }




  // /// Store user data from Google account (fallback)
  // Future<void> _storeUserDataFromGoogle(GoogleSignInAccount googleUser) async {
  //   try {
  //     // Use Google user data as fallback
  //     await _sharedPrefs.saveUserBasicInfo(
  //       googleUser.displayName ?? 'User',
  //       googleUser.email,
  //     );

  //     // Save profile image from Google
  //     if (googleUser.photoUrl != null) {
  //       await _sharedPrefs.saveProfileImageUrl(googleUser.photoUrl!);
  //     }

  //     // Set remember user preference and timestamps
  //     await _sharedPrefs.setRememberUser(true);
  //     await _sharedPrefs.saveLoginTimestamp();
  //     await _sharedPrefs.saveTokenExpiry();

  //     print("✅ User data stored from Google account");
  //   } catch (e) {
  //     print("Error storing user data from Google: $e");
  //     rethrow;
  //   }
  // }



//   /// Handle successful login
// Future<void> _handleSuccessfulLogin(GoogleSignInAccount googleUser, {Map<String, dynamic>? userData}) async {
//   isLoggedIn.value = true;
  
//   print("🎉 Google Sign-In Successful!");
//   print("👤 User: ${googleUser.displayName}");
//   print("📧 Email: ${googleUser.email}");

//   // Update UserController with Google user data
//   await _updateUserController(googleUser, userData);

//   // Navigate to home screen
//   Get.offAllNamed(AppRoutes.home);
  
//   // Show success message
//   Get.snackbar(
//     "Welcome!", 
//     "Signed in as ${googleUser.displayName ?? 'User'}",
//     snackPosition: SnackPosition.BOTTOM,
//     backgroundColor: Colors.green,
//     colorText: Colors.white,
//     duration: Duration(seconds: 3),
//   );
// }




// // ENHANCED: Better user ID extraction
// Future<void> _storeUserIdFromBackend(Map<String, dynamic> userData) async {
//   try {
//     print('🔍 Extracting user ID from backend response...');
//     print('🔍 Full userData: $userData');
    
//     // Try multiple possible keys for user ID
//     final String? userId = userData['_id'] ?? 
//                           userData['id'] ?? 
//                           userData['user_id'] ?? 
//                           userData['userId'] ??
//                           userData['sub'];
    
//     if (userId != null && userId.isNotEmpty) {
//       await _sharedPrefs.saveUserId(userId);
//       print("✅ User ID stored: $userId");
//     } else {
//       print("❌ No user ID found in backend response. Available keys: ${userData.keys}");
      
//       // Create a fallback user ID using email
//       final String? userEmail = userData['email'];
//       if (userEmail != null && userEmail.isNotEmpty) {
//         final fallbackUserId = "google_${userEmail.replaceAll('@', '_').replaceAll('.', '_')}";
//         await _sharedPrefs.saveUserId(fallbackUserId);
//         print("⚠️ Using fallback user ID: $fallbackUserId");
//       } else {
//         print("❌ Cannot create fallback - no email available");
//       }
//     }
//   } catch (e) {
//     print("❌ Error storing user ID: $e");
    
//     // Last resort fallback
//     final emergencyUserId = "google_emergency_${DateTime.now().millisecondsSinceEpoch}";
//     await _sharedPrefs.saveUserId(emergencyUserId);
//     print("🚨 Using emergency user ID: $emergencyUserId");
//   }
// }


// // Add this method to your GoogleSignInController
// Future<void> _storeUserIdFromBackend(Map<String, dynamic> userData) async {
//   try {
//     // Extract user ID from backend response
//     final String? userId = userData['_id'] ?? userData['id'] ?? userData['user_id'];
    
//     if (userId != null && userId.isNotEmpty) {
//       await _sharedPrefs.saveUserId(userId);
//       print("✅ User ID stored: $userId");
//     } else {
//       print("⚠️ No user ID found in backend response");
//     }
//   } catch (e) {
//     print("❌ Error storing user ID: $e");
//   }
// }






// /// Handle successful login - UPDATED WITH DEBUGNEWWWWWWW
// Future<void> _handleSuccessfulLogin(GoogleSignInAccount googleUser, {Map<String, dynamic>? userData}) async {
//   isLoggedIn.value = true;
  
//   print("🎉 Google Sign-In Successful!");
//   print("👤 User: ${googleUser.displayName}");
//   print("📧 Email: ${googleUser.email}");

//   // ✅ DEBUG: Check what data we have
//   await debugUserData();

//   // Update UserController with Google user data
//   await _updateUserController(googleUser, userData);

//   // Navigate to home screen
//   Get.offAllNamed(AppRoutes.home);
  
//   // Show success message
//   Get.snackbar(
//     "Welcome!", 
//     "Signed in as ${googleUser.displayName ?? 'User'}",
//     snackPosition: SnackPosition.BOTTOM,
//     backgroundColor: Colors.green,
//     colorText: Colors.white,
//     duration: Duration(seconds: 3),
//   );
// }

  // /// Main Sign-In Method with comprehensive error handling
  // Future<void> signInWithGoogle() async {
  //   try {
  //     isLoading.value = true;
  //     print("🔄 Starting Google Sign-In process...");

  //     // Check platform support
  //     if (!await _checkGoogleSignInSupport()) {
  //       throw Exception("Google Sign-In not supported on this platform");
  //     }

  //     // Initialize if needed
  //     if (_googleSignIn == null) {
  //       _initializeGoogleSignIn();
  //     }

  //     print("1️⃣ Triggering Google sign-in UI...");
      
  //     // 1. Trigger Google sign-in flow
  //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

  //     if (googleUser == null) {
  //       print("❌ User cancelled Google Sign-In");
  //       isLoading.value = false;
  //       return;
  //     }

  //     print("✅ Google user obtained: ${googleUser.email}");

  //     print("2️⃣ Getting authentication tokens...");
  //     // 2. Get authentication object
  //     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  //     // 3. Get the idToken (this is what we send to backend)
  //     final String? idToken = googleAuth.idToken;
  //     final String? accessToken = googleAuth.accessToken;

  //     print("🔑 ID Token: ${idToken != null ? 'Received' : 'NULL'}");
  //     print("🔑 Access Token: ${accessToken != null ? 'Received' : 'NULL'}");

  //     if (idToken == null) {
  //       throw Exception("Google ID Token was null - authentication failed");
  //     }

  //     print("3️⃣ Sending token to backend...");
  //     // 4. Send token to backend for verification
  //     final bool loginSuccess = await _sendTokenToBackend(idToken, googleUser);

  //     if (loginSuccess) {
  //       await _handleSuccessfulLogin(googleUser);
  //     } else {
  //       throw Exception("Backend authentication failed");
  //     }

  //   } catch (error) {
  //     print("❌ Error during Google Sign-In: $error");
  //     print("❌ Error type: ${error.runtimeType}");
  //     print("❌ Stack trace: ${error.toString()}");
      
  //     // Enhanced error handling
  //     String errorMessage = "Unable to sign in with Google. Please try again.";
      
  //     if (error.toString().contains('MissingPluginException')) {
  //       errorMessage = "Google Sign-In is not available on this device. Please check if Google Play Services are installed.";
  //     } else if (error.toString().contains('network') || error.toString().contains('SocketException')) {
  //       errorMessage = "Network error. Please check your internet connection.";
  //     } else if (error.toString().contains('sign_in_failed') || error.toString().contains('sign_in_canceled')) {
  //       errorMessage = "Google Sign-In was cancelled or failed. Please try again.";
  //     } else if (error.toString().contains('INVALID_CREDENTIALS')) {
  //       errorMessage = "Invalid Google account credentials. Please check your account.";
  //     }
      
  //     Get.snackbar(
  //       "Sign In Failed", 
  //       errorMessage,
  //       snackPosition: SnackPosition.BOTTOM,
  //       backgroundColor: Colors.red,
  //       colorText: Colors.white,
  //       duration: Duration(seconds: 5),
  //     );
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }



/// Send token to backend and handle response - ENHANCED DEBUGGING VERSION
// Future<bool> _sendTokenToBackend(String googleIdToken, GoogleSignInAccount googleUser) async {
//   final url = Uri.parse("$_baseUrl/auth/google");

//   try {
//     print("📡 Sending POST request to: $url");
//     print("📦 Payload: {token: $googleIdToken}");
//     print("👤 Google User Email: ${googleUser.email}");
//     print("👤 Google User Name: ${googleUser.displayName}");

//     final response = await http.post(
//       url,
//       headers: {
//         "Content-Type": "application/json",
//       },
//       body: json.encode({
//         "token": googleIdToken,
//       }),
//     ).timeout(Duration(seconds: 30));

//     print("📨 Backend response status: ${response.statusCode}");
//     print("📨 Backend response headers: ${response.headers}");
//     print("📨 Backend response body: ${response.body}");

//     // Handle successful responses (200 OK)
//     if (response.statusCode == 200) {
//       // Success! Parse the response
//       final Map<String, dynamic> responseData = json.decode(response.body);
      
//       // Extract access token and user data
//       final String? accessToken = responseData['access_token'];
//       final Map<String, dynamic>? userData = responseData['user'];

//       if (accessToken == null) {
//         print("❌ No access token in backend response");
//         throw Exception("Authentication failed: No access token received");
//       }

//       print("✅ Backend authentication successful");
//       print("🔑 App Access Token: $accessToken");
//       print("👤 User Data: $userData");

//       // Store the backend access token
//       await _sharedPrefs.saveAccessToken(accessToken);
      
//       // Store user data - use data from backend if available, otherwise from Google
//       if (userData != null) {
//         await _storeUserDataFromBackend(userData);
//       } else {
//         await _storeUserDataFromGoogle(googleUser);
//       }

//       // Update UserController with the user data
//       await _updateUserController(googleUser, userData);

//       return true;

//     } 
//     // Handle user creation (201 Created) - if your backend uses this
//     else if (response.statusCode == 201) {
//       final Map<String, dynamic> responseData = json.decode(response.body);
//       final String? accessToken = responseData['access_token'];
//       final Map<String, dynamic>? userData = responseData['user'];

//       if (accessToken == null) {
//         print("❌ No access token in backend response (201)");
//         throw Exception("Registration failed: No access token received");
//       }

//       print("✅ New user registered successfully");
//       print("🔑 App Access Token: $accessToken");
//       print("👤 User Data: $userData");

//       // Store the backend access token
//       await _sharedPrefs.saveAccessToken(accessToken);
      
//       // Store user data
//       if (userData != null) {
//         await _storeUserDataFromBackend(userData);
//       } else {
//         await _storeUserDataFromGoogle(googleUser);
//       }

//       // Update UserController with the user data
//       await _updateUserController(googleUser, userData);

//       return true;

//     }
//     // Handle 400 Bad Request (common for validation errors)
//     else if (response.statusCode == 400) {
//       final Map<String, dynamic> errorData = json.decode(response.body);
//       final errorMsg = errorData['detail'] ?? errorData['message'] ?? errorData['error'] ?? "Bad request";
//       throw Exception("Bad request: $errorMsg");
//     }
//     // Handle 422 Validation Error
//     else if (response.statusCode == 422) {
//       final Map<String, dynamic> errorData = json.decode(response.body);
//       final errorMsg = errorData['detail'] ?? "Validation error";
//       throw Exception("Validation error: $errorMsg");
//     }
//     // Handle 500 Internal Server Error
//     else if (response.statusCode == 500) {
//       throw Exception("Server error: Please try again later");
//     }
//     // Handle all other status codes
//     else {
//       // Try to parse error message
//       try {
//         final errorData = json.decode(response.body);
//         final errorMsg = errorData['detail'] ?? errorData['message'] ?? errorData['error'] ?? "Unknown error";
//         throw Exception("Backend error (${response.statusCode}): $errorMsg");
//       } catch (e) {
//         throw Exception("Backend returned status ${response.statusCode}: ${response.body}");
//       }
//     }
//   } catch (error) {
//     print("❌ Error sending token to backend: $error");
//     print("❌ Error type: ${error.runtimeType}");
//     rethrow;
//   }
// }



// /// Send token to backend and handle response
// Future<bool> _sendTokenToBackend(String googleIdToken, GoogleSignInAccount googleUser) async {
//   final url = Uri.parse("$_baseUrl/auth/google");

//   try {
//     print("📡 Sending POST request to: $url");
//     print("📦 Payload: {token: $googleIdToken}");

//     final response = await http.post(
//       url,
//       headers: {
//         "Content-Type": "application/json",
//       },
//       body: json.encode({
//         "token": googleIdToken,
//       }),
//     ).timeout(Duration(seconds: 30));

//     print("📨 Backend response status: ${response.statusCode}");
//     print("📨 Backend response body: ${response.body}");

//     if (response.statusCode == 200) {
//       // Success! Parse the response
//       final Map<String, dynamic> responseData = json.decode(response.body);
      
//       // Extract access token and user data
//       final String? accessToken = responseData['access_token'];
//       final Map<String, dynamic>? userData = responseData['user'];

//       if (accessToken == null) {
//         print("❌ No access token in backend response");
//         return false;
//       }

//       print("✅ Backend authentication successful");
//       print("🔑 App Access Token: $accessToken");
//       print("👤 User Data: $userData");

//       // Store the backend access token
//       await _sharedPrefs.saveAccessToken(accessToken);
      
//       // Store user data - use data from backend if available, otherwise from Google
//       if (userData != null) {
//         await _storeUserDataFromBackend(userData);
//       } else {
//         await _storeUserDataFromGoogle(googleUser);
//       }

//       // Update UserController with the user data
//       await _updateUserController(googleUser, userData);

//       return true;

//     } else if (response.statusCode == 201) {
//       // Handle 201 Created (new user registered)
//       final Map<String, dynamic> responseData = json.decode(response.body);
//       final String? accessToken = responseData['access_token'];
//       final Map<String, dynamic>? userData = responseData['user'];

//       if (accessToken == null) {
//         print("❌ No access token in backend response (201)");
//         return false;
//       }

//       print("✅ New user registered successfully");
//       print("🔑 App Access Token: $accessToken");
//       print("👤 User Data: $userData");

//       // Store the backend access token
//       await _sharedPrefs.saveAccessToken(accessToken);
      
//       // Store user data
//       if (userData != null) {
//         await _storeUserDataFromBackend(userData);
//       } else {
//         await _storeUserDataFromGoogle(googleUser);
//       }

//       // Update UserController with the user data
//       await _updateUserController(googleUser, userData);

//       return true;

//     } else {
//       // Handle backend errors
//       print("❌ Backend login failed. Status: ${response.statusCode}");
      
//       // Try to parse error message
//       try {
//         final errorData = json.decode(response.body);
//         final errorMsg = errorData['detail'] ?? errorData['message'] ?? errorData['error'] ?? response.body;
//         throw Exception("Backend error: $errorMsg");
//       } catch (e) {
//         throw Exception("Backend returned status ${response.statusCode}");
//       }
//     }
//   } catch (error) {
//     print("❌ Error sending token to backend: $error");
//     rethrow;
//   }
// }



















// import 'dart:convert';
// import 'package:fixibot_app/routes/app_routes.dart';
// import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:http/http.dart' as http;

// class GoogleSignInController extends GetxController {
//   final SharedPrefsHelper _sharedPrefs = SharedPrefsHelper();
//   final isLoading = false.obs;
//   final isLoggedIn = false.obs;

//   // Your WebApp Client ID (from Google API Console)
//   static const String _serverClientId = 
//       "322656333921-71gd3s8sckaacb7mj5cshq5ftg48fqjr.apps.googleusercontent.com";

//   // Your backend base URL
//   static const String _baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";

//   late GoogleSignIn _googleSignIn;

//   @override
//   void onInit() {
//     super.onInit();
//     _initializeGoogleSignIn();
//     _checkExistingLogin();
//   }

//   /// Initialize Google Sign-In
//   void _initializeGoogleSignIn() {
//     try {
//       _googleSignIn = GoogleSignIn(
//         serverClientId: _serverClientId,
//         scopes: ['email', 'profile'],
//       );
//       print("✅ Google Sign-In initialized successfully");
//     } catch (e) {
//       print("❌ Error initializing Google Sign-In: $e");
//     }
//   }

//   /// Check if user is already logged in
//   Future<void> _checkExistingLogin() async {
//     try {
//       final isUserLoggedIn = await _sharedPrefs.isUserLoggedIn();
//       isLoggedIn.value = isUserLoggedIn;
      
//       if (isLoggedIn.value) {
//         print("✅ User already logged in");
//       } else {
//         print("🔐 No active session found");
//       }
//     } catch (e) {
//       print("Error checking login status: $e");
//     }
//   }

//   /// Main Sign-In Method with better error handling
//   Future<void> signInWithGoogle() async {
//     try {
//       isLoading.value = true;

//       // Re-initialize if needed
//       if (_googleSignIn == null) {
//         _initializeGoogleSignIn();
//       }

//       print("🔄 Starting Google Sign-In flow...");

//       // 1. Trigger Google sign-in flow
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

//       if (googleUser == null) {
//         // User cancelled the sign-in
//         print("Google Sign-In cancelled by user.");
//         isLoading.value = false;
//         return;
//       }

//       print("✅ Google user obtained: ${googleUser.email}");

//       // 2. Get authentication object
//       final GoogleSignInAuthentication googleAuth = 
//           await googleUser.authentication;

//       // 3. Get the idToken (this is what we send to backend)
//       final String? idToken = googleAuth.idToken;

//       if (idToken == null) {
//         throw Exception("Google idToken was null - authentication failed");
//       }

//       print("🔑 Google ID Token received");

//       // 4. Send token to backend for verification
//       final bool loginSuccess = await _sendTokenToBackend(idToken, googleUser);

//       if (loginSuccess) {
//         await _handleSuccessfulLogin(googleUser);
//       } else {
//         throw Exception("Backend authentication failed");
//       }

//     } catch (error) {
//       print("Error during Google Sign-In: $error");
      
//       // Show user-friendly error message
//       String errorMessage = "Unable to sign in with Google. Please try again.";
      
//       if (error.toString().contains('MissingPluginException')) {
//         errorMessage = "Google Sign-In is not available on this device. Please check your app configuration.";
//       } else if (error.toString().contains('network')) {
//         errorMessage = "Network error. Please check your internet connection.";
//       } else if (error.toString().contains('sign_in_failed')) {
//         errorMessage = "Google Sign-In failed. Please try again.";
//       }
      
//       Get.snackbar(
//         "Sign In Failed", 
//         errorMessage,
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         duration: Duration(seconds: 5),
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// Send token to backend and handle response
//   Future<bool> _sendTokenToBackend(String googleIdToken, GoogleSignInAccount googleUser) async {
//     final url = Uri.parse("$_baseUrl/auth/google");

//     try {
//       print("📡 Sending token to backend...");

//       final response = await http.post(
//         url,
//         headers: {
//           "Content-Type": "application/json",
//         },
//         body: json.encode({
//           "token": googleIdToken,
//         }),
//       );

//       print("📨 Backend response status: ${response.statusCode}");

//       if (response.statusCode == 200) {
//         // Success! Parse the response
//         final Map<String, dynamic> responseData = json.decode(response.body);
        
//         // Extract access token and user data
//         final String? accessToken = responseData['access_token'];
//         final Map<String, dynamic>? userData = responseData['user'];

//         if (accessToken == null) {
//           print("❌ No access token in backend response");
//           return false;
//         }

//         // Store the backend access token
//         await _sharedPrefs.saveAccessToken(accessToken);
        
//         // Store user data - use data from backend if available, otherwise from Google
//         if (userData != null) {
//           await _storeUserDataFromBackend(userData);
//         } else {
//           await _storeUserDataFromGoogle(googleUser);
//         }

//         print("✅ Backend authentication successful");
//         return true;

//       } else {
//         // Handle backend errors
//         print("❌ Backend login failed. Status: ${response.statusCode}");
//         print("Response: ${response.body}");
        
//         // Try to parse error message
//         try {
//           final errorData = json.decode(response.body);
//           final errorMsg = errorData['detail'] ?? errorData['message'] ?? response.body;
//           throw Exception("Backend error: $errorMsg");
//         } catch (e) {
//           throw Exception("Backend error: ${response.statusCode} - ${response.body}");
//         }
//       }
//     } catch (error) {
//       print("❌ Error sending token to backend: $error");
//       rethrow;
//     }
//   }

//   /// Store user data from backend response
//   Future<void> _storeUserDataFromBackend(Map<String, dynamic> userData) async {
//     try {
//       final String email = userData['email'] ?? '';
//       final String fullName = userData['name'] ?? userData['full_name'] ?? '';
//       final String profileImage = userData['picture'] ?? userData['profile_image_url'] ?? '';

//       // Save basic user info
//       await _sharedPrefs.saveUserBasicInfo(fullName, email);
      
//       // Save profile image if available
//       if (profileImage.isNotEmpty) {
//         await _sharedPrefs.saveProfileImageUrl(profileImage);
//       }

//       // Set remember user preference and timestamps
//       await _sharedPrefs.setRememberUser(true);
//       await _sharedPrefs.saveLoginTimestamp();
//       await _sharedPrefs.saveTokenExpiry();

//       print("✅ User data stored from backend response");
//     } catch (e) {
//       print("Error storing user data from backend: $e");
//       rethrow;
//     }
//   }

//   /// Store user data from Google account (fallback)
//   Future<void> _storeUserDataFromGoogle(GoogleSignInAccount googleUser) async {
//     try {
//       // Use Google user data as fallback
//       await _sharedPrefs.saveUserBasicInfo(
//         googleUser.displayName ?? 'User',
//         googleUser.email,
//       );

//       // Save profile image from Google
//       if (googleUser.photoUrl != null) {
//         await _sharedPrefs.saveProfileImageUrl(googleUser.photoUrl!);
//       }

//       // Set remember user preference and timestamps
//       await _sharedPrefs.setRememberUser(true);
//       await _sharedPrefs.saveLoginTimestamp();
//       await _sharedPrefs.saveTokenExpiry();

//       print("✅ User data stored from Google account");
//     } catch (e) {
//       print("Error storing user data from Google: $e");
//       rethrow;
//     }
//   }

//   /// Handle successful login
//   Future<void> _handleSuccessfulLogin(GoogleSignInAccount googleUser) async {
//     isLoggedIn.value = true;
    
//     print("🎉 Google Sign-In Successful!");
//     print("👤 User: ${googleUser.displayName}");
//     print("📧 Email: ${googleUser.email}");

//     // Navigate to home screen
//     Get.offAllNamed(AppRoutes.home);
    
//     // Show success message
//     Get.snackbar(
//       "Welcome!", 
//       "Signed in as ${googleUser.displayName ?? 'User'}",
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.green,
//       colorText: Colors.white,
//       duration: Duration(seconds: 3),
//     );
//   }

//   /// Sign-Out Method
//   Future<void> signOut() async {
//     try {
//       isLoading.value = true;

//       // Sign out from Google
//       await _googleSignIn.signOut();
      
//       // Clear app's local session data
//       await _sharedPrefs.clearAuthData();
//       await _sharedPrefs.setRememberUser(false);
      
//       isLoggedIn.value = false;

//       print("✅ User signed out successfully");

//       // Show logout message
//       Get.snackbar(
//         "Signed Out", 
//         "You have been signed out successfully",
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.blue,
//         colorText: Colors.white,
//         duration: Duration(seconds: 3),
//       );

//     } catch (error) {
//       print("Error during sign-out: $error");
//       Get.snackbar(
//         "Sign Out Error", 
//         error.toString(),
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// Get current user profile
//   Future<Map<String, String?>> getCurrentUserProfile() async {
//     try {
//       final String? fullName = await _sharedPrefs.getString('full_name');
//       final String? email = await _sharedPrefs.getString('email');
//       final String? profileImage = await _sharedPrefs.getProfileImageUrl();

//       return {
//         'fullName': fullName,
//         'email': email,
//         'profileImage': profileImage,
//       };
//     } catch (e) {
//       print("Error getting user profile: $e");
//       return {};
//     }
//   }

//   /// Check if user has valid session
//   Future<bool> checkAuthStatus() async {
//     final bool isValid = await _sharedPrefs.isUserLoggedIn();
//     isLoggedIn.value = isValid;
//     return isValid;
//   }
// }




























//prevv


// import 'dart:convert';
// import 'package:fixibot_app/routes/app_routes.dart';
// import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
// import 'package:get/get_navigation/src/snackbar/snackbar.dart';
// import 'package:get/get_state_manager/src/simple/get_controllers.dart';
// import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
// import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher.dart';

// class GoogleSignInController extends GetxController {
//   final _sharedPrefs = SharedPrefsHelper();
//   final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";
//   final isLoading = false.obs;

//   late GoogleSignIn _googleSignIn;

//   @override
//   void onInit() {
//     super.onInit();
//     _googleSignIn = GoogleSignIn(
//       params: GoogleSignInParams(
//         clientId: "322656333921-71gd3s8sckaacb7mj5cshq5ftg48fqjr.apps.googleusercontent.com",
//         clientSecret: "YOUR_GOOGLE_CLIENT_SECRET",  // ensure you have it
//         redirectPort: 3000,
//       ),
//     );
//   }

//   Future<void> _openUrl(Uri url) async {
//   if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
//     throw Exception("Could not launch $url");
//   }
// }

