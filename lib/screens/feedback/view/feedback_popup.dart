import 'package:fixibot_app/screens/feedback/controller/feedbackController.dart';
import 'package:fixibot_app/widgets/custom_buttons.dart';
import 'package:fixibot_app/widgets/custom_textField.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';

class FeedbackPopup extends StatelessWidget {
  final Map<String, dynamic> service;
  final FeedbackController controller;

  const FeedbackPopup({
    super.key,
    required this.service,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenSize.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          child: _FeedbackPopupContent(
            service: service,
            controller: controller,
          ),
        ),
      ),
    );
  }
}

class _FeedbackPopupContent extends StatefulWidget {
  final Map<String, dynamic> service;
  final FeedbackController controller;

  const _FeedbackPopupContent({
    required this.service,
    required this.controller,
  });

  @override
  State<_FeedbackPopupContent> createState() => _FeedbackPopupContentState();
}

class _FeedbackPopupContentState extends State<_FeedbackPopupContent> {
  int selectedRating = 0;
  final TextEditingController commentController = TextEditingController();
  bool isSubmitting = false;

  String get mechanicName {
    return widget.service['mechanic_name'] ?? 'Unknown Mechanic';
  }

  String get serviceType {
    return widget.service['service_type'] ?? 'repair';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.rate_review,
              color: AppColors.mainColor,
              size: isSmallScreen ? 24 : 28,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rate Your Experience',
                style: isSmallScreen
                    ? AppFonts.montserratBlackHeading
                    : AppFonts.montserratBlackHeading.copyWith(fontSize: 20),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16),
        
        // Service info - SIMPLIFIED (no status)
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.person, size: 16, color: AppColors.mainColor),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mechanicName,
                      style: AppFonts.montserratText2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatServiceType(serviceType),
                      style: AppFonts.montserratGreyText14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Rating
        Text(
          'How was your experience?',
          style: AppFonts.montserratText2.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        
        // Star rating
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedRating = index + 1;
                  });
                },
                child: Icon(
                  index < selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: isSmallScreen ? 32 : 36,
                ),
              );
            }),
          ),
        ),
        
        SizedBox(height: 20),
        
        // Comment
        Text(
          'Additional comments (optional):',
          style: AppFonts.montserratText2.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        CustomTextField(
          controller: commentController,
          maxLines: 3,
          hintText: 'Tell us about your experience...',
        ),
        
        SizedBox(height: 24),
        
        // Buttons
        if (isSubmitting)
          Center(
            child: CircularProgressIndicator(color: AppColors.mainColor),
          )
        else
          Row(
            children: [
              // Remind later
              Expanded(
                child: CustomButton(
                  onPressed: () {
                    widget.controller.remindLater();
                  },
                  text: 'Later',
                ),
              ),
              SizedBox(width: 12),
              
              // Submit
              Expanded(
                child: CustomButton(
                  onPressed: selectedRating > 0 ? _submitFeedback : null,
                  text: 'Submit',
                ),
              ),
            ],
          ),
        
        SizedBox(height: 8),
        
        // Opt out
        Center(
          child: TextButton(
            onPressed: () {
              widget.controller.optOutFeedback();
            },
            child: Text(
              'Don\'t ask again',
              style: AppFonts.montserratGreyText14,
            ),
          ),
        ),
      ],
    );
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
        return serviceType;
    }
  }

  Future<void> _submitFeedback() async {
    setState(() {
      isSubmitting = true;
    });

    final serviceId = widget.service['_id'] ?? widget.service['id'];
    final mechanicId = widget.service['mechanic_id'];
    final mechanicName = widget.service['mechanic_name'];

    if (serviceId == null || mechanicId == null) {
      Get.snackbar(
        'Error',
        'Unable to submit feedback',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final success = await widget.controller.submitFeedback(
      serviceId: serviceId.toString(),
      mechanicId: mechanicId.toString(),
      mechanicName: mechanicName ?? 'Unknown Mechanic',
      rating: selectedRating,
      comment: commentController.text.trim(),
    );

    setState(() {
      isSubmitting = false;
    });

    if (success) {
      Get.snackbar(
        'Thank You!',
        'Your feedback has been submitted',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to submit feedback. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}




// import 'package:fixibot_app/screens/feedback/controller/feedbackController.dart';
// import 'package:fixibot_app/widgets/custom_buttons.dart';
// import 'package:fixibot_app/widgets/custom_textField.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:fixibot_app/constants/app_colors.dart';
// import 'package:fixibot_app/constants/app_fontStyles.dart';

// class FeedbackPopup extends StatelessWidget {
//   final Map<String, dynamic> service;
//   final FeedbackController controller;

//   const FeedbackPopup({
//     super.key,
//     required this.service,
//     required this.controller,
//   });

  
//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     final isSmallScreen = screenSize.width < 600;

//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       insetPadding: EdgeInsets.all(20), // Add padding from screen edges
//       child: ConstrainedBox(
//         constraints: BoxConstraints(
//           maxWidth: 500, // Limit maximum width
//           maxHeight: screenSize.height * 0.8, // Limit maximum height
//         ),
//         child: SingleChildScrollView( // Make it scrollable if content is too long
//           padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
//           child: _FeedbackPopupContent(
//             service: service,
//             controller: controller,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _FeedbackPopupContent extends StatefulWidget {
//   final Map<String, dynamic> service;
//   final FeedbackController controller;

//   const _FeedbackPopupContent({
//     required this.service,
//     required this.controller,
//   });

//   @override
//   State<_FeedbackPopupContent> createState() => _FeedbackPopupContentState();
// }

// class _FeedbackPopupContentState extends State<_FeedbackPopupContent> {
//   int selectedRating = 0;
//   final TextEditingController commentController = TextEditingController();
//   bool isSubmitting = false;

//   String get mechanicName {
//     return widget.service['mechanic_name'] ?? 'Unknown Mechanic';
//   }

//   String get serviceType {
//     return widget.service['service_type'] ?? 'repair';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     final isSmallScreen = screenSize.width < 600;

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Header
//         Row(
//           children: [
//             Icon(
//               Icons.rate_review,
//               color: AppColors.mainColor,
//               size: isSmallScreen ? 24 : 28,
//             ),
//             SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 'Rate Your Experience',
//                 style: isSmallScreen
//                     ? AppFonts.montserratBlackHeading
//                     : AppFonts.montserratBlackHeading.copyWith(fontSize: 20),
//               ),
//             ),
//           ],
//         ),
        
//         SizedBox(height: 16),
        
//         // Service info
//         Container(
//           padding: EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.grey[50],
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Row(
//             children: [
//               Icon(Icons.person, size: 16, color: AppColors.mainColor),
//               SizedBox(width: 8),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       mechanicName,
//                       style: AppFonts.montserratText2.copyWith(
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     Text(
//                       'Service: ${_formatServiceType(serviceType)}',
//                       style: AppFonts.montserratGreyText14,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
        
//         SizedBox(height: 20),
        
//         // Rating
//         Text(
//           'How was your experience?',
//           style: AppFonts.montserratText2.copyWith(
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         SizedBox(height: 12),
        
//         // Star rating
//         Center(
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: List.generate(5, (index) {
//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     selectedRating = index + 1;
//                   });
//                 },
//                 child: Icon(
//                   index < selectedRating ? Icons.star : Icons.star_border,
//                   color: Colors.amber,
//                   size: isSmallScreen ? 32 : 36,
//                 ),
//               );
//             }),
//           ),
//         ),
        
//         SizedBox(height: 20),
        
//         // Comment
//         Text(
//           'Additional comments (optional):',
//           style: AppFonts.montserratText2.copyWith(
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         SizedBox(height: 8),
//         CustomTextField(
//            controller: commentController,
//            maxLines: 3,
//           hintText: 'Tell us about your experience...',
//           ),
//         // TextField(
//         //   controller: commentController,
//         //   maxLines: 3,
//         //   decoration: InputDecoration(
//         //     hintText: 'Tell us about your experience...',
//         //     border: OutlineInputBorder(
//         //       borderRadius: BorderRadius.circular(8),
//         //     ),
//         //     contentPadding: EdgeInsets.all(12),
//         //   ),
//         // ),
        
//         SizedBox(height: 24),
        
//         // Buttons
//         if (isSubmitting)
//           Center(
//             child: CircularProgressIndicator(color: AppColors.mainColor),
//           )
//         else
//           Row(
//             children: [
//               // Remind later
//               Expanded(
//                 child: CustomButton(
//                   onPressed: () {
//                     widget.controller.remindLater();
//                   },
                 
//                   text: 'Later ',
                  
//                 ),
//               ),
//               SizedBox(width: 12),
              
//               // Submit
//               Expanded(
//                 child: CustomButton(
//                   onPressed: selectedRating > 0 ? _submitFeedback : null,
                  
//                   text: 'Submit',
//                 ),
//               ),
//             ],
//           ),
        
//         SizedBox(height: 8),
        
//         // Opt out
//         Center(
//           child: TextButton(
//             onPressed: () {
//               widget.controller.optOutFeedback();
//             },
//             child: Text(
//               'Don\'t ask again',
//               style: AppFonts.montserratGreyText14,
//             ),
//           ),
//         ),
//       ],
//     );
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

//   Future<void> _submitFeedback() async {
//     setState(() {
//       isSubmitting = true;
//     });

//     final serviceId = widget.service['_id'] ?? widget.service['id'];
//     final mechanicId = widget.service['mechanic_id'];
//     final mechanicName = widget.service['mechanic_name'];

//     if (serviceId == null || mechanicId == null) {
//       Get.snackbar(
//         'Error',
//         'Unable to submit feedback',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       return;
//     }

//     final success = await widget.controller.submitFeedback(
//       serviceId: serviceId.toString(),
//       mechanicId: mechanicId.toString(),
//       mechanicName: mechanicName ?? 'Unknown Mechanic',
//       rating: selectedRating,
//       comment: commentController.text.trim(),
//     );

//     setState(() {
//       isSubmitting = false;
//     });

//     if (success) {
//       Get.snackbar(
//         'Thank You!',
//         'Your feedback has been submitted',
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//       );
//     } else {
//       Get.snackbar(
//         'Error',
//         'Failed to submit feedback. Please try again.',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }
// }