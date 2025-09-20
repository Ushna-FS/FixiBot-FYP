import 'package:fixibot_app/screens/self-helpguide/breakdownDetailedSteps.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_fontStyles.dart';

class SelfHelpSolutions extends StatelessWidget {
  final Map<String, dynamic> issueData; // Pass full JSON object

  const SelfHelpSolutions({Key? key, required this.issueData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final issueName = issueData['Name'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.secondaryColor,
        title: Text(
          issueName,
          style: AppFonts.customTextStyle(
            fontSize: 20,
            color: AppColors.mainColor,
            fontWeight: FontWeight.bold,
          ),),
         leading: IconButton(
                    onPressed: () {
                      Get.back();
                    }, 
                    icon: Image.asset('assets/icons/back.png',
                    width: 30,
                    height:30),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: AppColors.secondaryColor,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Select Vehicle Type",
                  style: AppFonts.customTextStyle(
                    color: AppColors.textColor2,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
        
                // Generate buttons for Car / Bike / Truck
                ...["Car", "Bike", "Truck"].map((type) {
                  final categoryData = issueData["Categories"][type];
        
                  // Extract first image from "Images"
                  String? imagePath;
                  if (categoryData != null && categoryData["Images"] != null) {
                    final imagesMap = categoryData["Images"] as Map<String, dynamic>;
                    if (imagesMap.isNotEmpty) {
                      imagePath = imagesMap.values.first; 
                    }
                  }
        
                  return GestureDetector(
                    onTap: () {
                      if (categoryData != null) {
                        Get.to(() => BreakdownDetailScreen(
                              issueName: issueName,
                              vehicleType: type,
                              details: categoryData,
                            ));
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Category Box
                        Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.mainColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                type,
                                style: AppFonts.customTextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  color: Colors.white, size: 18),
                            ],
                          ),
                        ),
        
                       if (imagePath != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, left: 10.0, right: 10.0),
            child: Image.asset(
        imagePath,
        height: MediaQuery.of(context).size.height / 3, // 🔹 1/3 of screen height
        width: MediaQuery.of(context).size.width - 20,  // 🔹 full width minus 10px padding on each side
        fit: BoxFit.cover, // scales & crops nicely
            ),
          ),
        
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

