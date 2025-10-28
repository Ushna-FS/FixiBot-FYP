import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/model/mechanicModel.dart';
import 'package:fixibot_app/screens/location/locationScreen.dart';
import 'package:fixibot_app/screens/location/location_controller.dart';
import 'package:fixibot_app/screens/mechanics/controller/mechanicController.dart';
import 'package:fixibot_app/screens/mechanics/view/mechanicDetails.dart';
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
import 'package:fixibot_app/widgets/category_chips.dart';
import 'package:fixibot_app/widgets/customAppBar.dart';
import 'package:fixibot_app/widgets/mechanic_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MechanicScreen extends GetView<MechanicController> {
  const MechanicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final bool isMediumScreen =
        screenSize.width >= 600 && screenSize.width < 1200;
    final bool isLargeScreen = screenSize.width >= 1200;

    final locationController = Get.find<LocationController>();
    final userLat = locationController.userLatitude.value;
    final userLng = locationController.userLongitude.value;

    final vehicleController = Get.find<VehicleController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
    final userLat = locationController.userLatitude.value;
    final userLng = locationController.userLongitude.value;
    
    if (userLat != 0.0 && userLng != 0.0) {
      controller.updateUserLocation(userLat, userLng);
    }
  });
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.mainColor,
        title: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/icons/locationIcon.png",
                  color: AppColors.textColor,
                  width: isSmallScreen ? 20 : 24,
                  height: isSmallScreen ? 20 : 24,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: isSmallScreen
                      ? screenSize.width * 0.4
                      : screenSize.width * 0.3,
                  child: TextButton(
                    onPressed: () {
                      Get.to(LocationScreen());
                    },
                    child: Obx(() {
                      final location =
                          Get.find<LocationController>().userLocation.value;
                      return Text(
                        location.isEmpty
                            ? 'No location selected'
                            : (location.length > 20
                                ? "${location.substring(0, 20)}..."
                                : location),
                        style: isSmallScreen
                            ? AppFonts.montserratWhiteText
                            : AppFonts.montserratWhiteText
                                .copyWith(fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Image.asset(
            'assets/icons/back.png',
            color: AppColors.secondaryColor,
            width: isSmallScreen ? 24 : 30,
            height: isSmallScreen ? 24 : 30,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
            child: Obx(() => GestureDetector(
                  onTap: () {
                    controller.notificationSelection();
                  },
                  child: controller.isNotified.value
                      ? Image.asset(
                          "assets/icons/notification.png",
                          color: AppColors.secondaryColor,
                          width: isSmallScreen ? 24 : 30,
                          height: isSmallScreen ? 24 : 30,
                        )
                      : Image.asset(
                          "assets/icons/notification.png",
                          color: AppColors.textColor2,
                          width: isSmallScreen ? 24 : 30,
                          height: isSmallScreen ? 24 : 30,
                        ),
                )),
          )
        ],
      ),
      backgroundColor: AppColors.secondaryColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.mainColor,
            ),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.errorMessage.value,
                  style: AppFonts.montserratMainText14,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    controller.fetchMechanics();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isLargeScreen ? 1200 : double.infinity,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Type Dropdown - Using user's vehicles
                    Padding(
                      padding: EdgeInsets.only(
                        left: isSmallScreen ? 12.0 : 24.0,
                        right: isSmallScreen ? 12.0 : 24.0,
                        bottom: isSmallScreen ? 16.0 : 24.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Select Your Vehicle",
                            style: isSmallScreen
                                ? AppFonts.montserratBlackHeading
                                    .copyWith(fontSize: 16)
                                : AppFonts.montserratBlackHeading
                                    .copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Obx(() {
                            if (vehicleController.isLoading.value) {
                              return Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 12.0 : 16.0,
                                  vertical: isSmallScreen ? 12.0 : 16.0,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.mainColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.mainColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Loading your vehicles...',
                                      style: isSmallScreen
                                          ? AppFonts.montserratMainText14
                                          : AppFonts.montserratMainText14
                                              .copyWith(fontSize: 16),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (vehicleController.userVehicles.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 12.0 : 16.0,
                                  vertical: isSmallScreen ? 12.0 : 16.0,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange,
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'No vehicles added',
                                            style: isSmallScreen
                                                ? AppFonts.montserratMainText14
                                                : AppFonts.montserratMainText14
                                                    .copyWith(fontSize: 16),
                                          ),
                                          Text(
                                            'Add a vehicle to filter mechanics',
                                            style: isSmallScreen
                                                ? AppFonts.montserratMainText14
                                                    .copyWith(fontSize: 12)
                                                : AppFonts.montserratMainText14
                                                    .copyWith(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12.0 : 16.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.textColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.mainColor,
                                  width: 1.5,
                                ),
                              ),
                              child: DropdownButton<String>(
                                value: controller.selectedVehicleId.value
                                        .isEmpty
                                    ? null
                                    : controller.selectedVehicleId.value,
                                isExpanded: true,
                                underline: const SizedBox(),
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.mainColor,
                                  size: isSmallScreen ? 24 : 28,
                                ),
                                hint: Text(
                                  'Select your vehicle',
                                  style: isSmallScreen
                                      ? AppFonts.montserratMainText14
                                      : AppFonts.montserratMainText14
                                          .copyWith(fontSize: 16),
                                ),
                                items: [
                                  DropdownMenuItem<String>(
                                    value: '',
                                    child: Text(
                                      'All Vehicles',
                                      style: isSmallScreen
                                          ? AppFonts.montserratMainText14
                                          : AppFonts.montserratMainText14
                                              .copyWith(fontSize: 16),
                                    ),
                                  ),
                                  ...vehicleController.userVehicles
                                      .map<DropdownMenuItem<String>>((vehicle) {
                                    final brand = (vehicle['brand'] ??
                                            'Unknown Brand')
                                        .toString();
                                    final model = (vehicle['model'] ??
                                            'Unknown Model')
                                        .toString();
                                    final vehicleType = (vehicle['category'] ??
                                            vehicle['category'] )
                                        .toString();
                                    final vehicleId = (vehicle['_id'] ??
                                            vehicle['id'] ?? '')
                                        .toString();

                                    // Create a unique display name
                                    final vehicleName =
                                        '$brand $model (${_formatVehicleType(vehicleType)})';

                                    // Create a unique value using ID + brand + model as fallback
                                    final uniqueValue =
                                        vehicleId.isNotEmpty &&
                                                vehicleId != 'null'
                                            ? vehicleId
                                            : '${brand}_${model}_${vehicleType}'
                                                .toLowerCase()
                                                .replaceAll(' ', '_');

                                    return DropdownMenuItem<String>(
                                      value: uniqueValue,
                                      child: Text(
                                        vehicleName,
                                        style: isSmallScreen
                                            ? AppFonts.montserratMainText14
                                            : AppFonts.montserratMainText14
                                                .copyWith(fontSize: 16),
                                      ),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (String? newValue) {
                                  if (newValue == null) return;

                                  // Store the selected vehicle ID
                                  controller.selectedVehicleId.value = newValue;

                                  if (newValue.isEmpty) {
                                    // "All Vehicles" selected
                                    controller.selectedVehicleType.value = '';
                                  } else {
                                    // Find the selected vehicle to get its type
                                    final selectedVehicle = vehicleController
                                        .userVehicles
                                        .firstWhere(
                                      (vehicle) {
                                        final vehicleId = (vehicle['_id'] ??
                                                vehicle['id'] ?? '')
                                            .toString();
                                        final brand =
                                            (vehicle['brand'] ?? '').toString();
                                        final model =
                                            (vehicle['model'] ?? '').toString();
                                        final vehicleType =
                                            (vehicle['category'])
                                                .toString();

                                        final uniqueValue =
                                            vehicleId.isNotEmpty &&
                                                    vehicleId != 'null'
                                                ? vehicleId
                                                : '${brand}_${model}_${vehicleType}'
                                                    .toLowerCase()
                                                    .replaceAll(' ', '_');

                                        return uniqueValue == newValue;
                                      },
                                      orElse: () => <String, dynamic>{},
                                    );

                                    if (selectedVehicle.isNotEmpty) {
                                      final vehicleType =
                                          (selectedVehicle['category'] )
                                              .toString()
                                              .toLowerCase();
                                      final onlyType =
                                          vehicleType.split('_').first;
                                      controller.selectedVehicleType.value =
                                          onlyType;
                                    }
                                  }
                                  controller.filterMechanics();
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.only(
                          left: isSmallScreen ? 12.0 : 24.0,
                          bottom: isSmallScreen ? 16.0 : 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Breakdown Category",
                            style: isSmallScreen
                                ? AppFonts.montserratBlackHeading
                                : AppFonts.montserratBlackHeading
                                    .copyWith(fontSize: 24),
                          ),
                          if (controller.selectedCategory.value.isNotEmpty)
                            GestureDetector(
                              onTap: controller.clearCategoryFilter,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Clear',
                                      style: AppFonts.montserratMainText14
                                          .copyWith(
                                        fontSize: isSmallScreen ? 10 : 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.close,
                                      size: isSmallScreen ? 14 : 16,
                                      color: AppColors.mainColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Obx(() => CategoryChips(
                                  icon: "assets/icons/engine.png",
                                  category: "Engine",
                                  isSmallScreen: isSmallScreen,
                                  isSelected:
                                      controller.selectedCategory.value ==
                                          "Engine",
                                  onTap: () =>
                                      controller.selectCategory("Engine"),
                                )),
                            Obx(() => CategoryChips(
                                  icon: "assets/icons/tyre.png",
                                  category: "Tyre",
                                  isSmallScreen: isSmallScreen,
                                  isSelected:
                                      controller.selectedCategory.value ==
                                          "Tyre",
                                  onTap: () =>
                                      controller.selectCategory("Tyre"),
                                )),
                            Obx(() => CategoryChips(
                                  icon: "assets/icons/brake.png",
                                  category: "Brakes",
                                  isSmallScreen: isSmallScreen,
                                  isSelected:
                                      controller.selectedCategory.value ==
                                          "Brakes",
                                  onTap: () =>
                                      controller.selectCategory("Brakes"),
                                )),
                            
                          ],
                        ),
                      ),
                    ),

                    // Show active filters
                    if (controller.selectedCategory.value.isNotEmpty ||
                        controller.selectedVehicleId.value.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          left: isSmallScreen ? 12.0 : 24.0,
                          top: isSmallScreen ? 16.0 : 20.0,
                          bottom: isSmallScreen ? 8.0 : 12.0,
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (controller.selectedVehicleId.value.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mainColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getSelectedVehicleName(controller),
                                      style: AppFonts.montserratWhiteText
                                          .copyWith(
                                        fontSize: isSmallScreen ? 10 : 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: controller.clearVehicleFilter,
                                      child: Icon(
                                        Icons.close,
                                        size: isSmallScreen ? 14 : 16,
                                        color: AppColors.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (controller.selectedCategory.value.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[600],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Specialty: ${controller.selectedCategory.value}',
                                      style: AppFonts.montserratWhiteText
                                          .copyWith(
                                        fontSize: isSmallScreen ? 10 : 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: controller.clearCategoryFilter,
                                      child: Icon(
                                        Icons.close,
                                        size: isSmallScreen ? 14 : 16,
                                        color: AppColors.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                    SizedBox(
                      height: isSmallScreen
                          ? screenSize.height * 0.03
                          : screenSize.height * 0.05,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: isSmallScreen ? 12.0 : 24.0,
                          bottom: isSmallScreen ? 8.0 : 16.0),
                      child: Row(
                        children: [
                          Text(
                            "Suggested Mechanics",
                            style: isSmallScreen
                                ? AppFonts.montserratBlackHeading
                                : AppFonts.montserratBlackHeading
                                    .copyWith(fontSize: 24),
                          ),
                        ],
                      ),
                    ),

                    // Show filtered mechanics count
                    Padding(
                      padding: EdgeInsets.only(
                        left: isSmallScreen ? 12.0 : 24.0,
                        bottom: isSmallScreen ? 16.0 : 20.0,
                      ),
                      child: Text(
                        _getFilterMessage(controller),
                        style: isSmallScreen
                            ? AppFonts.montserratMainText14
                            : AppFonts.montserratMainText14
                                .copyWith(fontSize: 16),
                      ),
                    ),

                    if (isLargeScreen) ...[
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: controller.filteredMechanics.length,
                        itemBuilder: (context, index) {
                          final mechanic = controller.filteredMechanics[index];
                          return GestureDetector(
                            onTap: () {
                              _navigateToMechanicDetail(
                                  _mechanicToMap(mechanic));
                            },
                            child: MechanicCard(
                              mechanic: mechanic.fullName,
                              expertise: mechanic.expertiseString,
                              phNum: mechanic.phoneNumber,
                              distance:
                                  "${mechanic.calculateDistance(userLat, userLng).toStringAsFixed(1)} km",
                              imageSource: mechanic.profilePicture,
                              rating: mechanic.yearsOfExperience > 0
                                  ? "${mechanic.yearsOfExperience} yrs exp"
                                  : "",
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      Column(
                        children: controller.filteredMechanics
                            .map((mechanic) => GestureDetector(
                                  onTap: () {
                                    _navigateToMechanicDetail(
                                        _mechanicToMap(mechanic));
                                  },
                                  child: MechanicCard(
                                    mechanic: mechanic.fullName,
                                    expertise: mechanic.expertiseString,
                                    phNum: mechanic.phoneNumber,
                                    distance:
                                        "${mechanic.calculateDistance(userLat, userLng).toStringAsFixed(1)} km",
                                    imageSource: mechanic.profilePicture,
                                    rating: mechanic.yearsOfExperience > 0
                                        ? "${mechanic.yearsOfExperience} yrs exp"
                                        : "",
                                  ),
                                ))
                            .toList(),
                      ),
                    ],

                    // Show message when no mechanics found
                    if (controller.filteredMechanics.isEmpty &&
                        (controller.selectedVehicleType.value.isNotEmpty ||
                            controller.selectedCategory.value.isNotEmpty))
                      Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 20.0 : 30.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.car_repair,
                              size: isSmallScreen ? 50 : 70,
                              color: AppColors.mainColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getNoMechanicsMessage(controller),
                              style: isSmallScreen
                                  ? AppFonts.montserratBlackHeading
                                  : AppFonts.montserratBlackHeading
                                      .copyWith(fontSize: 20),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try selecting different filters or check back later',
                              style: isSmallScreen
                                  ? AppFonts.montserratMainText14
                                  : AppFonts.montserratMainText14
                                      .copyWith(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                controller.clearAllFilters();
                              },
                              child: Text('Clear All Filters'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _navigateToMechanicDetail(Map<String, dynamic> mechanicData) {
    // Validate mechanic ID before navigation
    final mechanicId = mechanicData['_id'] ?? mechanicData['id'];

    if (mechanicId == null || mechanicId.toString().isEmpty) {
      print('⚠️ Mechanic ID is empty, but allowing navigation for debugging');
      print('🔍 Mechanic data available: ${mechanicData.keys}');
      print('🔍 Mechanic name: ${mechanicData['full_name']}');

      // Allow navigation even without ID for now, but show warning
      Get.snackbar(
        'Info',
        'Showing mechanic details (limited functionality)',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } else {
      print('✅ Navigating to mechanic detail with ID: $mechanicId');
    }

    Get.to(
      () => MechanicDetailScreen(mechanic: mechanicData),
      transition: Transition.rightToLeft,
      duration: Duration(milliseconds: 300),
    );
  }

  String _getFilterMessage(MechanicController controller) {
    final count = controller.filteredMechanics.length;
    final vehicleType = controller.selectedVehicleType.value;
    final category = controller.selectedCategory.value;

    if (vehicleType.isEmpty && category.isEmpty) {
      return "Showing all $count mechanics";
    } else if (vehicleType.isNotEmpty && category.isEmpty) {
      return "Showing $count ${count == 1 ? 'mechanic' : 'mechanics'} for ${_formatVehicleType(vehicleType).toLowerCase()}";
    } else if (vehicleType.isEmpty && category.isNotEmpty) {
      return "Showing $count ${count == 1 ? 'mechanic' : 'mechanics'} specializing in $category";
    } else {
      return "Showing $count ${count == 1 ? 'mechanic' : 'mechanics'} for ${_formatVehicleType(vehicleType).toLowerCase()} specializing in $category";
    }
  }

  String _getNoMechanicsMessage(MechanicController controller) {
    final vehicleType = controller.selectedVehicleType.value;
    final category = controller.selectedCategory.value;

    if (vehicleType.isNotEmpty && category.isNotEmpty) {
      return 'No mechanics found for ${_formatVehicleType(vehicleType).toLowerCase()} specializing in $category';
    } else if (vehicleType.isNotEmpty) {
      return 'No mechanics found for ${_formatVehicleType(vehicleType).toLowerCase()}';
    } else {
      return 'No mechanics found specializing in $category';
    }
  }

  String _formatVehicleType(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'motorcycle':
      case 'bike':
      case 'scooter':
        return 'Motorcycle';
      case 'car':
      case 'sedan':
      case 'suv':
      case 'hatchback':
        return 'Car';
      case 'truck':
      case 'lorry':
        return 'Truck';
      case 'bus':
      case 'coach':
        return 'Bus';
      case 'van':
      case 'minivan':
        return 'Van';
      default:
        return vehicleType;
    }
  }

  // Helper method to get selected vehicle name for display
  String _getSelectedVehicleName(MechanicController controller) {
    if (controller.selectedVehicleId.value.isEmpty) return '';

    final vehicle = Get.find<VehicleController>().userVehicles.firstWhere(
      (v) {
        final vehicleId = (v['_id'] ?? v['id'] ?? '').toString();
        final brand = (v['brand'] ?? '').toString();
        final model = (v['model'] ?? '').toString();
        final vehicleType = (v['category']).toString();

        final uniqueValue = vehicleId.isNotEmpty && vehicleId != 'null'
            ? vehicleId
            : '${brand}_${model}_${vehicleType}'.toLowerCase().replaceAll(' ', '_');

        return uniqueValue == controller.selectedVehicleId.value;
      },
      orElse: () => <String, dynamic>{},
    );

    if (vehicle.isNotEmpty) {
      final brand = (vehicle['brand'] ?? 'Unknown Brand').toString();
      final model = (vehicle['model'] ?? 'Unknown Model').toString();
      final vehicleType = (vehicle['category']).toString();
      return '$brand $model (${_formatVehicleType(vehicleType)})';
    }

    return 'Selected Vehicle';
  }

  Map<String, dynamic> _mechanicToMap(Mechanic mechanic) {
    // Debug: Check all possible ID fields
    print('🔍 Debug mechanic ID fields:');
    print('   - mechanic.id: "${mechanic.id}"');
    print('   - mechanic.id isEmpty: ${mechanic.id.isEmpty}');
    print('   - mechanic.id length: ${mechanic.id.length}');

    // Use the mechanic's ID directly (it should now come from _id field)
    String mechanicId = mechanic.id;

    // If still empty, try toJson approach
    if (mechanicId.isEmpty) {
      final mechanicJson = mechanic.toJson();
      mechanicId = mechanicJson['_id'] ?? mechanicJson['id'] ?? '';
    }

    print('✅ Final mechanic ID: "$mechanicId"');

    // Create the map with proper data
    return {
      '_id': mechanicId,
      'id': mechanicId,
      'full_name': mechanic.fullName,
      'expertise': mechanic.expertiseString,
      'phone_number': mechanic.phoneNumber,
      'profile_picture': mechanic.profilePicture,
      'years_of_experience': mechanic.yearsOfExperience,
      'city': mechanic.city,
      'address': mechanic.address,
      'workshop_name': mechanic.workshopName,
      'email': mechanic.email,
      'latitude': mechanic.latitude,
      'longitude': mechanic.longitude,
      'province': mechanic.province,
      'cnic': mechanic.cnic,
      'average_rating': 4.5, // Default values
      'is_verified': true,
      'is_available': true,
      'total_feedbacks': 0,
      'working_days': mechanic.workingDays.isNotEmpty
          ? mechanic.workingDays
          : ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      'working_hours': {
        'start_time':
            mechanic.startTime.isNotEmpty ? mechanic.startTime : '09:00',
        'end_time': mechanic.endTime.isNotEmpty ? mechanic.endTime : '18:00',
      },
      'serviced_vehicle_types': mechanic.servicedVehicleTypes,
    };
  }
}