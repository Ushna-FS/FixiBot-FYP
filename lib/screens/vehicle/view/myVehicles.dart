import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/screens/vehicle/view/editVehicle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/vehicleController.dart';

class MyVehicleScreen extends StatefulWidget {
  const MyVehicleScreen({super.key});

  @override
  State<MyVehicleScreen> createState() => _MyVehicleScreenState();
}

class _MyVehicleScreenState extends State<MyVehicleScreen> {
  final VehicleController vehicleController = Get.find<VehicleController>();
  bool isLoading = true;
  List<dynamic>? vehicles; // Make it nullable

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
  try {
    setState(() => isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");
    
    if (userId == null || userId.isEmpty) {
      Get.snackbar("Error", "User not logged in");
      setState(() {
        isLoading = false;
        vehicles = [];
      });
      return;
    }

    final result = await vehicleController.getUserVehicles(userId);
    
    // Ensure all vehicles are properly typed
    final typedVehicles = result?.map((vehicle) {
      return vehicle is Map<String, dynamic> 
          ? vehicle 
          : Map<String, dynamic>.from(vehicle);
    }).toList() ?? [];
    
    setState(() {
      vehicles = typedVehicles;
      isLoading = false;
    });
  } catch (e) {
    setState(() {
      isLoading = false;
      vehicles = [];
    });
    Get.snackbar("Error", "Failed to load vehicles: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    // Safe check for null or empty
    final bool showEmptyState = vehicles == null || vehicles!.isEmpty;

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Text("Vehicles Information",
            style: AppFonts.montserrathomecardText),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Image.asset('assets/icons/back.png', width: 30, height: 30),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.mainColor),
            onPressed: _loadVehicles,
          ),
        ],
      ),
      backgroundColor: AppColors.secondaryColor,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.mainColor))
          : showEmptyState
              ? _buildEmptyState()
              : _buildVehicleList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/add-vehicle'),
        backgroundColor: AppColors.mainColor,
        child: Icon(Icons.add, color: AppColors.secondaryColor),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car,
              size: 64, color: AppColors.mainColor.withOpacity(0.5)),
          SizedBox(height: 16),
          Text(
            "No vehicles found",
            style: AppFonts.montserratMainText.copyWith(
              color: AppColors.mainColor.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Add your first vehicle to get started",
            style: AppFonts.montserratText5.copyWith(
              color: AppColors.mainColor.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Get.toNamed('/add-vehicle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              "Add Vehicle",
              style: AppFonts.montserratMainText14.copyWith(
                color: AppColors.secondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList() {
    // One more safety check
    if (vehicles == null || vehicles!.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "My Vehicles (${vehicles!.length})",
            style: AppFonts.montserratMainText.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: vehicles!.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles![index];
                return _buildVehicleCard(vehicle);
              },
            ),
          ),
        ],
      ),
    );
  }
Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
  return Card(
    margin: EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car, color: AppColors.mainColor, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "${vehicle['brand'] ?? 'Unknown'} ${vehicle['model'] ?? ''}",
                  style: AppFonts.montserratMainText.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (vehicle['is_primary'] == true)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Primary",
                    style: AppFonts.montserratText5.copyWith(
                      color: AppColors.mainColor,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          
          // FIXED: First chip row with horizontal scrolling
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildInfoChip(Icons.calendar_today, "${vehicle['year'] ?? 'N/A'}"),
                SizedBox(width: 8),
                _buildInfoChip(Icons.settings, "${vehicle['transmission'] ?? 'N/A'}"),
                SizedBox(width: 8),
                _buildInfoChip(Icons.local_gas_station, "${vehicle['fuel_type'] ?? 'N/A'}"),
              ],
            ),
          ),
          
          SizedBox(height: 12),
          
          // FIXED: Second chip row with horizontal scrolling
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildInfoChip(Icons.category, "${vehicle['type'] ?? 'N/A'}"),
                SizedBox(width: 8),
                if (vehicle['mileage_km'] != null)
                  _buildInfoChip(Icons.speed, "${vehicle['mileage_km']} km"),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _editVehicle(vehicle),
                child: Text("Edit", style: TextStyle(color: AppColors.mainColor)),
              ),
              SizedBox(width: 8),
              TextButton(
                onPressed: () => _deleteVehicle(vehicle['_id']),
                child: Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      margin: EdgeInsets.only(right: 6),
      child: Chip(
        backgroundColor: AppColors.secondaryColor,
        side: BorderSide(color: AppColors.mainColor.withOpacity(0.3)),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        labelPadding: EdgeInsets.symmetric(horizontal: 2),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: AppColors.mainColor),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                _truncateText(text, 10), // Truncate long text
                style: AppFonts.montserratText5.copyWith(
                  fontSize: 10,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Add this helper method to truncate long text
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  }
void _editVehicle(Map<String, dynamic> vehicle) {
  // Navigate to edit vehicle screen with the vehicle data
  Get.to(
    const EditVehicle(),
    arguments: {
      'vehicle': vehicle,
      'onUpdate': (Map<String, dynamic> updatedVehicle) async {
        // This callback will be called when the vehicle is updated
        await _updateVehicleInList(updatedVehicle);
      },
    },
  );
}

Future<void> _updateVehicleInList(Map<String, dynamic> updatedVehicle) async {
  try {
    // Quick null check
    if (vehicles == null) return;
    
    final vehicleId = updatedVehicle['_id'];
    if (vehicleId == null) return;

    // Find index with null-safe access
    int index = -1;
    for (int i = 0; i < vehicles!.length; i++) {
      final v = vehicles![i];
      final currentId = v['_id'];
      if (currentId == vehicleId) {
        index = i;
        break;
      }
    }
    
    if (index != -1) {
      setState(() {
        // Simple merge with type casting
        vehicles![index] = {
          ...(vehicles![index] as Map<String, dynamic>), 
          ...(updatedVehicle as Map<String, dynamic>)
        };
      });
      
      Future.delayed(Duration(milliseconds: 100), () {
        Get.snackbar("Success", "Vehicle updated successfully");
      });
    }
  } catch (e) {
    print('❌ Error: $e');
    Future.delayed(Duration(milliseconds: 100), () {
      Get.snackbar("Error", "Failed to update vehicle");
    });
  }
}


  Future<void> _deleteVehicle(String? vehicleId) async {
    if (vehicleId == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Are you sure you want to delete this vehicle?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await vehicleController.deleteVehicle(vehicleId);
        Get.snackbar("Success", "Vehicle deleted successfully");
        _loadVehicles();
      } catch (e) {
        Get.snackbar("Error", "Failed to delete vehicle: $e");
      }
    }
  }
}
