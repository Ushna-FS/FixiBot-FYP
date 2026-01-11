import 'package:fixibot_app/constants/app_errors.dart';
import 'package:fixibot_app/screens/profile/controller/userController.dart';
import 'package:fixibot_app/screens/vehicle/view/addVehicle.dart';
import 'package:fixibot_app/widgets/custom_buttons.dart';
import 'package:flutter/material.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import '../screens/auth/controller/shared_pref_helper.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; 
class HomeHeaderBox extends StatefulWidget {
  final VoidCallback? onRefresh;
  const HomeHeaderBox({super.key, this.onRefresh});

  @override
  _HomeHeaderBoxState createState() => _HomeHeaderBoxState();
}

class _HomeHeaderBoxState extends State<HomeHeaderBox> {
  final SharedPrefsHelper _sharedPrefs = SharedPrefsHelper();
  final VehicleController vehicleController = Get.find<VehicleController>();
  final UserController userController = Get.find<UserController>();
  final Connectivity _connectivity = Connectivity();
  
  RxBool hasInternet = true.obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    _loadUserName();
    _fetchVehicles();
    
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        hasInternet.value = true;
        // Retry fetching vehicles when connection is restored
        _fetchVehicles();
      } else {
        hasInternet.value = false;
        errorMessage.value = 'No internet connection';
      }
    });
  }

  Future<void> _checkInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      hasInternet.value = connectivityResult != ConnectivityResult.none;
      if (!hasInternet.value) {
        errorMessage.value = 'No internet connection';
      }
    } catch (e) {
      AppErrors.showError('Failed to check internet connection');
    }
  }

  Future<void> _loadUserName() async {
    try {
      final name = await _sharedPrefs.getString("full_name");
      final email = await _sharedPrefs.getString("email");
      if (name != null && name.isNotEmpty) {
        userController.updateUser(name, email ?? "");
      }
    } catch (e) {
      AppErrors.showError('Failed to load user information');
    }
  }

  // Future<void> _fetchVehicles() async {
  //   // Don't try to fetch if no internet
  //   if (!hasInternet.value) {
  //     errorMessage.value = 'No internet connection';
  //     return;
  //   }

  //   isLoading.value = true;
  //   errorMessage.value = '';

  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final userId = prefs.getString("user_id");
      
  //     if (userId != null && userId.isNotEmpty) {
  //       await vehicleController.fetchUserVehicles();
  //     } else {
  //       errorMessage.value = 'User session expired. Please login again.';
  //     }
  //   } catch (e) {
  //     errorMessage.value = AppErrors.humanReadableError(e);
  //     // Optional: Show error toast
  //     AppErrors.showError(errorMessage.value);
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }


Future<void> _fetchVehicles() async {
  // Don't show loading if we already have cached vehicles
  if (vehicleController.userVehicles.isNotEmpty) {
    // Don't reset isLoading to true if we have data
    // This prevents the loading state when coming back from chat
    if (!isLoading.value) return;
  }

  // Don't try to fetch if no internet but show cached data
  if (!hasInternet.value) {
    if (vehicleController.userVehicles.isEmpty) {
      errorMessage.value = 'No internet connection';
    }
    return;
  }

  // Only show loading if we have no vehicles
  if (vehicleController.userVehicles.isEmpty) {
    isLoading.value = true;
  }
  
  errorMessage.value = '';

  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");
    
    if (userId != null && userId.isNotEmpty) {
      await vehicleController.fetchUserVehicles();
    } else {
      // Only show error if we have no cached vehicles
      if (vehicleController.userVehicles.isEmpty) {
        errorMessage.value = 'User session expired. Please login again.';
      }
    }
  } catch (e) {
    // Don't show error if we have cached vehicles
    if (vehicleController.userVehicles.isEmpty) {
      errorMessage.value = AppErrors.humanReadableError(e);
    } else {
      // Show toast but don't set error message
      AppErrors.showError('Cannot refresh: ${AppErrors.humanReadableError(e)}');
    }
  } finally {
    isLoading.value = false;
  }
}


  Widget _buildVehicleChip(Map<String, dynamic> vehicle, bool isPrimary) {
    IconData vehicleIcon;
    Color iconColor = AppColors.mainColor;
    
    final category = vehicle['category']?.toString().toLowerCase() ?? '';
    
    switch (category) {
      case 'car':
        vehicleIcon = Icons.directions_car;
        break;
      case 'motorcycle':
        vehicleIcon = Icons.motorcycle;
        break;
      case 'truck':
        vehicleIcon = Icons.local_shipping;
        break;
      case 'suv':
        vehicleIcon = Icons.airport_shuttle;
        break;
      default:
        vehicleIcon = Icons.directions_car;
    }

    final brand = vehicle['brand'] ?? 'Vehicle';
    final model = vehicle['model'] ?? '';
    final displayName = '$brand $model'.trim();

    return GestureDetector(
      onTap: () {
        Get.toNamed('/my-vehicles');
      },
      child: Container(
        margin: EdgeInsets.only(right: 8, bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.secondaryColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(vehicleIcon, size: 16, color: iconColor),
            SizedBox(width: 6),
            Text(
              displayName.isEmpty ? 'Unnamed Vehicle' : displayName,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mainColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isPrimary)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.star, size: 12, color: Colors.amber),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.white),
        SizedBox(height: 16),
        Text(
          'Loading your vehicles...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.white.withOpacity(0.7),
        ),
        SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Please check your connection and try again',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        CustomButton(
          text: 'Retry',
          color: AppColors.mainSwatch.shade200,
          onPressed: () => _fetchVehicles(),
        ),
      ],
    );
  }

  Widget _buildNoVehiclesState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.directions_car_outlined,
          size: 64,
          color: Colors.white.withOpacity(0.7),
        ),
        SizedBox(height: 16),
        Text(
          'No Vehicles Added Yet',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Add your first vehicle to get started',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        CustomButton(
          text: 'Add Vehicle',
          color: AppColors.mainSwatch.shade200,
          onPressed: () {
            Get.to(() => AddVehicle());
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFF715B),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(110),
          bottomRight: Radius.circular(110),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(35, 10, 35, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Text(
                "Hello ${userController.fullName.value}",
                style: AppFonts.HomeheaderBox,
              )),
          Text(
            "Start Your Smart Journey.",
            style: AppFonts.montserratHomeAppbar,
          ),
          const SizedBox(height: 20),

          // Vehicle Section
          Text(
            "Your Vehicles",
            style: AppFonts.HomeheaderBox,
          ),
          const SizedBox(height: 10),
// In HomeHeader.dart build method - Update the Obx widget:
Obx(() {
  final vehicles = vehicleController.userVehicles;
  final isLoading = vehicleController.isLoading.value;
  final hasError = vehicleController.hasError.value;
  final errorMsg = vehicleController.errorMessage.value;
  
  // Always show cached vehicles if we have them, even if loading/error
  if (vehicles.isNotEmpty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show error banner above vehicles if there's an error
        if (hasError && errorMsg.isNotEmpty)
          Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMsg,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Show the vehicles
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: vehicles.map((v) {
            final isPrimary = v['is_primary'] == true;
            return _buildVehicleChip(v, isPrimary);
          }).toList(),
        ),
        
        // Show loading indicator at bottom if refreshing
        if (isLoading)
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
      ],
    );
  }
  
  // No vehicles - show loading/error states
  if (isLoading) {
    return _buildLoadingState();
  }
  
  if (hasError && errorMsg.isNotEmpty) {
    return _buildErrorState(errorMsg);
  }
  
  return _buildNoVehiclesState();
}),


          // Display vehicle chips with proper error handling
//           // In HomeHeader.dart, update the vehicle display section:
// Obx(() {
//   final vehicles = vehicleController.userVehicles;
//   final isLoading = vehicleController.isLoading.value;
//   final hasError = vehicleController.hasError.value;
//   final errorMsg = vehicleController.errorMessage.value;
  
//   // Show loading state
//   if (isLoading) {
//     return Center(
//       child: CircularProgressIndicator(color: Colors.white),
//     );
//   }
  
//   // Handle error state
//   if (hasError) {
//     // Check if it's a server error (priority)
//     final isServerError = errorMsg.toLowerCase().contains('server');
    
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//     Icon(
//   isServerError
//       ? Icons.cloud_off
//       : Icons.cloud_done,
//   size: 64,
//   color: Colors.white.withOpacity(0.7),
// ),
//         SizedBox(height: 16),
//         Text(
//           isServerError ? 'Server Error' : 'Connection Error',
//           style: TextStyle(
//             fontSize: 18,
//             color: Colors.white,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         SizedBox(height: 8),
//         Text(
//           errorMsg.isNotEmpty ? errorMsg : 
//           isServerError ? 'Server is currently unavailable' : 'Check your internet connection',
//           style: TextStyle(
//             fontSize: 14,
//             color: Colors.white70,
//           ),
//           textAlign: TextAlign.center,
//         ),
//         SizedBox(height: 16),
//         // Show vehicles if we have cached data, even with server error
//         if (vehicles.isNotEmpty) ...[
//           Text(
//             'Showing cached data',
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.white60,
//               fontStyle: FontStyle.italic,
//             ),
//           ),
//           SizedBox(height: 16),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: vehicles.map((v) {
//               final isPrimary = v['is_primary'] == true;
//               return _buildVehicleChip(v, isPrimary);
//             }).toList(),
//           ),
//         ],
//       ],
//     );
//   }
  
//   // No vehicles (but no error)
//   if (vehicles.isEmpty) {
//     return Column(
//       children: [
//         Icon(
//           Icons.directions_car_outlined,
//           size: 64,
//           color: Colors.white.withOpacity(0.7),
//         ),
//         SizedBox(height: 16),
//         Text(
//           'No Vehicles Yet',
//           style: TextStyle(
//             fontSize: 18,
//             color: Colors.white,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         SizedBox(height: 8),
//         Text(
//           'Add your first vehicle to get started',
//           style: TextStyle(
//             fontSize: 14,
//             color: Colors.white70,
//           ),
//           textAlign: TextAlign.center,
//         ),
//         SizedBox(height: 24),
//         CustomButton(
//           text: 'Add Vehicle',
//           color: AppColors.mainSwatch.shade200,
//           onPressed: () {
//             Get.to(() => AddVehicle());
//           },
//         ),
//       ],
//     );
//   }
  
//   // Has vehicles - display them
//   return Wrap(
//     spacing: 8,
//     runSpacing: 8,
//     children: vehicles.map((v) {
//       final isPrimary = v['is_primary'] == true;
//       return _buildVehicleChip(v, isPrimary);
//     }).toList(),
//   );
// }),


          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(width: 25),
              ],
            ),
          )
        ],
      ),
    );
  }
}