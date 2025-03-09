import '../constants/app_colors.dart';
import '../constants/app_fontStyles.dart';
import '../screens/mechanics/view/controller/mechanicController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryChips extends StatelessWidget {
  final String icon;
  final String category;
  final MechanicController mechanicController = Get.find<MechanicController>();

  CategoryChips({
    super.key,
    required this.icon,
    required this.category,
  });
  var isSelected = RxBool(false);
  void categorySelection() {
    print("category selection");
    if (isSelected.value == false) {
      isSelected.value = true;
      print("category selected $category");
      mechanicController.mechanicCategories.add(category);
      print("category selected ${mechanicController.mechanicCategories}");
    } else {
      isSelected.value = false;
      mechanicController.mechanicCategories.remove(category);
      print("category selected ${mechanicController.mechanicCategories}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Obx(() => Padding(
          padding: const EdgeInsets.only(top: 2.0, left: 10.0),
          child: GestureDetector(
            onTap: () {
              categorySelection();
            },
            child: isSelected.value
                ? Container(
                    decoration: const BoxDecoration(
                        color: AppColors.mainColor,
                        border: Border(
                          top: BorderSide(color: AppColors.mainColor),
                          left: BorderSide(color: AppColors.mainColor),
                          bottom: BorderSide(color: AppColors.mainColor),
                          right: BorderSide(color: AppColors.mainColor),
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    width: screenSize.width * 0.3,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            icon,
                            color: AppColors.textColor,
                          ),
                          SizedBox(
                            width: screenSize.width * 0.01,
                          ),
                          Text(
                            category,
                            style: AppFonts.montserratWhiteText,
                          )
                        ],
                      ),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                        color: AppColors.textColor,
                        border: Border(
                          top: BorderSide(color: AppColors.mainColor),
                          left: BorderSide(color: AppColors.mainColor),
                          bottom: BorderSide(color: AppColors.mainColor),
                          right: BorderSide(color: AppColors.mainColor),
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    width: screenSize.width * 0.3,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            icon,
                            color: AppColors.mainColor,
                          ),
                          SizedBox(
                            width: screenSize.width * 0.01,
                          ),
                          Text(
                            category,
                            style: AppFonts.montserratMainText,
                          )
                        ],
                      ),
                    ),
                  ),
          ),
        ));
  }
}
