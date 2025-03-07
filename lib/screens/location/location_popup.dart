import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:flutter/material.dart';

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
        return Padding(
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
                  IconButton(
                    onPressed: () {},
                    icon: Image.asset(
                      'assets/icons/currentLocation.png',
                      width: 16,
                      height: 19,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Use current location",
                    style: AppFonts.customTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Image.asset(
                      'assets/icons/newLocation.png',
                      width: 16,
                      height: 19,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Add new location",
                    style: AppFonts.customTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainColor,
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
