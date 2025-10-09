import 'package:fixibot_app/screens/vehicle/model/vehiclebrandModel.dart';
import 'package:fixibot_app/widgets/customAppBar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/vehicleController.dart';
import '../../../constants/app_fontStyles.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/custom_buttons.dart';
import '../../../widgets/custom_textField.dart';

class AddVehicle extends StatefulWidget {
  
  const AddVehicle({super.key});
  
 State<AddVehicle> createState() => _AddVehicleState();
}

class _AddVehicleState extends State<AddVehicle> {
  final VehicleController controller = Get.find<VehicleController>();

  @override
  void initState() {
    super.initState();
    // Reset form when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.resetForm();
    });
  }

  // Helper functions should be defined here, outside build() but inside class
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  int? _validateYear(String yearText) {
    final year = int.tryParse(yearText);
    if (year == null) return null;

    if (year < 1900 || year > 2026) {
      Get.snackbar('Error', 'Year must be between 1900 and 2026');
      return null;
    }
    return year;
  }

  Future<void> _onAddVehiclePressed() async {
    if (controller.selectedVehicleType.value.isEmpty) {
      Get.snackbar("Error", "Please select a vehicle type");
      return;
    }
    if (controller.selectedModel.value.isEmpty) {
      Get.snackbar("Error", "Please enter vehicle model");
      return;
    }

    if (controller.selectedBrand.value.isEmpty) {
      Get.snackbar("Error", "Please enter vehicle Brand Name");
      return;
    }

    // Validate year if provided
    if (controller.carModelYear.text.trim().isNotEmpty) {
      final validatedYear = _validateYear(controller.carModelYear.text.trim());
      if (validatedYear == null) {
        return; // Don't proceed if year is invalid
      }
    }

    // ADD FUEL TYPE VALIDATION FOR MOTORIZED VEHICLES
    final motorizedVehicles = ['car', 'truck', 'van', 'suv', 'bus', 'other'];
    if (motorizedVehicles.contains(controller.selectedVehicleType.value) &&
        controller.fuelType.text.trim().isEmpty) {
      Get.snackbar("Error", "Please specify fuel type for motorized vehicles");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");
    final accessToken = prefs.getString("access_token");

    print('🔍 Debug - User ID from prefs: $userId');
    print('🔍 Debug - Access token from prefs: $accessToken');

    if (userId == null || userId.isEmpty) {
      Get.snackbar("Error", "User not logged in. Please log in again.");
      return;
    }

    await controller.saveVehicle(
      userId: userId,
      isPrimary: true,
      isActive: true,
    );
  }

  VoidCallback _getOnPressed() {
    if (controller.isLoading.value) {
      return () {}; // Return an empty function when loading
    } else {
      return () {
        _onAddVehiclePressed();
      };
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final motorizedVehicles = ['car','bike', 'truck', 'van', 'suv', 'bus', 'other'];
    final Size screenSize = MediaQuery.of(context).size;
    final bool isPortrait = screenSize.height > screenSize.width;
    final double horizontalPadding =
        isPortrait ? screenSize.width * 0.08 : screenSize.width * 0.15;
    final double verticalPadding =
        isPortrait ? screenSize.height * 0.02 : screenSize.height * 0.03;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Add Your Vehicles",
      ),
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
                      Obx(() => Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: isPortrait
                                  ? screenSize.width * 0.05
                                  : screenSize.width * 0.02,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: AppColors.mainColor, width: 1.5),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value:
                                    controller.selectedVehicleType.value.isEmpty
                                        ? null
                                        : controller.selectedVehicleType.value,
                                hint: Text(
                                  "Select Vehicle Type",
                                  style: AppFonts.montserratMainText14.copyWith(
                                    color: AppColors.mainColor.withOpacity(0.9),
                                  ),
                                ),
                                items: vehicleTypes.map((String backendValue) {
                                  return DropdownMenuItem<String>(
                                    value: backendValue,
                                    child: Text(
                                      _capitalize(backendValue),
                                      style: AppFonts.montserratMainText14,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  if (newValue != null)
                                    controller.selectedVehicleType.value =
                                        newValue;
                                },
                              ),
                            ),
                          )),
                      SizedBox(height: verticalPadding),
                      // ===== Vehicle Brand Dropdown =====
                      
                      Obx(() {
                        if (motorizedVehicles.contains(controller.selectedVehicleType.value.toLowerCase())) {
                          return Column(
                            children: [
                              // Brand Dropdown
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
                                      color: AppColors.mainColor, width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value:
                                        controller.selectedBrand.value.isEmpty
                                            ? null
                                            : controller.selectedBrand.value,
                                    hint: Text(
                                      "Select Brand",
                                      style: AppFonts.montserratMainText14
                                          .copyWith(
                                              color: AppColors.mainColor
                                                  .withOpacity(0.9)),
                                    ),
                                    items: carBrandData
                                        .map((e) => DropdownMenuItem<String>(
                                              value: e['brand'],
                                              child: Text(e['brand'],
                                                  style: AppFonts
                                                      .montserratMainText14),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      controller.selectedBrand.value =
                                          value ?? '';
                                      controller.selectedModel.value = '';
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(height: verticalPadding),
                              // Model Dropdown
                              Obx(() {
                                final selectedBrandMap =
                                    carBrandData.firstWhere(
                                  (e) =>
                                      e['brand'] ==
                                      controller.selectedBrand.value,
                                  orElse: () => {},
                                );
                                final models = selectedBrandMap.isNotEmpty
                                    ? List<String>.from(
                                        selectedBrandMap['models'])
                                    : <String>[];
                                return Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isPortrait
                                        ? screenSize.width * 0.05
                                        : screenSize.width * 0.02,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                        color: AppColors.mainColor, width: 1.5),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value:
                                          controller.selectedModel.value.isEmpty
                                              ? null
                                              : controller.selectedModel.value,
                                      hint: Text("Select Model",
                                          style: AppFonts.montserratMainText14
                                              .copyWith(
                                                  color: AppColors.mainColor
                                                      .withOpacity(0.9))),
                                      items: models
                                          .map((m) => DropdownMenuItem<String>(
                                                value: m,
                                                child: Text(m,
                                                    style: AppFonts
                                                        .montserratMainText14),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        controller.selectedModel.value =
                                            value ?? '';
                                      },
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        } else {
                          return SizedBox.shrink();
                        }
                      }),

                      SizedBox(height: verticalPadding),
                      CustomTextField(
                        hintText: "Model Year",
                        icon: Icons.car_rental,
                        controller: controller.carModelYear,
                      ),
                      SizedBox(height: verticalPadding),
                      CustomTextField(
  hintText: "Fuel Type (e.g., Petrol, Diesel, Electric)",
  icon: Icons.local_gas_station,
  controller: controller.fuelType,
  onChanged: (value) {
    // Normalize the first letter to uppercase, rest lowercase
    if (value.isNotEmpty) {
      final normalized = value[0].toUpperCase() + value.substring(1).toLowerCase();
      // Only update if text actually differs to avoid cursor jump
      if (controller.fuelType.text != normalized) {
        controller.fuelType.value = TextEditingValue(
          text: normalized,
          selection: TextSelection.fromPosition(
            TextPosition(offset: normalized.length),
          ),
        );
      }
    }
  },
  TextCapitalization: TextCapitalization.none, // important to avoid conflicts
),


                      SizedBox(height: verticalPadding),
                      Obx(() => Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                controller.transmissionAuto.value
                                    ? "automatic"
                                    : "manual",
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
                      Obx(() => CustomButton(
                            text: controller.isLoading.value
                                ? 'Adding Vehicle...'
                                : 'Add Vehicle',
                            onPressed: _getOnPressed(),
                          )),
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
