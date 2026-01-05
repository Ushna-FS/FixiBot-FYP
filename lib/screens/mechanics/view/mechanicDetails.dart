// // perfect with new flow
// import 'package:fixibot_app/screens/mechanics/controller/mechanicController.dart';
// import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:fixibot_app/constants/app_colors.dart';
// import 'dart:math';
// import 'package:fixibot_app/constants/app_fontStyles.dart';
// import 'package:fixibot_app/widgets/customAppBar.dart';

// class MechanicDetailScreen extends StatelessWidget {
//   final dynamic mechanic;

//   const MechanicDetailScreen({super.key, required this.mechanic});

//   @override
//   Widget build(BuildContext context) {
//     final Size screenSize = MediaQuery.of(context).size;
//     final bool isSmallScreen = screenSize.width < 600;

//     return Scaffold(
//       backgroundColor: AppColors.secondaryColor,
//       appBar: AppBar(
//         backgroundColor: AppColors.mainColor,
//         title: Text(
//           "Mechanic Details",
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
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             padding: EdgeInsets.only(
//               bottom: 100, // Add padding at bottom to avoid content being hidden behind fixed button
//             ),
//             child: Padding(
//               padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
//               child: Center(
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints(
//                     maxWidth: 600,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Profile Header
//                       _buildProfileHeader(context),
                      
//                       SizedBox(height: isSmallScreen ? 24 : 32),
                      
//                       // Workshop Info
//                       _buildInfoSection(
//                         title: "Workshop Information",
//                         icon: Icons.work_outline,
//                         children: [
//                           _buildInfoRow("Workshop Name", mechanic['workshop_name'] ?? 'N/A'),
//                           _buildInfoRow("Address", _getFullAddress()),
//                           _buildInfoRow("City", mechanic['city'] ?? 'N/A'),
//                           _buildInfoRow("Province", mechanic['province'] ?? 'N/A'),
//                         ],
//                       ),
                      
//                       SizedBox(height: isSmallScreen ? 20 : 28),
                      
//                       // Contact Info
//                       _buildInfoSection(
//                         title: "Contact Information",
//                         icon: Icons.contact_phone_outlined,
//                         children: [
//                           _buildInfoRow("Phone", mechanic['phone_number'] ?? 'N/A'),
//                           _buildInfoRow("Email", mechanic['email'] ?? 'N/A'),
//                         ],
//                       ),
                      
//                       SizedBox(height: isSmallScreen ? 20 : 28),
                      
//                       // Expertise & Experience
//                       _buildInfoSection(
//                         title: "Expertise & Experience",
//                         icon: Icons.handyman_outlined,
//                         children: [
//                           _buildInfoRow("Experience", "${mechanic['years_of_experience'] ?? 0} years"),
//                           _buildInfoRow("Expertise", _getExpertiseString()),
//                           _buildInfoRow("Average Rating", _getRatingString()),
//                           _buildInfoRow("Total Feedbacks", "${mechanic['total_feedbacks'] ?? 0}"),
//                         ],
//                       ),
                      
//                       SizedBox(height: isSmallScreen ? 20 : 28),
                      
//                       // Working Hours
//                       _buildInfoSection(
//                         title: "Working Hours",
//                         icon: Icons.access_time_outlined,
//                         children: [
//                           _buildInfoRow("Days", _getWorkingDays()),
//                           _buildInfoRow("Hours", _getWorkingHours()),
//                         ],
//                       ),
                      
//                       SizedBox(height: isSmallScreen ? 20 : 28),
                      
//                       // Verification Status
//                       _buildVerificationStatus(),
                      
//                       SizedBox(height: isSmallScreen ? 80 : 100), // Extra space for the fixed button
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
          
//           // Fixed Call Button at Bottom
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: Container(
//               color: AppColors.secondaryColor,
//               padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
//               child: Center(
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints(maxWidth: 600),
//                   child: _buildCallButton(context),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileHeader(BuildContext context) {
//     final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
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
//       child: Row(
//         children: [
//           Container(
//             width: isSmallScreen ? 80 : 100,
//             height: isSmallScreen ? 80 : 100,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(
//                 color: AppColors.mainColor,
//                 width: 2,
//               ),
//             ),
//             child: ClipOval(
//               child: mechanic['profile_picture'] != null
//                   ? Image.network(
//                       mechanic['profile_picture'],
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) {
//                         return Container(
//                           color: AppColors.mainColor.withOpacity(0.1),
//                           child: Icon(
//                             Icons.person,
//                             size: isSmallScreen ? 40 : 50,
//                             color: AppColors.mainColor,
//                           ),
//                         );
//                       },
//                     )
//                   : Container(
//                       color: AppColors.mainColor.withOpacity(0.1),
//                       child: Icon(
//                         Icons.person,
//                         size: isSmallScreen ? 40 : 50,
//                         color: AppColors.mainColor,
//                       ),
//                     ),
//             ),
//           ),
//           SizedBox(width: isSmallScreen ? 16 : 20),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   mechanic['full_name'] ?? 'Unknown Mechanic',
//                   style: isSmallScreen
//                       ? AppFonts.montserratBlackHeading
//                       : AppFonts.montserratBlackHeading.copyWith(fontSize: 22),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   _getExpertiseString(),
//                   style: isSmallScreen
//                       ? AppFonts.montserratGreyText14
//                       : AppFonts.montserratGreyText14.copyWith(fontSize: 16),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.star,
//                       color: Colors.amber,
//                       size: isSmallScreen ? 16 : 18,
//                     ),
//                     SizedBox(width: 4),
//                     Text(
//                       _getRatingString(),
//                       style: isSmallScreen
//                           ? AppFonts.montserratText2
//                           : AppFonts.montserratText2.copyWith(fontSize: 16),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoSection({
//     required String title,
//     required IconData icon,
//     required List<Widget> children,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(16),
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
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 icon,
//                 color: AppColors.mainColor,
//                 size: 20,
//               ),
//               SizedBox(width: 8),
//               Text(
//                 title,
//                 style: AppFonts.montserratBlackHeading.copyWith(fontSize: 18),
//               ),
//             ],
//           ),
//           SizedBox(height: 12),
//           ...children,
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text(
//               "$label:",
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

//   Widget _buildVerificationStatus() {
//     final bool isVerified = mechanic['is_verified'] ?? false;
//     final bool isAvailable = mechanic['is_available'] ?? false;
    
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(16),
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
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildStatusIndicator(
//             "Verified",
//             isVerified ? Icons.verified : Icons.verified_outlined,
//             isVerified ? Colors.green : Colors.grey,
//           ),
//           _buildStatusIndicator(
//             "Available",
//             isAvailable ? Icons.check_circle : Icons.cancel,
//             isAvailable ? Colors.green : Colors.red,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusIndicator(String text, IconData icon, Color color) {
//     return Column(
//       children: [
//         Icon(
//           icon,
//           color: color,
//           size: 30,
//         ),
//         SizedBox(height: 4),
//         Text(
//           text,
//           style: AppFonts.montserratText2.copyWith(
//             color: color,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCallButton(BuildContext context) {
//     final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: () {
//           _showIssueDescriptionDialog(context);
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColors.mainColor,
//           padding: EdgeInsets.symmetric(
//             vertical: isSmallScreen ? 16 : 20,
//             horizontal: 24,
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           elevation: 4,
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.phone,
//               color: Colors.white,
//               size: isSmallScreen ? 20 : 24,
//             ),
//             SizedBox(width: 12),
//             Text(
//               "Call Mechanic",
//               style: isSmallScreen
//                   ? AppFonts.montserratWhiteText.copyWith(fontSize: 16)
//                   : AppFonts.montserratWhiteText.copyWith(fontSize: 18),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ✅ NEW: Issue Description Dialog (appears BEFORE call)
//   void _showIssueDescriptionDialog(BuildContext context) {
//     final TextEditingController issueController = TextEditingController();
//     final FocusNode issueFocusNode = FocusNode();
    
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return IssueDescriptionDialog(
//           mechanicName: mechanic['full_name'] ?? 'this mechanic',
//           issueController: issueController,
//           focusNode: issueFocusNode,
//           onProceed: (issueDescription) {
//             Navigator.of(context).pop();
//             _makePhoneCall(issueDescription);
//           },
//           onCancel: () {
//             Navigator.of(context).pop();
//           },
//         );
//       },
//     );
//   }

//   // ✅ UPDATED: Make phone call with issue description
//   Future<void> _makePhoneCall(String issueDescription) async {
//     final phoneNumber = mechanic['phone_number'];
    
//     if (phoneNumber != null && phoneNumber.isNotEmpty) {
//       // Clean the phone number - remove any non-digit characters except +
//       String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
//       // If the number doesn't start with +, add the country code (assuming Pakistan +92)
//       if (!cleanedNumber.startsWith('+')) {
//         // Remove any leading zeros
//         cleanedNumber = cleanedNumber.replaceFirst(RegExp(r'^0+'), '');
//         // Add Pakistan country code
//         cleanedNumber = '+92$cleanedNumber';
//       }
      
//       final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);
      
//       try {
//         if (await canLaunchUrl(phoneUri)) {
//           // Track the call attempt with issue description
//           _trackCallAttempt(issueDescription);
          
//           await launchUrl(phoneUri);
          
//           // Show service confirmation dialog when user returns to app
//           _showServiceConfirmationDialog(issueDescription);
          
//         } else {
//           throw 'Could not launch phone app';
//         }
//       } catch (e) {
//         Get.snackbar(
//           'Error',
//           'Could not make phone call: $e',
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//           snackPosition: SnackPosition.BOTTOM,
//           duration: Duration(seconds: 3),
//         );
//       }
//     } else {
//       Get.snackbar(
//         'Error',
//         'Phone number not available',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         duration: Duration(seconds: 3),
//       );
//     }
//   }

//   // ✅ UPDATED: Track call attempt with issue description
//   void _trackCallAttempt(String issueDescription) {
//     try {
//       // Try different possible ID field names
//       String? mechanicId;
//       List<String> possibleIdFields = ['_id', 'id', 'mechanic_id', 'userId', 'user_id'];
      
//       for (var field in possibleIdFields) {
//         if (mechanic[field] != null && mechanic[field].toString().isNotEmpty) {
//           mechanicId = mechanic[field].toString();
//           print('✅ Call tracking - Found mechanic ID in field "$field": $mechanicId');
//           break;
//         }
//       }

//       // If no ID found, use alternative approach
//       if (mechanicId == null) {
//         if (mechanic['phone_number'] != null && mechanic['phone_number'].toString().isNotEmpty) {
//           mechanicId = 'phone_${mechanic['phone_number']}';
//         } else if (mechanic['email'] != null && mechanic['email'].toString().isNotEmpty) {
//           mechanicId = 'email_${mechanic['email']}';
//         } else {
//           mechanicId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
//         }
//       }

//       final callData = {
//         'mechanic_id': mechanicId,
//         'mechanic_name': mechanic['full_name'] ?? 'Unknown Mechanic',
//         'mechanic_phone': mechanic['phone_number'] ?? 'N/A',
//         'issue_description': issueDescription,
//         'user_id': 'current_user_id',
//         'timestamp': DateTime.now().toIso8601String(),
//         'call_status': 'attempted',
//       };
      
//       print('📞 Call attempt tracked: $callData');
//       print('📝 Issue description: $issueDescription');
      
//       // TODO: Implement API call to track the call attempt
//       // await apiService.trackCallAttempt(callData);
      
//     } catch (e) {
//       print('❌ Error in call tracking: $e');
//     }
//   }

//   // ✅ UPDATED: Service confirmation dialog with issue description
//   void _showServiceConfirmationDialog(String issueDescription) {
//     // This dialog will appear when the user returns to the app after the call
//     Future.delayed(Duration(milliseconds: 500), () {
//       if (!Get.isDialogOpen!) {
//         showDialog(
//           context: Get.context!,
//           barrierDismissible: false,
//           builder: (BuildContext context) {
//             return ServiceConfirmationDialog(
//               mechanicName: mechanic['full_name'] ?? 'this mechanic',
//               issueDescription: issueDescription,
//               onConfirm: () {
//                 Navigator.of(context).pop();
//                 _checkVehicleAndTrackService(issueDescription);
//               },
//               onCancel: () {
//                 Navigator.of(context).pop();
//                 Get.snackbar(
//                   'Info',
//                   'You can explore other mechanics if needed.',
//                   backgroundColor: Colors.blue,
//                   colorText: Colors.white,
//                   snackPosition: SnackPosition.BOTTOM,
//                 );
//               },
//             );
//           },
//         );
//       }
//     });
//   }

//   // ✅ UPDATED: Check if vehicle is selected before tracking service
//   void _checkVehicleAndTrackService(String issueDescription) {
//     final mechanicController = Get.find<MechanicController>();
    
//     // Check if a vehicle is selected in the dropdown
//     if (mechanicController.selectedVehicleType.value.isEmpty) {
//       // No vehicle selected - show snackbar and don't store service history
//       Get.snackbar(
//         'No Vehicle Selected',
//         'Mechanic service history will not be stored as no vehicle was selected.',
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         duration: Duration(seconds: 4),
//       );
//       print('⚠️ No vehicle selected - service history not stored');
//     } else {
//       // Vehicle is selected - proceed with service tracking
//       _trackServiceSelection(issueDescription);
//     }
//   }

//   // ✅ UPDATED: Track service selection with issue description
//   void _trackServiceSelection(String issueDescription) async {
//     try {
//       print('🔧 Starting service recording process...');
      
//       final vehicleController = Get.find<VehicleController>();
//       final mechanicServiceController = Get.find<MechanicController>();
      
//     // Debug: Check available vehicles
//     print('🚗 Available vehicles: ${vehicleController.userVehicles.length}');
//     for (var vehicle in vehicleController.userVehicles) {
//       print('   - ${vehicle['brand']} ${vehicle['model']} (ID: ${vehicle['_id'] ?? vehicle['id']}) - Primary: ${vehicle['is_primary']}');
//     }
    
//     // Get the primary vehicle or first vehicle
//     String? vehicleId;
//     String? vehicleName = 'Unknown Vehicle';
    
//     if (vehicleController.userVehicles.isNotEmpty) {
//       // Try to find primary vehicle first
//       final primaryVehicles = vehicleController.userVehicles.where((vehicle) => vehicle['is_primary'] == true).toList();
//       final selectedVehicle = primaryVehicles.isNotEmpty ? primaryVehicles.first : vehicleController.userVehicles.first;
      
//       vehicleId = selectedVehicle['_id'] ?? selectedVehicle['id'];
//       final brand = selectedVehicle['brand'] ?? '';
//       final model = selectedVehicle['model'] ?? '';
//       vehicleName = '$brand $model'.trim();
      
//       print('✅ Selected vehicle: $vehicleName (ID: $vehicleId)');
//     }

//     if (vehicleId == null || vehicleId.isEmpty) {
//       print('❌ No valid vehicle ID found');
//       Get.snackbar(
//         'Error',
//         'Please add a vehicle first to record service',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//       return;
//     }

//     // Debug mechanic data - Check all possible ID fields
//     print('👨‍🔧 Mechanic data analysis:');
//     print('   - Full mechanic object: $mechanic');
    
//     // Try multiple possible ID fields with better validation
//     String? mechanicId;
//     List<String> possibleIdFields = ['_id', 'id', 'mechanic_id', 'userId', 'user_id'];
    
//     for (var field in possibleIdFields) {
//       final fieldValue = mechanic[field];
//       if (fieldValue != null && fieldValue.toString().trim().isNotEmpty) {
//         mechanicId = fieldValue.toString();
//         print('✅ Found valid mechanic ID in field "$field": $mechanicId');
//         break;
//       }
//     }

//     // If still no valid ID, try alternative approaches
//     if (mechanicId == null) {
//       print('⚠️ No standard ID field found, trying alternatives...');
      
//       // Use phone number as fallback identifier
//       if (mechanic['phone_number'] != null && mechanic['phone_number'].toString().trim().isNotEmpty) {
//         mechanicId = 'phone_${mechanic['phone_number']}';
//         print('✅ Using phone-based ID: $mechanicId');
//       } 
//       // Use email as fallback identifier
//       else if (mechanic['email'] != null && mechanic['email'].toString().trim().isNotEmpty) {
//         mechanicId = 'email_${mechanic['email']}';
//         print('✅ Using email-based ID: $mechanicId');
//       }
//       // Last resort - generate temporary ID
//       else {
//         mechanicId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
//         print('⚠️ Using temporary ID: $mechanicId');
        
//         // Show warning to user about temporary ID
//         Get.snackbar(
//           'Warning',
//           'Using temporary service ID - some features may be limited',
//           backgroundColor: Colors.orange,
//           colorText: Colors.white,
//           snackPosition: SnackPosition.BOTTOM,
//         );
//       }
//     }

//     // Validate the final mechanic ID
//     if (mechanicId == null || mechanicId.isEmpty) {
//       print('❌ Critical: No mechanic ID could be determined');
//       Get.snackbar(
//         'Error',
//         'Cannot record service - mechanic information is incomplete',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       return;
//     }

//     print('🎯 Final mechanic ID for service: $mechanicId');

//     // ✅ Generate random estimated time between 1-10 hours
//     final random = Random();
//     final randomHours = random.nextInt(10) + 1; // 1-10 hours
//     String estimatedTime;
    
//     if (randomHours == 1) {
//       estimatedTime = "1 hour";
//     } else {
//       estimatedTime = "$randomHours hours";
//     }
    
//     print('⏱️ Generated random estimated time: $estimatedTime');

//     print('📡 Creating mechanic service record...');
//     final success = await mechanicServiceController.createMechanicService(
//       mechanicId: mechanicId,
//       mechanicName: mechanic['full_name'] ?? 'Unknown Mechanic',
//       vehicleId: vehicleId,
//       issueDescription: issueDescription, // ✅ Use the user-provided issue description
//       serviceType: 'repair',
//       serviceCost: 0.0,
//       estimatedTime: estimatedTime,
//     );

//     if (success) {
//       print('✅ Service recorded successfully!');
//       Get.snackbar(
//         'Success',
//         'Mechanic service recorded successfully!',
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         duration: Duration(seconds: 3),
//       );
//     } else {
//       print('❌ Failed to record service: ${mechanicServiceController.servicesErrorMessage.value}');
//       Get.snackbar(
//         'Error',
//         'Failed to record service: ${mechanicServiceController.servicesErrorMessage.value}',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         duration: Duration(seconds: 5),
//       );
//     }
//   } catch (e) {
//     print('❌ Exception in _trackServiceSelection: $e');
//     print('   Stack trace: ${e.toString()}');
//     Get.snackbar(
//       'Error',
//       'Failed to record service: $e',
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//       snackPosition: SnackPosition.BOTTOM,
//     );
//   }
// }

//   String _getFullAddress() {
//     final address = mechanic['address'] ?? '';
//     final city = mechanic['city'] ?? '';
//     final province = mechanic['province'] ?? '';
    
//     if (address.isEmpty && city.isEmpty && province.isEmpty) {
//       return 'Address not available';
//     }
    
//     return [address, city, province].where((part) => part.isNotEmpty).join(', ');
//   }

//   String _getExpertiseString() {
//     final expertise = mechanic['expertise'];
//     if (expertise is List) {
//       return expertise.map((e) => e.toString().capitalize).join(', ');
//     } else if (expertise is String) {
//       return expertise;
//     }
//     return 'General Mechanic';
//   }

//   String _getRatingString() {
//     final rating = mechanic['average_rating'] ?? 0.0;
//     return rating > 0 ? '$rating/5.0' : 'No ratings yet';
//   }

//   String _getWorkingDays() {
//     final days = mechanic['working_days'] ?? [];
//     if (days is List) {
//       return days.map((e) => e.toString().capitalize).join(', ');
//     }
//     return 'Monday - Friday';
//   }

//   String _getWorkingHours() {
//     final hours = mechanic['working_hours'] ?? {};
//     final start = hours['start_time'] ?? '09:00';
//     final end = hours['end_time'] ?? '18:00';
//     return '$start - $end';
//   }
// }

// // ✅ NEW: Issue Description Dialog Widget
// class IssueDescriptionDialog extends StatefulWidget {
//   final String mechanicName;
//   final TextEditingController issueController;
//   final FocusNode focusNode;
//   final Function(String) onProceed;
//   final Function() onCancel;

//   const IssueDescriptionDialog({
//     super.key,
//     required this.mechanicName,
//     required this.issueController,
//     required this.focusNode,
//     required this.onProceed,
//     required this.onCancel,
//   });

//   @override
//   State<IssueDescriptionDialog> createState() => _IssueDescriptionDialogState();
// }

// class _IssueDescriptionDialogState extends State<IssueDescriptionDialog> {
//   bool _isButtonEnabled = false;

//   @override
//   void initState() {
//     super.initState();
//     widget.issueController.addListener(_validateInput);
//     // Auto-focus on the text field
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       FocusScope.of(context).requestFocus(widget.focusNode);
//     });
//   }

//   void _validateInput() {
//     final text = widget.issueController.text.trim();
//     final wordCount = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
//     setState(() {
//       _isButtonEnabled = wordCount >= 5;
//     });
//   }

//   int _getWordCount() {
//     final text = widget.issueController.text.trim();
//     return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
//   }

//   @override
//   void dispose() {
//     widget.issueController.removeListener(_validateInput);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final wordCount = _getWordCount();
//     final wordsRemaining = 5 - wordCount;

//     return AlertDialog(
//       title: Text(
//         "Describe Your Issue",
//         style: AppFonts.montserratBlackHeading,
//       ),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Please describe the vehicle issue before calling ${widget.mechanicName}:",
//               style: AppFonts.montserratText2,
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: widget.issueController,
//               focusNode: widget.focusNode,
//               maxLines: 4,
//               decoration: InputDecoration(
//                 hintText: "Describe the vehicle issue in detail (minimum 5 words required)...",
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide(color: AppColors.mainColor),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide(color: AppColors.mainColor, width: 2),
//                 ),
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               wordsRemaining > 0 
//                   ? "Words remaining: $wordsRemaining"
//                   : "✅ Minimum word count reached",
//               style: AppFonts.montserratText2.copyWith(
//                 color: wordsRemaining > 0 ? Colors.orange : Colors.green,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             if (wordCount > 0) ...[
//               SizedBox(height: 4),
//               Text(
//                 "Current word count: $wordCount",
//                 style: AppFonts.montserratText2.copyWith(
//                   fontSize: 12,
//                   color: Colors.grey,
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: widget.onCancel,
//           child: Text(
//             "Cancel",
//             style: AppFonts.montserratText2.copyWith(
//               color: Colors.grey,
//             ),
//           ),
//         ),
//         ElevatedButton(
//           onPressed: _isButtonEnabled
//               ? () {
//                   widget.onProceed(widget.issueController.text.trim());
//                 }
//               : null,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: _isButtonEnabled ? AppColors.mainColor : Colors.grey,
//           ),
//           child: Text(
//             "Proceed to Call",
//             style: AppFonts.montserratWhiteText,
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ✅ NEW: Service Confirmation Dialog Widget
// class ServiceConfirmationDialog extends StatelessWidget {
//   final String mechanicName;
//   final String issueDescription;
//   final Function() onConfirm;
//   final Function() onCancel;

//   const ServiceConfirmationDialog({
//     super.key,
//     required this.mechanicName,
//     required this.issueDescription,
//     required this.onConfirm,
//     required this.onCancel,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text(
//         "Service Confirmation",
//         style: AppFonts.montserratBlackHeading,
//       ),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Did you choose $mechanicName for your vehicle service?",
//               style: AppFonts.montserratText2,
//             ),
//             SizedBox(height: 12),
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Issue Description:",
//                     style: AppFonts.montserratText2.copyWith(
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     issueDescription,
//                     style: AppFonts.montserratText2.copyWith(
//                       color: Colors.grey[700],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: onCancel,
//           child: Text(
//             "No",
//             style: AppFonts.montserratText2.copyWith(
//               color: Colors.grey,
//             ),
//           ),
//         ),
//         ElevatedButton(
//           onPressed: onConfirm,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppColors.mainColor,
//           ),
//           child: Text(
//             "Yes, I Chose This",
//             style: AppFonts.montserratWhiteText,
//           ),
//         ),
//       ],
//     );
//   }
// }













import 'package:fixibot_app/screens/mechanics/controller/mechanicController.dart';
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';

class MechanicDetailScreen extends StatelessWidget {
  final dynamic mechanic;

  const MechanicDetailScreen({super.key, required this.mechanic});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.mainColor,
        title: Text(
          "Mechanic Details",
          style: isSmallScreen
              ? AppFonts.montserratWhiteText
              : AppFonts.montserratWhiteText.copyWith(fontSize: 18),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back, color: AppColors.secondaryColor),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 100),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header with essential info
                      _buildProfileHeader(context),
                      
                      SizedBox(height: isSmallScreen ? 20 : 28),
                      
                      // Quick Stats Row
                      _buildQuickStats(context),
                      
                      SizedBox(height: isSmallScreen ? 20 : 28),
                      
                      // Contact Information
                      _buildContactSection(context),
                      
                      SizedBox(height: isSmallScreen ? 20 : 28),
                      
                      // Location Information
                      _buildLocationSection(context),
                      
                      SizedBox(height: isSmallScreen ? 20 : 28),
                      
                      // Availability Status
                      _buildAvailabilityStatus(),
                      
                      SizedBox(height: isSmallScreen ? 80 : 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Fixed Call Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: AppColors.secondaryColor,
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: _buildCallButton(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
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
      child: Column(
        children: [
          // Profile Image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.mainColor, width: 2),
            ),
            child: ClipOval(
              child: mechanic['profile_picture'] != null
                  ? Image.network(
                      mechanic['profile_picture'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderIcon();
                      },
                    )
                  : _buildPlaceholderIcon(),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Name and Rating
          Column(
            children: [
              Text(
                mechanic['full_name'] ?? 'Unknown Mechanic',
                style: isSmallScreen
                    ? AppFonts.montserratBlackHeading.copyWith(fontSize: 20)
                    : AppFonts.montserratBlackHeading.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 8),
              
              // Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  SizedBox(width: 4),
                  Text(
                    _getRatingString(),
                    style: AppFonts.montserratText2.copyWith(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "(${mechanic['total_feedbacks'] ?? 0} reviews)",
                    style: AppFonts.montserratGreyText14.copyWith(
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Expertise
              Text(
                _getExpertiseString(),
                style: AppFonts.montserratGreyText14.copyWith(
                  fontSize: isSmallScreen ? 13 : 15,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: AppColors.mainColor.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: 50,
        color: AppColors.mainColor,
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.work_history,
            value: "${mechanic['years_of_experience'] ?? 0}",
            label: "Years Exp",
            isSmallScreen: isSmallScreen,
          ),
          _buildStatItem(
            icon: Icons.verified,
            value: mechanic['is_verified'] ?? false ? "Verified" : "Not Verified",
            label: "Status",
            isSmallScreen: isSmallScreen,
            color: mechanic['is_verified'] ?? false ? Colors.green : Colors.grey,
          ),
          _buildStatItem(
            icon: Icons.access_time,
            value: _getWorkingHoursShort(),
            label: "Hours",
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required bool isSmallScreen,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color ?? AppColors.mainColor,
          size: isSmallScreen ? 24 : 28,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: AppFonts.montserratText2.copyWith(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: AppFonts.montserratGreyText14.copyWith(
            fontSize: isSmallScreen ? 11 : 13,
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_phone, color: AppColors.mainColor, size: 20),
              SizedBox(width: 8),
              Text(
                "Contact Information",
                style: AppFonts.montserratBlackHeading.copyWith(fontSize: 18),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Phone
          _buildContactItem(
            icon: Icons.phone,
            title: "Phone",
            value: mechanic['phone_number'] ?? 'N/A',
            isPhone: true,
          ),
          
          SizedBox(height: 12),
          
          // Email
          _buildContactItem(
            icon: Icons.email,
            title: "Email",
            value: mechanic['email'] ?? 'N/A',
            isPhone: false,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isPhone,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.mainColor.withOpacity(0.7), size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppFonts.montserratGreyText14.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: AppFonts.montserratText2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppColors.mainColor, size: 20),
              SizedBox(width: 8),
              Text(
                "Location",
                style: AppFonts.montserratBlackHeading.copyWith(fontSize: 18),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Workshop Name
          if (mechanic['workshop_name'] != null && mechanic['workshop_name'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                mechanic['workshop_name'],
                style: AppFonts.montserratText2.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          
          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.place, color: Colors.grey, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getFullAddress(),
                  style: AppFonts.montserratText2.copyWith(
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityStatus() {
    final bool isAvailable = mechanic['is_available'] ?? false;
    
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAvailable ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvailable ? "Available Now" : "Currently Unavailable",
                  style: AppFonts.montserratText2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isAvailable ? Colors.green : Colors.red,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  isAvailable 
                      ? "Ready to take your call"
                      : "Mechanic is not available at the moment",
                  style: AppFonts.montserratGreyText14.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    final bool isAvailable = mechanic['is_available'] ?? false;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isAvailable ? () {
          _showIssueDescriptionDialog(context);
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isAvailable ? AppColors.mainColor : Colors.grey,
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 16 : 20,
            horizontal: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone,
              color: Colors.white,
              size: isSmallScreen ? 20 : 24,
            ),
            SizedBox(width: 12),
            Text(
              isAvailable ? "Call Mechanic" : "Not Available",
              style: isSmallScreen
                  ? AppFonts.montserratWhiteText.copyWith(fontSize: 16)
                  : AppFonts.montserratWhiteText.copyWith(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  // Keep these methods as they are essential
  void _showIssueDescriptionDialog(BuildContext context) {
    final TextEditingController issueController = TextEditingController();
    final FocusNode issueFocusNode = FocusNode();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return IssueDescriptionDialog(
          mechanicName: mechanic['full_name'] ?? 'this mechanic',
          issueController: issueController,
          focusNode: issueFocusNode,
          onProceed: (issueDescription) {
            Navigator.of(context).pop();
            _makePhoneCall(issueDescription);
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _makePhoneCall(String issueDescription) async {
    final phoneNumber = mechanic['phone_number'];
    
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      if (!cleanedNumber.startsWith('+')) {
        cleanedNumber = cleanedNumber.replaceFirst(RegExp(r'^0+'), '');
        cleanedNumber = '+92$cleanedNumber';
      }
      
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);
      
      try {
        if (await canLaunchUrl(phoneUri)) {
          _trackCallAttempt(issueDescription);
          await launchUrl(phoneUri);
          _showServiceConfirmationDialog(issueDescription);
        } else {
          throw 'Could not launch phone app';
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Could not make phone call: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } else {
      Get.snackbar(
        'Error',
        'Phone number not available',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _trackCallAttempt(String issueDescription) {
    try {
      String? mechanicId;
      List<String> possibleIdFields = ['_id', 'id', 'mechanic_id', 'userId', 'user_id'];
      
      for (var field in possibleIdFields) {
        if (mechanic[field] != null && mechanic[field].toString().isNotEmpty) {
          mechanicId = mechanic[field].toString();
          break;
        }
      }

      if (mechanicId == null) {
        if (mechanic['phone_number'] != null && mechanic['phone_number'].toString().isNotEmpty) {
          mechanicId = 'phone_${mechanic['phone_number']}';
        } else if (mechanic['email'] != null && mechanic['email'].toString().isNotEmpty) {
          mechanicId = 'email_${mechanic['email']}';
        } else {
          mechanicId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
        }
      }

      final callData = {
        'mechanic_id': mechanicId,
        'mechanic_name': mechanic['full_name'] ?? 'Unknown Mechanic',
        'mechanic_phone': mechanic['phone_number'] ?? 'N/A',
        'issue_description': issueDescription,
        'user_id': 'current_user_id',
        'timestamp': DateTime.now().toIso8601String(),
        'call_status': 'attempted',
      };
      
      print('📞 Call attempt tracked: ${callData['mechanic_name']}');
    } catch (e) {
      print('❌ Error in call tracking: $e');
    }
  }

  void _showServiceConfirmationDialog(String issueDescription) {
    Future.delayed(Duration(milliseconds: 500), () {
      if (!Get.isDialogOpen!) {
        showDialog(
          context: Get.context!,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return ServiceConfirmationDialog(
              mechanicName: mechanic['full_name'] ?? 'this mechanic',
              issueDescription: issueDescription,
              onConfirm: () {
                Navigator.of(context).pop();
                _checkVehicleAndTrackService(issueDescription);
              },
              onCancel: () {
                Navigator.of(context).pop();
                Get.snackbar(
                  'Info',
                  'You can explore other mechanics if needed.',
                  backgroundColor: Colors.blue,
                );
              },
            );
          },
        );
      }
    });
  }

  void _checkVehicleAndTrackService(String issueDescription) {
    final mechanicController = Get.find<MechanicController>();
    
    if (mechanicController.selectedVehicleType.value.isEmpty) {
      Get.snackbar(
        'No Vehicle Selected',
        'Mechanic service history will not be stored as no vehicle was selected.',
        backgroundColor: Colors.orange,
      );
    } else {
      _trackServiceSelection(issueDescription);
    }
  }

  void _trackServiceSelection(String issueDescription) async {
    try {
      final vehicleController = Get.find<VehicleController>();
      final mechanicServiceController = Get.find<MechanicController>();
      
      String? vehicleId;
      String? vehicleName = 'Unknown Vehicle';
      
      if (vehicleController.userVehicles.isNotEmpty) {
        final primaryVehicles = vehicleController.userVehicles.where((vehicle) => vehicle['is_primary'] == true).toList();
        final selectedVehicle = primaryVehicles.isNotEmpty ? primaryVehicles.first : vehicleController.userVehicles.first;
        
        vehicleId = selectedVehicle['_id'] ?? selectedVehicle['id'];
        final brand = selectedVehicle['brand'] ?? '';
        final model = selectedVehicle['model'] ?? '';
        vehicleName = '$brand $model'.trim();
      }

      if (vehicleId == null || vehicleId.isEmpty) {
        Get.snackbar(
          'Error',
          'Please add a vehicle first to record service',
          backgroundColor: Colors.red,
        );
        return;
      }

      String? mechanicId;
      List<String> possibleIdFields = ['_id', 'id', 'mechanic_id', 'userId', 'user_id'];
      
      for (var field in possibleIdFields) {
        final fieldValue = mechanic[field];
        if (fieldValue != null && fieldValue.toString().trim().isNotEmpty) {
          mechanicId = fieldValue.toString();
          break;
        }
      }

      if (mechanicId == null) {
        if (mechanic['phone_number'] != null && mechanic['phone_number'].toString().trim().isNotEmpty) {
          mechanicId = 'phone_${mechanic['phone_number']}';
        } else if (mechanic['email'] != null && mechanic['email'].toString().trim().isNotEmpty) {
          mechanicId = 'email_${mechanic['email']}';
        } else {
          mechanicId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        }
      }

      final success = await mechanicServiceController.createMechanicService(
        mechanicId: mechanicId!,
        mechanicName: mechanic['full_name'] ?? 'Unknown Mechanic',
        vehicleId: vehicleId,
        issueDescription: issueDescription,
        serviceType: 'repair',
        serviceCost: 0.0,
        estimatedTime: "2-4 hours",
      );

      if (success) {
        Get.snackbar(
          'Success',
          'Mechanic service recorded successfully!',
          backgroundColor: Colors.green,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to record service',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to record service: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  String _getFullAddress() {
    final address = mechanic['address'] ?? '';
    final city = mechanic['city'] ?? '';
    final province = mechanic['province'] ?? '';
    
    if (address.isEmpty && city.isEmpty && province.isEmpty) {
      return 'Address not available';
    }
    
    return [address, city, province].where((part) => part.isNotEmpty).join(', ');
  }

  String _getExpertiseString() {
    final expertise = mechanic['expertise'];
    if (expertise is List) {
      return expertise.map((e) => e.toString().capitalize).join(', ');
    } else if (expertise is String) {
      return expertise;
    }
    return 'General Mechanic';
  }

  String _getRatingString() {
    final rating = mechanic['average_rating'] ?? 0.0;
    return rating > 0 ? rating.toStringAsFixed(1) : 'No ratings';
  }

  String _getWorkingHoursShort() {
    final hours = mechanic['working_hours'] ?? {};
    final start = hours['start_time'] ?? '9AM';
    final end = hours['end_time'] ?? '6PM';
    return '$start-$end';
  }
}

// Simplified Issue Description Dialog
class IssueDescriptionDialog extends StatefulWidget {
  final String mechanicName;
  final TextEditingController issueController;
  final FocusNode focusNode;
  final Function(String) onProceed;
  final Function() onCancel;

  const IssueDescriptionDialog({
    super.key,
    required this.mechanicName,
    required this.issueController,
    required this.focusNode,
    required this.onProceed,
    required this.onCancel,
  });

  @override
  State<IssueDescriptionDialog> createState() => _IssueDescriptionDialogState();
}

class _IssueDescriptionDialogState extends State<IssueDescriptionDialog> {
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    widget.issueController.addListener(_validateInput);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(widget.focusNode);
    });
  }

  void _validateInput() {
    final text = widget.issueController.text.trim();
    final wordCount = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    setState(() {
      _isButtonEnabled = wordCount >= 5;
    });
  }

  @override
  void dispose() {
    widget.issueController.removeListener(_validateInput);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordCount = widget.issueController.text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;

    return AlertDialog(
      title: Text(
        "Describe Your Issue",
        style: AppFonts.montserratBlackHeading,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Briefly describe your vehicle issue:",
              style: AppFonts.montserratText2,
            ),
            SizedBox(height: 16),
            TextField(
              controller: widget.issueController,
              focusNode: widget.focusNode,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Minimum 5 words required...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Words: $wordCount/5",
              style: AppFonts.montserratText2.copyWith(
                color: wordCount >= 5 ? Colors.green : Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isButtonEnabled
              ? () => widget.onProceed(widget.issueController.text.trim())
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isButtonEnabled ? AppColors.mainColor : Colors.grey,
          ),
          child: Text("Call Now"),
        ),
      ],
    );
  }
}

// Simplified Service Confirmation Dialog
class ServiceConfirmationDialog extends StatelessWidget {
  final String mechanicName;
  final String issueDescription;
  final Function() onConfirm;
  final Function() onCancel;

  const ServiceConfirmationDialog({
    super.key,
    required this.mechanicName,
    required this.issueDescription,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Service Booked?",
        style: AppFonts.montserratBlackHeading,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Did you book service with $mechanicName?",
            style: AppFonts.montserratText2,
          ),
          if (issueDescription.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              "Issue: ${issueDescription.length > 50 ? '${issueDescription.substring(0, 50)}...' : issueDescription}",
              style: AppFonts.montserratText2.copyWith(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ]
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text("No"),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.mainColor,
          ),
          child: Text("Yes"),
        ),
      ],
    );
  }
}




