import 'package:fixibot_app/screens/location/location_controller.dart';
import '../../constants/app_fontStyles.dart';
import 'locationScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../widgets/custom_buttons.dart';

class LocationPopup {
  static void showLocationPopup(BuildContext context) {
    final LocationController locationController = Get.put(LocationController());
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Please select your default location",
                style: AppFonts.customTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textColor2,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const ImageIcon(
                      AssetImage('assets/icons/currentLocation.png'),
                      size: 24,
                      color: AppColors.mainColor),
                  const SizedBox(width: 10),
                  TextButton(
                      onPressed: () async {
                        await locationController.fetchCurrentLocation();
                        Navigator.pop(context); 
                      },
                      child: Text(
                        "Use current location",
                        style: AppFonts.customTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainColor,
                        ),
                      )),
                ],
              ),
              Row(
                children: [
                  const ImageIcon(
                      AssetImage(
                        'assets/icons/newLocation.png',
                      ),
                      size: 24,
                      color: AppColors.mainColor),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () {
                      Get.to(const LocationScreen());
                    },
                    child: Text(
                      "Add new location",
                      style: AppFonts.customTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: "Confirm Location",
                onPressed: () => Navigator.pop(context), // Close popup
              ),
            ],
          ),
        );
      },
    );
  }
}
