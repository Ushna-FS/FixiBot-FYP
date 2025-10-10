import 'package:fixibot_app/screens/mechanics/controller/mechanicController.dart';
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'dart:math';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/widgets/customAppBar.dart';

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
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: 100, // Add padding at bottom to avoid content being hidden behind fixed button
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 600,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      _buildProfileHeader(context),
                      
                      SizedBox(height: isSmallScreen ? 24 : 32),
                      
                      // Workshop Info
                      _buildInfoSection(
                        title: "Workshop Information",
                        icon: Icons.work_outline,
                        children: [
                          _buildInfoRow("Workshop Name", mechanic['workshop_name'] ?? 'N/A'),
                          _buildInfoRow("Address", _getFullAddress()),
                          _buildInfoRow("City", mechanic['city'] ?? 'N/A'),
                          _buildInfoRow("Province", mechanic['province'] ?? 'N/A'),
                        ],
                      ),
                      
                      SizedBox(height: isSmallScreen ? 20 : 28),
                      
                      // Contact Info
                      _buildInfoSection(
                        title: "Contact Information",
                        icon: Icons.contact_phone_outlined,
                        children: [
                          _buildInfoRow("Phone", mechanic['phone_number'] ?? 'N/A'),
                          _buildInfoRow("Email", mechanic['email'] ?? 'N/A'),
                        ],
                      ),
                      
                      SizedBox(height: isSmallScreen ? 20 : 28),
                      
                      // Expertise & Experience
                      _buildInfoSection(
                        title: "Expertise & Experience",
                        icon: Icons.handyman_outlined,
                        children: [
                          _buildInfoRow("Experience", "${mechanic['years_of_experience'] ?? 0} years"),
                          _buildInfoRow("Expertise", _getExpertiseString()),
                          _buildInfoRow("Average Rating", _getRatingString()),
                          _buildInfoRow("Total Feedbacks", "${mechanic['total_feedbacks'] ?? 0}"),
                        ],
                      ),
                      
                      SizedBox(height: isSmallScreen ? 20 : 28),
                      
                      // Working Hours
                      _buildInfoSection(
                        title: "Working Hours",
                        icon: Icons.access_time_outlined,
                        children: [
                          _buildInfoRow("Days", _getWorkingDays()),
                          _buildInfoRow("Hours", _getWorkingHours()),
                        ],
                      ),
                      
                      SizedBox(height: isSmallScreen ? 20 : 28),
                      
                      // Verification Status
                      _buildVerificationStatus(),
                      
                      SizedBox(height: isSmallScreen ? 80 : 100), // Extra space for the fixed button
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Fixed Call Button at Bottom
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
      width: double.infinity,
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
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 80 : 100,
            height: isSmallScreen ? 80 : 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.mainColor,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: mechanic['profile_picture'] != null
                  ? Image.network(
                      mechanic['profile_picture'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.mainColor.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: isSmallScreen ? 40 : 50,
                            color: AppColors.mainColor,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.mainColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: isSmallScreen ? 40 : 50,
                        color: AppColors.mainColor,
                      ),
                    ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 16 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mechanic['full_name'] ?? 'Unknown Mechanic',
                  style: isSmallScreen
                      ? AppFonts.montserratBlackHeading
                      : AppFonts.montserratBlackHeading.copyWith(fontSize: 22),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  _getExpertiseString(),
                  style: isSmallScreen
                      ? AppFonts.montserratGreyText14
                      : AppFonts.montserratGreyText14.copyWith(fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: isSmallScreen ? 16 : 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      _getRatingString(),
                      style: isSmallScreen
                          ? AppFonts.montserratText2
                          : AppFonts.montserratText2.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
              Icon(
                icon,
                color: AppColors.mainColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: AppFonts.montserratBlackHeading.copyWith(fontSize: 18),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus() {
    final bool isVerified = mechanic['is_verified'] ?? false;
    final bool isAvailable = mechanic['is_available'] ?? false;
    
    return Container(
      width: double.infinity,
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
          _buildStatusIndicator(
            "Verified",
            isVerified ? Icons.verified : Icons.verified_outlined,
            isVerified ? Colors.green : Colors.grey,
          ),
          _buildStatusIndicator(
            "Available",
            isAvailable ? Icons.check_circle : Icons.cancel,
            isAvailable ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String text, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 30,
        ),
        SizedBox(height: 4),
        Text(
          text,
          style: AppFonts.montserratText2.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCallButton(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _showCallConfirmationDialog(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mainColor,
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
              "Call Mechanic",
              style: isSmallScreen
                  ? AppFonts.montserratWhiteText.copyWith(fontSize: 16)
                  : AppFonts.montserratWhiteText.copyWith(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _showCallConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Call Mechanic",
            style: AppFonts.montserratBlackHeading,
          ),
          content: Text(
            "Do you want to call ${mechanic['full_name'] ?? 'the mechanic'}? This will open your phone dialer with the mechanic's number.",
            style: AppFonts.montserratText2,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "No",
                style: AppFonts.montserratText2.copyWith(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _makePhoneCall();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
              ),
              child: Text(
                "Yes, Call",
                style: AppFonts.montserratWhiteText,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _makePhoneCall() async {
    final phoneNumber = mechanic['phone_number'];
    
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      // Clean the phone number - remove any non-digit characters except +
      String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // If the number doesn't start with +, add the country code (assuming Pakistan +92)
      if (!cleanedNumber.startsWith('+')) {
        // Remove any leading zeros
        cleanedNumber = cleanedNumber.replaceFirst(RegExp(r'^0+'), '');
        // Add Pakistan country code
        cleanedNumber = '+92$cleanedNumber';
      }
      
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);
      
      try {
        if (await canLaunchUrl(phoneUri)) {
          // Track the call attempt in your system
          _trackCallAttempt();
          
          await launchUrl(phoneUri);
          
          // Show service confirmation dialog when user returns to app
          _showServiceConfirmationDialog();
          
        } else {
          throw 'Could not launch phone app';
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Could not make phone call: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
      }
    } else {
      Get.snackbar(
        'Error',
        'Phone number not available',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    }
  }

  void _trackCallAttempt() {
    try {
      // Try different possible ID field names
      String? mechanicId;
      List<String> possibleIdFields = ['_id', 'id', 'mechanic_id', 'userId', 'user_id'];
      
      for (var field in possibleIdFields) {
        if (mechanic[field] != null && mechanic[field].toString().isNotEmpty) {
          mechanicId = mechanic[field].toString();
          print('✅ Call tracking - Found mechanic ID in field "$field": $mechanicId');
          break;
        }
      }

      // If no ID found, use alternative approach
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
        'user_id': 'current_user_id', // This should be replaced with actual user ID from SharedPreferences
        'timestamp': DateTime.now().toIso8601String(),
        'call_status': 'attempted',
      };
      
      print('📞 Call attempt tracked: $callData');
      
      // TODO: Implement API call to track the call attempt
      // await apiService.trackCallAttempt(callData);
      
    } catch (e) {
      print('❌ Error in call tracking: $e');
    }
  }

  void _showServiceConfirmationDialog() {
    // This dialog will appear when the user returns to the app after the call
    Future.delayed(Duration(milliseconds: 500), () {
      if (!Get.isDialogOpen!) {
        showDialog(
          context: Get.context!,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                "Service Confirmation",
                style: AppFonts.montserratBlackHeading,
              ),
              content: Text(
                "Did you choose ${mechanic['full_name'] ?? 'this mechanic'} for your vehicle service?",
                style: AppFonts.montserratText2,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Get.snackbar(
                      'Info',
                      'You can explore other mechanics if needed.',
                      backgroundColor: Colors.blue,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: Text(
                    "No",
                    style: AppFonts.montserratText2.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _checkVehicleAndTrackService();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                  ),
                  child: Text(
                    "Yes, Chose This",
                    style: AppFonts.montserratWhiteText,
                  ),
                ),
              ],
            );
          },
        );
      }
    });
  }

  // NEW METHOD: Check if vehicle is selected before tracking service
  void _checkVehicleAndTrackService() {
    final mechanicController = Get.find<MechanicController>();
    
    // Check if a vehicle is selected in the dropdown
    if (mechanicController.selectedVehicleType.value.isEmpty) {
      // No vehicle selected - show snackbar and don't store service history
      Get.snackbar(
        'No Vehicle Selected',
        'Mechanic service history will not be stored as no vehicle was selected.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 4),
      );
      print('⚠️ No vehicle selected - service history not stored');
    } else {
      // Vehicle is selected - proceed with service tracking
      _trackServiceSelection();
    }
  }

void _trackServiceSelection() async {
  try {
    print('🔧 Starting service recording process...');
    
    final vehicleController = Get.find<VehicleController>();
    final mechanicServiceController = Get.find<MechanicController>();
    
    // Debug: Check available vehicles
    print('🚗 Available vehicles: ${vehicleController.userVehicles.length}');
    for (var vehicle in vehicleController.userVehicles) {
      print('   - ${vehicle['brand']} ${vehicle['model']} (ID: ${vehicle['_id'] ?? vehicle['id']}) - Primary: ${vehicle['is_primary']}');
    }
    
    // Get the primary vehicle or first vehicle
    String? vehicleId;
    String? vehicleName = 'Unknown Vehicle';
    
    if (vehicleController.userVehicles.isNotEmpty) {
      // Try to find primary vehicle first
      final primaryVehicles = vehicleController.userVehicles.where((vehicle) => vehicle['is_primary'] == true).toList();
      final selectedVehicle = primaryVehicles.isNotEmpty ? primaryVehicles.first : vehicleController.userVehicles.first;
      
      vehicleId = selectedVehicle['_id'] ?? selectedVehicle['id'];
      final brand = selectedVehicle['brand'] ?? '';
      final model = selectedVehicle['model'] ?? '';
      vehicleName = '$brand $model'.trim();
      
      print('✅ Selected vehicle: $vehicleName (ID: $vehicleId)');
    }

    if (vehicleId == null || vehicleId.isEmpty) {
      print('❌ No valid vehicle ID found');
      Get.snackbar(
        'Error',
        'Please add a vehicle first to record service',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Debug mechanic data - Check all possible ID fields
    print('👨‍🔧 Mechanic data analysis:');
    print('   - Full mechanic object: $mechanic');
    
    // Try multiple possible ID fields with better validation
    String? mechanicId;
    List<String> possibleIdFields = ['_id', 'id', 'mechanic_id', 'userId', 'user_id'];
    
    for (var field in possibleIdFields) {
      final fieldValue = mechanic[field];
      if (fieldValue != null && fieldValue.toString().trim().isNotEmpty) {
        mechanicId = fieldValue.toString();
        print('✅ Found valid mechanic ID in field "$field": $mechanicId');
        break;
      }
    }

    // If still no valid ID, try alternative approaches
    if (mechanicId == null) {
      print('⚠️ No standard ID field found, trying alternatives...');
      
      // Use phone number as fallback identifier
      if (mechanic['phone_number'] != null && mechanic['phone_number'].toString().trim().isNotEmpty) {
        mechanicId = 'phone_${mechanic['phone_number']}';
        print('✅ Using phone-based ID: $mechanicId');
      } 
      // Use email as fallback identifier
      else if (mechanic['email'] != null && mechanic['email'].toString().trim().isNotEmpty) {
        mechanicId = 'email_${mechanic['email']}';
        print('✅ Using email-based ID: $mechanicId');
      }
      // Last resort - generate temporary ID
      else {
        mechanicId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        print('⚠️ Using temporary ID: $mechanicId');
        
        // Show warning to user about temporary ID
        Get.snackbar(
          'Warning',
          'Using temporary service ID - some features may be limited',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }

    // Validate the final mechanic ID
    if (mechanicId == null || mechanicId.isEmpty) {
      print('❌ Critical: No mechanic ID could be determined');
      Get.snackbar(
        'Error',
        'Cannot record service - mechanic information is incomplete',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    print('🎯 Final mechanic ID for service: $mechanicId');

    // ✅ Generate random estimated time between 1-10 hours
    final random = Random();
    final randomHours = random.nextInt(10) + 1; // 1-10 hours
    String estimatedTime;
    
    if (randomHours == 1) {
      estimatedTime = "1 hour";
    } else {
      estimatedTime = "$randomHours hours";
    }
    
    print('⏱️ Generated random estimated time: $estimatedTime');

    print('📡 Creating mechanic service record...');
    final success = await mechanicServiceController.createMechanicService(
      mechanicId: mechanicId,
      mechanicName: mechanic['full_name'] ?? 'Unknown Mechanic',
      vehicleId: vehicleId,
      issueDescription: 'Service requested for $vehicleName via Fixibot app',
      serviceType: 'repair',
      serviceCost: 0.0,
      estimatedTime: estimatedTime, // ✅ Now random between 1-10 hours
    );

    if (success) {
      print('✅ Service recorded successfully!');
      Get.snackbar(
        'Success',
        'Mechanic service recorded successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    } else {
      print('❌ Failed to record service: ${mechanicServiceController.servicesErrorMessage.value}');
      Get.snackbar(
        'Error',
        'Failed to record service: ${mechanicServiceController.servicesErrorMessage.value}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 5),
      );
    }
  } catch (e) {
    print('❌ Exception in _trackServiceSelection: $e');
    print('   Stack trace: ${e.toString()}');
    Get.snackbar(
      'Error',
      'Failed to record service: $e',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
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
    return rating > 0 ? '$rating/5.0' : 'No ratings yet';
  }

  String _getWorkingDays() {
    final days = mechanic['working_days'] ?? [];
    if (days is List) {
      return days.map((e) => e.toString().capitalize).join(', ');
    }
    return 'Monday - Friday';
  }

  String _getWorkingHours() {
    final hours = mechanic['working_hours'] ?? {};
    final start = hours['start_time'] ?? '09:00';
    final end = hours['end_time'] ?? '18:00';
    return '$start - $end';
  }
}







//2 sample
// import 'package:fixibot_app/screens/mechanics/controller/mechanicController.dart';
// import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:fixibot_app/constants/app_colors.dart';
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
//           _showCallConfirmationDialog(context);
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

//   void _showCallConfirmationDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             "Call Mechanic",
//             style: AppFonts.montserratBlackHeading,
//           ),
//           content: Text(
//             "Do you want to call ${mechanic['full_name'] ?? 'the mechanic'}? This will open your phone dialer with the mechanic's number.",
//             style: AppFonts.montserratText2,
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text(
//                 "No",
//                 style: AppFonts.montserratText2.copyWith(
//                   color: Colors.grey,
//                 ),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _makePhoneCall();
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.mainColor,
//               ),
//               child: Text(
//                 "Yes, Call",
//                 style: AppFonts.montserratWhiteText,
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _makePhoneCall() async {
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
//           // Track the call attempt in your system
//           _trackCallAttempt();
          
//           await launchUrl(phoneUri);
          
//           // Show service confirmation dialog when user returns to app
//           _showServiceConfirmationDialog();
          
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

//   void _trackCallAttempt() {
//   try {
//     // Try different possible ID field names
//     String? mechanicId;
//     List<String> possibleIdFields = ['_id', 'id', 'mechanic_id', 'userId', 'user_id'];
    
//     for (var field in possibleIdFields) {
//       if (mechanic[field] != null && mechanic[field].toString().isNotEmpty) {
//         mechanicId = mechanic[field].toString();
//         print('✅ Call tracking - Found mechanic ID in field "$field": $mechanicId');
//         break;
//       }
//     }

//     // If no ID found, use alternative approach
//     if (mechanicId == null) {
//       if (mechanic['phone_number'] != null && mechanic['phone_number'].toString().isNotEmpty) {
//         mechanicId = 'phone_${mechanic['phone_number']}';
//       } else if (mechanic['email'] != null && mechanic['email'].toString().isNotEmpty) {
//         mechanicId = 'email_${mechanic['email']}';
//       } else {
//         mechanicId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
//       }
//     }

//     final callData = {
//       'mechanic_id': mechanicId,
//       'mechanic_name': mechanic['full_name'] ?? 'Unknown Mechanic',
//       'mechanic_phone': mechanic['phone_number'] ?? 'N/A',
//       'user_id': 'current_user_id', // This should be replaced with actual user ID from SharedPreferences
//       'timestamp': DateTime.now().toIso8601String(),
//       'call_status': 'attempted',
//     };
    
//     print('📞 Call attempt tracked: $callData');
    
//     // TODO: Implement API call to track the call attempt
//     // await apiService.trackCallAttempt(callData);
    
//   } catch (e) {
//     print('❌ Error in call tracking: $e');
//   }
// }


// // void _trackServiceSelection() async {
// //   try {
// //     print('🔧 Starting service recording process...');
    
// //     final vehicleController = Get.find<VehicleController>();
// //     final mechanicServiceController = Get.find<MechanicController>();
    
// //     // Debug: Check available vehicles
// //     print('🚗 Available vehicles: ${vehicleController.userVehicles.length}');
// //     for (var vehicle in vehicleController.userVehicles) {
// //       print('   - ${vehicle['brand']} ${vehicle['model']} (ID: ${vehicle['_id'] ?? vehicle['id']}) - Primary: ${vehicle['is_primary']}');
// //     }
    
// //     // Get the primary vehicle or first vehicle
// //     String? vehicleId;
// //     String? vehicleName = 'Unknown Vehicle';
    
// //     if (vehicleController.userVehicles.isNotEmpty) {
// //       // Try to find primary vehicle first
// //       final primaryVehicles = vehicleController.userVehicles.where((vehicle) => vehicle['is_primary'] == true).toList();
// //       final selectedVehicle = primaryVehicles.isNotEmpty ? primaryVehicles.first : vehicleController.userVehicles.first;
      
// //       vehicleId = selectedVehicle['_id'] ?? selectedVehicle['id'];
// //       final brand = selectedVehicle['brand'] ?? '';
// //       final model = selectedVehicle['model'] ?? '';
// //       vehicleName = '$brand $model'.trim();
      
// //       print('✅ Selected vehicle: $vehicleName (ID: $vehicleId)');
// //     }

// //     if (vehicleId == null || vehicleId.isEmpty) {
// //       print('❌ No valid vehicle ID found');
// //       Get.snackbar(
// //         'Error',
// //         'Please add a vehicle first to record service',
// //         backgroundColor: Colors.red,
// //         colorText: Colors.white,
// //         snackPosition: SnackPosition.BOTTOM,
// //       );
// //       return;
// //     }

// //     // Debug mechanic data - Check all possible ID fields
// //     print('👨‍🔧 Mechanic data analysis:');
// //     print('   - Full mechanic object: $mechanic');
    
// //     // Try multiple possible ID fields with better validation
// //     String? mechanicId;
// //     List<String> possibleIdFields = ['_id', 'id', 'mechanic_id', 'userId', 'user_id'];
    
// //     for (var field in possibleIdFields) {
// //       final fieldValue = mechanic[field];
// //       if (fieldValue != null && fieldValue.toString().trim().isNotEmpty) {
// //         mechanicId = fieldValue.toString();
// //         print('✅ Found valid mechanic ID in field "$field": $mechanicId');
// //         break;
// //       }
// //     }

// //     // If still no valid ID, try alternative approaches
// //     if (mechanicId == null) {
// //       print('⚠️ No standard ID field found, trying alternatives...');
      
// //       // Use phone number as fallback identifier
// //       if (mechanic['phone_number'] != null && mechanic['phone_number'].toString().trim().isNotEmpty) {
// //         mechanicId = 'phone_${mechanic['phone_number']}';
// //         print('✅ Using phone-based ID: $mechanicId');
// //       } 
// //       // Use email as fallback identifier
// //       else if (mechanic['email'] != null && mechanic['email'].toString().trim().isNotEmpty) {
// //         mechanicId = 'email_${mechanic['email']}';
// //         print('✅ Using email-based ID: $mechanicId');
// //       }
// //       // Last resort - generate temporary ID
// //       else {
// //         mechanicId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
// //         print('⚠️ Using temporary ID: $mechanicId');
        
// //         // Show warning to user about temporary ID
// //         Get.snackbar(
// //           'Warning',
// //           'Using temporary service ID - some features may be limited',
// //           backgroundColor: Colors.orange,
// //           colorText: Colors.white,
// //           snackPosition: SnackPosition.BOTTOM,
// //         );
// //       }
// //     }

// //     // Validate the final mechanic ID
// //     if (mechanicId == null || mechanicId.isEmpty) {
// //       print('❌ Critical: No mechanic ID could be determined');
// //       Get.snackbar(
// //         'Error',
// //         'Cannot record service - mechanic information is incomplete',
// //         backgroundColor: Colors.red,
// //         colorText: Colors.white,
// //       );
// //       return;
// //     }

// //     print('🎯 Final mechanic ID for service: $mechanicId');

// //     // Create mechanic service record
// //     print('📡 Creating mechanic service record...');
// //     final success = await mechanicServiceController.createMechanicService(
// //       mechanicId: mechanicId,
// //       mechanicName: mechanic['full_name'] ?? 'Unknown Mechanic',
// //       vehicleId: vehicleId,
// //       issueDescription: 'Service requested for $vehicleName via Fixibot app',
// //       serviceType: 'repair',
// //       serviceCost: 0.0,
// //       estimatedTime: 'To be determined',
// //     );

// //     if (success) {
// //       print('✅ Service recorded successfully!');
// //       Get.snackbar(
// //         'Success',
// //         'Mechanic service recorded successfully!',
// //         backgroundColor: Colors.green,
// //         colorText: Colors.white,
// //         snackPosition: SnackPosition.BOTTOM,
// //         duration: Duration(seconds: 3),
// //       );
// //     } else {
// //       print('❌ Failed to record service: ${mechanicServiceController.servicesErrorMessage.value}');
// //       Get.snackbar(
// //         'Error',
// //         'Failed to record service: ${mechanicServiceController.servicesErrorMessage.value}',
// //         backgroundColor: Colors.red,
// //         colorText: Colors.white,
// //         snackPosition: SnackPosition.BOTTOM,
// //         duration: Duration(seconds: 5),
// //       );
// //     }
// //   } catch (e) {
// //     print('❌ Exception in _trackServiceSelection: $e');
// //     print('   Stack trace: ${e.toString()}');
// //     Get.snackbar(
// //       'Error',
// //       'Failed to record service: $e',
// //       backgroundColor: Colors.red,
// //       colorText: Colors.white,
// //       snackPosition: SnackPosition.BOTTOM,
// //     );
// //   }
// // }



// void _trackServiceSelection() async {
//   try {
//     print('🔧 Starting service recording process...');
    
//     final vehicleController = Get.find<VehicleController>();
//     final mechanicServiceController = Get.find<MechanicController>();
    
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

//     // ✅ FIX: Provide a valid estimated time with time unit
//     // Choose one of these options:
//     String estimatedTime;
    
//     // Option 1: Use a realistic estimate based on service type
//     estimatedTime = "2 hours"; // Most common for basic repairs
    
//     // Option 2: Use a range
//     // estimatedTime = "1-2 hours";
    
//     // Option 3: For more complex services
//     // estimatedTime = "1 day";

//     print('📡 Creating mechanic service record...');
//     final success = await mechanicServiceController.createMechanicService(
//       mechanicId: mechanicId,
//       mechanicName: mechanic['full_name'] ?? 'Unknown Mechanic',
//       vehicleId: vehicleId,
//       issueDescription: 'Service requested for $vehicleName via Fixibot app',
//       serviceType: 'repair',
//       serviceCost: 0.0,
//       estimatedTime: estimatedTime, // ✅ Now includes time unit
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
//   void _showServiceConfirmationDialog() {
//     // This dialog will appear when the user returns to the app after the call
//     Future.delayed(Duration(milliseconds: 500), () {
//       if (!Get.isDialogOpen!) {
//         showDialog(
//           context: Get.context!,
//           barrierDismissible: false,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               title: Text(
//                 "Service Confirmation",
//                 style: AppFonts.montserratBlackHeading,
//               ),
//               content: Text(
//                 "Did you choose ${mechanic['full_name'] ?? 'this mechanic'} for your vehicle service?",
//                 style: AppFonts.montserratText2,
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                     Get.snackbar(
//                       'Info',
//                       'You can explore other mechanics if needed.',
//                       backgroundColor: Colors.blue,
//                       colorText: Colors.white,
//                       snackPosition: SnackPosition.BOTTOM,
//                     );
//                   },
//                   child: Text(
//                     "No",
//                     style: AppFonts.montserratText2.copyWith(
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                     _trackServiceSelection();
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.mainColor,
//                   ),
//                   child: Text(
//                     "Yes, Chose This",
//                     style: AppFonts.montserratWhiteText,
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       }
//     });
//   }

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

