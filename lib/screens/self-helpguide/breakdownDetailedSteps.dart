import 'package:fixibot_app/widgets/customAppBar.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_fontStyles.dart';

class BreakdownDetailScreen extends StatelessWidget {
  final String issueName;
  final String vehicleType;
  final Map<String, dynamic> details;

  const BreakdownDetailScreen({
    Key? key,
    required this.issueName,
    required this.vehicleType,
    required this.details,
  }) : super(key: key);

  // Function to find the most relevant image for a step
  String? _findRelevantImage(String stepText, Map<dynamic, dynamic> images, int stepIndex) {
    final stepLower = stepText.toLowerCase();
    
    // Convert images to String keys and values
    final Map<String, String> stringImages = {};
    images.forEach((key, value) {
      stringImages[key.toString()] = value.toString();
    });
    
    final availableImages = Map<String, String>.from(stringImages);
    
    // Try to find exact keyword matches first
    for (final entry in availableImages.entries) {
      final imageKey = entry.key.toLowerCase();
      
      // Check for specific tool matches
      if (stepLower.contains('jack') && imageKey.contains('jack')) {
        return entry.value;
      }
      if (stepLower.contains('spanner') && imageKey.contains('spanner')) {
        return entry.value;
      }
      if (stepLower.contains('triangle') && imageKey.contains('triangle')) {
        return entry.value;
      }
      if (stepLower.contains('tyre') && imageKey.contains('tyre')) {
        return entry.value;
      }
      if (stepLower.contains('tire') && imageKey.contains('tire')) {
        return entry.value;
      }
      if (stepLower.contains('battery') && imageKey.contains('battery')) {
        return entry.value;
      }
      if (stepLower.contains('jumper') && imageKey.contains('jumper')) {
        return entry.value;
      }
      if (stepLower.contains('coolant') && imageKey.contains('coolant')) {
        return entry.value;
      }
      if (stepLower.contains('brake') && imageKey.contains('brake')) {
        return entry.value;
      }
      if (stepLower.contains('fuel') && imageKey.contains('fuel')) {
        return entry.value;
      }
      if (stepLower.contains('clutch') && imageKey.contains('clutch')) {
        return entry.value;
      }
      if (stepLower.contains('starter') && imageKey.contains('starter')) {
        return entry.value;
      }
      if (stepLower.contains('engine') && imageKey.contains('engine')) {
        return entry.value;
      }
      if (stepLower.contains('wiring') && imageKey.contains('wiring')) {
        return entry.value;
      }
      if (stepLower.contains('fuse') && imageKey.contains('fuse')) {
        return entry.value;
      }
      if (stepLower.contains('pump') && imageKey.contains('pump')) {
        return entry.value;
      }
      if (stepLower.contains('tube') && imageKey.contains('tube')) {
        return entry.value;
      }
      if (stepLower.contains('lever') && imageKey.contains('lever')) {
        return entry.value;
      }
      if (stepLower.contains('kit') && imageKey.contains('kit')) {
        return entry.value;
      }
    }
    
    // If no exact match, return any available image (first one)
    if (availableImages.isNotEmpty) {
      return availableImages.values.first;
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tools = (details["Tools Required"] != null)
        ? List<String>.from(details["Tools Required"])
        : [];

    final steps = (details["Steps"] != null)
        ? List<String>.from(details["Steps"])
        : [];

    final images = (details["Images"] != null)
        ? Map<dynamic, dynamic>.from(details["Images"])
        : <dynamic, dynamic>{};

    // Track used images to avoid repetition
    final usedImages = <String>{};

    return Scaffold(
      appBar: CustomAppBar(
        title: "$issueName - $vehicleType",
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tools Section
            if (tools.isNotEmpty) ...[
              Text("Tools Required:",
                  style: AppFonts.customTextStyle(
                      fontSize: 18,
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...tools.map((t) => ListTile(
                    leading: const Icon(Icons.build, color: AppColors.mainColor),
                    title: Text(t),
                  )),
              const SizedBox(height: 20),
            ],

            // Steps Section with Smart Image Distribution
            if (steps.isNotEmpty) ...[
              Text("Steps:",
                  style: AppFonts.customTextStyle(
                      fontSize: 18,
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              ...steps.asMap().entries.map((e) {
                final stepIndex = e.key;
                final stepText = e.value;
                
                String? imagePathForThisStep;
                
                // Only assign image if we have available images and haven't used all
                if (images.isNotEmpty && usedImages.length < images.length) {
                  // Find relevant image for this step
                  imagePathForThisStep = _findRelevantImage(stepText, images, stepIndex);
                  
                  // Convert to string for comparison
                  final imagePathString = imagePathForThisStep?.toString() ?? '';
                  
                  // If we found a relevant image and haven't used it yet
                  if (imagePathForThisStep != null && !usedImages.contains(imagePathString)) {
                    usedImages.add(imagePathString);
                  } else {
                    // If the relevant image is already used, try to find another unused image
                    for (final imageEntry in images.entries) {
                      final imagePath = imageEntry.value.toString();
                      if (!usedImages.contains(imagePath)) {
                        imagePathForThisStep = imagePath;
                        usedImages.add(imagePath);
                        break;
                      }
                    }
                  }
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Text
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.mainColor,
                            child: Text(
                              "${stepIndex + 1}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              stepText,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Image below step (if available and assigned to this step)
                    if (imagePathForThisStep != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            imagePathForThisStep!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 180,
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.image_not_supported, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Image not found',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else if (stepIndex < steps.length - 1) ...[
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}










// ///pperff
// import 'package:fixibot_app/widgets/customAppBar.dart';
// import 'package:flutter/material.dart';
// import '../../constants/app_colors.dart';
// import '../../constants/app_fontStyles.dart';

// class BreakdownDetailScreen extends StatelessWidget {
//   final String issueName;
//   final String vehicleType;
//   final Map<String, dynamic> details;

//   const BreakdownDetailScreen({
//     Key? key,
//     required this.issueName,
//     required this.vehicleType,
//     required this.details,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final tools = (details["Tools Required"] != null)
//         ? List<String>.from(details["Tools Required"])
//         : []; // safe fallback

//     final steps = (details["Steps"] != null)
//         ? List<String>.from(details["Steps"])
//         : [];

//     final images = (details["Images"] != null)
//         ? Map<String, String>.from(details["Images"])
//         : {};

//     return Scaffold(
//       appBar: CustomAppBar(

//   title: "$issueName - $vehicleType",
// ),
      
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Tools
//             if (tools.isNotEmpty) ...[
//               Text("Tools Required:",
//                   style: AppFonts.customTextStyle(
//                       fontSize: 18,
//                       color: AppColors.mainColor,
//                       fontWeight: FontWeight.bold)),
//               const SizedBox(height: 8),
//               ...tools.map((t) => ListTile(
//                     leading: const Icon(Icons.build),
//                     title: Text(t),
//                   )),
//               const SizedBox(height: 20),
//             ],

//             // Steps
//             if (steps.isNotEmpty) ...[
//               Text("Steps:",
//                   style: AppFonts.customTextStyle(
//                       fontSize: 18,
//                       color: AppColors.mainColor,
//                       fontWeight: FontWeight.bold)),
//               const SizedBox(height: 8),
//               ...steps.asMap().entries.map((e) => ListTile(
//                     leading: CircleAvatar(
//                       radius: 12,
//                       child: Text("${e.key + 1}"),
//                     ),
//                     title: Text(e.value),
//                   )),
//               const SizedBox(height: 20),
//             ],

//             // Images
//             if (images.isNotEmpty) ...[
//               Text("Illustrations:",
//                   style: AppFonts.customTextStyle(
//                       fontSize: 18,
//                       color: AppColors.mainColor,
//                       fontWeight: FontWeight.bold)),
//               const SizedBox(height: 12),
            
//               Center(
//   child: Wrap(
//     spacing: 12,
//     runSpacing: 12,
//     alignment: WrapAlignment.center,
//     children: images.values
//         .map((imgPath) => ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: Image.asset(
//                 imgPath,
//                 height: 250,
//                 width: 250,
//                 fit: BoxFit.cover,
//               ),
//             ))
//         .toList(),
//   ),
// )

//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }