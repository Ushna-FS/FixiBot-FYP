import '../../../constants/app_colors.dart';
import '../../auth/view/login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_fontStyles.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          children: [
            SizedBox(
              height: screenSize.height * 0.15,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                          backgroundColor: AppColors.secondaryColor,
                          radius: 30,
                          child: Image.asset(
                            "assets/icons/profileImg.png",
                            height: 300,
                            width: 300,
                          )),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          children: [
                            Text(
                              "Jasmine Rose",
                              style: AppFonts.montserratHeading,
                            ),
                            Text(
                              "email@email.com",
                              style: AppFonts.montserratText,
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  GestureDetector(
                      onTap: () {
                        //Back Button
                        Get.back();
                      },
                      child: Image.asset("assets/icons/backWhiteArrow.png"))
                ],
              ),
            ),
            SizedBox(
              height: screenSize.height * 0.1478,
            ),
            Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                      color: AppColors.textColor,
                      borderRadius:
                          BorderRadius.only(topRight: Radius.circular(250))),
                  width: screenSize.width * 1,
                  height: screenSize.height * 0.595,
                ),
                Positioned(
                    top: 100,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset("assets/icons/profile.png"),
                                SizedBox(
                                  width: screenSize.width * 0.01,
                                ),
                                Text(
                                  "My Vehicles",
                                  style: AppFonts.montserratText2,
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                            height: screenSize.height * 0.02,
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset("assets/icons/editText.png"),
                                SizedBox(
                                  width: screenSize.width * 0.01,
                                ),
                                Text(
                                  "Edit Profile",
                                  style: AppFonts.montserratText2,
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                            height: screenSize.height * 0.02,
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset("assets/icons/help.png"),
                                SizedBox(
                                  width: screenSize.width * 0.01,
                                ),
                                Text(
                                  "Help & Support",
                                  style: AppFonts.montserratText2,
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                            height: screenSize.height * 0.01,
                          ),
                        ],
                      ),
                    )),
                Positioned(
                    bottom: 40,
                    right: 20,
                    child: GestureDetector(
                      onTap: () {
                        // LogOut Button
                        Get.to(const Login());
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Logout",
                            style: AppFonts.montserratText2,
                          ),
                          SizedBox(
                            width: screenSize.width * 0.01,
                          ),
                          Image.asset("assets/icons/logout.png"),
                        ],
                      ),
                    ))
              ],
            ),
          ],
        ),
      ),
    );
  }
}
