import 'dart:async';
import 'dart:convert';

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

  String baseUrl = 'https://chalky-anjelica-bovinely.ngrok-free.dev';
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
  }

  @override
  void onClose() {
    _feedbackTimer?.cancel();
    super.onClose();
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

// Update the submitFeedback method to always generate IDs for local services
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

    // Build feedback object
    final feedbackData = {
      'service_id': serviceId,
      'mechanic_id': mechanicId,
      'user_id': userId,
      'mechanic_name': mechanicName,
      'rating': rating,
      'comment': comment,
      'created_at': DateTime.now().toIso8601String(),
    };

    print('📤 [FEEDBACK] Submitting feedback for service: $serviceId');
    
    // Check if this is a local service
    final isLocalService = serviceId.startsWith('local_');
    
    String? feedbackId;
    FeedbackModel submittedFeedback;

    if (!isLocalService) {
      // For non-local services, try to submit to backend
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/feedback'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(feedbackData),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          print('✅ [FEEDBACK] Backend response: $data');
          
          // Extract feedback ID from response
          feedbackId = data['_id'] ?? data['id'] ?? data['feedback_id'];
        }
      } catch (e) {
        print('❌ [FEEDBACK] Backend submission failed: $e');
        // Continue with local storage
      }
    }

    // If no backend ID (either local service or backend failed), generate local ID
    if (feedbackId == null) {
      feedbackId = _generateLocalFeedbackId(serviceId);
      print('🔧 [FEEDBACK] Using local feedback ID: $feedbackId');
    }

    // Create the feedback model with the ID
    submittedFeedback = FeedbackModel(
      id: feedbackId,
      serviceId: serviceId,
      mechanicId: mechanicId,
      mechanicName: mechanicName,
      serviceType: lastServiceForFeedback['service_type'] ?? 'General Service',
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
      status: isLocalService ? 'submitted_local' : 'submitted',
    );

    // Store the feedback ID for future reference
    await prefs.setString('feedback_$serviceId', feedbackId);
    print('💾 [FEEDBACK] Feedback ID stored for service $serviceId: $feedbackId');

    // Add to history
    feedbackHistory.add(submittedFeedback);
    await _saveFeedbackHistoryToLocal();

    // Remove from pending
    removePendingFeedback(serviceId);

    // Mark this service as feedback given
    await prefs.setBool('feedback_given_$serviceId', true);

    // Close popup
    showFeedbackPopup.value = false;
    hasPendingFeedback.value = false;
    lastServiceForFeedback.value = {};

    print('✅ [FEEDBACK] Feedback submitted successfully');
    return true;
    
  } catch (e) {
    print('❌ [FEEDBACK] Error in submitFeedback: $e');
    
    // Emergency fallback
    return await _emergencySaveFeedback(
      serviceId: serviceId,
      mechanicId: mechanicId,
      mechanicName: mechanicName,
      rating: rating,
      comment: comment,
    );
  }
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

  // Call this method right after a mechanic service is completed
  void scheduleFeedback(Map<String, dynamic> service) {
    lastServiceForFeedback.value = service;

    // Add to pending feedback
    addPendingFeedback(
      serviceId: service['_id'] ?? service['id'],
      mechanicId: service['mechanic_id'] ?? '',
      mechanicName: service['mechanic_name'] ?? 'Unknown Mechanic',
      serviceType: service['service_type'] ?? 'General Service',
    );

    // Cancel existing timer if any
    _feedbackTimer?.cancel();

    // Schedule feedback popup 30 seconds later
    _feedbackTimer = Timer(const Duration(seconds: 30), () {
      _showGlobalPopup();
    });

    print("🕐 Feedback popup scheduled in 30 seconds for service: ${service['_id']}");
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