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

class EditVehicle extends StatefulWidget {
  const EditVehicle({super.key});

  @override
  State<EditVehicle> createState() => _EditVehicleState();
}

class _EditVehicleState extends State<EditVehicle> {
  final VehicleController controller = Get.find<VehicleController>();
  final Map<String, dynamic> vehicleData = Get.arguments['vehicle'];
  final Function(Map<String, dynamic>) onUpdate = Get.arguments['onUpdate'];

  @override
  void initState() {
    super.initState();
    _populateForm();
  }

  void _populateForm() {
    // Pre-fill the form with existing vehicle data
    controller.carManufacturer.text = vehicleData['brand'] ?? '';
    controller.carModel.text = vehicleData['model'] ?? '';
    controller.carModelYear.text = vehicleData['year']?.toString() ?? '';
    controller.carMileage.text = vehicleData['mileage_km']?.toString() ?? '';
    controller.fuelType.text = vehicleData['fuel_type'] ?? '';
    controller.selectedVehicleType.value = vehicleData['type'] ?? '';
    controller.transmissionAuto.value =
        (vehicleData['transmission'] ?? '').toLowerCase() == 'automatic';

    // TODO: Load existing images if available
  }

Future<void> _updateVehicle() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");

    if (userId == null || userId.isEmpty) {
      Get.snackbar("Error", "User not logged in");
      return;
    }

    // Show loading
    Get.dialog(
      Center(
        child: CircularProgressIndicator(color: AppColors.mainColor),
      ),
      barrierDismissible: false,
    );

    // Call the update API
    await controller.updateVehicle(
      vehicleId: vehicleData['_id'],
      userId: userId,
      model: controller.carModel.text.trim(),
      brand: controller.carManufacturer.text.trim(),
      year: int.tryParse(controller.carModelYear.text),
      type: controller.selectedVehicleType.value,
      fuelType: controller.fuelType.text.trim(),
      transmission: controller.transmissionAuto.value ? "automatic" : "manual",
      mileageKm: int.tryParse(controller.carMileage.text),
      isPrimary: vehicleData['is_primary'] ?? false,
      isActive: vehicleData['is_active'] ?? true,
    );

    // Close loading
    Get.back();

    // Prepare updated vehicle data with proper typing
    final updatedVehicle = Map<String, dynamic>.from({
      '_id': vehicleData['_id'],
      'brand': controller.carManufacturer.text.trim(),
      'model': controller.carModel.text.trim(),
      'year': int.tryParse(controller.carModelYear.text),
      'type': controller.selectedVehicleType.value,
      'fuel_type': controller.fuelType.text.trim(),
      'transmission': controller.transmissionAuto.value ? "automatic" : "manual",
      'mileage_km': int.tryParse(controller.carMileage.text),
      'is_primary': vehicleData['is_primary'] ?? false,
      'is_active': vehicleData['is_active'] ?? true,
    });

    // Call the update callback
    onUpdate(updatedVehicle);

    // Go back to previous screen
    Get.back();

    // Add delay to avoid snackbar conflict
    Future.delayed(Duration(milliseconds: 100), () {
      Get.snackbar(
        "Success", 
        "Vehicle updated successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    });

  } catch (e) {
    Get.back(); // Close loading if still open
    print('❌ Error updating vehicle: $e');
    
    Future.delayed(Duration(milliseconds: 100), () {
      Get.snackbar(
        "Update Failed", 
        "Failed to update vehicle: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    });
  }
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

  void _handleUpdate() {
    _updateVehicle();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isPortrait = screenSize.height > screenSize.width;
    final double horizontalPadding =
        isPortrait ? screenSize.width * 0.08 : screenSize.width * 0.15;
    final double verticalPadding =
        isPortrait ? screenSize.height * 0.02 : screenSize.height * 0.03;

    final List<String> vehicleTypes = [
      'bike',
      'car',
      'truck',
      'van',
      'suv',
      'bus',
      'other'
    ];

    String _capitalize(String text) {
      if (text.isEmpty) return text;
      return text[0].toUpperCase() + text.substring(1);
    }

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
              top: screenSize.height * 0.03,
              left: screenSize.width * 0.05,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
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
                                value: controller.selectedVehicleType.value,
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
                      CustomTextField(
                        hintText: "Mileage (km)",
                        icon: Icons.speed,
                        controller: controller.carMileage,
                      ),
                      SizedBox(height: verticalPadding),
                      CustomTextField(
                        hintText: "Fuel Type",
                        icon: Icons.local_gas_station,
                        controller: controller.fuelType,
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
                      Obx(() => CustomButton(
                            text: controller.isLoading.value
                                ? 'Updating Vehicle...'
                                : 'Update Vehicle',
                            onPressed: controller.isLoading.value
                                ? null
                                : _handleUpdate,
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
}
