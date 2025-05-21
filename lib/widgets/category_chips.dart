import '../constants/app_colors.dart';
import '../constants/app_fontStyles.dart';
import '../screens/mechanics/view/controller/mechanicController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryChips extends StatelessWidget {
  final String icon;
  final String category;
  final bool isSmallScreen;
  final MechanicController mechanicController = Get.find<MechanicController>();

  CategoryChips({
    super.key,
    required this.icon,
    required this.category,
    required this.isSmallScreen,
  });
  
  var isSelected = RxBool(false);
  
  void categorySelection() {
    if (isSelected.value == false) {
      isSelected.value = true;
      mechanicController.mechanicCategories.add(category);
    } else {
      isSelected.value = false;
      mechanicController.mechanicCategories.remove(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    
    return Obx(() => Padding(
          padding: EdgeInsets.only(
            top: 2.0, 
            left: isSmallScreen ? 10.0 : 16.0,
            right: isSmallScreen ? 0 : 8.0,
          ),
          child: GestureDetector(
            onTap: categorySelection,
            child: Container(
              decoration: BoxDecoration(
                color: isSelected.value ? AppColors.mainColor : AppColors.textColor,
                border: Border.all(
                  color: AppColors.mainColor,
                  width: isSmallScreen ? 1.0 : 1.5,
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
              ),
              width: isSmallScreen 
                  ? screenSize.width * 0.4 
                  : screenSize.width * 0.3,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      icon,
                      color: isSelected.value 
                          ? AppColors.textColor 
                          : AppColors.mainColor,
                      width: isSmallScreen ? 20 : 24,
                      height: isSmallScreen ? 20 : 24,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 10),
                    Text(
                      category,
                      style: isSelected.value
                          ? AppFonts.montserratWhiteText.copyWith(
                              fontSize: isSmallScreen ? null : 16,
                            )
                          : AppFonts.montserratMainText.copyWith(
                              fontSize: isSmallScreen ? null : 16,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}