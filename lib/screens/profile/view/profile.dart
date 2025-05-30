import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
import 'package:fixibot_app/screens/vehicle/view/myVehicles.dart';
import 'package:fixibot_app/screens/help/support.dart';
import 'package:fixibot_app/screens/profile/editProfile.dart';
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

  String userEmail = "email@email.com";
  String userName = 'Guest';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = await _sharedPrefs.getUserData();
    final email = await _sharedPrefs.getUserEmail();
    if (mounted) {
      setState(() {
        userName = user?['name'] ?? 'User';
        userEmail = email ?? '';
      });
    }
  }

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
                      CircleAvatar(
                        backgroundColor: AppColors.secondaryColor,
                        radius: 30,
                        child: Image.asset(
                          "assets/icons/profileImg.png",
                          height: 300,
                          width: 300,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userName, style: AppFonts.montserratHeading),
                            Text( (userEmail.length > 12)
                      ? "${userEmail.substring(0, 15)}..."
                      : userEmail,
              
                  maxLines: 1, style: AppFonts.montserratText,),
                          ],
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: Image.asset("assets/icons/backWhiteArrow.png"),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenSize.height * 0.1478),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.textColor,
                  borderRadius:
                      BorderRadius.only(topRight: Radius.circular(250)),
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Image.asset("assets/icons/profile.png"),
                      title: InkWell(
                        onTap: () => Get.to(const MyVehicleScreen()),
                        child: Text("My Vehicles",
                            style: AppFonts.montserratText2),
                      ),
                    ),
                    ListTile(
                      leading: Image.asset("assets/icons/editText.png"),
                      title: InkWell(
                        onTap: () async {
                          // Wait for the result from EditProfile screen
                          final updatedData = await Get.to(EditProfile(
                            currentName: userName,
                            currentEmail: userEmail,
                          ));

                          // If data is returned, update the profile
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
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(bottom: 20.0, right: 20.0),
                        child: GestureDetector(
                          onTap: () => Get.to(Login()),
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
}
