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
                hintText: "Minimum 10 words required...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Words: $wordCount/10",
              style: AppFonts.montserratText2.copyWith(
                color: wordCount >= 10 ? Colors.green : Colors.orange,
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




