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
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
//           child: Center(
//             child: ConstrainedBox(
//               constraints: BoxConstraints(
//                 maxWidth: 600,
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Profile Header
//                   _buildProfileHeader(context),
                  
//                   SizedBox(height: isSmallScreen ? 24 : 32),
                  
//                   // Workshop Info
//                   _buildInfoSection(
//                     title: "Workshop Information",
//                     icon: Icons.work_outline,
//                     children: [
//                       _buildInfoRow("Workshop Name", mechanic['workshop_name'] ?? 'N/A'),
//                       _buildInfoRow("Address", _getFullAddress()),
//                       _buildInfoRow("City", mechanic['city'] ?? 'N/A'),
//                       _buildInfoRow("Province", mechanic['province'] ?? 'N/A'),
//                     ],
//                   ),
                  
//                   SizedBox(height: isSmallScreen ? 20 : 28),
                  
//                   // Contact Info
//                   _buildInfoSection(
//                     title: "Contact Information",
//                     icon: Icons.contact_phone_outlined,
//                     children: [
//                       _buildInfoRow("Phone", mechanic['phone_number'] ?? 'N/A'),
//                       _buildInfoRow("Email", mechanic['email'] ?? 'N/A'),
//                     ],
//                   ),
                  
//                   SizedBox(height: isSmallScreen ? 20 : 28),
                  
//                   // Expertise & Experience
//                   _buildInfoSection(
//                     title: "Expertise & Experience",
//                     icon: Icons.handyman_outlined,
//                     children: [
//                       _buildInfoRow("Experience", "${mechanic['years_of_experience'] ?? 0} years"),
//                       _buildInfoRow("Expertise", _getExpertiseString()),
//                       _buildInfoRow("Average Rating", _getRatingString()),
//                       _buildInfoRow("Total Feedbacks", "${mechanic['total_feedbacks'] ?? 0}"),
//                     ],
//                   ),
                  
//                   SizedBox(height: isSmallScreen ? 20 : 28),
                  
//                   // Working Hours
//                   _buildInfoSection(
//                     title: "Working Hours",
//                     icon: Icons.access_time_outlined,
//                     children: [
//                       _buildInfoRow("Days", _getWorkingDays()),
//                       _buildInfoRow("Hours", _getWorkingHours()),
//                     ],
//                   ),
                  
//                   SizedBox(height: isSmallScreen ? 20 : 28),
                  
//                   // Verification Status
//                   _buildVerificationStatus(),
                  
//                   SizedBox(height: isSmallScreen ? 32 : 40),
                  
//                  Positioned(
//           left: 0,
//           right: 0,
//           bottom: 0,
//           child: Container(
//             color: AppColors.secondaryColor,
//             padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
//             child: Center(
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(maxWidth: 600),
//                 child: _buildCallButton(context),
//               ),
//             ),)),
                  
//                   SizedBox(height: isSmallScreen ? 16 : 24),
//                 ],
//               ),
//             ),
//           ),
//         ),
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
//           _makePhoneCall();
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
//           await launchUrl(phoneUri);
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
// }







import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fixibot_app/constants/app_colors.dart';
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
          _makePhoneCall();
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
          await launchUrl(phoneUri);
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
}