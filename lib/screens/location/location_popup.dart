import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/screens/location/locationScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../widgets/custom_buttons.dart';

class LocationPopup {
  static void showLocationPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isDismissible: false,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: EdgeInsets.all(16.0),
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
              SizedBox(height: 15),
              Row(
                children: [
                  ImageIcon(
                    AssetImage('assets/icons/currentLocation.png'),
                    size: 24,
                    color: AppColors.mainColor
                  ),
                  SizedBox(width: 10),
                  TextButton(
                      onPressed: () {},
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
                  ImageIcon(
                    AssetImage(
                      'assets/icons/newLocation.png',
                    ),
                    size: 24,
                    color: AppColors.mainColor
                  ),
                  SizedBox(width: 10),
                  TextButton(
                    onPressed: () {
                      Get.to(LocationScreen());
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
              SizedBox(height: 20),
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
