///perfect
import 'package:fixibot_app/screens/mechanics/controller/mechanicController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
import 'package:fixibot_app/widgets/customAppBar.dart';

class MechanicServicesPage extends StatelessWidget {
  final MechanicController controller = Get.find<MechanicController>();
  final VehicleController vehicleController = Get.find<VehicleController>();

  MechanicServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.mainColor,
        title: Text(
          "My Mechanic Services",
          style: isSmallScreen
              ? AppFonts.montserratWhiteText
              : AppFonts.montserratWhiteText.copyWith(fontSize: 18),
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
          // Refresh button
          IconButton(
            onPressed: () {
              controller.getUserMechanicServices();
            },
            icon: Icon(Icons.refresh, color: AppColors.secondaryColor),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(context),
          Expanded(
            child: Obx(() {
              // Use filtered services for display
              final displayServices = controller.filteredServices.isEmpty && 
                                    controller.searchQuery.isEmpty
                  ? controller.mechanicServices
                  : controller.filteredServices;

              if (controller.isServicesLoading.value && displayServices.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.mainColor,
                  ),
                );
              }

              // Show error but still display any available services
              if (controller.servicesErrorMessage.value.isNotEmpty) {
                return Column(
                  children: [
                    // Error banner
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      color: Colors.orange[100],
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange[800]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.servicesErrorMessage.value,
                              style: AppFonts.montserratText2.copyWith(
                                color: Colors.orange[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 16),
                            onPressed: () {
                              controller.servicesErrorMessage.value = '';
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildServicesList(displayServices, context),
                    ),
                  ],
                );
              }

              return _buildServicesList(displayServices, context);
            }),
          ),
        ],
      ),
    );
  }


  Widget _buildSearchBar(BuildContext context) {
  final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
  
  return Container(
    padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
    color: AppColors.secondaryColor,
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 800),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller.searchController,
            onChanged: (value) {
              controller.searchServices(value);
            },
            decoration: InputDecoration(
              hintText: "Search services by mechanic, vehicle, issue, or status...",
              hintStyle: AppFonts.montserratGreyText14,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isSmallScreen ? 14 : 16,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.mainColor,
                size: isSmallScreen ? 20 : 24,
              ),
              suffixIcon: Obx(() => controller.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppColors.mainColor,
                        size: isSmallScreen ? 18 : 22,
                      ),
                      onPressed: () {
                        controller.clearSearch();
                      },
                    )
                  : SizedBox.shrink()), // ✅ FIX: Use SizedBox.shrink() instead of null
            ),
            style: isSmallScreen
                ? AppFonts.montserratText2
                : AppFonts.montserratText2.copyWith(fontSize: 16),
          ),
        ),
      ),
    ),
  );
}





  

  Widget _buildServicesList(List<dynamic> services, BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;

    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (controller.searchQuery.isNotEmpty) ...[
              Icon(
                Icons.search_off,
                size: 80,
                color: AppColors.mainColor.withOpacity(0.5),
              ),
              SizedBox(height: 16),
              Text(
                'No Services Found',
                style: isSmallScreen
                    ? AppFonts.montserratBlackHeading
                    : AppFonts.montserratBlackHeading.copyWith(fontSize: 22),
              ),
              SizedBox(height: 8),
              Text(
                'No services match your search "${controller.searchQuery}"',
                style: isSmallScreen
                    ? AppFonts.montserratMainText14
                    : AppFonts.montserratMainText14.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  controller.clearSearch();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Clear Search',
                  style: AppFonts.montserratWhiteText,
                ),
              ),
            ] else ...[
              Icon(
                Icons.car_repair,
                size: 80,
                color: AppColors.mainColor.withOpacity(0.5),
              ),
              SizedBox(height: 16),
              Text(
                'No Mechanic Services Yet',
                style: isSmallScreen
                    ? AppFonts.montserratBlackHeading
                    : AppFonts.montserratBlackHeading.copyWith(fontSize: 22),
              ),
              SizedBox(height: 8),
              Text(
                'Your mechanic service requests will appear here',
                style: isSmallScreen
                    ? AppFonts.montserratMainText14
                    : AppFonts.montserratMainText14.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Find Mechanics',
                  style: AppFonts.montserratWhiteText,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 800,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Service History (${services.length})${controller.searchQuery.isNotEmpty ? ' found' : ''}',
                    style: isSmallScreen
                        ? AppFonts.montserratBlackHeading
                        : AppFonts.montserratBlackHeading.copyWith(fontSize: 22),
                  ),
                  // Show indicators
                  Row(
                    children: [
                      if (controller.searchQuery.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 12, color: Colors.green[800]),
                              SizedBox(width: 4),
                              Text(
                                'Search: "${controller.searchQuery}"',
                                style: AppFonts.montserratText2.copyWith(
                                  fontSize: 10,
                                  color: Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_hasLocalServices(services) && !controller.searchQuery.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Local Backup',
                            style: AppFonts.montserratText2.copyWith(
                              fontSize: 10,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              ...services.map((service) => 
                _buildServiceCard(service, context)
              ).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and local indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        _formatServiceType(service['service_type'] ?? 'repair'),
                        style: isSmallScreen
                            ? AppFonts.montserratBlackHeading
                            : AppFonts.montserratBlackHeading.copyWith(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(width: 8),
                      // Show local backup indicator
                      if (service['local_backup'] == true)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            'Local',
                            style: AppFonts.montserratText2.copyWith(
                              fontSize: 8,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(service['status'] ?? 'pending'),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatStatus(service['status'] ?? 'pending'),
                    style: AppFonts.montserratWhiteText.copyWith(
                      fontSize: isSmallScreen ? 10 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Service Details
            _buildServiceDetailRow(
              'Mechanic',
              service['mechanic_name'] ?? 'Unknown Mechanic',
              Icons.person,
            ),
            
            _buildServiceDetailRow(
              'Vehicle',
              _getVehicleName(service['vehicle_id']),
              Icons.directions_car,
            ),
            
            _buildServiceDetailRow(
              'Issue',
              service['issue_description'] ?? 'Not specified',
              Icons.description,
            ),
            
            if (service['estimated_time'] != null && service['estimated_time'].toString().isNotEmpty)
              _buildServiceDetailRow(
                'Estimated Time',
                service['estimated_time'].toString(),
                Icons.access_time,
              ),
            
            if (service['service_cost'] != null && (service['service_cost'] as num) > 0)
              _buildServiceDetailRow(
                'Cost',
                'Rs. ${service['service_cost']}',
                Icons.attach_money,
              ),
            
            // Show creation date if available
            if (service['created_at'] != null)
              _buildServiceDetailRow(
                'Created',
                _formatDate(service['created_at']),
                Icons.calendar_today,
              ),
            
            SizedBox(height: 12),
            
            // ✅ UPDATED: Only show Delete button for all services, Update button for pending/in_progress
            Row(
              children: [
                if (service['status'] == 'pending' || service['status'] == 'in_progress')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _showUpdateDialog(service);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                      ),
                      child: Text(
                        'Update',
                        style: AppFonts.montserratWhiteText,
                      ),
                    ),
                  ),
                if (service['status'] == 'pending' || service['status'] == 'in_progress')
                  SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showDeleteConfirmation(service);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text(
                      'Delete',
                      style: AppFonts.montserratWhiteText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.mainColor,
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: AppFonts.montserratGreyText14.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppFonts.montserratText2.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getVehicleName(String vehicleId) {
    try {
      if (vehicleId == null || vehicleId.isEmpty) {
        return 'Unknown Vehicle';
      }
      
      final vehicle = vehicleController.userVehicles.firstWhere(
        (v) {
          final vId = v['_id'] ?? v['id'];
          return vId != null && vId.toString() == vehicleId.toString();
        },
        orElse: () => {},
      );
      
      if (vehicle.isNotEmpty) {
        final brand = vehicle['brand'] ?? '';
        final model = vehicle['model'] ?? '';
        final year = vehicle['year'] ?? '';
        
        String vehicleName = '$brand $model'.trim();
        if (year != null && year.toString().isNotEmpty) {
          vehicleName += ' ($year)';
        }
        
        return vehicleName.isEmpty ? 'Unknown Vehicle' : vehicleName;
      }
    } catch (e) {
      print('Error getting vehicle name: $e');
    }
    
    return 'Unknown Vehicle';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'In Progress';
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toString().capitalizeFirst ?? status.toString();
    }
  }

  String _formatServiceType(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'repair':
        return 'Repair Service';
      case 'maintenance':
        return 'Maintenance Service';
      case 'inspection':
        return 'Vehicle Inspection';
      case 'emergency':
        return 'Emergency Service';
      default:
        return serviceType.toString().capitalizeFirst ?? serviceType.toString();
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  bool _hasLocalServices(List<dynamic> services) {
    return services.any((service) => 
      service is Map<String, dynamic> && service['local_backup'] == true
    );
  }

  // ✅ UPDATED: Real update dialog with editable fields
  void _showUpdateDialog(Map<String, dynamic> service) {
    final TextEditingController issueController = TextEditingController(
      text: service['issue_description'] ?? ''
    );
    final TextEditingController timeController = TextEditingController(
      text: service['estimated_time'] ?? '2 hours'
    );

    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: Text(
          "Update Service Details",
          style: AppFonts.montserratBlackHeading,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Update the service details below:",
                style: AppFonts.montserratText2,
              ),
              SizedBox(height: 16),
              
              // Issue Description Field
              Text(
                "Issue Description:",
                style: AppFonts.montserratText2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: issueController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Describe the vehicle issue...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.mainColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Estimated Time Field
              Text(
                "Estimated Time:",
                style: AppFonts.montserratText2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                  hintText: "e.g., 2 hours, 1 day, 3-4 hours",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.mainColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "Cancel",
              style: AppFonts.montserratText2.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final String newIssue = issueController.text.trim();
              final String newTime = timeController.text.trim();
              
              if (newIssue.isEmpty || newTime.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Please fill in all fields',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              // Show loading
              Get.back();
              Get.dialog(
                Center(
                  child: CircularProgressIndicator(
                    color: AppColors.mainColor,
                  ),
                ),
                barrierDismissible: false,
              );

              try {
                final success = await controller.updateServiceDetails(
                  serviceId: service['_id'] ?? service['id'],
                  issueDescription: newIssue,
                  estimatedTime: newTime,
                );

                Get.back(); // Close loading dialog

                if (success) {
                  Get.snackbar(
                    'Success',
                    'Service details updated successfully!',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    'Failed to update service details',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              } catch (e) {
                Get.back(); // Close loading dialog
                Get.snackbar(
                  'Error',
                  'Failed to update: $e',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
            ),
            child: Text(
              "Save Changes",
              style: AppFonts.montserratWhiteText,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: Delete confirmation dialog
  void _showDeleteConfirmation(Map<String, dynamic> service) {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Service',
          style: AppFonts.montserratBlackHeading,
        ),
        content: Text(
          'Are you sure you want to delete this service record? This action cannot be undone.',
          style: AppFonts.montserratText2,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'No, Keep',
              style: AppFonts.montserratText2,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              
              // Show loading
              Get.dialog(
                Center(
                  child: CircularProgressIndicator(
                    color: AppColors.mainColor,
                  ),
                ),
                barrierDismissible: false,
              );

              final serviceId = service['_id'] ?? service['id'];
              if (serviceId != null) {
                final success = await controller.deleteService(serviceId.toString());
                
                Get.back(); // Close loading dialog

                if (success) {
                  Get.snackbar(
                    'Success',
                    'Service deleted successfully',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    'Failed to delete service',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              } else {
                Get.back(); // Close loading dialog
                Get.snackbar(
                  'Error',
                  'Cannot delete service without ID',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Yes, Delete',
              style: AppFonts.montserratWhiteText,
            ),
          ),
        ],
      ),
    );
  }
}













//TRY/////////////
// import 'package:fixibot_app/screens/mechanics/controller/mechanicController.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:fixibot_app/constants/app_colors.dart';
// import 'package:fixibot_app/constants/app_fontStyles.dart';
// import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
// import 'package:fixibot_app/widgets/customAppBar.dart';

// class MechanicServicesPage extends StatelessWidget {
//   final MechanicController controller = Get.find<MechanicController>();
//   final VehicleController vehicleController = Get.find<VehicleController>();

//   MechanicServicesPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final Size screenSize = MediaQuery.of(context).size;
//     final bool isSmallScreen = screenSize.width < 600;

//     return Scaffold(
//       backgroundColor: AppColors.secondaryColor,
//       appBar: AppBar(
//         backgroundColor: AppColors.mainColor,
//         title: Text(
//           "My Mechanic Services",
//           style: isSmallScreen
//               ? AppFonts.montserratWhiteText
//               : AppFonts.montserratWhiteText.copyWith(fontSize: 18),
//         ),
//         leading: IconButton(
//           onPressed: () {
//             Get.back();
//           },
//           icon: Image.asset(
//             'assets/icons/back.png',
//             color: AppColors.secondaryColor,
//             width: isSmallScreen ? 24 : 30,
//             height: isSmallScreen ? 24 : 30,
//           ),
//         ),
//         centerTitle: true,
//         actions: [
//           // Refresh button
//           IconButton(
//             onPressed: () {
//               controller.getUserMechanicServices();
//             },
//             icon: Icon(Icons.refresh, color: AppColors.secondaryColor),
//           ),
//         ],
//       ),
//       body: Obx(() {
//         // Use combined services for display
//         final displayServices = controller.mechanicServices;

//         if (controller.isServicesLoading.value && displayServices.isEmpty) {
//           return const Center(
//             child: CircularProgressIndicator(
//               color: AppColors.mainColor,
//             ),
//           );
//         }

//         // Show error but still display any available services
//         if (controller.servicesErrorMessage.value.isNotEmpty) {
//           return Column(
//             children: [
//               // Error banner
//               Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.all(12),
//                 color: Colors.orange[100],
//                 child: Row(
//                   children: [
//                     Icon(Icons.warning_amber, color: Colors.orange[800]),
//                     SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         controller.servicesErrorMessage.value,
//                         style: AppFonts.montserratText2.copyWith(
//                           color: Colors.orange[800],
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.close, size: 16),
//                       onPressed: () {
//                         controller.servicesErrorMessage.value = '';
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: _buildServicesList(displayServices, context),
//               ),
//             ],
//           );
//         }

//         return _buildServicesList(displayServices, context);
//       }),
//     );
//   }

//   Widget _buildServicesList(List<dynamic> services, BuildContext context) {
//     final Size screenSize = MediaQuery.of(context).size;
//     final bool isSmallScreen = screenSize.width < 600;

//     if (services.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.car_repair,
//               size: 80,
//               color: AppColors.mainColor.withOpacity(0.5),
//             ),
//             SizedBox(height: 16),
//             Text(
//               'No Mechanic Services Yet',
//               style: isSmallScreen
//                   ? AppFonts.montserratBlackHeading
//                   : AppFonts.montserratBlackHeading.copyWith(fontSize: 22),
//             ),
//             SizedBox(height: 8),
//             Text(
//               'Your mechanic service requests will appear here',
//               style: isSmallScreen
//                   ? AppFonts.montserratMainText14
//                   : AppFonts.montserratMainText14.copyWith(fontSize: 16),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 Get.back();
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.mainColor,
//                 padding: EdgeInsets.symmetric(
//                   horizontal: 24,
//                   vertical: 12,
//                 ),
//               ),
//               child: Text(
//                 'Find Mechanics',
//                 style: AppFonts.montserratWhiteText,
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return SingleChildScrollView(
//       padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
//       child: Center(
//         child: ConstrainedBox(
//           constraints: BoxConstraints(
//             maxWidth: 800,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Service History (${services.length})',
//                     style: isSmallScreen
//                         ? AppFonts.montserratBlackHeading
//                         : AppFonts.montserratBlackHeading.copyWith(fontSize: 22),
//                   ),
//                   // Show local storage indicator if any services are locally stored
//                   if (_hasLocalServices(services))
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.blue[100],
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         'Local Backup',
//                         style: AppFonts.montserratText2.copyWith(
//                           fontSize: 10,
//                           color: Colors.blue[800],
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//               SizedBox(height: 16),
//               ...services.map((service) => 
//                 _buildServiceCard(service, context)
//               ).toList(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildServiceCard(Map<String, dynamic> service, BuildContext context) {
//     final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    
//     return Container(
//       margin: EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header with status and local indicator
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Row(
//                     children: [
//                       Text(
//                         _formatServiceType(service['service_type'] ?? 'repair'),
//                         style: isSmallScreen
//                             ? AppFonts.montserratBlackHeading
//                             : AppFonts.montserratBlackHeading.copyWith(fontSize: 18),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       SizedBox(width: 8),
//                       // Show local backup indicator
//                       if (service['local_backup'] == true)
//                         Container(
//                           padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                           decoration: BoxDecoration(
//                             color: Colors.blue[50],
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.blue[200]!),
//                           ),
//                           child: Text(
//                             'Local',
//                             style: AppFonts.montserratText2.copyWith(
//                               fontSize: 8,
//                               color: Colors.blue[700],
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: _getStatusColor(service['status'] ?? 'pending'),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     _formatStatus(service['status'] ?? 'pending'),
//                     style: AppFonts.montserratWhiteText.copyWith(
//                       fontSize: isSmallScreen ? 10 : 12,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
            
//             SizedBox(height: 12),
            
//             // Service Details
//             _buildServiceDetailRow(
//               'Mechanic',
//               service['mechanic_name'] ?? 'Unknown Mechanic',
//               Icons.person,
//             ),
            
//             _buildServiceDetailRow(
//               'Vehicle',
//               _getVehicleName(service['vehicle_id']),
//               Icons.directions_car,
//             ),
            
//             _buildServiceDetailRow(
//               'Issue',
//               service['issue_description'] ?? 'Not specified',
//               Icons.description,
//             ),
            
//             if (service['estimated_time'] != null && service['estimated_time'].toString().isNotEmpty)
//               _buildServiceDetailRow(
//                 'Estimated Time',
//                 service['estimated_time'].toString(),
//                 Icons.access_time,
//               ),
            
//             if (service['service_cost'] != null && (service['service_cost'] as num) > 0)
//               _buildServiceDetailRow(
//                 'Cost',
//                 'Rs. ${service['service_cost']}',
//                 Icons.attach_money,
//               ),
            
//             // Show creation date if available
//             if (service['created_at'] != null)
//               _buildServiceDetailRow(
//                 'Created',
//                 _formatDate(service['created_at']),
//                 Icons.calendar_today,
//               ),
            
//             SizedBox(height: 12),
            
//             // Actions based on status
//             if (service['status'] == 'pending' || service['status'] == 'in_progress')
//               Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         _showUpdateDialog(service);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.mainColor,
//                       ),
//                       child: Text(
//                         'Update',
//                         style: AppFonts.montserratWhiteText,
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () {
//                         _showDeleteConfirmation(service);
//                       },
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.red,
//                         side: BorderSide(color: Colors.red),
//                       ),
//                       child: Text(
//                         'Cancel',
//                         style: AppFonts.montserratText2.copyWith(color: Colors.red),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildServiceDetailRow(String label, String value, IconData icon) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(
//             icon,
//             color: AppColors.mainColor,
//             size: 16,
//           ),
//           SizedBox(width: 8),
//           Expanded(
//             flex: 2,
//             child: Text(
//               '$label:',
//               style: AppFonts.montserratGreyText14.copyWith(
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           SizedBox(width: 8),
//           Expanded(
//             flex: 3,
//             child: Text(
//               value,
//               style: AppFonts.montserratText2.copyWith(
//                 fontWeight: FontWeight.w600,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getVehicleName(String vehicleId) {
//     try {
//       if (vehicleId == null || vehicleId.isEmpty) {
//         return 'Unknown Vehicle';
//       }
      
//       // ✅ UPDATED: Better vehicle matching with the new vehicle ID system
//       final vehicle = vehicleController.userVehicles.firstWhere(
//         (v) {
//           final vId = v['_id'] ?? v['id'];
//           return vId != null && vId.toString() == vehicleId.toString();
//         },
//         orElse: () => {},
//       );
      
//       if (vehicle.isNotEmpty) {
//         final brand = vehicle['brand'] ?? '';
//         final model = vehicle['model'] ?? '';
//         final year = vehicle['year'] ?? '';
        
//         String vehicleName = '$brand $model'.trim();
//         if (year != null && year.toString().isNotEmpty) {
//           vehicleName += ' ($year)';
//         }
        
//         return vehicleName.isEmpty ? 'Unknown Vehicle' : vehicleName;
//       }
//     } catch (e) {
//       print('Error getting vehicle name: $e');
//     }
    
//     return 'Unknown Vehicle';
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'completed':
//         return Colors.green;
//       case 'in_progress':
//         return Colors.blue;
//       case 'pending':
//         return Colors.orange;
//       case 'cancelled':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   String _formatStatus(String status) {
//     switch (status.toLowerCase()) {
//       case 'in_progress':
//         return 'In Progress';
//       case 'pending':
//         return 'Pending';
//       case 'completed':
//         return 'Completed';
//       case 'cancelled':
//         return 'Cancelled';
//       default:
//         return status.toString().capitalizeFirst ?? status.toString();
//     }
//   }

//   String _formatServiceType(String serviceType) {
//     switch (serviceType.toLowerCase()) {
//       case 'repair':
//         return 'Repair Service';
//       case 'maintenance':
//         return 'Maintenance Service';
//       case 'inspection':
//         return 'Vehicle Inspection';
//       case 'emergency':
//         return 'Emergency Service';
//       default:
//         return serviceType.toString().capitalizeFirst ?? serviceType.toString();
//     }
//   }

//   String _formatDate(String dateString) {
//     try {
//       final date = DateTime.parse(dateString);
//       return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//     } catch (e) {
//       return 'Unknown date';
//     }
//   }

//   bool _hasLocalServices(List<dynamic> services) {
//     return services.any((service) => 
//       service is Map<String, dynamic> && service['local_backup'] == true
//     );
//   }

//   void _showUpdateDialog(Map<String, dynamic> service) {
//     showDialog(
//       context: Get.context!,
//       builder: (context) => AlertDialog(
//         title: Text(
//           'Update Service',
//           style: AppFonts.montserratBlackHeading,
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Update service status or details',
//               style: AppFonts.montserratText2,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: Text(
//               'Cancel',
//               style: AppFonts.montserratText2,
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Get.back();
//               Get.snackbar(
//                 'Info',
//                 'Update functionality coming soon',
//                 backgroundColor: Colors.blue,
//                 colorText: Colors.white,
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.mainColor,
//             ),
//             child: Text(
//               'Update',
//               style: AppFonts.montserratWhiteText,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showDeleteConfirmation(Map<String, dynamic> service) {
//     showDialog(
//       context: Get.context!,
//       builder: (context) => AlertDialog(
//         title: Text(
//           'Cancel Service',
//           style: AppFonts.montserratBlackHeading,
//         ),
//         content: Text(
//           'Are you sure you want to cancel this service? This action cannot be undone.',
//           style: AppFonts.montserratText2,
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: Text(
//               'No',
//               style: AppFonts.montserratText2,
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Get.back();
//               final serviceId = service['_id'] ?? service['id'];
//               if (serviceId != null) {
//                 final success = await controller.deleteService(serviceId.toString());
//                 if (success) {
//                   Get.snackbar(
//                     'Success',
//                     'Service cancelled successfully',
//                     backgroundColor: Colors.green,
//                     colorText: Colors.white,
//                   );
//                 } else {
//                   Get.snackbar(
//                     'Error',
//                     'Failed to cancel service',
//                     backgroundColor: Colors.red,
//                     colorText: Colors.white,
//                   );
//                 }
//               } else {
//                 Get.snackbar(
//                   'Error',
//                   'Cannot cancel service without ID',
//                   backgroundColor: Colors.red,
//                   colorText: Colors.white,
//                 );
//               }
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: Text(
//               'Yes, Cancel',
//               style: AppFonts.montserratWhiteText,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }





