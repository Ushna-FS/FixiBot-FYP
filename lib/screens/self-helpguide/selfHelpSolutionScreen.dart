// screens/self-helpguide/self_help_solutions.dart
import 'package:fixibot_app/screens/self-helpguide/breakdownDetailedSteps.dart';
import 'package:fixibot_app/services/language_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_fontStyles.dart';

class SelfHelpSolutions extends StatefulWidget {
  final Map<String, dynamic> issueData;
  final int breakdownIndex;

  const SelfHelpSolutions({
    Key? key, 
    required this.issueData,
    required this.breakdownIndex
  }) : super(key: key);

  @override
  State<SelfHelpSolutions> createState() => _SelfHelpSolutionsState();
}

class _SelfHelpSolutionsState extends State<SelfHelpSolutions> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    await LanguageService.initialize();
    setState(() {
      _isLoading = false;
    });
  }

  void _changeLanguage(String language) {
    setState(() {
      LanguageService.setLanguage(language);
    });
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

    // DEBUG: Print the complete structure
    print('🎯 COMPLETE issueData STRUCTURE:');
    print('Main Keys: ${widget.issueData.keys}');
    
    // Check if we have direct Car/Bike keys or if they're nested under "Categories"
    bool hasDirectKeys = widget.issueData.containsKey("Car") || widget.issueData.containsKey("Bike");
    bool hasCategoriesKey = widget.issueData.containsKey("Categories");
    
    print('Has direct Car/Bike keys: $hasDirectKeys');
    print('Has Categories key: $hasCategoriesKey');
    
    if (hasCategoriesKey) {
      final categories = widget.issueData["Categories"];
      print('Categories type: ${categories.runtimeType}');
      if (categories is Map) {
        print('Categories keys: ${categories.keys}');
      }
    }

    final issueName = widget.issueData["Name"] ?? 'Unknown Issue';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.secondaryColor,
        title: Text(
          issueName,
          style: AppFonts.customTextStyle(
            fontSize: 20,
            color: AppColors.mainColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Get.back();
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
        child: Container(
          color: AppColors.secondaryColor,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Horizontal Language Selector
                _buildLanguageSelector(),
                const SizedBox(height: 20),

                Text(
                  LanguageService.getTranslatedUIText("Select Vehicle Type"),
                  style: AppFonts.customTextStyle(
                    color: AppColors.textColor2,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),

                // Build vehicle options based on actual data structure
                ..._buildVehicleOptions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildVehicleOptions() {
    final List<Widget> options = [];
    
    // Check different possible data structures
    Map<String, dynamic>? carData;
    Map<String, dynamic>? bikeData;

    // Case 1: Direct Car/Bike keys
    if (widget.issueData.containsKey("Car")) {
      final carDataDynamic = widget.issueData["Car"];
      if (carDataDynamic is Map) {
        carData = Map<String, dynamic>.from(carDataDynamic);
        print('✅ Found Car data directly');
      }
    }
    if (widget.issueData.containsKey("Bike")) {
      final bikeDataDynamic = widget.issueData["Bike"];
      if (bikeDataDynamic is Map) {
        bikeData = Map<String, dynamic>.from(bikeDataDynamic);
        print('✅ Found Bike data directly');
      }
    }

    // Case 2: Nested under "Categories"
    if (widget.issueData.containsKey("Categories")) {
      final categories = widget.issueData["Categories"];
      if (categories is Map) {
        final categoriesMap = Map<String, dynamic>.from(categories);
        if (categoriesMap.containsKey("Car")) {
          final carDataDynamic = categoriesMap["Car"];
          if (carDataDynamic is Map) {
            carData = Map<String, dynamic>.from(carDataDynamic);
            print('✅ Found Car data under Categories');
          }
        }
        if (categoriesMap.containsKey("Bike")) {
          final bikeDataDynamic = categoriesMap["Bike"];
          if (bikeDataDynamic is Map) {
            bikeData = Map<String, dynamic>.from(bikeDataDynamic);
            print('✅ Found Bike data under Categories');
          }
        }
      }
    }

    // Case 3: Try to find any vehicle-like keys
    if (carData == null && bikeData == null) {
      print('🔍 Searching for vehicle data in all keys...');
      widget.issueData.forEach((key, value) {
        if (value is Map && key != "Name" && key != "Categories") {
          final keyLower = key.toLowerCase();
          if (keyLower.contains('car') && carData == null) {
            carData = Map<String, dynamic>.from(value);
            print('✅ Found Car-like data with key: $key');
          } else if (keyLower.contains('bike') && bikeData == null) {
            bikeData = Map<String, dynamic>.from(value);
            print('✅ Found Bike-like data with key: $key');
          }
        }
      });
    }

    // Build options for found data
    if (carData != null) {
      options.add(_buildVehicleOption("Car", carData!, LanguageService.getTranslatedUIText("Car")));
    }
    if (bikeData != null) {
      options.add(_buildVehicleOption("Bike", bikeData!, LanguageService.getTranslatedUIText("Bike")));
    }

    // If no options found, show error
    if (options.isEmpty) {
      print('❌ No vehicle data found at all!');
      options.add(
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No vehicle data available',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return options;
  }

  Widget _buildVehicleOption(String vehicleKey, Map<String, dynamic> categoryData, String translatedType) {
    print('🚗 Building option for $vehicleKey');
    print('📦 Category data keys: ${categoryData.keys}');

    // Extract first image from "Images"
    String? imagePath;
    if (categoryData["Images"] != null) {
      final imagesDynamic = categoryData["Images"];
      if (imagesDynamic is Map) {
        final imagesMap = Map<String, dynamic>.from(imagesDynamic);
        if (imagesMap.isNotEmpty) {
          // Get the first image value
          final firstImageEntry = imagesMap.entries.first;
          imagePath = firstImageEntry.value.toString();
          print('🖼️ First image for $vehicleKey: $imagePath');
        }
      }
    }

    // Check if we have steps data
    final hasSteps = categoryData["Steps"] != null && (categoryData["Steps"] as List).isNotEmpty;
    final hasTools = categoryData["Tools Required"] != null && (categoryData["Tools Required"] as List).isNotEmpty;
    
    print('📝 $vehicleKey has steps: $hasSteps');
    print('🔧 $vehicleKey has tools: $hasTools');

    return GestureDetector(
      onTap: () {
        print('🎯 Navigating to detail screen for $vehicleKey');
        print('📋 Details data type: ${categoryData.runtimeType}');
        
        Get.to(() => BreakdownDetailScreen(
              breakdownIndex: widget.breakdownIndex,
              issueName: widget.issueData['Name'],
              vehicleType: vehicleKey,
              details: categoryData,
            ));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Box
          Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mainColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  translatedType,
                  style: AppFonts.customTextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 18),
              ],
            ),
          ),

          // Image display
          if (imagePath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0, left: 10.0, right: 10.0),
              child: Container(
                height: MediaQuery.of(context).size.height / 3,
                width: MediaQuery.of(context).size.width - 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('❌ Error loading image: $error');
                      return Container(
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, 
                                color: Colors.grey, size: 50),
                            SizedBox(height: 8),
                            Text(
                              'Image not found',
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No image available',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Steps: ${hasSteps ? "Available" : "Not available"}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Horizontal Language Selector
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