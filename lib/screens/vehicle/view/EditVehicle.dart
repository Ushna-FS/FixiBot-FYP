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

class EditVehicle extends StatefulWidget {
  const EditVehicle({super.key});

  @override
  State<EditVehicle> createState() => _EditVehicleState();
}

class _EditVehicleState extends State<EditVehicle> {
  final VehicleController controller = Get.find<VehicleController>();
  final Map<String, dynamic> vehicleDataFromArgs = Get.arguments['vehicle'];
  final Function(Map<String, dynamic>) onUpdate = Get.arguments['onUpdate'];

  @override
  void initState() {
    super.initState();
    _populateForm();
  }

  void _populateForm() {
    // Pre-fill the form with existing vehicle data
    controller.selectedBrand.value = vehicleDataFromArgs['brand'] ?? '';
    controller.selectedModel.value = vehicleDataFromArgs['model'] ?? '';
    controller.carModelYear.text = vehicleDataFromArgs['year']?.toString() ?? '';
    controller.carMileage.text = vehicleDataFromArgs['mileage_km']?.toString() ?? '';
    controller.selectedFuelType.value = vehicleDataFromArgs['fuel_type'] ?? '';
    controller.selectedVehicleType.value = vehicleDataFromArgs['category'] ?? '';
    controller.selectedSubType.value = vehicleDataFromArgs['sub_type'] ?? '';
    controller.selectedTransmission.value = vehicleDataFromArgs['transmission'] ?? '';
    controller.registrationNumber.text = vehicleDataFromArgs['registration_number'] ?? '';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatSubTypeDisplay(String subType) {
    return subType.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  int? _validateYear(String yearText) {
    final year = int.tryParse(yearText);
    if (year == null) return null;

    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear + 1) {
      Get.snackbar('Error', 'Year must be between 1900 and ${currentYear + 1}');
      return null;
    }
    return year;
  }

  // Get ONLY suggested sub-types (not all)
  List<String> _getSuggestedSubTypes(String vehicleType, String brand, String model) {
    try {
      for (var typeData in vehicleData) {
        if (typeData["type"] == vehicleType) {
          final brands = typeData["brands"] as List;
          for (var brandData in brands) {
            if (brandData["brand"] == brand) {
              final models = brandData["models"] as List;
              for (var modelData in models) {
                if (modelData["name"] == model) {
                  final suggestedSubtypes = modelData["suggested_subtypes"] as List<String>?;
                  return suggestedSubtypes ?? [];
                }
              }
              break;
            }
          }
          break;
        }
      }
      return [];
    } catch (e) {
      print('Error getting suggested sub-types: $e');
      return [];
    }
  }

  // Get ONLY suggested fuel types based on selection
  List<String> _getSuggestedFuelTypes(String vehicleType, String subType) {
    final suggestions = <String>[];
    
    // Electric vehicles
    if (subType.contains('electric')) {
      suggestions.add('electric');
    }
    
    // Hybrid vehicles
    if (subType.contains('hybrid')) {
      suggestions.addAll(['hybrid', 'petrol']);
    }
    
    // Default based on vehicle type
    if (vehicleType == 'car') {
      if (suggestions.isEmpty) {
        suggestions.addAll(['petrol', 'diesel', 'cng', 'lpg']);
      }
    } else if (vehicleType == 'motorcycle') {
      suggestions.addAll(['petrol']);
    }
    
    // Always include 'other' as fallback
    if (suggestions.isNotEmpty) {
      suggestions.add('other');
    }
    
    return suggestions.toSet().toList();
  }

  // Get ONLY suggested transmissions based on selection
  List<String> _getSuggestedTransmissions(String vehicleType, String subType) {
    final suggestions = <String>[];
    
    // Electric vehicles
    if (subType.contains('electric')) {
      suggestions.addAll(['direct_drive', 'automatic']);
    }
    
    // Sports/super vehicles
    if (subType.contains('sports') || subType.contains('super')) {
      suggestions.addAll(['manual', 'dual_clutch', 'automatic']);
    }
    
    // Motorcycles
    if (vehicleType == 'motorcycle') {
      suggestions.addAll(['manual', 'semi_automatic']);
    }
    
    // Default for cars
    if (vehicleType == 'car' && suggestions.isEmpty) {
      suggestions.addAll(['manual', 'automatic', 'cvt']);
    }
    
    // Always include 'other' as fallback
    if (suggestions.isNotEmpty) {
      suggestions.add('other');
    }
    
    return suggestions.toSet().toList();
  }

  List<String> _getBrandsForType(String vehicleType) {
    try {
      for (var typeData in vehicleData) {
        if (typeData["type"] == vehicleType) {
          final brands = typeData["brands"] as List;
          return brands.map<String>((brand) => brand["brand"] as String).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting brands for type $vehicleType: $e');
      return [];
    }
  }

  List<String> _getModelsForBrand(String vehicleType, String brand) {
    try {
      for (var typeData in vehicleData) {
        if (typeData["type"] == vehicleType) {
          final brands = typeData["brands"] as List;
          for (var brandData in brands) {
            if (brandData["brand"] == brand) {
              final models = brandData["models"] as List;
              return models.map<String>((model) => model["name"] as String).toList();
            }
          }
        }
      }
      return [];
    } catch (e) {
      print('Error getting models for brand $brand: $e');
      return [];
    }
  }

  Future<void> _updateVehicle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id");

      if (userId == null || userId.isEmpty) {
        Get.snackbar("Error", "User not logged in");
        return;
      }

      // Validate required fields
      if (controller.selectedVehicleType.value.isEmpty) {
        Get.snackbar("Error", "Please select a vehicle type");
        return;
      }
      if (controller.selectedBrand.value.isEmpty) {
        Get.snackbar("Error", "Please select a vehicle brand");
        return;
      }
      if (controller.selectedModel.value.isEmpty) {
        Get.snackbar("Error", "Please select a vehicle model");
        return;
      }
      if (controller.selectedSubType.value.isEmpty) {
        Get.snackbar("Error", "Please select a vehicle sub-type");
        return;
      }
      if (controller.selectedFuelType.value.isEmpty) {
        Get.snackbar("Error", "Please select fuel type");
        return;
      }
      if (controller.selectedTransmission.value.isEmpty) {
        Get.snackbar("Error", "Please select transmission type");
        return;
      }
      if (controller.carModelYear.text.trim().isEmpty) {
        Get.snackbar("Error", "Please enter model year");
        return;
      }
      if (controller.carMileage.text.trim().isEmpty) {
        Get.snackbar("Error", "Please enter mileage");
        return;
      }

      // Validate year
      final validatedYear = _validateYear(controller.carModelYear.text.trim());
      if (validatedYear == null) return;

      // Show loading
      Get.dialog(
        Center(
          child: CircularProgressIndicator(color: AppColors.mainColor),
        ),
        barrierDismissible: false,
      );

      // Call the update API
      await controller.updateVehicle(
        vehicleId: vehicleDataFromArgs['_id'],
        userId: userId,
        model: controller.selectedModel.value,
        brand: controller.selectedBrand.value,
        year: validatedYear,
        category: controller.selectedVehicleType.value,
        subType: controller.selectedSubType.value,
        fuelType: controller.selectedFuelType.value,
        transmission: controller.selectedTransmission.value,
        mileageKm: int.tryParse(controller.carMileage.text),
        registrationNumber: controller.registrationNumber.text.trim(),
        isPrimary: vehicleDataFromArgs['is_primary'] ?? false,
        isActive: vehicleDataFromArgs['is_active'] ?? true,
      );

      // Close loading
      Get.back();

      // Prepare updated vehicle data with proper typing
      final updatedVehicle = Map<String, dynamic>.from({
        '_id': vehicleDataFromArgs['_id'],
        'brand': controller.selectedBrand.value,
        'model': controller.selectedModel.value,
        'year': validatedYear,
        'category': controller.selectedVehicleType.value,
        'sub_type': controller.selectedSubType.value,
        'fuel_type': controller.selectedFuelType.value,
        'transmission': controller.selectedTransmission.value,
        'mileage_km': int.tryParse(controller.carMileage.text),
        'registration_number': controller.registrationNumber.text.trim(),
        'is_primary': vehicleDataFromArgs['is_primary'] ?? false,
        'is_active': vehicleDataFromArgs['is_active'] ?? true,
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

  void _handleUpdate() {
    _updateVehicle();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isPortrait = screenSize.height > screenSize.width;
    final double horizontalPadding = isPortrait ? screenSize.width * 0.08 : screenSize.width * 0.15;
    final double verticalPadding = isPortrait ? screenSize.height * 0.02 : screenSize.height * 0.03;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Edit Your Vehicle",
      ),
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
                width: isPortrait ? screenSize.width * 0.5 : screenSize.height * 0.5,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Image.asset(
                'assets/icons/lower.png',
                width: isPortrait ? screenSize.width * 0.5 : screenSize.height * 0.5,
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
                      // Image Picker Section
                      GestureDetector(
                        onTap: () => OpenDialog(context),
                        child: Center(
                          child: Obx(
                            () => Stack(
                              children: [
                                Container(
                                  width: isPortrait ? screenSize.width * 0.8 : screenSize.width * 0.5,
                                  height: isPortrait ? screenSize.height * 0.25 : screenSize.height * 0.4,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryColor,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: AppColors.mainColor, width: 2),
                                  ),
                                  child: controller.image.value == null && controller.imageBytes.value == null
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_a_photo,
                                                size: isPortrait ? screenSize.height * 0.08 : screenSize.width * 0.08,
                                                color: AppColors.mainColor,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                "Update Vehicle Photo",
                                                style: AppFonts.montserratMainText14.copyWith(
                                                  color: AppColors.mainColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(30),
                                          child: kIsWeb
                                              ? Image.memory(
                                                  controller.imageBytes.value!,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                )
                                              : Image.file(
                                                  controller.image.value!,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                ),
                                        ),
                                ),
                                if (controller.image.value != null || controller.imageBytes.value != null)
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Row(
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.mainColor,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                          onPressed: () => OpenDialog(context),
                                          child: Text(
                                            'Update',
                                            style: AppFonts.montserratMainText14.copyWith(color: AppColors.secondaryColor),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                          onPressed: () {
                                            controller.image.value = null;
                                            controller.imageBytes.value = null;
                                          },
                                          child: Text(
                                            'Remove',
                                            style: AppFonts.montserratMainText14.copyWith(color: AppColors.secondaryColor),
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

                      // ========== FIELDS APPEAR IN SEQUENCE ==========

                      // Vehicle Type Dropdown (ALWAYS VISIBLE)
                      _buildDropdown(
                        value: controller.selectedVehicleType.value,
                        hint: "Select Vehicle Type",
                        items: vehicleTypes,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              controller.selectedVehicleType.value = newValue;
                              controller.selectedBrand.value = '';
                              controller.selectedModel.value = '';
                              controller.selectedSubType.value = '';
                              controller.selectedFuelType.value = '';
                              controller.selectedTransmission.value = '';
                            });
                          }
                        },
                        isPortrait: isPortrait,
                        screenSize: screenSize,
                      ),
                      SizedBox(height: verticalPadding),

                      // Brand Dropdown (appears after vehicle type selected)
                      if (controller.selectedVehicleType.value.isNotEmpty) 
                        _buildDropdown(
                          value: controller.selectedBrand.value,
                          hint: "Select Brand",
                          items: _getBrandsForType(controller.selectedVehicleType.value),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                controller.selectedBrand.value = newValue;
                                controller.selectedModel.value = '';
                                controller.selectedSubType.value = '';
                                controller.selectedFuelType.value = '';
                                controller.selectedTransmission.value = '';
                              });
                            }
                          },
                          isPortrait: isPortrait,
                          screenSize: screenSize,
                        ),
                      if (controller.selectedVehicleType.value.isNotEmpty) SizedBox(height: verticalPadding),

                      // Model Dropdown (appears after brand selected)
                      if (controller.selectedBrand.value.isNotEmpty) 
                        _buildDropdown(
                          value: controller.selectedModel.value,
                          hint: "Select Model",
                          items: _getModelsForBrand(controller.selectedVehicleType.value, controller.selectedBrand.value),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                controller.selectedModel.value = newValue;
                                // Auto-select first suggested sub-type
                                final suggestedSubTypes = _getSuggestedSubTypes(
                                  controller.selectedVehicleType.value,
                                  controller.selectedBrand.value,
                                  newValue
                                );
                                if (suggestedSubTypes.isNotEmpty) {
                                  controller.selectedSubType.value = suggestedSubTypes.first;
                                } else {
                                  controller.selectedSubType.value = '';
                                }
                                controller.selectedFuelType.value = '';
                                controller.selectedTransmission.value = '';
                              });
                            }
                          },
                          isPortrait: isPortrait,
                          screenSize: screenSize,
                        ),
                      if (controller.selectedBrand.value.isNotEmpty) SizedBox(height: verticalPadding),

                      // Sub-type Dropdown (appears after model selected)
                      if (controller.selectedModel.value.isNotEmpty) 
                        _buildSuggestedDropdown(
                          value: controller.selectedSubType.value,
                          hint: "Select Sub-type",
                          suggestedItems: _getSuggestedSubTypes(
                            controller.selectedVehicleType.value,
                            controller.selectedBrand.value,
                            controller.selectedModel.value
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                controller.selectedSubType.value = newValue;
                                controller.selectedFuelType.value = '';
                                controller.selectedTransmission.value = '';
                              });
                            }
                          },
                          isPortrait: isPortrait,
                          screenSize: screenSize,
                        ),
                      if (controller.selectedModel.value.isNotEmpty) SizedBox(height: verticalPadding),

                      // Fuel Type Dropdown (appears after sub-type selected)
                      if (controller.selectedSubType.value.isNotEmpty) 
                        _buildSuggestedDropdown(
                          value: controller.selectedFuelType.value,
                          hint: "Select Fuel Type",
                          suggestedItems: _getSuggestedFuelTypes(
                            controller.selectedVehicleType.value,
                            controller.selectedSubType.value
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                controller.selectedFuelType.value = newValue;
                                controller.selectedTransmission.value = '';
                              });
                            }
                          },
                          isPortrait: isPortrait,
                          screenSize: screenSize,
                        ),
                      if (controller.selectedSubType.value.isNotEmpty) SizedBox(height: verticalPadding),

                      // Transmission Dropdown (appears after fuel type selected)
                      if (controller.selectedFuelType.value.isNotEmpty) 
                        _buildTransmissionDropdown(
                          value: controller.selectedTransmission.value,
                          hint: "Select Transmission",
                          suggestedItems: _getSuggestedTransmissions(
                            controller.selectedVehicleType.value,
                            controller.selectedSubType.value
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                controller.selectedTransmission.value = newValue;
                              });
                            }
                          },
                          isPortrait: isPortrait,
                          screenSize: screenSize,
                        ),
                      if (controller.selectedFuelType.value.isNotEmpty) SizedBox(height: verticalPadding),

                      // Text Fields and Button (ALWAYS VISIBLE)
                      CustomTextField(
                        hintText: "Model Year (e.g., 2020)",
                        icon: Icons.calendar_today,
                        controller: controller.carModelYear,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: verticalPadding),

                      CustomTextField(
                        hintText: "Mileage in KM (e.g., 50000)",
                        icon: Icons.speed,
                        controller: controller.carMileage,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: verticalPadding),

                      CustomTextField(
                        hintText: "Registration Number (e.g., ABC-123)",
                        icon: Icons.confirmation_number,
                        controller: controller.registrationNumber,
                      ),
                      SizedBox(height: verticalPadding * 2),

                      // Update Vehicle Button (ALWAYS VISIBLE)
                      Obx(() => CustomButton(
                            text: controller.isLoading.value ? 'Updating Vehicle...' : 'Update Vehicle',
                            onPressed: controller.isLoading.value ? null : _handleUpdate,
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

  Widget _buildDropdown({
    required String value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isPortrait,
    required Size screenSize,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isPortrait ? screenSize.width * 0.05 : screenSize.width * 0.02),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.mainColor, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value.isEmpty ? null : value,
          hint: Text(
            hint,
            style: AppFonts.montserratMainText14.copyWith(color: AppColors.mainColor.withOpacity(0.9)),
          ),
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(_capitalize(item), style: AppFonts.montserratMainText14),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSuggestedDropdown({
    required String value,
    required String hint,
    required List<String> suggestedItems,
    required Function(String?) onChanged,
    required bool isPortrait,
    required Size screenSize,
  }) {
    final hasSuggestions = suggestedItems.isNotEmpty;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isPortrait ? screenSize.width * 0.05 : screenSize.width * 0.02),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: hasSuggestions ? AppColors.mainColor : Colors.grey,
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value.isEmpty ? null : value,
          hint: Text(
            hasSuggestions ? hint : "No options available",
            style: AppFonts.montserratMainText14.copyWith(
              color: hasSuggestions ? AppColors.mainColor.withOpacity(0.9) : Colors.grey,
            ),
          ),
          items: suggestedItems.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                _formatSubTypeDisplay(item), 
                style: AppFonts.montserratMainText14,
              ),
            );
          }).toList(),
          onChanged: hasSuggestions ? onChanged : null,
        ),
      ),
    );
  }

  Widget _buildTransmissionDropdown({
    required String value,
    required String hint,
    required List<String> suggestedItems,
    required Function(String?) onChanged,
    required bool isPortrait,
    required Size screenSize,
  }) {
    final hasSuggestions = suggestedItems.isNotEmpty;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isPortrait ? screenSize.width * 0.05 : screenSize.width * 0.02),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: hasSuggestions ? AppColors.mainColor : Colors.grey,
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value.isEmpty ? null : value,
          hint: Text(
            hasSuggestions ? hint : "No options available",
            style: AppFonts.montserratMainText14.copyWith(
              color: hasSuggestions ? AppColors.mainColor.withOpacity(0.9) : Colors.grey,
            ),
          ),
          items: suggestedItems.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                _formatSubTypeDisplay(item), 
                style: AppFonts.montserratMainText14,
              ),
            );
          }).toList(),
          onChanged: hasSuggestions ? onChanged : null,
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
            fontSize: isPortrait ? screenSize.height * 0.025 : screenSize.width * 0.025,
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
                fontSize: isPortrait ? screenSize.height * 0.02 : screenSize.width * 0.02,
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
                fontSize: isPortrait ? screenSize.height * 0.02 : screenSize.width * 0.02,
              ),
            ),
          ),
        ],
      ),
    );
  }
}