import 'package:carousel_slider/carousel_slider.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/screens/mechanics/view/mechanicsScreen.dart';
import 'package:fixibot_app/screens/profile/view/profile.dart';
import 'package:fixibot_app/screens/searchScreen.dart';
import 'package:fixibot_app/screens/selfHelpSolutionScreen.dart';
import 'package:fixibot_app/widgets/custom_buttons.dart';
import 'package:fixibot_app/widgets/home_header.dart';
import 'package:fixibot_app/widgets/navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:fixibot_app/screens/location/location_popup.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  int _selectedIndex = 0;

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
      Get.to(MechanicScreen()); 
      break;
    case 3:
      Get.to(const ProfileScreen());
      break;
  }
}

  final List<List<String>> issuesList = [
    ["Flat Tire", "Engine Overheat", "Weak AC", "Strange Noises"],
    ["Battery Issues", "Brake Failure", "Oil Leak", "Transmission Fault"]
  ];

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 10), () {
      LocationPopup.showLocationPopup(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    

      appBar: AppBar(
  backgroundColor: AppColors.mainColor, 
  elevation: 0,
  automaticallyImplyLeading: false, 
  title: Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      const CircleAvatar(radius: 20),
      Image.asset("assets/icons/locationIcon.png", color: AppColors.textColor),
      Text(
        'COMSATS UNIVERSITY ISLAMABAD',
        style: AppFonts.montserratHomeAppbar, 
      ),
      Image.asset("assets/icons/notification.png", color: AppColors.textColor),
    ],
  ),
),

      body: SingleChildScrollView(
        child: Column(
          
          children: [
            HomeHeaderBox(),
            const SizedBox(height: 20),
            Container(
              height: 215,
              margin: const EdgeInsets.symmetric(horizontal: 18,),
              padding: const EdgeInsets.all(4),
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
                  const SizedBox(height: 10),
            

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
      spacing: 15,
      runSpacing: 20,
      children: issues.map((issue) => GestureDetector(
            onTap: () {
              Get.to(() => SelfHelpSolutions()); 
            },
            child: Container(
              height: 48,
              width: 105,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0x4DA4A1A1), width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                issue,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          )).toList(),
    );
  }).toList(),
),





const SizedBox(height: 4),

DotsIndicator(
                    dotsCount: issuesList.length,
                    position: currentIndex.toDouble(),
                    decorator: DotsDecorator(
                      activeColor: AppColors.mainColor,
                      color: Colors.grey,
                      activeSize: const Size(10.0, 10.0),
                      size: const Size(8.0, 8.0),
                      spacing: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                    ),
                  ),
        
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              "Find Mechanic",
              "Locate expert mechanics nearby, fast and hassle-free.",
              "assets/images/MechanicIllustration.png",
              () {
                Get.to(MechanicScreen());
              },
              buttonText: "Find Now", 
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              "Add Your Vehicle",
              "Save details for quick fixes and smart assistance.",
              "assets/images/AddVeh-illustration.png",
              () {
                Get.to(MechanicScreen());
              },
              buttonText: "Add Vehicle", 
            
            ),
            const SizedBox(height: 20,)
          ],
        ),
      ),
      bottomNavigationBar:CustomNavBar(  currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,)
    );
  
  }

  Widget _buildInfoCard(
      String title, String description, String imagePath, VoidCallback onPressed,
      {String buttonText = "Click"}) {
    return Container(
    
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      height:150,
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
                const SizedBox(height: 5),
                Text(description,style: AppFonts.montserratHomecardText2,),
                const SizedBox(height: 10),

                CustomHomeButton(
                  
                  text: buttonText,
                  icon: const Icon(
                    Icons.arrow_circle_right_outlined,
                    color: AppColors.mainColor,
                  ), // Use dynamic button text
                  onPressed: onPressed,
                  color: const Color(0xFFFFF4F2),
                  textColor:AppColors.mainColor,
                  isOutlined: false,
                  
                ),
                
              ],
            ),
          ),
          const SizedBox(width: 10),
          Image.asset(imagePath, width: 115,height: 160,),
        ],
      ),
    
    );
  }
  
}
