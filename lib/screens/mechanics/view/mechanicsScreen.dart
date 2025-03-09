import '../../../constants/app_colors.dart';
import '../../../constants/app_fontStyles.dart';
import 'controller/mechanicController.dart';
import '../../../widgets/category_chips.dart';
import '../../../widgets/mechanic_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MechanicScreen extends GetView<MechanicController> {
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.secondaryColor,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Row(
              children: [
                Image.asset(
                  "assets/icons/locationIcon.png",
                  color: AppColors.mainColor,
                ),
                Text(
                  (controller.location.value.length > 16)
                      ? "${controller.location.value.substring(0, 20)}..."
                      : controller.location.value,
                  style: AppFonts.montserratText4,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
        leading: GestureDetector(
          child: Image.asset("assets/icons/backArrow.png"),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() => GestureDetector(
                  onTap: () {
                    controller.notificationSelection();
                  },
                  child: controller.isNotified.value
                      ? Image.asset(
                          "assets/icons/notification.png",
                          color: AppColors.mainColor,
                        )
                      : Image.asset(
                          "assets/icons/notification.png",
                          color: AppColors.textColor2,
                        ),
                )),
          )
        ],
      ),
      backgroundColor: AppColors.secondaryColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, bottom: 16.0),
                  child: Text(
                    "Breakdown Category",
                    style: AppFonts.montserratBlackHeading,
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CategoryChips(
                          icon: "assets/icons/engine.png", category: "Engine"),
                      CategoryChips(
                          icon: "assets/icons/tyre.png", category: "Tyre"),
                      CategoryChips(
                          icon: "assets/icons/brake.png", category: "Brakes"),
                      CategoryChips(
                          icon: "assets/icons/brake.png", category: "category"),
                    ],
                  ),
                ),
                SizedBox(
                  height: screenSize.height * 0.05,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text(
                    "Suggested Mechanics",
                    style: AppFonts.montserratBlackHeading,
                  ),
                ),
                const MechanicCard(
                  mechanic: "mechanic",
                  expertise: "expertise",
                  phNum: "phNum",
                  distance: "distance",
                  imageSource: "assets/icons/mechanicShop.png",
                  rating: "4.4",
                ),
                const MechanicCard(
                  mechanic: "mechanic",
                  expertise: "expertise",
                  phNum: "phNum",
                  distance: "distance",
                  imageSource: "assets/icons/mechanicShop.png",
                  rating: "",
                ),
                const MechanicCard(
                  mechanic: "mechanic",
                  expertise: "expertise",
                  phNum: "phNum",
                  distance: "distance",
                  imageSource: "assets/icons/mechanicShop.png",
                  rating: "",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
