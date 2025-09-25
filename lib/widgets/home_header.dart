import 'package:fixibot_app/screens/profile/controller/userController.dart';
import 'package:fixibot_app/screens/vehicle/view/addVehicle.dart';
import 'package:flutter/material.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import '../screens/auth/controller/shared_pref_helper.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';

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

  int? selectedIndex;


  @override
  void initState() {
    super.initState();
    _loadUserName();
  _fetchVehicles();
  }

  @override
  void didUpdateWidget(HomeHeaderBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fetchVehicles();
  }




  Future<void> _loadUserName() async {
    final name = await _sharedPrefs.getString("full_name");
    final email = await _sharedPrefs.getString("email");
    if (name != null && name.isNotEmpty) {
      userController.updateUser(name, email ?? "");
    }
  }

Future<void> _fetchVehicles() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString("user_id");
  if (userId != null && userId.isNotEmpty) {
    await vehicleController.getUserVehicles(userId);
  }
}


  // Build vehicle chip widget
  Widget _buildVehicleChip(Map<String, dynamic> vehicle, bool isPrimary) {
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

          // Display vehicle chips - FIXED: Show all vehicles, not just first
          Obx(() {
            final vehicles = vehicleController.userVehicles;
            if (vehicles.isEmpty) {
              return const Text('No Vehicle Added',
                  style: TextStyle(fontSize: 12, color: Colors.white));
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vehicles.map((v) {
                final isPrimary = v['is_primary'] == true;
                return _buildVehicleChip(v, isPrimary);
              }).toList(),
            );
          }),

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
