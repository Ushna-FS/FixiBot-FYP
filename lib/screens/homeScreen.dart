import 'package:carousel_slider/carousel_slider.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/screens/location/locationScreen.dart';
import 'package:fixibot_app/screens/mechanics/view/mechanicsScreen.dart';
import 'package:fixibot_app/screens/profile/view/profile.dart';
import 'package:fixibot_app/screens/search/searchScreen.dart';
import 'package:fixibot_app/screens/selfHelpSolutionScreen.dart';
import 'package:fixibot_app/screens/vehicle/view/addVehicle.dart';
import 'package:fixibot_app/screens/viewNotifications.dart';
import 'package:fixibot_app/widgets/custom_buttons.dart';
import 'package:fixibot_app/widgets/home_header.dart';
import 'package:fixibot_app/widgets/navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:fixibot_app/screens/location/location_popup.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  int _selectedIndex = 0;
  var location = 'COMSATS UNIVERSITY ISLAMABAD'.obs;
 int currentIndex = 0;
  final List<List<String>> issuesList = [
    ["Flat Tire", "Engine Overheat", "Weak AC", "Strange Noises"],
    ["Battery Issues", "Brake Failure", "Oil Leak", "Transmission Fault"]
  ];

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Get.offAll(const HomeScreen());
        break;
      case 1:
        Get.to(const SearchScreen());
        break;
      case 2:
        Get.to(const MechanicScreen());
        break;
      case 3:
        Get.to(const ProfileScreen());
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAndShowPopup();
  }

  void _checkAndShowPopup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTimeHome') ?? true;

    if (isFirstTime) {
      Future.delayed(const Duration(seconds: 5), () {
        LocationPopup.showLocationPopup(context);
      });
      await prefs.setBool('isFirstTimeHome', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.mainColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const CircleAvatar(radius: 20),
              Image.asset("assets/icons/locationIcon.png",
                  color: AppColors.textColor),
              TextButton(
                  onPressed: () {
                    Get.to(LocationScreen());
                  },
                  child: Text(
                     (location.value.length > 16)
                      ? "${location.value.substring(0, 20)}..."
                      : location.value,
                  style: AppFonts.montserratHomeAppbar,
                  maxLines: 1,
                  )),
              IconButton(
                onPressed: () {
                  Get.to(const ViewNotificationsScreen());
                },
                icon: Image.asset('assets/icons/notification.png',
                    width: 30, height: 30, color: AppColors.textColor),
              ),
            ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const HomeHeaderBox(),
            SizedBox(height: screenHeight * 0.02),
            Container(
              height: screenHeight * 0.28,
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              padding: EdgeInsets.all(screenWidth * 0.01),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 20,
                    color: Color(0x1A263238),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Self Help Solutions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  SizedBox(height: screenHeight * 0.01),
                  CarouselSlider(
                    options: CarouselOptions(
                      autoPlay: true,
                      enlargeCenterPage: true,
                      aspectRatio: 3,
                      onPageChanged: (index, reason) {
                        setState(() {
                          currentIndex = index;
                        });
                      },
                    ),
                    items: issuesList.map((issues) {
                      return Wrap(
                        spacing: screenWidth * 0.04,
                        runSpacing: screenHeight * 0.02,
                        children: issues.map((issue) => GestureDetector(
                          onTap: () {
                            Get.to(() => SelfHelpSolutions(issueTitle: issue));
                          },
                          child: Container(
                            height: screenHeight * 0.06,
                            width: screenWidth * 0.3,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0x4DA4A1A1),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              issue,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )).toList(),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  DotsIndicator(
                    dotsCount: issuesList.length,
                    position: currentIndex.toDouble(),
                    decorator: const DotsDecorator(
                      activeColor: AppColors.mainColor,
                      color: Colors.grey,
                      activeSize: Size(10.0, 10.0),
                      size: Size(8.0, 8.0),
                      spacing: EdgeInsets.fromLTRB(4, 0, 4, 0),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.035),
            _buildInfoCard(
              "Find Mechanic",
              "Locate expert mechanics nearby, fast and hassle-free.",
              "assets/images/MechanicIllustration.png",
              () {
                Get.to(const MechanicScreen());
              },
              buttonText: "Find Now",
            ),
            SizedBox(height: screenHeight * 0.025),
            _buildInfoCard(
              "Add Your Vehicle",
              "Save details for quick fixes and smart assistance.",
              "assets/images/AddVeh-illustration.png",
              () {
                Get.to(const AddVehicle());
              },
              buttonText: "Add Vehicle",
            ),
            SizedBox(height: screenHeight * 0.025),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String description,
    String imagePath,
    VoidCallback onPressed, {
    String buttonText = "Click",
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      padding: EdgeInsets.all(screenWidth * 0.04),
      height: screenHeight * 0.2,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            color: Color(0x1A263238),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.montserrathomecardText,
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  description,
                  style: AppFonts.montserratHomecardText2,
                ),
                SizedBox(height: screenHeight * 0.015),
                CustomHomeButton(
                  text: buttonText,
                  icon: const Icon(
                    Icons.arrow_circle_right_outlined,
                    color: AppColors.mainColor,
                  ),
                  onPressed: onPressed,
                  color: const Color(0xFFFFF4F2),
                  textColor: AppColors.mainColor,
                  isOutlined: false,
                ),
              ],
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Image.asset(
            imagePath,
            width: screenWidth * 0.3,
            height: screenHeight * 0.22,
          ),
        ],
      ),
    );
  }
} 