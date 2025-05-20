import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/vehicleController.dart';
import '../../../constants/app_fontStyles.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/custom_buttons.dart';
import '../../../widgets/custom_textField.dart';

class AddVehicle extends GetView<VehicleController> {
  const AddVehicle({super.key});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isPortrait = screenSize.height > screenSize.width;
    final double horizontalPadding =
        isPortrait ? screenSize.width * 0.08 : screenSize.width * 0.15;
    final double verticalPadding =
        isPortrait ? screenSize.height * 0.02 : screenSize.height * 0.03;

    // Vehicle types for dropdown
    final List<String> vehicleTypes = [
      'Car',
      'Truck',
      'Motorcycle',
      'SUV',
      'Van'
    ];

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      body: SafeArea(
        child: Stack(
          children: [
            Container(color: AppColors.secondaryColor),
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset(
                'assets/icons/upper.png',
                width: isPortrait
                    ? screenSize.width * 0.5
                    : screenSize.height * 0.5,
              ),
            ),
            Positioned(
              top: screenSize.height * 0.02,
              left: screenSize.width * 0.05,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  print('Back arrow tapped'); // Debugging
                  Get.back();
                },
                child: Image.asset(
                  "assets/icons/backArrow.png",
                  width: isPortrait
                      ? screenSize.width * 0.08
                      : screenSize.height * 0.08,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Image.asset(
                'assets/icons/lower.png',
                width: isPortrait
                    ? screenSize.width * 0.5
                    : screenSize.height * 0.5,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: screenSize.height * 0.02,
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => OpenDialog(context),
                        child: Center(
                          child: Obx(
                            () => Stack(
                              children: [
                                Container(
                                  width: isPortrait
                                      ? screenSize.width * 0.8
                                      : screenSize.width * 0.5,
                                  height: isPortrait
                                      ? screenSize.height * 0.25
                                      : screenSize.height * 0.4,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryColor,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: AppColors.mainColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: controller.image.value == null &&
                                          controller.imageBytes.value == null
                                      ? Center(
                                          child: Icon(
                                            Icons.add,
                                            size: isPortrait
                                                ? screenSize.height * 0.08
                                                : screenSize.width * 0.08,
                                            color: AppColors.mainColor,
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          child: kIsWeb
                                              ? Image.memory(
                                                  controller.imageBytes.value!,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Center(
                                                    child: Icon(
                                                      Icons.error,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                )
                                              : Image.file(
                                                  controller.image.value!,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Center(
                                                    child: Icon(
                                                      Icons.error,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                ),
                                if (controller.image.value != null ||
                                    controller.imageBytes.value != null)
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Row(
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.mainColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          onPressed: () => OpenDialog(context),
                                          child: Text(
                                            'Update',
                                            style: AppFonts.montserratMainText14
                                                .copyWith(
                                              color: AppColors.secondaryColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          onPressed: () {
                                            controller.image.value = null;
                                            controller.imageBytes.value = null;
                                          },
                                          child: Text(
                                            'Remove',
                                            style: AppFonts.montserratMainText14
                                                .copyWith(
                                              color: AppColors.secondaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: verticalPadding),
                      // Vehicle Type Dropdown
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: isPortrait
                              ? screenSize.width * 0.05
                              : screenSize.width * 0.02,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.mainColor,
                            width: 1.5,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: Text(
                              "Select Vehicle Type",
                              style: AppFonts.montserratMainText14.copyWith(
                                color: AppColors.mainColor.withOpacity(0.9),
                              ),
                            ),
                            items: vehicleTypes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: AppFonts.montserratMainText14,
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              // Handle vehicle type selection
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: verticalPadding),
                      CustomTextField(
                        hintText: "Vehicle Manufacturer",
                        icon: Icons.car_rental,
                        controller: controller.carManufacturer,
                      ),
                      SizedBox(height: verticalPadding),
                      CustomTextField(
                        hintText: "Vehicle Model",
                        icon: Icons.car_rental,
                        controller: controller.carModel,
                      ),
                      SizedBox(height: verticalPadding),
                      CustomTextField(
                        hintText: "Vehicle Model Year",
                        icon: Icons.car_rental,
                        controller: controller.carModelYear,
                      ),
                      SizedBox(height: verticalPadding),
                      Obx(() => Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                controller.transmissionAuto.value
                                    ? "Manual"
                                    : "Auto",
                                style: AppFonts.montserratMainText14.copyWith(
                                  fontSize: isPortrait
                                      ? screenSize.height * 0.018
                                      : screenSize.width * 0.018,
                                ),
                              ),
                              Switch(
                                inactiveThumbColor: AppColors.mainColor,
                                activeColor: AppColors.mainColor,
                                value: controller.transmissionAuto.value,
                                onChanged: (value) =>
                                    controller.toggleTransmission(),
                              ),
                            ],
                          )),
                      SizedBox(height: verticalPadding),
                      CustomButton(
                        text: 'Add Vehicle',
                        onPressed: () {
                          // TODO: Add Vehicle function
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void OpenDialog(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryColor,
        title: Text(
          "Select Image Source",
          style: AppFonts.montserratMainText.copyWith(
            fontSize: isPortrait
                ? screenSize.height * 0.025
                : screenSize.width * 0.025,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              controller.pickImage(ImageSource.camera);
            },
            child: Text(
              "Camera",
              style: AppFonts.montserratText5.copyWith(
                fontSize: isPortrait
                    ? screenSize.height * 0.02
                    : screenSize.width * 0.02,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.pickImage(ImageSource.gallery);
            },
            child: Text(
              "Gallery",
              style: AppFonts.montserratText5.copyWith(
                fontSize: isPortrait
                    ? screenSize.height * 0.02
                    : screenSize.width * 0.02,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
