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
      body: Obx(() {
        // Use combined services for display
        final displayServices = controller.mechanicServices;

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
                    'Service History (${services.length})',
                    style: isSmallScreen
                        ? AppFonts.montserratBlackHeading
                        : AppFonts.montserratBlackHeading.copyWith(fontSize: 22),
                  ),
                  if (controller.servicesErrorMessage.value.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Limited Data',
                        style: AppFonts.montserratText2.copyWith(
                          fontSize: 10,
                          color: Colors.orange[800],
                        ),
                      ),
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
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _formatServiceType(service['service_type'] ?? 'repair'),
                    style: isSmallScreen
                        ? AppFonts.montserratBlackHeading
                        : AppFonts.montserratBlackHeading.copyWith(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
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
            
            // Show creation source if available
            if (service['_id'] == null && service['id'] == null)
              _buildServiceDetailRow(
                'Note',
                'Locally stored service',
                Icons.info,
              ),
            
            SizedBox(height: 12),
            
            // Actions based on status
            if (service['status'] == 'pending' || service['status'] == 'in_progress')
              Row(
                children: [
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
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _showDeleteConfirmation(service);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppFonts.montserratText2.copyWith(color: Colors.red),
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
        (v) => v['_id'] == vehicleId || v['id'] == vehicleId,
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

  void _showUpdateDialog(Map<String, dynamic> service) {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Service',
          style: AppFonts.montserratBlackHeading,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Update service status or details',
              style: AppFonts.montserratText2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: AppFonts.montserratText2,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Info',
                'Update functionality coming soon',
                backgroundColor: Colors.blue,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
            ),
            child: Text(
              'Update',
              style: AppFonts.montserratWhiteText,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> service) {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Service',
          style: AppFonts.montserratBlackHeading,
        ),
        content: Text(
          'Are you sure you want to cancel this service? This action cannot be undone.',
          style: AppFonts.montserratText2,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'No',
              style: AppFonts.montserratText2,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final serviceId = service['_id'] ?? service['id'];
              if (serviceId != null) {
                final success = await controller.deleteService(serviceId.toString());
                if (success) {
                  Get.snackbar(
                    'Success',
                    'Service cancelled successfully',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    'Failed to cancel service',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              } else {
                Get.snackbar(
                  'Error',
                  'Cannot cancel service without ID',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Yes, Cancel',
              style: AppFonts.montserratWhiteText,
            ),
          ),
        ],
      ),
    );
  }
}





//lat
// import 'package:fixibot_app/screens/mechanics/controller/mechanicController.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:fixibot_app/constants/app_colors.dart';
// import 'package:fixibot_app/constants/app_fontStyles.dart';
// import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
// import 'package:fixibot_app/widgets/customAppBar.dart';

// class MechanicServicesPage extends StatelessWidget {
//   final MechanicController controller = Get.find<MechanicController>(); // Use Find instead of Put
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
//       ),
//       body: Obx(() {
//         // Use the services-specific loading and error states
//         if (controller.isServicesLoading.value) {
//           return const Center(
//             child: CircularProgressIndicator(
//               color: AppColors.mainColor,
//             ),
//           );
//         }

//         if (controller.servicesErrorMessage.value.isNotEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.error_outline,
//                   size: 50,
//                   color: Colors.red,
//                 ),
//                 SizedBox(height: 16),
//                 Text(
//                   controller.servicesErrorMessage.value,
//                   style: AppFonts.montserratMainText14,
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () {
//                     controller.getUserMechanicServices();
//                   },
//                   child: Text('Retry'),
//                 ),
//               ],
//             ),
//           );
//         }

//         if (controller.mechanicServices.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.car_repair,
//                   size: 80,
//                   color: AppColors.mainColor.withOpacity(0.5),
//                 ),
//                 SizedBox(height: 16),
//                 Text(
//                   'No Mechanic Services Yet',
//                   style: isSmallScreen
//                       ? AppFonts.montserratBlackHeading
//                       : AppFonts.montserratBlackHeading.copyWith(fontSize: 22),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Your mechanic service requests will appear here',
//                   style: isSmallScreen
//                       ? AppFonts.montserratMainText14
//                       : AppFonts.montserratMainText14.copyWith(fontSize: 16),
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: () {
//                     Get.back(); // Go back to find mechanics
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.mainColor,
//                     padding: EdgeInsets.symmetric(
//                       horizontal: 24,
//                       vertical: 12,
//                     ),
//                   ),
//                   child: Text(
//                     'Find Mechanics',
//                     style: AppFonts.montserratWhiteText,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         return SingleChildScrollView(
//           padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
//           child: Center(
//             child: ConstrainedBox(
//               constraints: BoxConstraints(
//                 maxWidth: 800,
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Service History (${controller.mechanicServices.length})',
//                     style: isSmallScreen
//                         ? AppFonts.montserratBlackHeading
//                         : AppFonts.montserratBlackHeading.copyWith(fontSize: 22),
//                   ),
//                   SizedBox(height: 16),
//                   ...controller.mechanicServices.map((service) => 
//                     _buildServiceCard(service, context)
//                   ).toList(),
//                 ],
//               ),
//             ),
//           ),
//         );
//       }),
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
//             // Header with status
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   _formatServiceType(service['service_type'] ?? 'repair'),
//                   style: isSmallScreen
//                       ? AppFonts.montserratBlackHeading
//                       : AppFonts.montserratBlackHeading.copyWith(fontSize: 18),
//                 ),
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
            
//             if (service['estimated_time'] != null)
//               _buildServiceDetailRow(
//                 'Estimated Time',
//                 service['estimated_time'],
//                 Icons.access_time,
//               ),
            
//             if (service['service_cost'] != null && service['service_cost'] > 0)
//               _buildServiceDetailRow(
//                 'Cost',
//                 'Rs. ${service['service_cost']}',
//                 Icons.attach_money,
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
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getVehicleName(String vehicleId) {
//     try {
//       final vehicle = vehicleController.userVehicles.firstWhere(
//         (v) => v['_id'] == vehicleId || v['id'] == vehicleId,
//         orElse: () => {},
//       );
      
//       if (vehicle.isNotEmpty) {
//         final brand = vehicle['brand'] ?? '';
//         final model = vehicle['model'] ?? '';
//         return '$brand $model'.trim();
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
//         return status;
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
//         return serviceType;
//     }
//   }

//   void _showUpdateDialog(Map<String, dynamic> service) {
//     showDialog(
//       context: Get.context!,
//       builder: (context) => AlertDialog(
//         title: Text('Update Service'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // You can add form fields here for updating service details
//             Text('Update service status or details'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               // Implement update logic
//               Get.back();
//             },
//             child: Text('Update'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showDeleteConfirmation(Map<String, dynamic> service) {
//     showDialog(
//       context: Get.context!,
//       builder: (context) => AlertDialog(
//         title: Text('Cancel Service'),
//         content: Text('Are you sure you want to cancel this service?'),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: Text('No'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Get.back();
//               final success = await controller.deleteService(service['_id'] ?? service['id']);
//               if (success) {
//                 Get.snackbar(
//                   'Success',
//                   'Service cancelled successfully',
//                   backgroundColor: Colors.green,
//                   colorText: Colors.white,
//                 );
//               } else {
//                 Get.snackbar(
//                   'Error',
//                   'Failed to cancel service',
//                   backgroundColor: Colors.red,
//                   colorText: Colors.white,
//                 );
//               }
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: Text('Yes, Cancel'),
//           ),
//         ],
//       ),
//     );
//   }
// }