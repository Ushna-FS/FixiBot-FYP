// screens/self-helpguide/breakdownDetailedSteps.dart
import 'package:fixibot_app/services/language_handler.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_fontStyles.dart';

class BreakdownDetailScreen extends StatefulWidget {
  final int breakdownIndex;
  final String issueName;
  final String vehicleType;
  final Map<String, dynamic> details;

  const BreakdownDetailScreen({
    Key? key,
    required this.breakdownIndex,
    required this.issueName,
    required this.vehicleType,
    required this.details,
  }) : super(key: key);

  @override
  State<BreakdownDetailScreen> createState() => _BreakdownDetailScreenState();
}

class _BreakdownDetailScreenState extends State<BreakdownDetailScreen> {
  bool _isLoading = true;
  List<String> _translatedTools = [];
  List<String> _translatedSteps = [];
  Map<dynamic, dynamic> _images = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    await LanguageService.initialize();
    _loadTranslatedData();
    setState(() {
      _isLoading = false;
    });
  }

  void _loadTranslatedData() {
    print('🔄 Loading translated data for breakdown index: ${widget.breakdownIndex}');
    print('🚗 Vehicle type: ${widget.vehicleType}');
    print('🌐 Current language: ${LanguageService.currentLanguage}');
    
    final List<String> originalTools = [];
    final List<String> originalSteps = [];

    if (widget.details["Tools Required"] != null) {
      final toolsDynamic = widget.details["Tools Required"];
      if (toolsDynamic is List) {
        originalTools.addAll(List<String>.from(toolsDynamic.map((item) => item.toString())));
      }
    }
    if (widget.details["Steps"] != null) {
      final stepsDynamic = widget.details["Steps"];
      if (stepsDynamic is List) {
        originalSteps.addAll(List<String>.from(stepsDynamic.map((item) => item.toString())));
      }
    }
    if (widget.details["Images"] != null) {
      final imagesDynamic = widget.details["Images"];
      if (imagesDynamic is Map) {
        _images.addAll(Map<dynamic, dynamic>.from(imagesDynamic));
      }
    }

    _translatedTools = LanguageService.getTranslatedTools(
      widget.breakdownIndex,
      widget.vehicleType, 
      originalTools
    );

    _translatedSteps = originalSteps.asMap().entries.map((e) {
      final stepIndex = e.key;
      final originalStepText = e.value;
      
      final translatedStep = LanguageService.getTranslatedStep(
        widget.breakdownIndex,
        widget.vehicleType,
        stepIndex,
        originalStepText,
      );
      
      return translatedStep;
    }).toList();
  }

  void _changeLanguage(String language) {
    setState(() {
      LanguageService.setLanguage(language);
      _loadTranslatedData();
    });
  }

  String? _findRelevantImage(String stepText, Map<dynamic, dynamic> images, int stepIndex) {
    final stepLower = stepText.toLowerCase();
    
    final Map<String, String> stringImages = {};
    images.forEach((key, value) {
      stringImages[key.toString()] = value.toString();
    });
    
    final availableImages = Map<String, String>.from(stringImages);
    
    for (final entry in availableImages.entries) {
      final imageKey = entry.key.toLowerCase();
      
      if (stepLower.contains('jack') && imageKey.contains('jack')) return entry.value;
      if (stepLower.contains('spanner') && imageKey.contains('spanner')) return entry.value;
      if (stepLower.contains('triangle') && imageKey.contains('triangle')) return entry.value;
      if (stepLower.contains('tyre') && imageKey.contains('tyre')) return entry.value;
      if (stepLower.contains('tire') && imageKey.contains('tire')) return entry.value;
      if (stepLower.contains('battery') && imageKey.contains('battery')) return entry.value;
      if (stepLower.contains('jumper') && imageKey.contains('jumper')) return entry.value;
      if (stepLower.contains('coolant') && imageKey.contains('coolant')) return entry.value;
      if (stepLower.contains('brake') && imageKey.contains('brake')) return entry.value;
      if (stepLower.contains('fuel') && imageKey.contains('fuel')) return entry.value;
      if (stepLower.contains('engine') && imageKey.contains('engine')) return entry.value;
      if (stepLower.contains('clutch') && imageKey.contains('clutch')) return entry.value;
      if (stepLower.contains('starter') && imageKey.contains('starter')) return entry.value;
      if (stepLower.contains('indicator') && imageKey.contains('indicator')) return entry.value;
    }
    
    final imageEntries = availableImages.entries.toList();
    if (imageEntries.isNotEmpty) {
      return imageEntries[stepIndex % imageEntries.length].value;
    }
    
    return null;
  }

  // 🔥 NEW: Check if current language is RTL
  bool get _isRTL {
    final lang = LanguageService.currentLanguage;
    return lang == 'urdu' || lang == 'punjabi' || lang == 'sindhi' || lang == 'arabic';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.secondaryColor,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.mainColor,
          ),
        ),
      );
    }

    final usedImages = <String>{};
    final translatedVehicleType = _getTranslatedVehicleType(widget.vehicleType);

    return Directionality( // 🔥 WRAP ENTIRE SCREEN IN DIRECTIONALITY
      textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.secondaryColor,
          title: Text(
            "${widget.issueName} - $translatedVehicleType",
            style: AppFonts.customTextStyle(
              fontSize: 20,
              color: AppColors.mainColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            }, 
            icon: Image.asset(
              'assets/icons/back.png',
              width: 30,
              height: 30,
            ),
          ),
          centerTitle: true,
        ),
        
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: _isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Horizontal Language Selector
              _buildLanguageSelector(),
              const SizedBox(height: 20),

              // Tools Section
              if (_translatedTools.isNotEmpty) ...[
                Container(
                  alignment: _isRTL ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    "${LanguageService.getTranslatedUIText("Tools Required")}:",
                    style: AppFonts.customTextStyle(
                      fontSize: 18,
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ..._translatedTools.map((t) => Directionality(
                  textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
                  child: ListTile(
                    leading: _isRTL ? null : const Icon(Icons.build, color: AppColors.mainColor),
                    trailing: _isRTL ? const Icon(Icons.build, color: AppColors.mainColor) : null,
                    title: Text(
                      t,
                      style: TextStyle(fontSize: 16),
                      textAlign: _isRTL ? TextAlign.right : TextAlign.left,
                    ),
                  ),
                )),
                const SizedBox(height: 20),
              ],

              // Steps Section
              _buildStepsSection(_translatedSteps, _images, usedImages),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepsSection(List<String> stepsToDisplay, Map<dynamic, dynamic> images, Set<String> usedImages) {
    if (stepsToDisplay.isEmpty) {
      return Center(
        child: Text(
          'No steps available',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return Directionality(
      textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: _isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            alignment: _isRTL ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              "${LanguageService.getTranslatedUIText("Steps")}:",
              style: AppFonts.customTextStyle(
                fontSize: 18,
                color: AppColors.mainColor,
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          ...stepsToDisplay.asMap().entries.map((e) {
            final stepIndex = e.key;
            final stepText = e.value;
            
            String? imagePathForThisStep;
            
            if (images.isNotEmpty) {
              imagePathForThisStep = _findRelevantImage(stepText, images, stepIndex);
              
              if (imagePathForThisStep != null) {
                final imagePathString = imagePathForThisStep.toString();
                if (!usedImages.contains(imagePathString)) {
                  usedImages.add(imagePathString);
                } else {
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
            }
            
            return Directionality(
              textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
              child: Column(
                crossAxisAlignment: _isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
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
                      mainAxisAlignment: _isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!_isRTL) ...[
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
                        ],
                        Expanded(
                          child: Text(
                            stepText,
                            style: TextStyle(fontSize: 14),
                            textAlign: _isRTL ? TextAlign.right : TextAlign.left,
                          ),
                        ),
                        if (_isRTL) ...[
                          const SizedBox(width: 16),
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
                        ],
                      ],
                    ),
                  ),
                  
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
                                    'Image not found: ${imagePathForThisStep?.split('/').last}',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else if (stepIndex < stepsToDisplay.length - 1) ...[
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _getTranslatedVehicleType(String vehicleKey) {
    switch (vehicleKey) {
      case "Car":
        return LanguageService.getTranslatedUIText("Car");
      case "Bike":
        return LanguageService.getTranslatedUIText("Bike");
      default:
        return vehicleKey;
    }
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.mainColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
        children: [
          _buildLanguageButton('english', 'English'),
          _buildLanguageButton('urdu', 'Urdu'),
          _buildLanguageButton('punjabi', 'Punjabi'),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String language, String displayText) {
    bool isSelected = LanguageService.currentLanguage == language;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            _changeLanguage(language);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.mainColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            displayText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.mainColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}










// // screens/self-helpguide/breakdownDetailedSteps.dart
// import 'package:fixibot_app/services/language_handler.dart';
// import 'package:flutter/material.dart';
// import '../../constants/app_colors.dart';
// import '../../constants/app_fontStyles.dart';

// class BreakdownDetailScreen extends StatefulWidget {
//   final int breakdownIndex;
//   final String issueName;
//   final String vehicleType;
//   final Map<String, dynamic> details;

//   const BreakdownDetailScreen({
//     Key? key,
//     required this.breakdownIndex,
//     required this.issueName,
//     required this.vehicleType,
//     required this.details,
//   }) : super(key: key);

//   @override
//   State<BreakdownDetailScreen> createState() => _BreakdownDetailScreenState();
// }

// class _BreakdownDetailScreenState extends State<BreakdownDetailScreen> {
//   bool _isLoading = true;
//   List<String> _translatedTools = [];
//   List<String> _translatedSteps = [];
//   Map<dynamic, dynamic> _images = {};

//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//   }

//   void _initializeData() async {
//     await LanguageService.initialize();
//     _loadTranslatedData();
//     setState(() {
//       _isLoading = false;
//     });
//   }

//   void _loadTranslatedData() {
//   print('🔄 Loading translated data for breakdown index: ${widget.breakdownIndex}');
//   print('🚗 Vehicle type: ${widget.vehicleType}');
//   print('🌐 Current language: ${LanguageService.currentLanguage}');
  
//   // Get original data from the passed details
//   final List<String> originalTools = [];
//   final List<String> originalSteps = [];

//   // Extract original data
//   if (widget.details["Tools Required"] != null) {
//     final toolsDynamic = widget.details["Tools Required"];
//     if (toolsDynamic is List) {
//       originalTools.addAll(List<String>.from(toolsDynamic.map((item) => item.toString())));
//     }
//   }
//   if (widget.details["Steps"] != null) {
//     final stepsDynamic = widget.details["Steps"];
//     if (stepsDynamic is List) {
//       originalSteps.addAll(List<String>.from(stepsDynamic.map((item) => item.toString())));
//     }
//   }
//   if (widget.details["Images"] != null) {
//     final imagesDynamic = widget.details["Images"];
//     if (imagesDynamic is Map) {
//       _images.addAll(Map<dynamic, dynamic>.from(imagesDynamic));
//     }
//   }

//   print('🔧 Original tools: $originalTools');
//   print('📝 Original steps: $originalSteps');
//   print('🖼️ Available images: $_images');

//   // Get translated content using the language service
//   _translatedTools = LanguageService.getTranslatedTools(
//     widget.breakdownIndex,
//     widget.vehicleType, 
//     originalTools
//   );

//   print('🔧 Translated tools: $_translatedTools');

//   // Debug each step translation
//   _translatedSteps = originalSteps.asMap().entries.map((e) {
//     final stepIndex = e.key;
//     final originalStepText = e.value;
    
//     final translatedStep = LanguageService.getTranslatedStep(
//       widget.breakdownIndex,
//       widget.vehicleType,
//       stepIndex,
//       originalStepText,
//     );
    
//     print('📝 Step $stepIndex - Original: "$originalStepText"');
//     print('📝 Step $stepIndex - Translated: "$translatedStep"');
//     print('📝 Step $stepIndex - Changed: ${originalStepText != translatedStep}');
    
//     return translatedStep;
//   }).toList();

//   print('📝 Final translated steps count: ${_translatedSteps.length}');
// }
//   void _changeLanguage(String language) {
//     setState(() {
//       LanguageService.setLanguage(language);
//       _loadTranslatedData(); // Reload data when language changes
//     });
//   }

//   String? _findRelevantImage(String stepText, Map<dynamic, dynamic> images, int stepIndex) {
//     final stepLower = stepText.toLowerCase();
    
//     final Map<String, String> stringImages = {};
//     images.forEach((key, value) {
//       stringImages[key.toString()] = value.toString();
//     });
    
//     final availableImages = Map<String, String>.from(stringImages);
    
//     // Try to find exact keyword matches first
//     for (final entry in availableImages.entries) {
//       final imageKey = entry.key.toLowerCase();
      
//       if (stepLower.contains('jack') && imageKey.contains('jack')) return entry.value;
//       if (stepLower.contains('spanner') && imageKey.contains('spanner')) return entry.value;
//       if (stepLower.contains('triangle') && imageKey.contains('triangle')) return entry.value;
//       if (stepLower.contains('tyre') && imageKey.contains('tyre')) return entry.value;
//       if (stepLower.contains('tire') && imageKey.contains('tire')) return entry.value;
//       if (stepLower.contains('battery') && imageKey.contains('battery')) return entry.value;
//       if (stepLower.contains('jumper') && imageKey.contains('jumper')) return entry.value;
//       if (stepLower.contains('coolant') && imageKey.contains('coolant')) return entry.value;
//       if (stepLower.contains('brake') && imageKey.contains('brake')) return entry.value;
//       if (stepLower.contains('fuel') && imageKey.contains('fuel')) return entry.value;
//       if (stepLower.contains('engine') && imageKey.contains('engine')) return entry.value;
//       if (stepLower.contains('clutch') && imageKey.contains('clutch')) return entry.value;
//       if (stepLower.contains('starter') && imageKey.contains('starter')) return entry.value;
//       if (stepLower.contains('indicator') && imageKey.contains('indicator')) return entry.value;
//     }
    
//     // If no match found, use round-robin assignment
//     final imageEntries = availableImages.entries.toList();
//     if (imageEntries.isNotEmpty) {
//       return imageEntries[stepIndex % imageEntries.length].value;
//     }
    
//     return null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Scaffold(
//         backgroundColor: AppColors.secondaryColor,
//         body: Center(
//           child: CircularProgressIndicator(
//             color: AppColors.mainColor,
//           ),
//         ),
//       );
//     }

//     final usedImages = <String>{};
//     final translatedVehicleType = _getTranslatedVehicleType(widget.vehicleType);

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: AppColors.secondaryColor,
//         title: Text(
//           "${widget.issueName} - $translatedVehicleType",
//           style: AppFonts.customTextStyle(
//             fontSize: 20,
//             color: AppColors.mainColor,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         leading: IconButton(
//           onPressed: () {
//             Navigator.pop(context);
//           }, 
//           icon: Image.asset(
//             'assets/icons/back.png',
//             width: 30,
//             height: 30,
//           ),
//         ),
//         centerTitle: true,
//       ),
      
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Horizontal Language Selector
//             _buildLanguageSelector(),
//             const SizedBox(height: 20),

//             // Tools Section
//             if (_translatedTools.isNotEmpty) ...[
//               Text(
//                 "${LanguageService.getTranslatedUIText("Tools Required")}:",
//                 style: AppFonts.customTextStyle(
//                   fontSize: 18,
//                   color: AppColors.mainColor,
//                   fontWeight: FontWeight.bold
//                 ),
//               ),
//               const SizedBox(height: 8),
//               ..._translatedTools.map((t) => ListTile(
//                     leading: const Icon(Icons.build, color: AppColors.mainColor),
//                     title: Text(
//                       t,
//                       style: TextStyle(fontSize: 16),
//                     ),
//                   )),
//               const SizedBox(height: 20),
//             ],

//             // Steps Section
//             _buildStepsSection(_translatedSteps, _images, usedImages),
//           ],
//         ),
//       ),
//     );
//   }

//   // Separate method to build steps section
//   Widget _buildStepsSection(List<String> stepsToDisplay, Map<dynamic, dynamic> images, Set<String> usedImages) {
//     if (stepsToDisplay.isEmpty) {
//       return Center(
//         child: Text(
//           'No steps available',
//           style: TextStyle(
//             color: Colors.grey,
//             fontSize: 16,
//           ),
//         ),
//       );
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "${LanguageService.getTranslatedUIText("Steps")}:",
//           style: AppFonts.customTextStyle(
//             fontSize: 18,
//             color: AppColors.mainColor,
//             fontWeight: FontWeight.bold
//           ),
//         ),
//         const SizedBox(height: 8),
        
//         ...stepsToDisplay.asMap().entries.map((e) {
//           final stepIndex = e.key;
//           final stepText = e.value;
          
//           String? imagePathForThisStep;
          
//           if (images.isNotEmpty) {
//             imagePathForThisStep = _findRelevantImage(stepText, images, stepIndex);
            
//             if (imagePathForThisStep != null) {
//               final imagePathString = imagePathForThisStep.toString();
//               if (!usedImages.contains(imagePathString)) {
//                 usedImages.add(imagePathString);
//               } else {
//                 // If image already used, find next available
//                 for (final imageEntry in images.entries) {
//                   final imagePath = imageEntry.value.toString();
//                   if (!usedImages.contains(imagePath)) {
//                     imagePathForThisStep = imagePath;
//                     usedImages.add(imagePath);
//                     break;
//                   }
//                 }
//               }
//             }
//           }
          
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[50],
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey[200]!),
//                 ),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     CircleAvatar(
//                       radius: 14,
//                       backgroundColor: AppColors.mainColor,
//                       child: Text(
//                         "${stepIndex + 1}",
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Text(
//                         stepText,
//                         style: TextStyle(fontSize: 14),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
              
//               if (imagePathForThisStep != null) ...[
//                 const SizedBox(height: 12),
//                 Center(
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(12),
//                     child: Image.asset(
//                       imagePathForThisStep!,
//                       height: 180,
//                       width: double.infinity,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) {
//                         print('❌ Error loading detail image: $error');
//                         return Container(
//                           height: 180,
//                           width: double.infinity,
//                           color: Colors.grey[200],
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               const Icon(Icons.image_not_supported, color: Colors.grey),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Image not found: ${imagePathForThisStep?.split('/').last}',
//                                 textAlign: TextAlign.center,
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//               ] else if (stepIndex < stepsToDisplay.length - 1) ...[
//                 const SizedBox(height: 16),
//               ],
//             ],
//           );
//         }).toList(),
//       ],
//     );
//   }

//   String _getTranslatedVehicleType(String vehicleKey) {
//     switch (vehicleKey) {
//       case "Car":
//         return LanguageService.getTranslatedUIText("Car");
//       case "Bike":
//         return LanguageService.getTranslatedUIText("Bike");
//       default:
//         return vehicleKey;
//     }
//   }

//   // Horizontal Language Selector for Detail Screen
//   Widget _buildLanguageSelector() {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(25),
//         border: Border.all(color: AppColors.mainColor),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           _buildLanguageButton('english', 'English'),
//           _buildLanguageButton('urdu', 'Urdu'),
//           _buildLanguageButton('punjabi', 'Punjabi'),
//         ],
//       ),
//     );
//   }

//   Widget _buildLanguageButton(String language, String displayText) {
//     bool isSelected = LanguageService.currentLanguage == language;
//     return Expanded(
//       child: GestureDetector(
//         onTap: () {
//           if (!isSelected) {
//             _changeLanguage(language);
//           }
//         },
//         child: Container(
//           margin: const EdgeInsets.symmetric(horizontal: 4),
//           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
//           decoration: BoxDecoration(
//             color: isSelected ? AppColors.mainColor : Colors.transparent,
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Text(
//             displayText,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: isSelected ? Colors.white : AppColors.mainColor,
//               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//               fontSize: 14,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }