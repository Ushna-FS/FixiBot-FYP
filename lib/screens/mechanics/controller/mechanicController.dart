import 'package:fixibot_app/model/mechanicModel.dart';
import 'package:fixibot_app/screens/location/location_controller.dart';
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MechanicController extends GetxController {
  var mechanicCategories = <Mechanic>[].obs;
  var filteredMechanics = <Mechanic>[].obs;
  var selectedVehicleType = ''.obs;
  var selectedCategory = ''.obs;

  final VehicleController vehicleController = Get.find<VehicleController>();
  final LocationController locationController = Get.put(LocationController());

  var isNotified = false.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  String apiUrl = 'https://chalky-anjelica-bovinely.ngrok-free.dev/mechanics';

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
        filteredMechanics.assignAll(mechanicList); // Initialize filtered list
      } else {
        errorMessage.value = 'Failed to load mechanics';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(String category) {
    if (selectedCategory.value == category) {
      // If same category is clicked again, deselect it
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
    filterMechanics();
  }

  void clearAllFilters() {
    selectedVehicleType.value = '';
    selectedCategory.value = '';
    filterMechanics();
  }

  void filterMechanics() {
    if (selectedVehicleType.value.isEmpty && selectedCategory.value.isEmpty) {
      // No filters applied, show all mechanics
      filteredMechanics.assignAll(mechanicCategories);
    } else {
      // Apply filters
      final filtered = mechanicCategories.where((mechanic) {
        bool vehicleMatch = true;
        bool categoryMatch = true;

        // Vehicle type filter
        if (selectedVehicleType.value.isNotEmpty) {
          vehicleMatch = _doesMechanicSupportVehicleType(mechanic, selectedVehicleType.value);
        }

        // Category/specialty filter
        if (selectedCategory.value.isNotEmpty) {
          categoryMatch = _doesMechanicHaveSpecialty(mechanic, selectedCategory.value);
        }

        return vehicleMatch && categoryMatch;
      }).toList();

      filteredMechanics.assignAll(filtered);
    }
  }

  bool _doesMechanicSupportVehicleType(Mechanic mechanic, String vehicleType) {
    // Check if mechanic supports the selected vehicle type
    if (mechanic.servicedVehicleTypes != null) {
      return mechanic.servicedVehicleTypes!.any((type) => 
          type.toLowerCase().contains(vehicleType.toLowerCase()));
    }
    
    // Fallback: check expertise string
    if (mechanic.expertiseString != null) {
      return mechanic.expertiseString!.toLowerCase()
          .contains(vehicleType.toLowerCase());
    }
    
    // If no vehicle type info available, show the mechanic
    return true;
  }

  bool _doesMechanicHaveSpecialty(Mechanic mechanic, String category) {
    // Check if mechanic has the selected specialty/category
    if (mechanic.expertiseString != null) {
      final expertise = mechanic.expertiseString!.toLowerCase();
      final categoryLower = category.toLowerCase();
      
      // Map categories to common expertise keywords
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

  // Update your existing filter method to use the new combined filter
  void filterMechanicsByVehicleType() {
    filterMechanics();
  }

  @override
  void onInit() {
    super.onInit();
    fetchMechanics();
    final prefs = SharedPreferences.getInstance();
    prefs.then((p) {
      final userId = p.getString("user_id");
      if (userId != null && userId.isNotEmpty) {
        vehicleController.getUserVehicles(userId);
      }
    });
  }
}