import 'dart:convert';
import 'package:flutter/services.dart';

class LanguageService {
  static Map<String, dynamic>? _englishData;
  static Map<String, dynamic>? _urduData;
  static Map<String, dynamic>? _punjabiData;

  static String _currentLanguage = 'english';

  static String get currentLanguage => _currentLanguage;

  static Future<void> initialize() async {
    try {
      // Load all language files
      final englishJson = await rootBundle.loadString('assets/breakdowns.json');
      _englishData = json.decode(englishJson);
      
      final urduJson = await rootBundle.loadString('assets/translated_urdu.json');
      _urduData = json.decode(urduJson);
      
      final punjabiJson = await rootBundle.loadString('assets/translated_punjabi.json');
      _punjabiData = json.decode(punjabiJson);
      
      print('✅ Language files loaded successfully');
      print('📊 English breakdowns: ${_englishData?["Breakdowns"]?.length ?? 0}');
      print('📊 Urdu breakdowns: ${_urduData?["Breakdowns"]?.length ?? 0}');
      print('📊 Punjabi breakdowns: ${_punjabiData?["Breakdowns"]?.length ?? 0}');
    } catch (e) {
      print('❌ Error loading language files: $e');
    }
  }

  static void setLanguage(String language) {
    _currentLanguage = language.toLowerCase();
    print('🌐 Language changed to: $_currentLanguage');
  }

  static Map<String, dynamic>? _getSourceData() {
    switch (_currentLanguage) {
      case 'urdu':
        return _urduData;
      case 'punjabi':
        return _punjabiData;
      case 'english':
      default:
        return _englishData;
    }
  }

  // Get all breakdowns for the current language
  static List<dynamic>? getBreakdowns() {
    final sourceData = _getSourceData();
    return sourceData?["Breakdowns"] as List?;
  }

  // Get breakdown by index
  static Map<String, dynamic>? getBreakdownByIndex(int index) {
    final breakdowns = getBreakdowns();
    if (breakdowns != null && index < breakdowns.length) {
      final breakdown = breakdowns[index] as Map<String, dynamic>?;
      print('🔍 Found breakdown at index $index: ${breakdown?["Name"]}');
      return breakdown;
    }
    print('❌ No breakdown found at index $index');
    return null;
  }

  // Get category data by breakdown index and vehicle type
  static Map<String, dynamic>? getCategoryData(int breakdownIndex, String vehicleType) {
    final breakdown = getBreakdownByIndex(breakdownIndex);
    if (breakdown != null) {
      // Handle both "Car" and "In Cars" style keys
      var categoryData = breakdown[vehicleType] as Map<String, dynamic>?;
      
      // If not found with exact key, try alternative keys
      if (categoryData == null) {
        if (vehicleType == "Car") {
          categoryData = breakdown["In Cars"] as Map<String, dynamic>?;
        } else if (vehicleType == "Bike") {
          categoryData = breakdown["In Bikes"] as Map<String, dynamic>?;
        }
      }
      
      print('🔍 Category data for index $breakdownIndex, $vehicleType: ${categoryData != null}');
      if (categoryData != null) {
        print('🔍 Category data keys: ${categoryData.keys}');
      }
      return categoryData;
    }
    return null;
  }

  // Get translated step by index
  static String getTranslatedStep(int breakdownIndex, String vehicleType, int stepIndex, String defaultStep) {
    final categoryData = getCategoryData(breakdownIndex, vehicleType);
    
    if (categoryData != null) {
      final steps = categoryData["Steps"] as List?;
      if (steps != null && stepIndex < steps.length) {
        final translatedStep = steps[stepIndex].toString();
        print('✅ Translated step $stepIndex: "$translatedStep"');
        return translatedStep;
      } else {
        print('❌ No translated step found at index $stepIndex');
      }
    } else {
      print('❌ No category data found for translation');
    }
    
    // Fallback to original step
    print('🔄 Using default step for index $stepIndex');
    return defaultStep;
  }

  // Get translated tools by index
  static List<String> getTranslatedTools(int breakdownIndex, String vehicleType, List<String> defaultTools) {
    final categoryData = getCategoryData(breakdownIndex, vehicleType);
    
    if (categoryData != null) {
      final tools = categoryData["Tools Required"] as List?;
      if (tools != null) {
        final translatedTools = tools.map((t) => t.toString()).toList();
        print('✅ Translated tools: $translatedTools');
        return translatedTools;
      } else {
        print('❌ No translated tools found');
      }
    } else {
      print('❌ No category data found for tools translation');
    }
    
    // Fallback to original tools
    print('🔄 Using default tools');
    return defaultTools;
  }

  // Helper method for UI text translations
  static String getTranslatedUIText(String text) {
    switch (_currentLanguage) {
      case 'urdu':
        final translations = {
          "Select Vehicle Type": "گاڑی کی قسم منتخب کریں",
          "Tools Required": "ضروری اوزار",
          "Steps": "مراحل",
          "Current Language": "موجودہ زبان",
          "Car": "کار",
          "Bike": "موٹر سائیکل",
        };
        return translations[text] ?? text;
      case 'punjabi':
        final translations = {
          "Select Vehicle Type": "گاڑی دی قسم چݨو",
          "Tools Required": "لوڑیندے ٹول",
          "Steps": "قدم",
          "Current Language": "موجودہ زبان",
          "Car": "کار",
          "Bike": "موٹر سائیکل",
        };
        return translations[text] ?? text;
      default:
        return text;
    }
  }
}