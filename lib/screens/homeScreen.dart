import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/model/breakdownsModel.dart';
import 'package:fixibot_app/routes/app_routes.dart';
import 'package:fixibot_app/screens/feedback/controller/feedbackController.dart';
import 'package:fixibot_app/screens/feedback/view/feedback_popup.dart';
import 'package:fixibot_app/screens/location/locationScreen.dart';
import 'package:fixibot_app/screens/location/location_controller.dart';
import 'package:fixibot_app/screens/location/location_popup.dart';
import 'package:fixibot_app/screens/mechanics/controller/mechanicController.dart';
import 'package:fixibot_app/screens/mechanics/view/mechanicsScreen.dart';
import 'package:fixibot_app/screens/profile/controller/userController.dart';
import 'package:fixibot_app/screens/profile/view/profile.dart';
import 'package:fixibot_app/screens/search/searchScreen.dart';
import 'package:fixibot_app/screens/self-helpguide/selfHelpSolutionScreen.dart';
import 'package:fixibot_app/screens/vehicle/view/addVehicle.dart';
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart'; // ADD THIS
import 'package:fixibot_app/screens/viewNotifications.dart';
import 'package:fixibot_app/services/breakdown-serv.dart';
import 'package:fixibot_app/widgets/custom_buttons.dart';
import 'package:fixibot_app/widgets/home_header.dart';
import 'package:fixibot_app/widgets/navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  final FeedbackController feedbackController = Get.put(FeedbackController());
  int _selectedIndex = 0;
  int currentIndex = 0;
  final Rx<File?> image = Rx<File?>(null);

  final LocationController locationController = Get.put(LocationController());

  late Future<List<BreakdownModel>> futureBreakdowns;
  final userController = Get.put(UserController());

  final List<List<String>> issuesList = [
    [
      "Flat Tire",
      "Battery Failure",
      "Engine Overheat",
      "Brake failure",
    ],
    [
      "Fuel Leakage",
      "Clutch Failure",
      "Starter Motor Failure",
      "Indicator Failure"
    ]
  ];
  
  void _initializeFeedbackCheck() async {
  await Future.delayed(Duration(seconds: 3));
  print('🏠 [HOME] Initializing feedback check for pending services...');
  
  // Use the new method that accepts pending services
  final feedbackController = Get.find<FeedbackController>();
 feedbackController.checkForPendingServicesFeedback();
}

  @override
  void initState() {
    super.initState();
    futureBreakdowns = BreakdownService.loadBreakdowns();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationPopup.showLocationPopup(context);
    });
    Get.find<LocationController>().fetchCurrentLocation();

    _initializeFeedbackCheck();
  }

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
        final locationController = Get.find<LocationController>();
        final mechanicController = Get.find<MechanicController>();

        if (locationController.userLatitude.value != 0.0 &&
            locationController.userLongitude.value != 0.0) {
          mechanicController.updateUserLocation(
            locationController.userLatitude.value,
            locationController.userLongitude.value,
          );
        }

        Get.to(const MechanicScreen());
        break;
      case 3:
        Get.to(const ProfileScreen());
        break;
    }
  }

  void _checkAndShowPopup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTimeHome') ?? true;

    if (isFirstTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        LocationPopup.showLocationPopup(context);
      });
      await prefs.setBool('isFirstTimeHome', true);
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75);
    if (picked != null) {
      userController.updateProfileImage(File(picked.path));
    }
  }

  void _showImagePickerDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("Select Image Source"),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              pickImage(ImageSource.camera);
            },
            child: const Text("Camera"),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              pickImage(ImageSource.gallery);
            },
            child: const Text("Gallery"),
          ),
        ],
      ),
    );
  }

  void _refreshHomeHeader() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.mainColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.textColor4,
                  backgroundImage: userController.profileImage.value != null
                      ? FileImage(userController.profileImage.value!)
                      : (userController.profileImageUrl.value.isNotEmpty
                          ? NetworkImage(userController.profileImageUrl.value)
                              as ImageProvider
                          : null),
                  child: userController.profileImage.value == null &&
                          userController.profileImageUrl.value.isEmpty
                      ? IconButton(
                          icon: const Icon(Icons.add, size: 10),
                          color: Colors.white,
                          onPressed: _showImagePickerDialog,
                        )
                      : null,
                ),
                Image.asset("assets/icons/locationIcon.png",
                    color: AppColors.textColor),
                TextButton(
                  onPressed: () {
                    Get.to(const LocationScreen());
                  },
                  child: Obx(() {
                    final location =
                        Get.find<LocationController>().userLocation.value;
                    return Text(
                      location.isEmpty
                          ? 'No location selected'
                          : (location.length > 18
                              ? "${location.substring(0, 18)}..."
                              : location),
                      style: isSmallScreen
                          ? AppFonts.montserratWhiteText
                          : AppFonts.montserratWhiteText.copyWith(fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }),
                ),
                IconButton(
                  onPressed: () {
                    Get.to(const ViewNotificationsScreen());
                  },
                  icon: Image.asset('assets/icons/notification.png',
                      width: 30, height: 30, color: AppColors.textColor),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
          child: Column(
            children: [
              HomeHeaderBox(
                onRefresh: _refreshHomeHeader,
              ),
              SizedBox(height: screenHeight * 0.02),
              FutureBuilder<List<BreakdownModel>>(
                future: futureBreakdowns,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.mainColor));
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No breakdowns found"));
                  }
        
                  final breakdowns = snapshot.data!;
        
                  return Container(
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
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
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
                              children: issues.map((issue) {
                                return GestureDetector(
                                  onTap: () {
                                    final issueData = breakdowns.firstWhere(
                                      (b) => b.name
                                          .toLowerCase()
                                          .contains(issue.toLowerCase()),
                                    );
                                    Get.to(() => SelfHelpSolutions(issueData: {
                                          "Name": issueData.name,
                                          "Categories": issueData.categories,
                                        }));
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
                                );
                              }).toList(),
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
                  );
                },
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
                  Get.to(const AddVehicle())?.then((_) {
                    _refreshHomeHeader();
                  });
                },
                buttonText: "Add Vehicle",
              ),
              SizedBox(height: screenHeight * 0.025),
            ],
          ),
        ),
           // Feedback popup
          Obx(() {
            print('👀 [HOME] Obx - showFeedbackPopup: ${feedbackController.showFeedbackPopup.value}');
            if (feedbackController.showFeedbackPopup.value &&
                feedbackController.lastServiceForFeedback.isNotEmpty) {
              print('🎪 [HOME] RENDERING POPUP NOW!');
              return Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: FeedbackPopup(
                      service: feedbackController.lastServiceForFeedback.value,
                      controller: feedbackController,
                    ),
                  ),
                ),
              );
            }
            print('🚫 [HOME] No popup to render');
            return SizedBox.shrink();
          }),

         ]),
      
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
      height: screenHeight * 0.27,
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
