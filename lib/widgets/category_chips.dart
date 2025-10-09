import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:flutter/material.dart';

class CategoryChips extends StatelessWidget {
  final String icon;
  final String category;
  final bool isSmallScreen;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChips({
    super.key,
    required this.icon,
    required this.category,
    required this.isSmallScreen,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4.0 : 8.0),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12.0 : 16.0,
          vertical: isSmallScreen ? 8.0 : 12.0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainColor : AppColors.textColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.mainColor : AppColors.mainColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              icon,
              width: isSmallScreen ? 16 : 20,
              height: isSmallScreen ? 16 : 20,
              color: isSelected ? AppColors.textColor : AppColors.mainColor,
            ),
            SizedBox(width: isSmallScreen ? 4 : 8),
            Text(
              category,
              style: isSmallScreen
                  ? AppFonts.montserratMainText14.copyWith(
                      color: isSelected ? AppColors.textColor : AppColors.mainColor,
                      fontSize: 12,
                    )
                  : AppFonts.montserratMainText14.copyWith(
                      color: isSelected ? AppColors.textColor : AppColors.mainColor,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}