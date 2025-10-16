// import 'dart:convert';

// import 'package:fixibot_app/screens/mechanics/controller/mechanicController.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class FeedbackController extends GetxController {
//   var showFeedbackPopup = false.obs;
//   var lastServiceForFeedback = <String, dynamic>{}.obs;
//   var hasPendingFeedback = false.obs;
//   String apiUrl = 'https://chalky-anjelica-bovinely.ngrok-free.dev/feedback';
//   final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";


//   // Check if user has completed services that need feedback
//   // Future<void> checkForPendingFeedback() async {
//   //   try {
//   //     final prefs = await SharedPreferences.getInstance();
//   //     final mechanicController = Get.find<MechanicController>();
      
//   //     // Get completed services (status = 'completed')
//   //     final completedServices = mechanicController.mechanicServices.where((service) {
//   //       return service['status'] == 'completed';
//   //     }).toList();

//   //     if (completedServices.isEmpty) {
//   //       hasPendingFeedback.value = false;
//   //       return;
//   //     }

//   //     // Sort by completion date (newest first)
//   //     completedServices.sort((a, b) {
//   //       final dateA = a['completed_at'] ?? a['updated_at'] ?? a['created_at'];
//   //       final dateB = b['completed_at'] ?? b['updated_at'] ?? b['created_at'];
//   //       return _compareDates(dateB, dateA);
//   //     });

//   //     // Get the most recent completed service
//   //     final latestService = completedServices.first;

//   //     // Check if feedback was already given for this service
//   //     final serviceId = latestService['_id'] ?? latestService['id'];
//   //     final feedbackGiven = prefs.getBool('feedback_given_$serviceId') ?? false;

//   //     if (!feedbackGiven) {
//   //       lastServiceForFeedback.value = latestService;
//   //       hasPendingFeedback.value = true;
        
//   //       // Check if enough time has passed since service completion (e.g., 1 hour)
//   //       final shouldShowPopup = await _shouldShowFeedbackPopup(latestService);
//   //       if (shouldShowPopup) {
//   //         showFeedbackPopup.value = true;
//   //       }
//   //     } else {
//   //       hasPendingFeedback.value = false;
//   //     }
//   //   } catch (e) {
//   //     print('Error checking for feedback: $e');
//   //   }
//   // }

//     Future<void> checkForPendingFeedback() async {
//     try {
//       print('🔄 [FEEDBACK] Starting feedback check...');
      
//       final prefs = await SharedPreferences.getInstance();
//       final mechanicController = Get.find<MechanicController>();
      
//       // Get all services
//       print('📋 [FEEDBACK] Total services: ${mechanicController.mechanicServices.length}');
      
//       // Get completed services (status = 'completed')
//       final completedServices = mechanicController.mechanicServices.where((service) {
//         final status = service['status']?.toString().toLowerCase();
//         final isCompleted = status == 'completed';
//         print('🔍 [FEEDBACK] Service ${service['_id']} - Status: $status - Completed: $isCompleted');
//         return isCompleted;
//       }).toList();

//       print('✅ [FEEDBACK] Completed services found: ${completedServices.length}');

//       if (completedServices.isEmpty) {
//         print('❌ [FEEDBACK] No completed services found');
//         hasPendingFeedback.value = false;
//         return;
//       }

//       // Sort by completion date (newest first)
//       completedServices.sort((a, b) {
//         final dateA = a['completed_at'] ?? a['updated_at'] ?? a['created_at'];
//         final dateB = b['completed_at'] ?? b['updated_at'] ?? b['created_at'];
//         return _compareDates(dateB, dateA);
//       });

//       // Get the most recent completed service
//       final latestService = completedServices.first;
//       final serviceId = latestService['_id'] ?? latestService['id'];
//       final mechanicName = latestService['mechanic_name'] ?? 'Unknown';
      
//       print('🎯 [FEEDBACK] Latest completed service: $serviceId - $mechanicName');
//       print('📅 [FEEDBACK] Service date: ${latestService['completed_at'] ?? latestService['created_at']}');

//       // Check if feedback was already given for this service
//       final feedbackGiven = prefs.getBool('feedback_given_$serviceId') ?? false;
//       print('📝 [FEEDBACK] Feedback already given: $feedbackGiven');

//       if (!feedbackGiven) {
//         lastServiceForFeedback.value = latestService;
//         hasPendingFeedback.value = true;
        
//         // Check if enough time has passed since service completion
//         final shouldShowPopup = await _shouldShowFeedbackPopup(latestService);
//         print('🎪 [FEEDBACK] Should show popup: $shouldShowPopup');
        
//         if (shouldShowPopup) {
//           showFeedbackPopup.value = true;
//           print('🚀 [FEEDBACK] POPUP TRIGGERED!');
//         }
//       } else {
//         hasPendingFeedback.value = false;
//         print('⏭️ [FEEDBACK] Feedback already given for this service');
//       }
//     } catch (e) {
//       print('❌ [FEEDBACK] Error in checkForPendingFeedback: $e');
//       print('❌ [FEEDBACK] Stack trace: ${e.toString()}');
//     }
//   }

//   // Determine if enough time has passed to show feedback popup
//   Future<bool> _shouldShowFeedbackPopup(Map<String, dynamic> service) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
      
//       // Check if user has opted out of feedback
//       final optOut = prefs.getBool('feedback_opt_out') ?? false;
//       print('🚫 [FEEDBACK] User opted out: $optOut');
//       if (optOut) return false;

//       // Get service completion time
//       final completedAt = service['completed_at'] ?? service['updated_at'] ?? service['created_at'];
//       print('⏰ [FEEDBACK] Service completion time: $completedAt');
      
//       if (completedAt == null) {
//         print('❌ [FEEDBACK] No completion time found');
//         return false;
//       }

//       final completionTime = DateTime.parse(completedAt);
//       final now = DateTime.now();
//       final timeDifference = now.difference(completionTime);

//       print('⏱️ [FEEDBACK] Time difference: ${timeDifference.inMinutes} minutes');
//       print('⏱️ [FEEDBACK] Time difference in hours: ${timeDifference.inHours} hours');
//       print('⏱️ [FEEDBACK] Time difference in days: ${timeDifference.inDays} days');

//       // TESTING: Show popup after 1 minute instead of 1 hour
//       final shouldShow = timeDifference.inMinutes >= 1 && timeDifference.inDays < 7;
//       print('🤔 [FEEDBACK] Should show based on time: $shouldShow');
      
//       return shouldShow;
      
//     } catch (e) {
//       print('❌ [FEEDBACK] Error in _shouldShowFeedbackPopup: $e');
//       return false;
//     }
//   }

//   // Add this method for manual testing
// void triggerFeedbackManually() async {
//   print('🎮 [FEEDBACK] MANUAL TRIGGER CALLED');
//   await checkForPendingFeedback();
  
//   if (!showFeedbackPopup.value) {
//     print('❌ [FEEDBACK] Manual trigger failed - no popup shown');
//     // Force show a test popup
//     final testService = {
//       '_id': 'test_service_123',
//       'mechanic_name': 'Test Mechanic',
//       'service_type': 'repair',
//       'mechanic_id': 'test_mechanic_123',
//       'completed_at': DateTime.now().toIso8601String(),
//     };
    
//     lastServiceForFeedback.value = testService;
//     showFeedbackPopup.value = true;
//     print('🎪 [FEEDBACK] TEST POPUP FORCED TO SHOW');
//   }
// }
//   // Determine if enough time has passed to show feedback popup
//   // Future<bool> _shouldShowFeedbackPopup(Map<String, dynamic> service) async {
//   //   try {
//   //     final prefs = await SharedPreferences.getInstance();
      
//   //     // Check if user has opted out of feedback
//   //     final optOut = prefs.getBool('feedback_opt_out') ?? false;
//   //     if (optOut) return false;

//   //     // Get service completion time
//   //     final completedAt = service['completed_at'] ?? service['updated_at'] ?? service['created_at'];
//   //     if (completedAt == null) return false;

//   //     final completionTime = DateTime.parse(completedAt);
//   //     final now = DateTime.now();
//   //     final timeDifference = now.difference(completionTime);

//   //     // Show popup if at least 1 hour has passed and less than 7 days
//   //     return timeDifference.inMinutes >= 0;
//   //     // return timeDifference.inHours >= 1 && timeDifference.inDays < 7;
//   //   } catch (e) {
//   //     return false;
//   //   }
//   // }

//   int _compareDates(String? dateA, String? dateB) {
//     try {
//       if (dateA == null && dateB == null) return 0;
//       if (dateA == null) return -1;
//       if (dateB == null) return 1;
      
//       final datetimeA = DateTime.parse(dateA);
//       final datetimeB = DateTime.parse(dateB);
//       return datetimeA.compareTo(datetimeB);
//     } catch (e) {
//       return 0;
//     }
//   }

//   // Submit feedback
//   Future<bool> submitFeedback({
//     required String serviceId,
//     required String mechanicId,
//     required String mechanicName,
//     required int rating,
//     required String comment,
//   }) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final accessToken = prefs.getString('access_token');
//       final userId = prefs.getString('user_id');

//       if (accessToken == null || userId == null) {
//         return false;
//       }

//       // TODO: Replace with your actual feedback API endpoint
//       final response = await http.post(
//         Uri.parse('$baseUrl/feedback'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $accessToken',
//         },
//         body: jsonEncode({
//           'user_id': userId,
//           'mechanic_id': mechanicId,
//           'service_id': serviceId,
//           'rating': rating,
//           'comment': comment,
//           'created_at': DateTime.now().toIso8601String(),
//         }),
//       );

//       // For now, simulate successful submission
//       await Future.delayed(Duration(seconds: 1));

//       // Mark feedback as given for this service
//       await prefs.setBool('feedback_given_$serviceId', true);
      
//       showFeedbackPopup.value = false;
//       hasPendingFeedback.value = false;
      
//       return true;
//     } catch (e) {
//       print('Error submitting feedback: $e');
//       return false;
//     }
//   }

//   // User opts out of feedback
//   Future<void> optOutFeedback() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('feedback_opt_out', true);
//     showFeedbackPopup.value = false;
//     hasPendingFeedback.value = false;
//   }

//   // Close popup without submitting (remind later)
//   void remindLater() {
//     showFeedbackPopup.value = false;
//     // The popup will reappear on next app launch or when checkForPendingFeedback is called
//   }
// }


import 'package:fixibot_app/screens/mechanics/controller/mechanicController.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedbackController extends GetxController {
  var showFeedbackPopup = false.obs;
  var lastServiceForFeedback = <String, dynamic>{}.obs;
  var hasPendingFeedback = false.obs;

  // Call this immediately when a new service is created
  void checkForNewServiceFeedback(Map<String, dynamic> newService) async {
    try {
      print('🔄 [FEEDBACK] Checking new service for feedback...');
      
      final prefs = await SharedPreferences.getInstance();
      final serviceId = newService['_id'] ?? newService['id'];
      
      if (serviceId == null) {
        print('❌ [FEEDBACK] Service ID is null');
        return;
      }

      print('🎯 [FEEDBACK] New service created: $serviceId');
      
      // Check if feedback was already given for this service
      final feedbackGiven = prefs.getBool('feedback_given_$serviceId') ?? false;
      print('📝 [FEEDBACK] Feedback already given: $feedbackGiven');

      if (!feedbackGiven) {
        // Show popup immediately for new service
        lastServiceForFeedback.value = newService;
        hasPendingFeedback.value = true;
        showFeedbackPopup.value = true;
        
        print('🚀 [FEEDBACK] POPUP TRIGGERED IMMEDIATELY for new service!');
      } else {
        print('⏭️ [FEEDBACK] Feedback already given for this service');
      }
    } catch (e) {
      print('❌ [FEEDBACK] Error in checkForNewServiceFeedback: $e');
    }
  }

  // Also keep the existing method for checking on app start
  Future<void> checkForPendingFeedback() async {
    try {
      print('🔄 [FEEDBACK] Checking for pending feedback on app start...');
      
      final prefs = await SharedPreferences.getInstance();
      final mechanicController = Get.find<MechanicController>();
      
      // Get the most recent service (any status)
      if (mechanicController.mechanicServices.isEmpty) {
        print('❌ [FEEDBACK] No services found');
        return;
      }

      // Sort by creation date (newest first)
      final sortedServices = List.from(mechanicController.mechanicServices);
      sortedServices.sort((a, b) {
        final dateA = a['created_at'];
        final dateB = b['created_at'];
        return _compareDates(dateB, dateA);
      });

      final latestService = sortedServices.first;
      final serviceId = latestService['_id'] ?? latestService['id'];
      
      print('🎯 [FEEDBACK] Latest service: $serviceId');

      // Check if feedback was already given
      final feedbackGiven = prefs.getBool('feedback_given_$serviceId') ?? false;

      if (!feedbackGiven) {
        lastServiceForFeedback.value = latestService;
        hasPendingFeedback.value = true;
        showFeedbackPopup.value = true;
        print('🚀 [FEEDBACK] POPUP TRIGGERED for latest service!');
      }
    } catch (e) {
      print('❌ [FEEDBACK] Error in checkForPendingFeedback: $e');
    }
  }

  // Submit feedback
  Future<bool> submitFeedback({
    required String serviceId,
    required String mechanicId,
    required String mechanicName,
    required int rating,
    required String comment,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Simulate API call
      print('📤 [FEEDBACK] Submitting feedback for service: $serviceId');
      await Future.delayed(Duration(seconds: 1));

      // Mark feedback as given for this service
      await prefs.setBool('feedback_given_$serviceId', true);
      
      showFeedbackPopup.value = false;
      hasPendingFeedback.value = false;
      
      print('✅ [FEEDBACK] Feedback submitted successfully!');
      return true;
    } catch (e) {
      print('❌ [FEEDBACK] Error submitting feedback: $e');
      return false;
    }
  }

  // User opts out of feedback
  Future<void> optOutFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('feedback_opt_out', true);
    showFeedbackPopup.value = false;
    hasPendingFeedback.value = false;
    print('🚫 [FEEDBACK] User opted out of feedback');
  }

  // Close popup without submitting (remind later)
  void remindLater() {
    showFeedbackPopup.value = false;
    print('⏰ [FEEDBACK] Feedback reminder postponed');
  }

  int _compareDates(String? dateA, String? dateB) {
    try {
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return -1;
      if (dateB == null) return 1;
      
      final datetimeA = DateTime.parse(dateA);
      final datetimeB = DateTime.parse(dateB);
      return datetimeA.compareTo(datetimeB);
    } catch (e) {
      return 0;
    }
  }

  // Manual trigger for testing
  void triggerFeedbackManually() {
    print('🎮 [FEEDBACK] Manual trigger called');
    
    // Create a test service
    final testService = {
      '_id': 'test_service_${DateTime.now().millisecondsSinceEpoch}',
      'mechanic_name': 'Test Mechanic',
      'service_type': 'repair',
      'mechanic_id': 'test_mechanic_123',
      'created_at': DateTime.now().toIso8601String(),
    };
    
    checkForNewServiceFeedback(testService);
  }

// Force show popup for testing
void forceShowPopup() {
  print('🎮 [TEST] Force showing feedback popup');
  
  // Create a test service
  final testService = {
    '_id': 'test_service_${DateTime.now().millisecondsSinceEpoch}',
    'mechanic_name': 'Test Mechanic',
    'service_type': 'repair',
    'mechanic_id': 'test_123',
    'status': 'completed',
    'created_at': DateTime.now().toIso8601String(),
    'completed_at': DateTime.now().toIso8601String(),
  };
  
  lastServiceForFeedback.value = testService;
  showFeedbackPopup.value = true;
  hasPendingFeedback.value = true;
  
  print('🚀 [TEST] Popup should be visible now!');
}

// Add this to FeedbackController for immediate debugging
void debugFeedbackStatus() async {
  print('🟡 [DEBUG] ===== FEEDBACK SYSTEM STATUS =====');
  
  final prefs = await SharedPreferences.getInstance();
  final mechanicController = Get.find<MechanicController>();
  
  // Check basic status
  print('🔍 showFeedbackPopup: ${showFeedbackPopup.value}');
  print('🔍 hasPendingFeedback: ${hasPendingFeedback.value}');
  print('🔍 lastServiceForFeedback: ${lastServiceForFeedback.value}');
  
  // Check services
  print('📋 Total services: ${mechanicController.mechanicServices.length}');
  
  // List all services with details
  for (int i = 0; i < mechanicController.mechanicServices.length; i++) {
    final service = mechanicController.mechanicServices[i];
    final status = service['status'] ?? 'no-status';
    final mechanicName = service['mechanic_name'] ?? 'no-name';
    final serviceId = service['_id'] ?? service['id'] ?? 'no-id';
    
    print('   Service $i: $serviceId');
    print('     - Status: $status');
    print('     - Mechanic: $mechanicName');
    print('     - Created: ${service['created_at']}');
    
    // Check if feedback already given
    final feedbackGiven = prefs.getBool('feedback_given_$serviceId') ?? false;
    print('     - Feedback given: $feedbackGiven');
  }
  
  // Check for completed services
  final completedServices = mechanicController.mechanicServices.where((service) {
    return service['status'] == 'completed';
  }).toList();
  
  print('✅ Completed services found: ${completedServices.length}');
  
  if (completedServices.isNotEmpty) {
    final latest = completedServices.first;
    print('🎯 Latest completed service: ${latest['_id']}');
    
    // Check time difference
    final completedAt = latest['completed_at'] ?? latest['updated_at'] ?? latest['created_at'];
    if (completedAt != null) {
      try {
        final completionTime = DateTime.parse(completedAt);
        final now = DateTime.now();
        final difference = now.difference(completionTime);
        print('⏰ Time since completion: ${difference.inMinutes} minutes');
        print('⏰ Should show popup: ${difference.inMinutes >= 1}');
      } catch (e) {
        print('❌ Error parsing date: $e');
      }
    }
  }
  
  print('🟡 [DEBUG] ===== END DEBUG =====');
}


// Add this to FeedbackController
void checkForPendingServicesFeedback() async {
  try {
    print('🔄 [FEEDBACK] Checking for ANY services (including pending)...');
    
    final prefs = await SharedPreferences.getInstance();
    final mechanicController = Get.find<MechanicController>();
    
    if (mechanicController.mechanicServices.isEmpty) {
      print('❌ [FEEDBACK] No services found');
      return;
    }

    // Get ALL services (including pending)
    final allServices = List.from(mechanicController.mechanicServices);
    
    // Sort by creation date (newest first)
    allServices.sort((a, b) {
      final dateA = a['created_at'];
      final dateB = b['created_at'];
      return _compareDates(dateB, dateA);
    });

    // Get the most recent service
    final latestService = allServices.first;
    final serviceId = latestService['_id'] ?? latestService['id'];
    final mechanicName = latestService['mechanic_name'] ?? 'Unknown Mechanic';
    
    print('🎯 [FEEDBACK] Latest service: $serviceId - $mechanicName');

    // Check if feedback was already given for this service
    final feedbackGiven = prefs.getBool('feedback_given_$serviceId') ?? false;
    print('📝 [FEEDBACK] Feedback already given: $feedbackGiven');

    if (!feedbackGiven) {
      lastServiceForFeedback.value = latestService;
      hasPendingFeedback.value = true;
      showFeedbackPopup.value = true;
      
      print('🚀 [FEEDBACK] POPUP TRIGGERED for service: $serviceId');
    } else {
      print('⏭️ [FEEDBACK] Feedback already given for this service');
    }
  } catch (e) {
    print('❌ [FEEDBACK] Error in checkForPendingServicesFeedback: $e');
  }
}
}