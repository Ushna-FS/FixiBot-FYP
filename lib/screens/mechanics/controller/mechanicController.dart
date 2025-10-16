
import 'dart:math';

import 'package:fixibot_app/model/mechanicModel.dart';
import 'package:fixibot_app/screens/feedback/controller/feedbackController.dart';
import 'package:fixibot_app/screens/location/location_controller.dart';
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MechanicController extends GetxController {
  var mechanicCategories = <Mechanic>[].obs;
  var filteredMechanics = <Mechanic>[].obs;
  var selectedVehicleType = ''.obs;
  var selectedVehicleId = ''.obs;
  var selectedCategory = ''.obs;
  var userLatitude = 0.0.obs;
var userLongitude = 0.0.obs;
var maxDistance = 50.0.obs;
  final VehicleController vehicleController = Get.find<VehicleController>();
  final LocationController locationController = Get.put(LocationController());

  var isNotified = false.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // Mechanic Services Properties
  RxList<dynamic> mechanicServices = <dynamic>[].obs;
  RxBool isServicesLoading = false.obs;
  RxString servicesErrorMessage = ''.obs;
  
  // Track successful service creation locally
  var locallyCreatedServices = <Map<String, dynamic>>[].obs;

  String apiUrl = 'https://chalky-anjelica-bovinely.ngrok-free.dev/mechanics';
  final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";

  @override
  void onInit() {
    super.onInit();
    fetchMechanics();
    // Load any previously stored local services first
    _loadLocalServices();
    getUserMechanicServices();
    testMechanicServiceAPI();

    final prefs = SharedPreferences.getInstance();
    prefs.then((p) {
      final userId = p.getString("user_id");
      if (userId != null && userId.isNotEmpty) {
        vehicleController.getUserVehicles(userId);
      }
    });
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371; // Earth's radius in kilometers

  double dLat = _toRadians(lat2 - lat1);
  double dLon = _toRadians(lon2 - lon1);

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

double _toRadians(double degrees) {
  return degrees * pi / 180;
}


void updateUserLocation(double lat, double lng) {
  userLatitude.value = lat;
  userLongitude.value = lng;
  filterNearbyMechanics();
}

// Method to filter and sort mechanics by distance
void filterNearbyMechanics() {
  if (userLatitude.value == 0.0 || userLongitude.value == 0.0) {
    print('📍 User location not set, showing all mechanics');
    // Apply other filters but don't filter by distance
    _applyOtherFilters();
    return;
  }

  print('📍 Filtering mechanics within ${maxDistance.value}km of user location');

  final nearbyMechanics = mechanicCategories.where((mechanic) {
    // Check if mechanic has valid coordinates
    if (mechanic.latitude == 0.0 || mechanic.longitude == 0.0) {
      return false; // Skip mechanics without coordinates
    }

    final distance = calculateDistance(
      userLatitude.value,
      userLongitude.value,
      mechanic.latitude,
      mechanic.longitude,
    );

    mechanic.distanceFromUser = distance; // Store distance in the model
    return distance <= maxDistance.value;
  }).toList();

  // Sort by distance (nearest first)
  nearbyMechanics.sort((a, b) {
    final distanceA = a.distanceFromUser ?? double.maxFinite;
    final distanceB = b.distanceFromUser ?? double.maxFinite;
    return distanceA.compareTo(distanceB);
  });

  // Apply other filters (vehicle type, category) on nearby mechanics
  _applyOtherFiltersOnList(nearbyMechanics);
}

// Helper method to apply other filters on a list
void _applyOtherFiltersOnList(List<Mechanic> mechanics) {
  final filtered = mechanics.where((mechanic) {
    bool vehicleMatch = true;
    bool categoryMatch = true;

    // Vehicle type filtering
    if (selectedVehicleType.value.isNotEmpty) {
      vehicleMatch = _doesMechanicSupportVehicleType(mechanic, selectedVehicleType.value);
    }

    // Category filtering
    if (selectedCategory.value.isNotEmpty) {
      categoryMatch = _doesMechanicHaveSpecialty(mechanic, selectedCategory.value);
    }

    return vehicleMatch && categoryMatch;
  }).toList();

  filteredMechanics.assignAll(filtered);
  
  print('📍 Nearby mechanics filtered: ${filtered.length} within ${maxDistance.value}km');
}

// Update your existing filterMechanics method
void filterMechanics() {
  print('🔧 Applying filters...');
  print('   - Vehicle Type: "${selectedVehicleType.value}"');
  print('   - Category: "${selectedCategory.value}"');
  print('   - User Location: (${userLatitude.value}, ${userLongitude.value})');
  print('   - Max Distance: ${maxDistance.value}km');

  filterNearbyMechanics();
}

// Update your existing _applyOtherFilters method to use the new logic
void _applyOtherFilters() {
  _applyOtherFiltersOnList(mechanicCategories);
}


  // Load locally stored services from SharedPreferences
  void _loadLocalServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localServicesJson = prefs.getString('local_mechanic_services');
      if (localServicesJson != null && localServicesJson.isNotEmpty) {
        final List<dynamic> loadedServices = jsonDecode(localServicesJson);
        locallyCreatedServices.assignAll(loadedServices.cast<Map<String, dynamic>>());
        print('📥 Loaded ${locallyCreatedServices.length} local services from storage');
      }
    } catch (e) {
      print('❌ Error loading local services: $e');
    }
  }

  // Save locally stored services to SharedPreferences
  void _saveLocalServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_mechanic_services', jsonEncode(locallyCreatedServices));
      print('💾 Saved ${locallyCreatedServices.length} local services to storage');
    } catch (e) {
      print('❌ Error saving local services: $e');
    }
  }

  void notificationSelection() {
    isNotified.toggle();
  }



  Future<void> fetchMechanics() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        errorMessage.value = 'Please login to view mechanics';
        return;
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<Mechanic> mechanicList = [];

        if (data is List) {
          mechanicList = data.map((item) => Mechanic.fromJson(item)).toList();
        } else if (data is Map && data.containsKey('data')) {
          mechanicList = (data['data'] as List)
              .map((item) => Mechanic.fromJson(item))
              .toList();
        }

        mechanicCategories.assignAll(mechanicList);
        filteredMechanics.assignAll(mechanicList);
      } else {
        errorMessage.value = 'Failed to load mechanics';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ========== MECHANIC SERVICES METHODS ==========

  // Create new mechanic service
  Future<bool> createMechanicService({
   required String mechanicId,
  required String mechanicName,
  required String vehicleId,
  required String issueDescription,
  required String serviceType,
  required double serviceCost,
  required String estimatedTime,
  }) async {
    try {
      isServicesLoading.value = true;
      servicesErrorMessage.value = '';

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final userId = prefs.getString('user_id');

      print('🔐 Auth check - Access Token: ${accessToken != null ? "Present" : "Missing"}');
      print('🔐 Auth check - User ID: ${userId ?? "Missing"}');

      if (accessToken == null || userId == null) {
        servicesErrorMessage.value = 'User not authenticated';
        print('❌ Authentication failed');
        return false;
      }

      // Prepare request body
      final requestBody = {
        'user_id': userId,
        'mechanic_id': mechanicId,
        'vehicle_id': vehicleId,
        'issue_description': issueDescription,
        'service_type': serviceType,
        'service_cost': serviceCost,
        'estimated_time': estimatedTime,
        'status': 'pending',
      };

      print('📦 Request body: $requestBody');
      print('🌐 Calling endpoint: $baseUrl/mechanic-services/post');

      final response = await http.post(
        Uri.parse('$baseUrl/mechanic-services/post'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 30));

      print('📡 API Response - Status: ${response.statusCode}');
      print('📡 API Response - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Service created successfully');
        
        // ✅ Store the created service locally as backup
        try {
          final createdService = jsonDecode(response.body);
          print('🔍 Parsed created service type: ${createdService.runtimeType}');
          print('🔍 Parsed created service keys: ${createdService is Map ? createdService.keys.toList() : 'NOT A MAP'}');
          
          if (createdService is Map<String, dynamic>) {
            // Create a proper service object with all required fields
            final Map<String, dynamic> localService = {
              '_id': createdService['_id'] ?? 'local_${DateTime.now().millisecondsSinceEpoch}',
              'user_id': createdService['user_id'] ?? userId,
              'mechanic_id': mechanicId,
              'mechanic_name': mechanicName, // Add the mechanic name
              'vehicle_id': vehicleId,
              'issue_description': issueDescription,
              'service_type': serviceType,
              'service_cost': serviceCost,
              'estimated_time': estimatedTime,
              'status': createdService['status'] ?? 'pending',
              'created_at': createdService['created_at'] ?? DateTime.now().toIso8601String(),
              'local_backup': true, // Mark as local backup
              'images': createdService['images'] ?? [],
              'region': createdService['region'],
            };

            print('💾 Local service object: $localService');
            
            // Store locally as backup
            locallyCreatedServices.add(localService);
            _saveLocalServices(); // Persist to shared preferences
            
            print('💾 Service stored locally as backup. Total local services: ${locallyCreatedServices.length}');
            
            // Update the services list immediately
            await _updateServicesListWithLocalData();
          } else {
            print('❌ Created service is not a Map, it is: ${createdService.runtimeType}');
            
            // Create a local service even if parsing fails
            final Map<String, dynamic> localService = {
              '_id': 'local_${DateTime.now().millisecondsSinceEpoch}',
              'user_id': userId,
              'mechanic_id': mechanicId,
              'mechanic_name': mechanicName,
              'vehicle_id': vehicleId,
              'issue_description': issueDescription,
              'service_type': serviceType,
              'service_cost': serviceCost,
              'estimated_time': estimatedTime,
              'status': 'pending',
              'created_at': DateTime.now().toIso8601String(),
              'local_backup': true,
              'images': [],
            };
            
            locallyCreatedServices.add(localService);
            _saveLocalServices();
            await _updateServicesListWithLocalData();
          }
        } catch (e) {
          print('⚠️ Could not parse created service for local storage: $e');
          
          // Create a local service even if parsing fails
          final Map<String, dynamic> localService = {
            '_id': 'local_${DateTime.now().millisecondsSinceEpoch}',
            'user_id': userId,
            'mechanic_id': mechanicId,
            'mechanic_name': mechanicName,
            'vehicle_id': vehicleId,
            'issue_description': issueDescription,
            'service_type': serviceType,
            'service_cost': serviceCost,
            'estimated_time': estimatedTime,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'local_backup': true,
            'images': [],
          };
          
          locallyCreatedServices.add(localService);
          _saveLocalPreferences();
          await _updateServicesListWithLocalData();
        }
         try {
        final createdService = jsonDecode(response.body);
        final feedbackController = Get.find<FeedbackController>();
        
        // Add mechanic name to the service data for feedback
        final serviceWithMechanicName = Map<String, dynamic>.from(createdService);
        serviceWithMechanicName['mechanic_name'] = mechanicName;
        
        // Trigger feedback popup immediately
        feedbackController.checkForNewServiceFeedback(serviceWithMechanicName);
        
        print('🚀 Feedback popup triggered for new service!');
      } catch (e) {
        print('⚠️ Could not trigger feedback popup: $e');
      }
        
        return true;
      } else {
        String errorDetail = 'Unknown error';
        try {
          final errorData = jsonDecode(response.body);
          errorDetail = errorData['detail'] ?? errorData['message'] ?? response.body;
        } catch (e) {
          errorDetail = response.body;
        }
        
        servicesErrorMessage.value = 'Failed to create service: ${response.statusCode} - $errorDetail';
        print('❌ Service creation failed: ${servicesErrorMessage.value}');
        return false;
      }
    } catch (e) {
      servicesErrorMessage.value = 'Network error: $e';
      print('❌ Exception in createMechanicService: $e');
      return false;
    } finally {
      isServicesLoading.value = false;
    }
  }

  // Update services list with combined data
  Future<void> _updateServicesListWithLocalData() async {
    try {
      final apiServices = await _fetchAPIServices();
      final combinedServices = _combineServices(apiServices, locallyCreatedServices);
      mechanicServices.value = combinedServices;
      
      print('🔄 Updated services list: ${mechanicServices.length} total services');
      print('   - API services: ${apiServices.length}');
      print('   - Local services: ${locallyCreatedServices.length}');
      
      // Debug: Print local services
      if (locallyCreatedServices.isNotEmpty) {
        print('🔍 Local services details:');
        for (int i = 0; i < locallyCreatedServices.length; i++) {
          print('   Service $i: ${locallyCreatedServices[i]}');
        }
      }
    } catch (e) {
      print('❌ Error updating services list: $e');
      // Fallback to local services only
      mechanicServices.value = locallyCreatedServices.toList();
    }
  }

  // Fetch services from API with proper error handling
  Future<List<dynamic>> _fetchAPIServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        return [];
      }

      print('🌐 Fetching API services from: $baseUrl/mechanic-services/user/my-services');
      
      // Try the main endpoint first
      final response = await http.get(
        Uri.parse('$baseUrl/mechanic-services/user/my-services?skip=0&limit=50'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(Duration(seconds: 10));

      print('📡 API Services Response - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ API services fetched successfully');
        
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('data')) {
          return data['data'] ?? [];
        }
        return [];
      } else if (response.statusCode == 404) {
        print('ℹ️ No services found in API (404)');
        return [];
      } else {
        print('⚠️ API returned status: ${response.statusCode}');
        print('⚠️ API response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching API services: $e');
      return [];
    }
  }

  // Combine API and local services, removing duplicates
  List<dynamic> _combineServices(List<dynamic> apiServices, List<Map<String, dynamic>> localServices) {
    final combined = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    print('🔗 Combining services: ${apiServices.length} API + ${localServices.length} local');

    // Add API services first
    for (var service in apiServices) {
      if (service is Map<String, dynamic>) {
        final id = service['_id']?.toString();
        if (id != null && !seenIds.contains(id)) {
          combined.add(service);
          seenIds.add(id);
          print('   ✅ Added API service: $id');
        }
      }
    }

    // Add local services that aren't in API
    for (var service in localServices) {
      final id = service['_id']?.toString();
      if (id == null || !seenIds.contains(id)) {
        combined.add(service);
        if (id != null) seenIds.add(id);
        print('   ✅ Added local service: ${id ?? 'no-id'}');
      } else {
        print('   ⚠️ Skipped duplicate local service: $id');
      }
    }

    // Sort by creation date (newest first)
    combined.sort((a, b) {
      final dateA = a['created_at']?.toString() ?? '';
      final dateB = b['created_at']?.toString() ?? '';
      return dateB.compareTo(dateA);
    });

    print('🔗 Combined ${combined.length} total services');
    return combined;
  }

  // Get user mechanic services with robust error handling
  Future<void> getUserMechanicServices() async {
    try {
      isServicesLoading.value = true;
      servicesErrorMessage.value = '';

      print('🔐 Fetching services...');

      await _updateServicesListWithLocalData();

      // If we have services (either from API or local), clear any previous errors
      if (mechanicServices.isNotEmpty) {
        servicesErrorMessage.value = '';
        print('✅ Services loaded successfully: ${mechanicServices.length} services');
      } else if (locallyCreatedServices.isEmpty) {
        servicesErrorMessage.value = 'No services found. Create your first service!';
        print('ℹ️ No services found locally or via API');
      } else {
        print('❌ Services list is empty but local services exist: ${locallyCreatedServices.length}');
      }

    } catch (e) {
      print('❌ Exception in getUserMechanicServices: $e');
      servicesErrorMessage.value = 'Unable to load service history';
      
      // Fallback to local services
      mechanicServices.value = locallyCreatedServices.toList();
      print('🔄 Fallback to local services: ${mechanicServices.length}');
    } finally {
      isServicesLoading.value = false;
    }
  }

  // Update service status
  Future<bool> updateServiceStatus({
    required String serviceId,
    required String status,
    String? estimatedTime,
    double? serviceCost,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      final Map<String, dynamic> updateData = {'status': status};
      if (estimatedTime != null) updateData['estimated_time'] = estimatedTime;
      if (serviceCost != null) updateData['service_cost'] = serviceCost;

      final response = await http.put(
        Uri.parse('$baseUrl/mechanic-services/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        await getUserMechanicServices();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Delete service
Future<bool> deleteService(String serviceId) async {
  try {
    // Check if this is a local service (starts with 'local_')
    final bool isLocalService = serviceId.startsWith('local_');
    
    if (isLocalService) {
      // ✅ Handle local service deletion
      print('🗑️ Deleting local service: $serviceId');
      
      // Remove from local storage
      locallyCreatedServices.removeWhere((service) => 
        service['_id'] == serviceId || service['id'] == serviceId);
      _saveLocalServices();
      
      await getUserMechanicServices();
      return true;
    } else {
      // ✅ Handle API service deletion
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      final response = await http.delete(
        Uri.parse('$baseUrl/mechanic-services/$serviceId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove from local storage as well
        locallyCreatedServices.removeWhere((service) => 
          service['_id'] == serviceId || service['id'] == serviceId);
        _saveLocalServices();
        
        await getUserMechanicServices();
        return true;
      }
      return false;
    }
  } catch (e) {
    return false;
  }
}
  // Clear local services (for testing)
  void clearLocalServices() {
    locallyCreatedServices.clear();
    _saveLocalServices();
    mechanicServices.value = [];
  }

  // Get service by ID (useful for details page)
  Future<Map<String, dynamic>?> getServiceById(String serviceId) async {
    try {
      // First check local services
      final localService = locallyCreatedServices.firstWhere(
        (service) => service['_id'] == serviceId || service['id'] == serviceId,
        orElse: () => {},
      );

      if (localService.isNotEmpty) {
        return localService;
      }

      // Then try API
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('$baseUrl/mechanic-services/$serviceId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // ========== FILTERING METHODS ==========

  void selectCategory(String category) {
    if (selectedCategory.value == category) {
      selectedCategory.value = '';
    } else {
      selectedCategory.value = category;
    }
    filterMechanics();
  }

  void clearCategoryFilter() {
    selectedCategory.value = '';
    filterMechanics();
  }

  void clearVehicleFilter() {
    selectedVehicleType.value = '';
    selectedVehicleId.value = '';
    filterMechanics();
  }

  void clearAllFilters() {
    selectedVehicleType.value = '';
    selectedVehicleId.value = '';
    selectedCategory.value = '';
    filterMechanics();
  }

// void filterMechanics() {
//   print('🔧 Applying filters...');
//   print('   - Vehicle Type: "${selectedVehicleType.value}"');
//   print('   - Category: "${selectedCategory.value}"');
//   print('   - Total mechanics before filter: ${mechanicCategories.length}');

//   if (selectedVehicleType.value.isEmpty && selectedCategory.value.isEmpty) {
//     filteredMechanics.assignAll(mechanicCategories);
//     print('✅ No filters applied, showing all ${mechanicCategories.length} mechanics');
//   } else {
//     final filtered = mechanicCategories.where((mechanic) {
//       bool vehicleMatch = true;
//       bool categoryMatch = true;

//       // Vehicle type filtering
//       if (selectedVehicleType.value.isNotEmpty) {
//         vehicleMatch = _doesMechanicSupportVehicleType(mechanic, selectedVehicleType.value);
//         if (!vehicleMatch) {
//           print('   ❌ ${mechanic.fullName} filtered out - vehicle type mismatch');
//         }
//       }

//       // Category filtering
//       if (selectedCategory.value.isNotEmpty) {
//         categoryMatch = _doesMechanicHaveSpecialty(mechanic, selectedCategory.value);
//         if (!categoryMatch) {
//           print('   ❌ ${mechanic.fullName} filtered out - category mismatch');
//         }
//       }

//       if (vehicleMatch && categoryMatch) {
//         print('   ✅ ${mechanic.fullName} passed filters');
//       }

//       return vehicleMatch && categoryMatch;
//     }).toList();

//     filteredMechanics.assignAll(filtered);
//     print('✅ Filtered to ${filtered.length} mechanics');
//   }
// }



bool _doesMechanicSupportVehicleType(Mechanic mechanic, String vehicleType) {
  if (mechanic.servicedVehicleTypes.isEmpty) {
    // If no specific vehicle types listed, assume mechanic supports all
    return true;
  }
  
  final mechanicTypes = mechanic.servicedVehicleTypes.toLowerCase();
  final searchType = vehicleType.toLowerCase();
  
  // More flexible matching
  final typeMappings = {
    'car': ['car', 'sedan', 'suv', 'hatchback', 'vehicle'],
    'bike': ['bike', 'motorcycle', 'scooter', 'bicycle'],
    'truck': ['truck', 'lorry', 'heavy'],
    'bus': ['bus', 'coach'],
  };
  
  // Check direct match
  if (mechanicTypes.contains(searchType)) {
    return true;
  }
  
  // Check related types
  if (typeMappings.containsKey(searchType)) {
    final relatedTypes = typeMappings[searchType]!;
    return relatedTypes.any((type) => mechanicTypes.contains(type));
  }
  
  return false;
}


  bool _doesMechanicHaveSpecialty(Mechanic mechanic, String category) {
    if (mechanic.expertiseString != null) {
      final expertise = mechanic.expertiseString!.toLowerCase();
      final categoryLower = category.toLowerCase();
      
      final categoryKeywords = {
        'engine': ['engine', 'motor', 'overhaul', 'cylinder', 'piston'],
        'tyre': ['tyre', 'tire', 'wheel', 'alignment', 'balancing'],
        'brakes': ['brake', 'disc', 'pad', 'caliper', 'stopping'],
        'electrical': ['electrical', 'battery', 'wiring', 'alternator', 'starter'],
        'suspension': ['suspension', 'shock', 'strut', 'spring', 'alignment'],
      };

      final keywords = categoryKeywords[categoryLower] ?? [categoryLower];
      return keywords.any((keyword) => expertise.contains(keyword));
    }
    
    return false;
  }

  void filterMechanicsByVehicleType() {
    filterMechanics();
  }

  // Test method to check if API endpoint is working
  Future<void> testMechanicServiceAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final userId = prefs.getString('user_id');

      print('🧪 Testing Mechanic Service API...');
      print('🔐 Access Token: ${accessToken != null ? "Present" : "Missing"}');
      print('🔐 User ID: ${userId ?? "Missing"}');

      final testResponse = await http.get(
        Uri.parse('$baseUrl/mechanic-services/user/my-services'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(Duration(seconds: 10));

      print('🧪 GET Test - Status: ${testResponse.statusCode}');
      if (testResponse.statusCode != 200) {
        print('🧪 GET Test - Body: ${testResponse.body}');
      }

    } catch (e) {
      print('🧪 API Test Failed: $e');
    }
  }

  // Fix the method name typo
  void _saveLocalPreferences() async {
    _saveLocalServices();
  }

Future<bool> updateServiceDetails({
  required String serviceId,
  required String issueDescription,
  required String estimatedTime,
}) async {
  try {
    // Check if this is a local service (starts with 'local_')
    final bool isLocalService = serviceId.startsWith('local_');
    
    if (isLocalService) {
      // ✅ Handle local service update
      print('🔄 Updating local service: $serviceId');
      
      // Update local service
      final localServiceIndex = locallyCreatedServices.indexWhere(
        (service) => service['_id'] == serviceId || service['id'] == serviceId
      );
      
      if (localServiceIndex != -1) {
        locallyCreatedServices[localServiceIndex]['issue_description'] = issueDescription;
        locallyCreatedServices[localServiceIndex]['estimated_time'] = estimatedTime;
        locallyCreatedServices[localServiceIndex]['updated_at'] = DateTime.now().toIso8601String();
        _saveLocalServices();
        
        print('✅ Local service updated successfully');
        await getUserMechanicServices(); // Refresh the list
        return true;
      } else {
        servicesErrorMessage.value = 'Local service not found';
        return false;
      }
    } else {
      // ✅ Handle API service update
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        servicesErrorMessage.value = 'User not authenticated';
        return false;
      }

      final Map<String, dynamic> updateData = {
        'issue_description': issueDescription,
        'estimated_time': estimatedTime,
      };

      print('📝 Updating API service $serviceId with: $updateData');

      final response = await http.put(
        Uri.parse('$baseUrl/mechanic-services/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(updateData),
      );

      print('📡 Update Response - Status: ${response.statusCode}');
      print('📡 Update Response - Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ API service updated successfully');
        
        // Also update local copy if it exists
        final localServiceIndex = locallyCreatedServices.indexWhere(
          (service) => service['_id'] == serviceId || service['id'] == serviceId
        );
        
        if (localServiceIndex != -1) {
          locallyCreatedServices[localServiceIndex]['issue_description'] = issueDescription;
          locallyCreatedServices[localServiceIndex]['estimated_time'] = estimatedTime;
          _saveLocalServices();
        }
        
        await getUserMechanicServices(); // Refresh the list
        return true;
      } else {
        String errorDetail = 'Unknown error';
        try {
          final errorData = jsonDecode(response.body);
          errorDetail = errorData['detail'] ?? errorData['message'] ?? response.body;
        } catch (e) {
          errorDetail = response.body;
        }
        
        servicesErrorMessage.value = 'Failed to update service: ${response.statusCode} - $errorDetail';
        return false;
      }
    }
  } catch (e) {
    servicesErrorMessage.value = 'Network error: $e';
    return false;
  }
}


// Add these to your MechanicController class

// Search properties
final TextEditingController searchController = TextEditingController();
final RxString searchQuery = ''.obs;
final RxList<dynamic> filteredServices = <dynamic>[].obs;

// Search method
void searchServices(String query) {
  searchQuery.value = query.trim().toLowerCase();
  
  if (searchQuery.isEmpty) {
    filteredServices.clear();
    return;
  }

  final allServices = mechanicServices.toList();
  final results = allServices.where((service) {
    if (service is! Map<String, dynamic>) return false;
    
    // Search in mechanic name
    final mechanicName = (service['mechanic_name'] ?? '').toString().toLowerCase();
    if (mechanicName.contains(searchQuery.value)) return true;
    
    // Search in vehicle name
    final vehicleId = service['vehicle_id'] ?? '';
    final vehicleName = _getVehicleNameForSearch(vehicleId).toLowerCase();
    if (vehicleName.contains(searchQuery.value)) return true;
    
    // Search in issue description
    final issueDescription = (service['issue_description'] ?? '').toString().toLowerCase();
    if (issueDescription.contains(searchQuery.value)) return true;
    
    // Search in service type
    final serviceType = (service['service_type'] ?? '').toString().toLowerCase();
    if (serviceType.contains(searchQuery.value)) return true;
    
    // Search in status
    final status = (service['status'] ?? '').toString().toLowerCase();
    if (status.contains(searchQuery.value)) return true;
    
    // Search in estimated time
    final estimatedTime = (service['estimated_time'] ?? '').toString().toLowerCase();
    if (estimatedTime.contains(searchQuery.value)) return true;
    
    return false;
  }).toList();

  filteredServices.assignAll(results);
}

// Helper method to get vehicle name for search
String _getVehicleNameForSearch(String vehicleId) {
  try {
    if (vehicleId.isEmpty) return 'Unknown Vehicle';
    
    final vehicle = Get.find<VehicleController>().userVehicles.firstWhere(
      (v) {
        final vId = v['_id'] ?? v['id'];
        return vId != null && vId.toString() == vehicleId.toString();
      },
      orElse: () => {},
    );
    
    if (vehicle.isNotEmpty) {
      final brand = vehicle['brand'] ?? '';
      final model = vehicle['model'] ?? '';
      return '$brand $model'.trim();
    }
  } catch (e) {
    print('Error getting vehicle name for search: $e');
  }
  
  return 'Unknown Vehicle';
}







// Clear search method
void clearSearch() {
  searchController.clear();
  searchQuery.value = '';
  filteredServices.clear();
}

// Don't forget to dispose the controller in onClose
@override
void onClose() {
  searchController.dispose();
  super.onClose();
}

}


























// 2nd Attempt/////////////////

// import 'package:fixibot_app/model/mechanicModel.dart';
// import 'package:fixibot_app/screens/location/location_controller.dart';
// import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';

// class MechanicController extends GetxController {
//   var mechanicCategories = <Mechanic>[].obs;
//   var filteredMechanics = <Mechanic>[].obs;
//   var selectedVehicleType = ''.obs;
//   var selectedCategory = ''.obs;

//   final VehicleController vehicleController = Get.find<VehicleController>();
//   final LocationController locationController = Get.put(LocationController());

//   var isNotified = false.obs;
//   var isLoading = false.obs;
//   var errorMessage = ''.obs;

//   // Mechanic Services Properties
//   RxList<dynamic> mechanicServices = <dynamic>[].obs;
//   RxBool isServicesLoading = false.obs;
//   RxString servicesErrorMessage = ''.obs;

//   String apiUrl = 'https://chalky-anjelica-bovinely.ngrok-free.dev/mechanics';
//   final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";

//   void notificationSelection() {
//     isNotified.toggle();
//   }

//   Future<void> fetchMechanics() async {
//     isLoading.value = true;
//     errorMessage.value = '';

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final accessToken = prefs.getString('access_token');

//       if (accessToken == null) {
//         errorMessage.value = 'Please login to view mechanics';
//         return;
//       }

//       final response = await http.get(
//         Uri.parse(apiUrl),
//         headers: {
//           "Authorization": "Bearer $accessToken",
//           "Content-Type": "application/json",
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);

//         List<Mechanic> mechanicList = [];

//         if (data is List) {
//           mechanicList = data.map((item) => Mechanic.fromJson(item)).toList();
//         } else if (data is Map && data.containsKey('data')) {
//           mechanicList = (data['data'] as List)
//               .map((item) => Mechanic.fromJson(item))
//               .toList();
//         }

//         mechanicCategories.assignAll(mechanicList);
//         filteredMechanics.assignAll(mechanicList); // Initialize filtered list
//       } else {
//         errorMessage.value = 'Failed to load mechanics';
//       }
//     } catch (e) {
//       errorMessage.value = 'Error: $e';
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   // ========== MECHANIC SERVICES METHODS ==========

//   // Create new mechanic service
  

  
// Future<bool> createMechanicService({
//   required String mechanicId,
//   required String mechanicName,
//   required String vehicleId,
//   required String issueDescription,
//   required String serviceType,
//   required double serviceCost,
//   required String estimatedTime,
// }) async {
//   try {
//     isServicesLoading.value = true;
//     servicesErrorMessage.value = '';

//     final prefs = await SharedPreferences.getInstance();
//     final accessToken = prefs.getString('access_token');
//     final userId = prefs.getString('user_id');

//     print('🔐 Auth check - Access Token: ${accessToken != null ? "Present" : "Missing"}');
//     print('🔐 Auth check - User ID: ${userId ?? "Missing"}');

//     if (accessToken == null || userId == null) {
//       servicesErrorMessage.value = 'User not authenticated';
//       print('❌ Authentication failed');
//       return false;
//     }

//     // Prepare request body - using exact field names from your API schema
//     final requestBody = {
//       'user_id': userId,
//       'mechanic_id': mechanicId,
//       'vehicle_id': vehicleId,
//       'issue_description': issueDescription,
//       'service_type': serviceType,
//       'service_cost': serviceCost,
//       'estimated_time': estimatedTime,
//       'status': 'pending',
//     };

//     print('📦 Request body: $requestBody');
//     print('🌐 Calling endpoint: $baseUrl/mechanic-services/post');

//     final response = await http.post(
//       Uri.parse('$baseUrl/mechanic-services/post'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $accessToken',
//       },
//       body: jsonEncode(requestBody),
//     ).timeout(Duration(seconds: 30));

//     print('📡 API Response - Status: ${response.statusCode}');
//     print('📡 API Response - Body: ${response.body}');

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       print('✅ Service created successfully');
//       // Refresh the services list
//       await getUserMechanicServices();
//       return true;
//     } else {
//       // Try to parse error message
//       String errorDetail = 'Unknown error';
//       try {
//         final errorData = jsonDecode(response.body);
//         errorDetail = errorData['detail'] ?? errorData['message'] ?? response.body;
//       } catch (e) {
//         errorDetail = response.body;
//       }
      
//       servicesErrorMessage.value = 'Failed to create service: ${response.statusCode} - $errorDetail';
//       print('❌ Service creation failed: ${servicesErrorMessage.value}');
//       return false;
//     }
//   } catch (e) {
//     servicesErrorMessage.value = 'Network error: $e';
//     print('❌ Exception in createMechanicService: $e');
//     return false;
//   } finally {
//     isServicesLoading.value = false;
//   }
// }

// Future<void> getUserMechanicServices() async {
//   try {
//     isServicesLoading.value = true;
//     servicesErrorMessage.value = '';

//     final prefs = await SharedPreferences.getInstance();
//     final accessToken = prefs.getString('access_token');
//     final userId = prefs.getString('user_id');

//     print('🔐 Fetching services - User ID: $userId');

//     if (accessToken == null) {
//       servicesErrorMessage.value = 'User not authenticated';
//       return;
//     }

//     // ✅ ADD QUERY PARAMETERS as per your API documentation
//     final Uri uri = Uri.parse('$baseUrl/mechanic-services/user/my-services')
//         .replace(queryParameters: {
//       'skip': '0',
//       'limit': '50', 
//       'sort_by': 'created_at',
//       'sort_order': '-1'
//     });

//     print('🌐 Calling service history endpoint: $uri');

//     final response = await http.get(
//       uri,
//       headers: {
//         'Authorization': 'Bearer $accessToken',
//       },
//     ).timeout(Duration(seconds: 15));

//     print('📡 Service History - Status: ${response.statusCode}');
    
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       print('✅ Services fetched successfully: ${data.length} services');
      
//       // Debug: Print service details
//       for (var i = 0; i < data.length; i++) {
//         print('   Service $i: ${data[i]}');
//       }
      
//       if (data is List) {
//         mechanicServices.value = data;
//       } else {
//         mechanicServices.value = [];
//       }
//     } else if (response.statusCode == 404) {
//       // No services found - this is normal for new users
//       print('ℹ️ No services found (404) - user might not have any services yet');
//       mechanicServices.value = [];
//     } else if (response.statusCode == 500) {
//       // Server error - provide more helpful message
//       try {
//         final errorData = jsonDecode(response.body);
//         final errorDetail = errorData['detail'] ?? 'Unknown server error';
//         servicesErrorMessage.value = 'Server error: $errorDetail';
//         print('❌ Server error fetching services: $errorDetail');
//       } catch (e) {
//         servicesErrorMessage.value = 'Server error: Failed to load service history';
//         print('❌ Server error (could not parse response): ${response.body}');
//       }
//       mechanicServices.value = [];
//     } else {
//       servicesErrorMessage.value = 'Failed to load services: ${response.statusCode}';
//       print('❌ Unexpected status code: ${response.statusCode} - Body: ${response.body}');
//       mechanicServices.value = [];
//     }
//   } catch (e) {
//     print('❌ Exception in getUserMechanicServices: $e');
//     servicesErrorMessage.value = 'Network error: Please check your connection';
//     mechanicServices.value = [];
//   } finally {
//     isServicesLoading.value = false;
//   }
// }


//   // Update service status
//   Future<bool> updateServiceStatus({
//     required String serviceId,
//     required String status,
//     String? estimatedTime,
//     double? serviceCost,
//   }) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final accessToken = prefs.getString('access_token');

//       final Map<String, dynamic> updateData = {'status': status};
//       if (estimatedTime != null) updateData['estimated_time'] = estimatedTime;
//       if (serviceCost != null) updateData['service_cost'] = serviceCost;

//       final response = await http.put(
//         Uri.parse('$baseUrl/mechanic-services/$serviceId'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $accessToken',
//         },
//         body: jsonEncode(updateData),
//       );

//       if (response.statusCode == 200) {
//         await getUserMechanicServices();
//         return true;
//       }
//       return false;
//     } catch (e) {
//       return false;
//     }
//   }

//   // Delete service
//   Future<bool> deleteService(String serviceId) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final accessToken = prefs.getString('access_token');

//       final response = await http.delete(
//         Uri.parse('$baseUrl/mechanic-services/$serviceId'),
//         headers: {
//           'Authorization': 'Bearer $accessToken',
//         },
//       );

//       if (response.statusCode == 200 || response.statusCode == 204) {
//         await getUserMechanicServices();
//         return true;
//       }
//       return false;
//     } catch (e) {
//       return false;
//     }
//   }

//   // ========== FILTERING METHODS ==========

//   void selectCategory(String category) {
//     if (selectedCategory.value == category) {
//       // If same category is clicked again, deselect it
//       selectedCategory.value = '';
//     } else {
//       selectedCategory.value = category;
//     }
//     filterMechanics();
//   }

//   void clearCategoryFilter() {
//     selectedCategory.value = '';
//     filterMechanics();
//   }

//   void clearVehicleFilter() {
//     selectedVehicleType.value = '';
//     filterMechanics();
//   }

//   void clearAllFilters() {
//     selectedVehicleType.value = '';
//     selectedCategory.value = '';
//     filterMechanics();
//   }

//   void filterMechanics() {
//     if (selectedVehicleType.value.isEmpty && selectedCategory.value.isEmpty) {
//       // No filters applied, show all mechanics
//       filteredMechanics.assignAll(mechanicCategories);
//     } else {
//       // Apply filters
//       final filtered = mechanicCategories.where((mechanic) {
//         bool vehicleMatch = true;
//         bool categoryMatch = true;

//         // Vehicle type filter
//         if (selectedVehicleType.value.isNotEmpty) {
//           vehicleMatch = _doesMechanicSupportVehicleType(mechanic, selectedVehicleType.value);
//         }

//         // Category/specialty filter
//         if (selectedCategory.value.isNotEmpty) {
//           categoryMatch = _doesMechanicHaveSpecialty(mechanic, selectedCategory.value);
//         }

//         return vehicleMatch && categoryMatch;
//       }).toList();

//       filteredMechanics.assignAll(filtered);
//     }
//   }

//   bool _doesMechanicSupportVehicleType(Mechanic mechanic, String vehicleType) {
//   // Check if mechanic supports the selected vehicle type
//   if (mechanic.servicedVehicleTypes.isNotEmpty) {
//     return mechanic.servicedVehicleTypes.toLowerCase()
//         .contains(vehicleType.toLowerCase());
//   }
  
//   // Fallback: check expertise string
//   if (mechanic.expertiseString.isNotEmpty) {
//     return mechanic.expertiseString.toLowerCase()
//         .contains(vehicleType.toLowerCase());
//   }
  
//   // If no vehicle type info available, show the mechanic
//   return true;
// }

//   bool _doesMechanicHaveSpecialty(Mechanic mechanic, String category) {
//     // Check if mechanic has the selected specialty/category
//     if (mechanic.expertiseString != null) {
//       final expertise = mechanic.expertiseString!.toLowerCase();
//       final categoryLower = category.toLowerCase();
      
//       // Map categories to common expertise keywords
//       final categoryKeywords = {
//         'engine': ['engine', 'motor', 'overhaul', 'cylinder', 'piston'],
//         'tyre': ['tyre', 'tire', 'wheel', 'alignment', 'balancing'],
//         'brakes': ['brake', 'disc', 'pad', 'caliper', 'stopping'],
//         'electrical': ['electrical', 'battery', 'wiring', 'alternator', 'starter'],
//         'suspension': ['suspension', 'shock', 'strut', 'spring', 'alignment'],
//       };

//       final keywords = categoryKeywords[categoryLower] ?? [categoryLower];
//       return keywords.any((keyword) => expertise.contains(keyword));
//     }
    
//     return false;
//   }

//   // Update your existing filter method to use the new combined filter
//   void filterMechanicsByVehicleType() {
//     filterMechanics();
//   }
//   // Test method to check if API endpoint is working
// Future<void> testMechanicServiceAPI() async {
//   try {
//     final prefs = await SharedPreferences.getInstance();
//     final accessToken = prefs.getString('access_token');
//     final userId = prefs.getString('user_id');

//     print('🧪 Testing Mechanic Service API...');
//     print('🔐 Access Token: ${accessToken != null ? "Present" : "Missing"}');
//     print('🔐 User ID: ${userId ?? "Missing"}');

//     // Test GET endpoint first
//     final testResponse = await http.get(
//       Uri.parse('$baseUrl/mechanic-services/user/my-services'),
//       headers: {
//         'Authorization': 'Bearer $accessToken',
//       },
//     ).timeout(Duration(seconds: 10));

//     print('🧪 GET Test - Status: ${testResponse.statusCode}');
//     print('🧪 GET Test - Body: ${testResponse.body}');

//   } catch (e) {
//     print('🧪 API Test Failed: $e');
//   }
// }

//   @override
//   void onInit() {
//     super.onInit();
//     fetchMechanics();
//     getUserMechanicServices(); // Initialize services on app start
//     testMechanicServiceAPI();

//     final prefs = SharedPreferences.getInstance();
//     prefs.then((p) {
//       final userId = p.getString("user_id");
//       if (userId != null && userId.isNotEmpty) {
//         vehicleController.getUserVehicles(userId);
//       }
//     });
//   }
//   // Add this method to test if service was created
// Future<bool> verifyServiceCreation(String mechanicId, String vehicleId) async {
//   try {
//     print('🔍 Verifying service creation...');
    
//     // Wait a bit for the backend to process
//     await Future.delayed(Duration(seconds: 2));
    
//     // Try to fetch services again
//     await getUserMechanicServices();
    
//     // Check if our new service appears in the list
//     if (mechanicServices.isNotEmpty) {
//       print('✅ Service verification: ${mechanicServices.length} services found');
//       return true;
//     } else {
//       print('⚠️ Service verification: No services found, but creation might still be successful');
//       // Even if we can't see it in the list, the creation might have worked
//       return true;
//     }
//   } catch (e) {
//     print('❌ Service verification error: $e');
//     return false;
//   }
// }
// }






