import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/screens/location/locationScreen.dart';
import 'package:fixibot_app/screens/location/location_controller.dart';
import 'package:fixibot_app/screens/mechanics/view/controller/mechanicController.dart';
import 'package:fixibot_app/widgets/category_chips.dart';
import 'package:fixibot_app/widgets/customAppBar.dart';
import 'package:fixibot_app/widgets/mechanic_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MechanicScreen extends GetView<MechanicController> {
  const MechanicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final bool isMediumScreen =
        screenSize.width >= 600 && screenSize.width < 1200;
    final bool isLargeScreen = screenSize.width >= 1200;
// In your MechanicScreen
final locationController = Get.find<LocationController>();
final userLat = locationController.userLatitude.value;
final userLng = locationController.userLongitude.value;

// Use them in your distance calculation
// String distanceText = "Distance N/A";
// if (userLat != 0.0 && userLng != 0.0) {
//   distanceText = "${mechanic.calculateDistance(userLat, userLng).toStringAsFixed(1)} km";
// }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.mainColor,
        title: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/icons/locationIcon.png",
                  color: AppColors.textColor,
                  width: isSmallScreen ? 20 : 24,
                  height: isSmallScreen ? 20 : 24,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: isSmallScreen
                      ? screenSize.width * 0.4
                      : screenSize.width * 0.3,
                  child: TextButton(
                    onPressed: () {
                      Get.to(LocationScreen());
                    },
                    child: Obx(() {
                      final location =
                          Get.find<LocationController>().userLocation.value;
                      return Text(
                        location.isEmpty
                            ? 'No location selected'
                            : (location.length > 20
                                ? "${location.substring(0, 20)}..."
                                : location),
                        style: isSmallScreen
                            ? AppFonts.montserratWhiteText
                            : AppFonts.montserratWhiteText
                                .copyWith(fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Image.asset(
            'assets/icons/back.png',color: AppColors.secondaryColor,
            width: isSmallScreen ? 24 : 30,
            height: isSmallScreen ? 24 : 30,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
            child: Obx(() => GestureDetector(
                  onTap: () {
                    controller.notificationSelection();
                  },
                  child: controller.isNotified.value
                      ? Image.asset(
                          "assets/icons/notification.png",
                          color: AppColors.secondaryColor,
                          width: isSmallScreen ? 24 : 30,
                          height: isSmallScreen ? 24 : 30,
                        )
                      : Image.asset(
                          "assets/icons/notification.png",
                          color: AppColors.textColor2,
                          width: isSmallScreen ? 24 : 30,
                          height: isSmallScreen ? 24 : 30,
                        ),
                )),
          )
        ],
      ),
   
      backgroundColor: AppColors.secondaryColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.mainColor,
            ),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.errorMessage.value,
                  style: AppFonts.montserratMainText14,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    controller.fetchMechanics();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isLargeScreen ? 1200 : double.infinity,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          left: isSmallScreen ? 12.0 : 24.0,
                          bottom: isSmallScreen ? 16.0 : 24.0),
                      child: Text(
                        "Breakdown Category",
                        style: isSmallScreen
                            ? AppFonts.montserratBlackHeading
                            : AppFonts.montserratBlackHeading
                                .copyWith(fontSize: 24),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CategoryChips(
                                icon: "assets/icons/engine.png",
                                category: "Engine",
                                isSmallScreen: isSmallScreen),
                            CategoryChips(
                                icon: "assets/icons/tyre.png",
                                category: "Tyre",
                                isSmallScreen: isSmallScreen),
                            CategoryChips(
                                icon: "assets/icons/brake.png",
                                category: "Brakes",
                                isSmallScreen: isSmallScreen),
                            CategoryChips(
                                icon: "assets/icons/brake.png",
                                category: "category",
                                isSmallScreen: isSmallScreen),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: isSmallScreen
                          ? screenSize.height * 0.05
                          : screenSize.height * 0.07,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: isSmallScreen ? 12.0 : 24.0,
                          bottom: isSmallScreen ? 8.0 : 16.0),
                      child: Text(
                        "Suggested Mechanics",
                        style: isSmallScreen
                            ? AppFonts.montserratBlackHeading
                            : AppFonts.montserratBlackHeading
                                .copyWith(fontSize: 24),
                      ),
                    ),
                    // In your MechanicScreen, update the MechanicCard usage:

                    if (isLargeScreen) ...[
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: controller.mechanicCategories.length,
                        itemBuilder: (context, index) {
                          final mechanic = controller.mechanicCategories[index];
                          return MechanicCard(
                            mechanic: mechanic.fullName,
                            expertise: mechanic.expertiseString,
                            phNum: mechanic.phoneNumber,
                            distance:
                                "${mechanic.calculateDistance(userLat, userLng).toStringAsFixed(1)} km", // You need user location
                            imageSource: mechanic.profilePicture,
                            rating: mechanic.yearsOfExperience > 0
                                ? "${mechanic.yearsOfExperience} yrs exp"
                                : "",
                          );
                        },
                      ),
                    ] else ...[
                      Column(
                        children: controller.mechanicCategories
                            .map((mechanic) => MechanicCard(
                                  mechanic: mechanic.fullName,
                                  expertise: mechanic.expertiseString,
                                  phNum: mechanic.phoneNumber,
                                  distance:
                                      "${mechanic.calculateDistance(userLat, userLng).toStringAsFixed(1)} km", // You need user location
                                  imageSource: mechanic.profilePicture,
                                  rating: mechanic.yearsOfExperience > 0
                                      ? "${mechanic.yearsOfExperience} yrs exp"
                                      : "",
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
