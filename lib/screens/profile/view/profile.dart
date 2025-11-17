import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
import 'package:fixibot_app/screens/feedback/view/feedbackHistory.dart';
import 'package:fixibot_app/screens/mechanics/view/mechanicServices.dart';
import 'package:fixibot_app/screens/profile/controller/userController.dart';
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
import 'package:fixibot_app/screens/vehicle/view/myVehicles.dart';
import 'package:fixibot_app/screens/help/support.dart';
import 'package:fixibot_app/screens/profile/editProfile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/app_colors.dart';
import '../../auth/view/login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_fontStyles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SharedPrefsHelper _sharedPrefs = SharedPrefsHelper();
  final userController = Get.find<UserController>();

  String userEmail = "email@email.com";
  String userName = 'Guest';

// In ProfileScreen.dart - Update initState to refresh data
@override
void initState() {
  super.initState();
  _loadUserInfo();
  _debugCurrentState();
  
  // Listen for login events to refresh profile data
  ever(userController.userId, (String userId) {
    if (userId.isNotEmpty) {
      print('🔄 User ID changed, refreshing profile data...');
      _loadUserInfo();
    }
  });
}

  // @override
  // void initState() {
  //   super.initState();
  //   _loadUserInfo();
  //   _debugCurrentState();
  // }

  Future<void> _loadUserInfo() async {
    print('🔄 Loading user info for profile screen...');
    final email = await _sharedPrefs.getString("email");
    final fullName = await _sharedPrefs.getString("full_name");
    final imageUrl = await _sharedPrefs.getProfileImageUrl();

    print('📥 Profile data loaded:');
    print('   - Name: $fullName');
    print('   - Email: $email');
    print('   - Image URL: $imageUrl');

    if (mounted) {
      setState(() {
        userName = (fullName != null && fullName.trim().isNotEmpty)
            ? fullName
            : "User";
        userEmail = email ?? "";
      });
    }
  }

  void _debugCurrentState() {
    print('=== Profile Screen Debug ===');
    print('UserController state:');
    userController.debugState();
    
    // Check SharedPreferences directly
    _sharedPrefs.getString("full_name").then((name) {
      print('SharedPreferences - Name: $name');
    });
    _sharedPrefs.getString("email").then((email) {
      print('SharedPreferences - Email: $email');
    });
    _sharedPrefs.getProfileImageUrl().then((url) {
      print('SharedPreferences - Image URL: $url');
    });
    print('============================');
  }



Future<void> _logout() async {
  print('🚪 Logging out...');
  
  // Get user info before clearing
  final userController = Get.find<UserController>();
  final userId = userController.userId.value;
  final rememberMe = await _sharedPrefs.getRememberUser();
  
  print('👤 Logging out user: $userId (remember me: $rememberMe)');
  
  // Clear user controller data (preserves user ID if remember me is enabled)
  await userController.clearUserData();
  
  // Clear shared preferences appropriately
  await _sharedPrefs.clearUserDataOnLogout(rememberMe);
  
  print('✅ User $userId logged out successfully');
  
  // Navigate to login
  Get.offAll(() => Login());
}





  // Future<void> _logout() async {
  //   print('🚪 Logging out...');
  //   // Clear user controller data
  //   userController.clearUserData();
  //   // Clear shared preferences
  //   await _sharedPrefs.clearAllData();
  //   // Navigate to login
  //   Get.offAll(() => Login());
  // }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          children: [
            SizedBox(height: screenSize.height * 0.15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Obx(() {
                        final hasImage = userController.profileImage.value != null || 
                                        userController.profileImageUrl.value.isNotEmpty;
                        
                        print('🖼️ Profile image state: ${hasImage ? "Has Image" : "No Image"}');
                        if (userController.profileImage.value != null) {
                          print('   - Using local image: ${userController.profileImage.value!.path}');
                        } else if (userController.profileImageUrl.value.isNotEmpty) {
                          print('   - Using network image: ${userController.profileImageUrl.value}');
                        }
                        
                        return CircleAvatar(
                          backgroundColor: AppColors.secondaryColor,
                          radius: 30,
                          backgroundImage: _getProfileImage(),
                          child: _getProfileImage() == null 
                              ? Icon(Icons.person, size: 40, color: Colors.white)
                              : null,
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (userName.length>9)
                              ? "${userName.substring(0, 9)}..."
                                  : userName,
                              maxLines: 1, style: AppFonts.montserratHeading),
                            Text(
                              (userEmail.length > 15)
                                  ? "${userEmail.substring(0, 15)}..."
                                  : userEmail,
                              maxLines: 1,
                              style: AppFonts.montserratText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  Row(
                    children: [
                      
                      GestureDetector(
                        onTap: () {
                          Get.back();
                        },
                        child: Image.asset("assets/icons/backWhiteArrow.png"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: screenSize.height * 0.1478),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.textColor,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(250)),
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Image.asset("assets/icons/profile.png"),
                      title: InkWell(
                        onTap: () {
                          Get.put(VehicleController());
                          Get.to(const MyVehicleScreen());
                        },
                        child: Text("My Vehicles",
                            style: AppFonts.montserratText2),
                      ),
                    ),
                    ListTile(
                      leading: Image.asset("assets/icons/editText.png"),
                      title: InkWell(
                        onTap: () async {
                          print('📝 Opening EditProfile...');
                          final updatedData = await Get.to(EditProfile(
                            currentName: userName,
                            currentEmail: userEmail,
                          ));
                          if (updatedData != null) {
                            print('✅ Profile updated, refreshing...');
                            _loadUserInfo(); // refresh if updated
                          }
                        },
                        child: Text("Edit Profile",
                            style: AppFonts.montserratText2),
                      ),
                    ),
                    ListTile(
                      leading: Image.asset("assets/icons/help.png"),
                      title: InkWell(
                        onTap: () => Get.to(HelpSupportPage()),
                        child: Text("Help & Support",
                            style: AppFonts.montserratText2),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.build, color: AppColors.mainColor),
                      title: InkWell(
                        onTap: () => Get.to(MechanicServicesPage()),
                        child: Text(
                          "Mechanic Services",
                          style: AppFonts.montserratText2,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.feedback, color: AppColors.mainColor),
                      title: InkWell(
                        onTap: () => Get.to(FeedbackHistoryScreen()),
                        child: Text(
                          "FeedBacks",
                          style: AppFonts.montserratText2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0, right: 20.0),
                        child: GestureDetector(
                          onTap: _logout,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset("assets/icons/logout.png"),
                              const SizedBox(width: 8),
                              Text("Logout", style: AppFonts.montserratText2),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    // Priority 1: Use local picked image (for immediate feedback)
    if (userController.profileImage.value != null) {
      return FileImage(userController.profileImage.value!);
    }
    // Priority 2: Use backend URL (for persisted images)
    else if (userController.profileImageUrl.value.isNotEmpty) {
      try {
        return NetworkImage(userController.profileImageUrl.value);
      } catch (e) {
        print('❌ Error loading network image: $e');
        return null;
      }
    }
    // Priority 3: No image available
    return null;
  }
}










