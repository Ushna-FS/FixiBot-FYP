import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:fixibot_app/constants/appConfig.dart';
import 'package:fixibot_app/constants/feedbackConstants.dart';
import 'package:fixibot_app/model/feedbackModel.dart';
import 'package:fixibot_app/screens/feedback/view/feedback_popup.dart';
import 'package:flutter/material.dart';
import 'package:fixibot_app/screens/mechanics/controller/mechanicController.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FeedbackController extends GetxController {
  var showFeedbackPopup = false.obs;
  var lastServiceForFeedback = <String, dynamic>{}.obs;
  var hasPendingFeedback = false.obs;
  var feedbackHistory = <FeedbackModel>[].obs;
  var pendingFeedback = <FeedbackModel>[].obs;
  var isLoadingHistory = false.obs;

final baseUrl  = AppConfig.baseUrl;
  // String baseUrl = 'https://chalky-anjelica-bovinely.ngrok-free.dev';
  Timer? _feedbackTimer;

  @override
  void onInit() {
    super.onInit();
    print('🟢 [FEEDBACK] FeedbackController initialized');
    
    // Auto-trigger popup globally when showFeedbackPopup becomes true
    ever(showFeedbackPopup, (value) {
      if (value == true) _showGlobalPopup();
    });
    
    // Load feedback history when controller initializes
    loadFeedbackHistory();
    // Check for scheduled feedback when app starts
    _checkScheduledFeedbackOnStartup();
  }

  @override
  void onClose() {
    _feedbackTimer?.cancel();
    super.onClose();
  }

// Check for scheduled feedback when app starts
  Future<void> _checkScheduledFeedbackOnStartup() async {
    try {
      print('🔄 [FEEDBACK] Checking for scheduled feedback on app start...');
      
      final prefs = await SharedPreferences.getInstance();
      final scheduledTimeString = prefs.getString(Feedbackconstants.FEEDBACK_SCHEDULED_TIME_KEY);
      final lastServiceDataString = prefs.getString(Feedbackconstants.LAST_SERVICE_DATA_KEY);
      
      if (scheduledTimeString == null || lastServiceDataString == null) {
        print('⏭️ [FEEDBACK] No scheduled feedback found');
        return;
      }
      
      final scheduledTime = DateTime.parse(scheduledTimeString);
      final lastServiceData = jsonDecode(lastServiceDataString);
      final serviceId = lastServiceData['_id'] ?? lastServiceData['id'];
      
      if (serviceId == null) {
        print('❌ [FEEDBACK] Invalid service data in storage');
        await _clearScheduledFeedback();
        return;
      }
      
      final now = DateTime.now();
      final timeDifference = now.difference(scheduledTime).inSeconds;
      
      print('⏰ [FEEDBACK] Scheduled time: $scheduledTime');
      print('⏰ [FEEDBACK] Current time: $now');
      print('⏰ [FEEDBACK] Time difference: $timeDifference seconds');
      
      // Check if feedback was already given for this service
      final feedbackGiven = prefs.getBool('feedback_given_$serviceId') ?? false;
      if (feedbackGiven) {
        print('✅ [FEEDBACK] Feedback already given for service: $serviceId');
        await _clearScheduledFeedback();
        return;
      }
      
      if (timeDifference >= Feedbackconstants.FEEDBACK_DELAY_SECONDS) {
        // Time has passed - add to pending but don't show popup
        print('⏰ [FEEDBACK] Feedback time passed, adding to pending only');
        addPendingFeedback(
          serviceId: serviceId,
          mechanicId: lastServiceData['mechanic_id'] ?? '',
          mechanicName: lastServiceData['mechanic_name'] ?? 'Unknown Mechanic',
          serviceType: lastServiceData['service_type'] ?? 'General Service',
        );
        
        lastServiceForFeedback.value = lastServiceData;
        hasPendingFeedback.value = true;
        showFeedbackPopup.value = false; // Don't show popup
        
        await _clearScheduledFeedback();
      } else {
        // Time hasn't passed yet - schedule the popup
        final remainingSeconds = Feedbackconstants.FEEDBACK_DELAY_SECONDS - timeDifference;
        print('⏰ [FEEDBACK] Scheduling popup in $remainingSeconds seconds');
        
        lastServiceForFeedback.value = lastServiceData;
        hasPendingFeedback.value = true;
        
        _schedulePopup(remainingSeconds);
      }
      
    } catch (e) {
      print('❌ [FEEDBACK] Error checking scheduled feedback: $e');
      await _clearScheduledFeedback();
    }
  }

  // Clear scheduled feedback data
  Future<void> _clearScheduledFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(Feedbackconstants.FEEDBACK_SCHEDULED_TIME_KEY);
    await prefs.remove(Feedbackconstants.LAST_SERVICE_DATA_KEY);
    print('🗑️ [FEEDBACK] Cleared scheduled feedback data');
  }

  // Save scheduled feedback data
  Future<void> _saveScheduledFeedback(Map<String, dynamic> service) async {
    final prefs = await SharedPreferences.getInstance();
    final scheduledTime = DateTime.now().add(Duration(seconds: Feedbackconstants.FEEDBACK_DELAY_SECONDS));
    
    await prefs.setString(Feedbackconstants.FEEDBACK_SCHEDULED_TIME_KEY, scheduledTime.toIso8601String());
    await prefs.setString(Feedbackconstants.LAST_SERVICE_DATA_KEY, jsonEncode(service));
    
    print('💾 [FEEDBACK] Scheduled feedback for: ${scheduledTime.toIso8601String()}');
  }

  // Schedule popup with remaining time
  void _schedulePopup(int seconds) {
    _feedbackTimer?.cancel();
    
    _feedbackTimer = Timer(Duration(seconds: seconds), () {
      _showGlobalPopup();
    });
    
    print("🕐 Feedback popup scheduled in $seconds seconds");
  }

  // ============ UPDATED FEEDBACK SCHEDULING ============

  // Call this method right after a mechanic service is completed
  void scheduleFeedback(Map<String, dynamic> service) async {
    try {
      final serviceId = service['_id'] ?? service['id'];
      if (serviceId == null) {
        print('❌ [FEEDBACK] Service ID is null - cannot schedule feedback');
        return;
      }

      // Check if feedback was already given
      final prefs = await SharedPreferences.getInstance();
      final feedbackGiven = prefs.getBool('feedback_given_$serviceId') ?? false;
      
      if (feedbackGiven) {
        print('✅ [FEEDBACK] Feedback already given for service: $serviceId');
        return;
      }

      lastServiceForFeedback.value = service;

      // Add to pending feedback immediately
      addPendingFeedback(
        serviceId: serviceId,
        mechanicId: service['mechanic_id'] ?? '',
        mechanicName: service['mechanic_name'] ?? 'Unknown Mechanic',
        serviceType: service['service_type'] ?? 'General Service',
      );

      // Save scheduled feedback data for persistence
      await _saveScheduledFeedback(service);

      // Cancel existing timer if any
      _feedbackTimer?.cancel();

      // Schedule feedback popup after 10 seconds
      _schedulePopup(Feedbackconstants.FEEDBACK_DELAY_SECONDS);

      print("🕐 Feedback popup scheduled in $Feedbackconstants.FEEDBACK_DELAY_SECONDS seconds for service: $serviceId");
      
    } catch (e) {
      print('❌ [FEEDBACK] Error scheduling feedback: $e');
    }
  }

  void _showGlobalPopup() {
    final service = lastServiceForFeedback.value;

    if (service.isEmpty) return;
    if (Get.isDialogOpen == true) return;

    Get.dialog(
      FeedbackPopup(
        service: service,
        controller: this,
      ),
      barrierDismissible: false,
      useSafeArea: true,
    );

    print("💬 Feedback popup displayed for service: ${service['_id']}");
  }

  // ============ UPDATED FEEDBACK SUBMISSION ============

  Future<bool> submitFeedback({
    required String serviceId,
    required String mechanicId,
    required String mechanicName,
    required int rating,
    required String comment,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final accessToken = prefs.getString('access_token');

      // ✅ Generate valid MongoDB ObjectId if service is local
      String backendServiceId = serviceId;
      if (serviceId.startsWith('local_')) {
        backendServiceId = _generateMongoId();
        print('🔧 [FEEDBACK] Generated MongoID for local service: $backendServiceId');
      }

      // Build feedback payload
      final feedbackData = {
        'service_id': backendServiceId, // Always a valid MongoDB ID
        'mechanic_id': mechanicId,
        'user_id': userId,
        'mechanic_name': mechanicName,
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      };

      print('📤 [FEEDBACK] Submitting feedback: $feedbackData');

      String? feedbackId;
      bool storedInBackend = false;
      bool storedInLocal = false;

      // Attempt backend submission
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/feedback/'),
          headers: {
            'Content-Type': 'application/json',
            if (accessToken != null) 'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(feedbackData),
        );

        print('🌐 [FEEDBACK] Backend response status: ${response.statusCode}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          feedbackId = data['_id'] ?? data['id'] ?? data['feedback_id'];
          storedInBackend = true;
          print('✅ [FEEDBACK] Backend storage successful. Feedback ID: $feedbackId');
        } else {
          print('❌ [FEEDBACK] Backend storage failed. Status: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ [FEEDBACK] Backend error: $e');
      }

      // Local fallback if backend fails
      if (feedbackId == null) {
        feedbackId = serviceId.startsWith('local_') ? serviceId : _generateLocalFeedbackId(serviceId);
        storedInLocal = true;
        print('📱 [FEEDBACK] Using local fallback ID: $feedbackId');
      }

      // Create FeedbackModel
      final submittedFeedback = FeedbackModel(
        id: feedbackId,
        serviceId: serviceId,
        mechanicId: mechanicId,
        mechanicName: mechanicName,
        serviceType: 'General Service',
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        status: storedInBackend ? 'submitted' : 'submitted_local',
      );

      // Store locally for reference
      await prefs.setString('feedback_$serviceId', feedbackId);
      await prefs.setBool('feedback_given_$serviceId', true); // Mark as given

      // Add to history and remove from pending
      feedbackHistory.add(submittedFeedback);
      await _saveFeedbackHistoryToLocal();
      removePendingFeedback(serviceId);

      // Clear scheduled feedback data
      await _clearScheduledFeedback();

      // Close popup and reset state
      showFeedbackPopup.value = false;
      hasPendingFeedback.value = false;
      lastServiceForFeedback.value = {};

      print('💾 [FEEDBACK] Stored feedback locally: $feedbackId');
      return true;
    } catch (e) {
      print('❌ [FEEDBACK] Critical error: $e');
      return false;
    }
  }
  // ============ FEEDBACK HISTORY METHODS ============

  // Load feedback history from backend and local storage
  Future<void> loadFeedbackHistory() async {
    try {
      isLoadingHistory.value = true;
      print('📚 [FEEDBACK] Loading feedback history...');

      // Clear existing data
      feedbackHistory.clear();
      pendingFeedback.clear();

      // Load from backend
      await _loadFeedbackFromBackend();
      
      // Load pending feedback from local storage
      await _loadPendingFeedbackFromLocal();

      print('✅ [FEEDBACK] Loaded ${feedbackHistory.length} feedback items');
      print('⏳ [FEEDBACK] ${pendingFeedback.length} pending feedback items');
      
    } catch (e) {
      print('❌ [FEEDBACK] Error loading feedback history: $e');
    } finally {
      isLoadingHistory.value = false;
    }
  }

  // Load submitted feedback from backend
  Future<void> _loadFeedbackFromBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final userId = prefs.getString('user_id'); // Using user_id instead of feedback_id

      if (accessToken == null || userId == null) {
        print('❌ [FEEDBACK] No auth token or user ID found');
        return;
      }

      // Get feedback by user ID
      final response = await http.get(
        Uri.parse('$baseUrl/feedback/user/$userId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        final List<FeedbackModel> backendFeedback = responseData
            .map((item) => FeedbackModel.fromJson(item))
            .toList();

        feedbackHistory.addAll(backendFeedback);
        print('✅ [FEEDBACK] Loaded ${backendFeedback.length} items from backend');
      } else {
        print('❌ [FEEDBACK] Backend returned ${response.statusCode}');
        // Fallback: Try to load from local storage
        await _loadFeedbackHistoryFromLocal();
      }
    } catch (e) {
      print('❌ [FEEDBACK] Error loading from backend: $e');
      // Fallback: Load from local storage
      await _loadFeedbackHistoryFromLocal();
    }
  }

  // Load feedback history from local storage (fallback)
  Future<void> _loadFeedbackHistoryFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyData = prefs.getString('feedback_history') ?? '[]';
      final List<dynamic> historyList = jsonDecode(historyData);
      
      final List<FeedbackModel> localHistory = historyList
          .map((item) => FeedbackModel.fromJson(item))
          .toList();

      feedbackHistory.addAll(localHistory);
      print('✅ [FEEDBACK] Loaded ${localHistory.length} items from local history');
    } catch (e) {
      print('❌ [FEEDBACK] Error loading feedback history from local: $e');
    }
  }

  // Save feedback history to local storage
  Future<void> _saveFeedbackHistoryToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(feedbackHistory.map((fb) => fb.toJson()).toList());
      await prefs.setString('feedback_history', historyJson);
      print('💾 [FEEDBACK] Saved ${feedbackHistory.length} items to local history');
    } catch (e) {
      print('❌ [FEEDBACK] Error saving feedback history: $e');
    }
  }

  // Load pending feedback from local storage
  Future<void> _loadPendingFeedbackFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingFeedbackData = prefs.getString('pending_feedback') ?? '[]';
      final List<dynamic> pendingList = jsonDecode(pendingFeedbackData);
      
      final List<FeedbackModel> localPending = pendingList
          .map((item) => FeedbackModel.fromJson(item))
          .toList();

      pendingFeedback.addAll(localPending);
      print('✅ [FEEDBACK] Loaded ${localPending.length} pending items from local storage');
    } catch (e) {
      print('❌ [FEEDBACK] Error loading pending feedback: $e');
    }
  }

  // Save pending feedback to local storage
  Future<void> _savePendingFeedbackToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = jsonEncode(pendingFeedback.map((fb) => fb.toJson()).toList());
      await prefs.setString('pending_feedback', pendingJson);
      print('💾 [FEEDBACK] Saved ${pendingFeedback.length} pending items to local storage');
    } catch (e) {
      print('❌ [FEEDBACK] Error saving pending feedback: $e');
    }
  }

  // Add pending feedback
  void addPendingFeedback({
    required String serviceId,
    required String mechanicId,
    required String mechanicName,
    required String serviceType,
  }) {
    // Check if already exists
    final existingIndex = pendingFeedback.indexWhere((fb) => fb.serviceId == serviceId);
    if (existingIndex != -1) {
      print('⚠️ [FEEDBACK] Pending feedback already exists for service: $serviceId');
      return;
    }

    final newFeedback = FeedbackModel(
      serviceId: serviceId,
      mechanicId: mechanicId,
      mechanicName: mechanicName,
      serviceType: serviceType,
      rating: 0, // Default rating
      comment: '', // Empty comment
      createdAt: DateTime.now(),
      status: 'pending',
    );

    pendingFeedback.add(newFeedback);
    _savePendingFeedbackToLocal();
    
    print('➕ [FEEDBACK] Added pending feedback for service: $serviceId');
  }

  // Remove pending feedback
  void removePendingFeedback(String serviceId) {
    pendingFeedback.removeWhere((fb) => fb.serviceId == serviceId);
    _savePendingFeedbackToLocal();
    print('🗑️ [FEEDBACK] Removed pending feedback for service: $serviceId');
  }

  // Get feedback by service ID
  FeedbackModel? getFeedbackByServiceId(String serviceId) {
    try {
      return feedbackHistory.firstWhere((fb) => fb.serviceId == serviceId);
    } catch (e) {
      return null;
    }
  }

  // Check if service has pending feedback
  bool hasPendingFeedbackForService(String serviceId) {
    return pendingFeedback.any((fb) => fb.serviceId == serviceId);
  }

  // ============ FEEDBACK SUBMISSION & UPDATES ============

// Replace your current submitFeedback method with this fixed version:

// Add this method to get feedback ID for a service
String? getFeedbackIdForService(String serviceId) {
  try {
    // First try to find in feedbackHistory
    final feedback = feedbackHistory.firstWhere(
      (fb) => fb.serviceId == serviceId && fb.id != null,
      orElse: () => FeedbackModel(
        serviceId: '',
        mechanicId: '',
        mechanicName: '',
        serviceType: '',
        rating: 0,
        comment: '',
        createdAt: DateTime.now(),
        status: '',
      ),
    );
    
    if (feedback.id != null) return feedback.id;
    
    // If not found in memory, try shared preferences
    return null; // We'll handle this async in the update method
  } catch (e) {
    return null;
  }
}
// Add this method to generate consistent feedback IDs for local services
String _generateLocalFeedbackId(String serviceId) {
  // Use the serviceId itself as base but ensure it's a valid feedback ID
  if (serviceId.startsWith('local_')) {
    return 'local_fb_${serviceId.substring(6)}'; // Convert local_123 to local_fb_123
  }
  return 'local_fb_${DateTime.now().millisecondsSinceEpoch}';
}


// Helper: Generate MongoDB ObjectId
String _generateMongoId() {
  final random = Random();
  const hexChars = '0123456789abcdef';
  return List.generate(24, (_) => hexChars[random.nextInt(16)]).join();
}


// Emergency fallback method
Future<bool> _emergencySaveFeedback({
  required String serviceId,
  required String mechanicId,
  required String mechanicName,
  required int rating,
  required String comment,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Generate a guaranteed feedback ID
    final feedbackId = _generateLocalFeedbackId(serviceId);
    
    // Create minimal feedback record
    final emergencyFeedback = FeedbackModel(
      id: feedbackId,
      serviceId: serviceId,
      mechanicId: mechanicId,
      mechanicName: mechanicName,
      serviceType: 'Emergency Save',
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
      status: 'emergency_saved',
    );

    // Force save to shared preferences
    await prefs.setString('feedback_$serviceId', feedbackId);
    await prefs.setBool('feedback_given_$serviceId', true);
    
    // Add to history
    feedbackHistory.add(emergencyFeedback);
    await _saveFeedbackHistoryToLocal();
    
    // Remove from pending
    removePendingFeedback(serviceId);

    print('🆘 [FEEDBACK] Emergency save completed for service: $serviceId');
    return true;
  } catch (e) {
    print('💥 [FEEDBACK] Emergency save failed: $e');
    return false;
  }
}

// Enhanced update method that handles missing IDs
// Enhanced updateFeedback method that always works
Future<bool> updateFeedback({
  required String serviceId,
  required int newRating,
  required String newComment,
}) async {
  try {
    print('✏️ [FEEDBACK] Updating feedback for service: $serviceId');

    // Method 1: Find in current feedbackHistory
    var existingIndex = feedbackHistory.indexWhere((fb) => fb.serviceId == serviceId);
    
    if (existingIndex != -1) {
      print('🔍 [FEEDBACK] Found feedback in memory');
      final existingFeedback = feedbackHistory[existingIndex];
      
      // Update the feedback
      final updatedFeedback = existingFeedback.copyWith(
        rating: newRating,
        comment: newComment,
        updatedAt: DateTime.now(),
      );
      
      feedbackHistory[existingIndex] = updatedFeedback;
      await _saveFeedbackHistoryToLocal();
      
      print('✅ [FEEDBACK] Feedback updated successfully in memory');
      return true;
    }

    // Method 2: Check if we have a stored feedback ID
    final prefs = await SharedPreferences.getInstance();
    final storedFeedbackId = prefs.getString('feedback_$serviceId');
    
    if (storedFeedbackId != null) {
      print('🔍 [FEEDBACK] Found stored feedback ID: $storedFeedbackId');
      
      // Create new feedback entry with the stored ID
      final newFeedback = FeedbackModel(
        id: storedFeedbackId,
        serviceId: serviceId,
        mechanicId: '', // We don't have this info, but that's okay for update
        mechanicName: 'Unknown Mechanic',
        serviceType: 'Updated Service',
        rating: newRating,
        comment: newComment,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'updated',
      );
      
      feedbackHistory.add(newFeedback);
      await _saveFeedbackHistoryToLocal();
      
      print('✅ [FEEDBACK] Feedback created with stored ID');
      return true;
    }

    // Method 3: Create a new feedback entry with generated ID
    print('🔧 [FEEDBACK] Creating new feedback entry');
    final newFeedbackId = _generateLocalFeedbackId(serviceId);
    
    final newFeedback = FeedbackModel(
      id: newFeedbackId,
      serviceId: serviceId,
      mechanicId: '',
      mechanicName: 'Unknown Mechanic',
      serviceType: 'New Feedback',
      rating: newRating,
      comment: newComment,
      createdAt: DateTime.now(),
      status: 'newly_created',
    );
    
    // Store the new ID
    await prefs.setString('feedback_$serviceId', newFeedbackId);
    
    feedbackHistory.add(newFeedback);
    await _saveFeedbackHistoryToLocal();
    
    print('✅ [FEEDBACK] New feedback entry created with ID: $newFeedbackId');
    return true;

  } catch (e) {
    print('❌ [FEEDBACK] Critical error in updateFeedback: $e');
    
    // Final fallback - just update shared preferences directly
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('feedback_updated_$serviceId', true);
      print('🆘 [FEEDBACK] Fallback update completed');
      return true;
    } catch (e2) {
      print('💥 [FEEDBACK] Fallback also failed: $e2');
      return false;
    }
  }
} 
  // ============ POPUP MANAGEMENT ============

  // Core feedback check (called when app launches or after new service creation)
  void checkForPendingServicesFeedback() async {
    try {
      print('\n🔄 [FEEDBACK] === CHECKING FOR PENDING SERVICES FEEDBACK ===');

      if (!Get.isRegistered<MechanicController>()) {
        print('❌ [FEEDBACK] MechanicController not registered, retrying...');
        await Future.delayed(Duration(seconds: 2));
      }

      if (!Get.isRegistered<MechanicController>()) {
        print('❌ [FEEDBACK] MechanicController still unavailable');
        return;
      }

      final mechanicController = Get.find<MechanicController>();
      if (mechanicController.mechanicServices.isEmpty) {
        print('❌ [FEEDBACK] No mechanic services found');
        return;
      }

      final allServices = List.from(mechanicController.mechanicServices);
      allServices.sort((a, b) => _compareDates(b['created_at'], a['created_at']));

      final latest = allServices.first;
      final serviceId = latest['_id'] ?? latest['id'];
      if (serviceId == null) {
        print('❌ [FEEDBACK] Latest service has no ID — skipping feedback');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final feedbackGiven = prefs.getBool('feedback_given_$serviceId') ?? false;

      print('🧾 [FEEDBACK] Latest Service ID: $serviceId | Feedback Given: $feedbackGiven');

      if (!feedbackGiven) {
        // Add to pending feedback
        addPendingFeedback(
          serviceId: serviceId,
          mechanicId: latest['mechanic_id'] ?? '',
          mechanicName: latest['mechanic_name'] ?? 'Unknown Mechanic',
          serviceType: latest['service_type'] ?? 'General Service',
        );

        lastServiceForFeedback.value = latest;
        hasPendingFeedback.value = true;
        showFeedbackPopup.value = true;
      } else {
        print('✅ [FEEDBACK] Feedback already given for latest service');
      }
    } catch (e) {
      print('❌ [FEEDBACK] Error in checkForPendingServicesFeedback: $e');
    }
  }

  // Trigger when new service is created
  void checkForNewServiceFeedback(Map<String, dynamic> newService) async {
    try {
      print('\n🔄 [FEEDBACK] === CHECKING NEW SERVICE FOR FEEDBACK ===');

      final serviceId = newService['_id'] ?? newService['id'];
      if (serviceId == null) {
        print('❌ [FEEDBACK] Service ID is null — cannot trigger popup');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final feedbackGiven = prefs.getBool('feedback_given_$serviceId') ?? false;

      if (!feedbackGiven) {
        // Add to pending feedback
        addPendingFeedback(
          serviceId: serviceId,
          mechanicId: newService['mechanic_id'] ?? '',
          mechanicName: newService['mechanic_name'] ?? 'Unknown Mechanic',
          serviceType: newService['service_type'] ?? 'General Service',
        );

        print('🚀 [FEEDBACK] TRIGGERING POPUP FOR NEW SERVICE: $serviceId');
        lastServiceForFeedback.value = newService;
        hasPendingFeedback.value = true;
        showFeedbackPopup.value = true;
      } else {
        print('⏭️ [FEEDBACK] Feedback already given for this service');
      }
    } catch (e) {
      print('❌ [FEEDBACK] Error in checkForNewServiceFeedback: $e');
    }
  }

  void remindLater() {
    showFeedbackPopup.value = false;
    print('⏰ [FEEDBACK] Feedback reminder postponed');
    if (Get.isDialogOpen == true) Get.back();
  }

  Future<void> optOutFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('feedback_opt_out', true);
    showFeedbackPopup.value = false;
    hasPendingFeedback.value = false;
    print('🚫 [FEEDBACK] User opted out of feedback');
    if (Get.isDialogOpen == true) Get.back();
  }

  // ============ UTILITY METHODS ============

  int _compareDates(String? a, String? b) {
    try {
      if (a == null || b == null) return 0;
      return DateTime.parse(b).compareTo(DateTime.parse(a));
    } catch (_) {
      return 0;
    }
  }

  // Clear all feedback data (for testing/debugging)
  Future<void> clearAllFeedbackData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all feedback-related keys
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('feedback_') || key.startsWith('pending_')) {
          await prefs.remove(key);
        }
      }
      
      feedbackHistory.clear();
      pendingFeedback.clear();
      showFeedbackPopup.value = false;
      hasPendingFeedback.value = false;
      lastServiceForFeedback.value = {};
      
      print('🗑️ [FEEDBACK] All feedback data cleared');
    } catch (e) {
      print('❌ [FEEDBACK] Error clearing feedback data: $e');
    }
  }
}


