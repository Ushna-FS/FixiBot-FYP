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
    return Scaffold(
        backgroundColor: AppColors.secondaryColor,
        body: Stack(children: [
          Container(
            color: AppColors.secondaryColor,
          ),
          Positioned(
              top: 0,
              right: 0,
              child: Image.asset('assets/icons/upperTyre.png')),
          Positioned(
            top: 15,
            left: 25,
            child: GestureDetector(
              onTap: () {
                //Back Button
                Get.back();
              },
              child: Image.asset("assets/icons/backArrow.png"),
            ),
          ),
          Positioned(
              bottom: 0,
              left: 0,
              child: Image.asset('assets/icons/lowerTyre.png')),
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                  child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.08),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => OpenDialog(context),
                              child: Center(
                                child: Obx(
                                  () => controller.image.value == null
                                      ? Container(
                                          width: screenSize.width * 0.6,
                                          height: screenSize.height * 0.2,
                                          decoration: const BoxDecoration(
                                              color: AppColors.secondaryColor,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(30)),
                                              border: Border(
                                                  top: BorderSide(
                                                      color:
                                                          AppColors.mainColor),
                                                  bottom: BorderSide(
                                                      color:
                                                          AppColors.mainColor),
                                                  left: BorderSide(
                                                      color:
                                                          AppColors.mainColor),
                                                  right: BorderSide(
                                                      color: AppColors
                                                          .mainColor))),
                                          child: Center(
                                            child: Text(
                                              "No Image added",
                                              style:
                                                  AppFonts.montserratMainText,
                                            ),
                                          ),
                                        )
                                      : Image(
                                          image: FileImage(
                                              controller.image.value!),
                                          width: screenSize.width * 0.8,
                                          height: screenSize.height * 0.4,
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            CustomTextField(
                              hintText: "Car Manufacturer",
                              icon: Icons.car_rental,
                              controller: controller.carManufacturer,
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            CustomTextField(
                              hintText: "Car Model",
                              icon: Icons.car_rental,
                              controller: controller.carModel,
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            CustomTextField(
                              hintText: "Car Model Year",
                              icon: Icons.car_rental,
                              controller: controller.carModelYear,
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            Obx(() => Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                        controller.transmissionAuto.value
                                            ? "Manual"
                                            : "Auto",
                                        style: AppFonts.montserratMainText14),
                                    Switch(
                                      inactiveThumbColor: AppColors.mainColor,
                                      activeColor: AppColors.mainColor,
                                      value: controller.transmissionAuto.value,
                                      onChanged: (value) =>
                                          controller.toggleTransmission(),
                                    ),
                                  ],
                                )),
                            SizedBox(height: screenSize.height * 0.001),
                            SizedBox(height: screenSize.height * 0.02),
                            CustomButton(
                              text: 'Add Vehicle',
                              onPressed: () {
                                // TODO: Add Vehicle function
                              },
                            ),
                          ]))))
        ]));
  }

  void OpenDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryColor,
        title: Text("Select Image Source", style: AppFonts.montserratMainText),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              controller.pickImage(ImageSource.camera);
            },
            child: Text("Camera", style: AppFonts.montserratText5),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              controller.pickImage(ImageSource.gallery);
            },
            child: Text("Gallery", style: AppFonts.montserratText5),
          ),
        ],
      ),
    );
  }
}
