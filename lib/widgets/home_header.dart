import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
import 'package:flutter/material.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import '../screens/auth/controller/shared_pref_helper.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeHeaderBox extends StatefulWidget {
  const HomeHeaderBox({super.key});

  @override
  _HomeHeaderBoxState createState() => _HomeHeaderBoxState();
}

class _HomeHeaderBoxState extends State<HomeHeaderBox> {
  final SharedPrefsHelper _sharedPrefs = SharedPrefsHelper();
  final VehicleController vehicleController = Get.find<VehicleController>();
  
  int? selectedIndex;
  String userName = 'Guest';
  List<dynamic> userVehicles = []; // Store user vehicles

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadUserVehicles(); // Load user vehicles
  }

  Future<void> _loadUserName() async {
    final name = await _sharedPrefs.getString("full_name");

    if (mounted) {
      setState(() {
        userName = (name != null && name.trim().isNotEmpty) ? name : "User";
      });
    }
    print("Loaded from prefs: full_name=$name");
  }

  // Load user vehicles
  Future<void> _loadUserVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id");

      if (userId != null && userId.isNotEmpty) {
        final vehicles = await vehicleController.getUserVehicles(userId);
        if (mounted) {
          setState(() {
            userVehicles = vehicles ?? [];
          });
        }
      }
    } catch (e) {
      print('Error loading vehicles for home header: $e');
      if (mounted) {
        setState(() {
          userVehicles = [];
        });
      }
    }
  }

  // Build vehicle chip widget
  Widget _buildVehicleChip(Map<String, dynamic> vehicle) {
    // Get vehicle type for icon
    IconData vehicleIcon;
    switch (vehicle['type']?.toString().toLowerCase()) {
      case 'car':
        vehicleIcon = Icons.directions_car;
        break;
      case 'bike':
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

    return GestureDetector(
      onTap: () {
        Get.toNamed('/my-vehicles');
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.secondaryColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(vehicleIcon, size: 16, color: AppColors.mainColor),
            SizedBox(width: 6),
            Text(
              '${vehicle['brand'] ?? 'Vehicle'} ${vehicle['model'] ?? ''}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mainColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (vehicle['is_primary'] == true)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.star, size: 12, color: Colors.amber),
              ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(35, 10, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello $userName",
            style: AppFonts.HomeheaderBox,
          ),
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
          
          // Display vehicle chip if vehicles exist
          if (userVehicles != null && userVehicles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildVehicleChip(userVehicles.first),
            )
          else
            GestureDetector(
              onTap: () {
                Get.toNamed('/add-vehicle');
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Add Vehicle',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 10),
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