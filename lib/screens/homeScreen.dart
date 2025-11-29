import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:fixibot_app/constants/appConfig.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/model/breakdownsModel.dart';
import 'package:fixibot_app/routes/app_routes.dart';
import 'package:fixibot_app/screens/auth/controller/shared_pref_helper.dart';
import 'package:fixibot_app/screens/chatbot/provider/chatManagerProvider.dart';
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
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
import 'package:fixibot_app/screens/viewNotifications.dart';
import 'package:fixibot_app/services/breakdown-serv.dart';
import 'package:fixibot_app/widgets/custom_buttons.dart';
import 'package:fixibot_app/widgets/home_header.dart';
import 'package:fixibot_app/widgets/navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
  void _debugBreakdownData(List<BreakdownModel> breakdowns) {
  print('🔍 DEBUG: Checking breakdown data structure');
  print('📊 Total breakdowns: ${breakdowns.length}');
  
  for (int i = 0; i < breakdowns.length; i++) {
    final breakdown = breakdowns[i];
    print('--- Breakdown $i: ${breakdown.name} ---');
    print('   Categories keys: ${breakdown.categories?.keys}');
    
    if (breakdown.categories != null) {
      for (final key in breakdown.categories!.keys) {
        print('   Category "$key": ${breakdown.categories![key] != null}');
        if (breakdown.categories![key] != null) {
          final categoryData = breakdown.categories![key] as Map<String, dynamic>;
          print('     - Steps: ${categoryData["Steps"] != null}');
          print('     - Tools: ${categoryData["Tools Required"] != null}');
          print('     - Images: ${categoryData["Images"] != null}');
        }
      }
    } else {
      print('   ❌ Categories is NULL');
    }
    print('');
  }
}
  // In your HomeScreen, update the initState method:
@override
void initState() {
  super.initState();
  futureBreakdowns = BreakdownService.loadBreakdowns();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    LocationPopup.showLocationPopup(context);
  });
  Get.find<LocationController>().fetchCurrentLocation();

  
    _initializeChatManagerIfNeeded();
    _initializeDependencies();

}

Future<void> _initializeDependencies() async {
    // Ensure dependencies are registered
    if (!Get.isRegistered<SharedPrefsHelper>()) {
      Get.put(SharedPrefsHelper(), permanent: true);
    }
    
    if (!Get.isRegistered<ChatManagerProvider>()) {
      Get.put(ChatManagerProvider(), permanent: true);
    }

    // Try to initialize chat manager if user is logged in
    final sharedPrefs = Get.find<SharedPrefsHelper>();
    final userId = await sharedPrefs.getCurrentUserId();
    
    if (userId != null && Get.isRegistered<ChatManagerProvider>()) {
      final chatManager = Get.find<ChatManagerProvider>();
      if (!chatManager.isInitialized) {
        await chatManager.initializeForUser(userId);
      }
    }
  }

  Future<void> _initializeChatManagerIfNeeded() async {
    final sharedPrefs = Get.find<SharedPrefsHelper>();
    final userId = await sharedPrefs.getCurrentUserId();
    
    if (userId != null && Get.isRegistered<ChatManagerProvider>()) {
      final chatManager = Get.find<ChatManagerProvider>();
      if (!chatManager.isInitialized) {
        await chatManager.initializeForUser(userId);
      }
    }
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
  try {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75);
    if (picked != null) {
      final imageFile = File(picked.path);
      final fileSize = await imageFile.length();
      final maxImageSize = 5 * 1024 * 1024; // 5MB
      
      // Check file size
      if (fileSize > maxImageSize) {
        Get.snackbar(
          "Image Too Large",
          "Please select an image smaller than 5MB",
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
        return;
      }
      
      print('📸 Image picked from home screen: ${picked.path}');
      
      // Update controller with the image
      userController.updateProfileImage(imageFile);
      
      // Immediately upload and save to backend
      await _uploadProfileImageFromHome(imageFile);
    }
  } catch (e) {
    print('❌ Error picking image from home: $e');
    Get.snackbar(
      "Error",
      "Failed to pick image. Please try again.",
      colorText: Colors.white,
      backgroundColor: Colors.red,
    );
  }
}


Future<void> _uploadProfileImageFromHome(File imageFile) async {
  try {
    print('🔄 Uploading profile image from home screen...');
    
    final SharedPrefsHelper _prefs = SharedPrefsHelper();
    final token = await _prefs.getString("access_token");
    if (token == null) {
      Get.snackbar("Error", "Authentication token not found");
      return;
    }
     final baseUrl  = AppConfig.baseUrl;

    // final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";
    final url = Uri.parse("$baseUrl/auth/users/me");
    final request = http.MultipartRequest("PUT", url);

    // Set headers
    request.headers["Authorization"] = "Bearer $token";
    
    // Get current user data to preserve it
    final currentName = userController.fullName.value;
    final currentEmail = userController.email.value;
    final parts = currentName.split(" ");
    final firstName = parts.isNotEmpty ? parts.first : "";
    final lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "";

    request.fields["first_name"] = firstName;
    request.fields["last_name"] = lastName;
    request.fields["email"] = currentEmail;

    // Add the image file using http prefix
    request.files.add(await http.MultipartFile.fromPath(
      "profile_picture",
      imageFile.path,
    ));

    // Show loading indicator
    Get.dialog(
      const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
           SizedBox(height: 10),
Text(
  "Updating profile picture...",
  style: TextStyle(
    color: Color.fromARGB(255, 124, 116, 202),
    fontSize: 14,
  ),
),

          ],
        ),
      ),
      barrierDismissible: false,
    );

    print("📡 Sending profile image upload request from home...");
    final response = await request.send().timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        throw TimeoutException("Image upload took too long. Please try again.");
      },
    );

    final respStr = await response.stream.bytesToString();
    print("📡 Response status: ${response.statusCode}");

    // Close loading dialog
    Get.back();

    if (response.statusCode == 200) {
      final updatedUser = json.decode(respStr);
      print("✅ Profile image updated successfully from home screen");
      
      // Handle the backend response for profile image URL
      if (updatedUser['profile_picture'] != null) {
        final imageUrl = updatedUser['profile_picture'].toString();
        print("✅ Backend returned image URL: $imageUrl");
        
        // Update controller and save to SharedPreferences
        userController.updateProfileImageUrl(imageUrl);
        
        // Clear the local file since we now have a URL
        userController.updateProfileImage(null);
        
        print("🖼️ Profile image successfully saved to persistent storage from home");
        
        // Show success message
        Get.snackbar(
          "Success",
          "Profile picture updated successfully",
          colorText: Colors.white,
          backgroundColor: AppColors.minorColor,
          duration: const Duration(seconds: 3),
        );
      }
    } else {
      print("❌ Error uploading profile image. Status: ${response.statusCode}");
      print("❌ Error response: $respStr");
      
      Get.snackbar(
        "Upload Failed",
        "Failed to update profile picture. Please try again.",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    }
  } on TimeoutException catch (e) {
    Get.back();
    print("❌ Upload timeout from home: $e");
    Get.snackbar(
      "Upload Timeout",
      "Image upload took too long. Please try with a smaller image.",
      colorText: Colors.white,
      backgroundColor: Colors.red,
    );
  } catch (e) {
    Get.back();
    print("❌ Unexpected error uploading from home: $e");
    Get.snackbar(
      "Error",
      "Failed to update profile picture. Please try again.",
      colorText: Colors.white,
      backgroundColor: Colors.red,
    );
  }
}


  // Future<void> pickImage(ImageSource source) async {
  //   final picker = ImagePicker();
  //   final picked = await picker.pickImage(source: source, imageQuality: 75);
  //   if (picked != null) {
  //     userController.updateProfileImage(File(picked.path));
  //   }
  // }

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
                // CircleAvatar(
                //   radius: 15,
                //   backgroundColor: AppColors.textColor4,
                //   backgroundImage: userController.profileImage.value != null
                //       ? FileImage(userController.profileImage.value!)
                //       : (userController.profileImageUrl.value.isNotEmpty
                //           ? NetworkImage(userController.profileImageUrl.value)
                //               as ImageProvider
                //           : null),
                //   child: userController.profileImage.value == null &&
                //           userController.profileImageUrl.value.isEmpty
                //       ? IconButton(
                //           icon: const Icon(Icons.add, size: 10),
                //           color: Colors.white,
                //           onPressed: _showImagePickerDialog,
                //         )
                //       : null,
                // ),

                // In homescreen.dart - Update the CircleAvatar in AppBar
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
      body: SingleChildScrollView(
      child: Column(
        children: [
          HomeHeaderBox(
            onRefresh: _refreshHomeHeader,
          ),
          SizedBox(height: screenHeight * 0.02),
          // In your HomeScreen, update the CarouselSlider part:
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugBreakdownData(breakdowns);
    });
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
                  // Find the breakdown and its index
                  int breakdownIndex = -1;
                  Map<String, dynamic>? issueData;
                  
                  for (int i = 0; i < breakdowns.length; i++) {
                    if (breakdowns[i].name.toLowerCase().contains(issue.toLowerCase())) {
                      breakdownIndex = i;
                      issueData = {
                        "Name": breakdowns[i].name,
                        "Categories": breakdowns[i].categories,
                      };
                      break;
                    }
                  }
                  
                  return GestureDetector(
                    onTap: () {
                      if (issueData != null && breakdownIndex != -1) {
                        print('🎯 Navigating to SelfHelpSolutions with index: $breakdownIndex');
                        Get.to(() => SelfHelpSolutions(
                          issueData: issueData!,
                          breakdownIndex: breakdownIndex, // Pass the index
                        ));
                      } else {
                        print('❌ Could not find breakdown for issue: $issue');
                        Get.snackbar(
                          "Error",
                          "No data found for $issue",
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
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