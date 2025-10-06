import 'package:fixibot_app/model/mechanicModel.dart';
import 'package:fixibot_app/screens/location/location_controller.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MechanicController extends GetxController {
  var mechanicCategories = <Mechanic>[].obs;
  var isNotified = RxBool(false);
  var isLoading = RxBool(false);
  var errorMessage = RxString('');
  String apiUrl = 'https://zoogloeal-byron-unruled.ngrok-free.dev/mechanics';
  RxList<Map<String, dynamic>> mechanics = <Map<String, dynamic>>[].obs;

  
  final LocationController locationController = Get.put(LocationController());
  
  void notificationSelection() {
    isNotified.value = !isNotified.value;
  }
  
  // Method to fetch mechanics data from API
 Future<void> fetchMechanics() async {
  isLoading.value = true;
  errorMessage.value = '';
  
  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    
    if (accessToken == null) {
      errorMessage.value = 'Please login to view mechanics';
      isLoading.value = false;
      return;
    }

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
      },
    ).timeout(const Duration(seconds: 30));
    
    print('Response status: ${response.statusCode}');
    print('Raw response: ${response.body}'); // Add this to see raw response
    
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      
      // Debug print to see the actual structure
      print('Parsed response: $responseData');
      print('Response type: ${responseData.runtimeType}');
      
      if (responseData is Map) {
        print('Map keys: ${responseData.keys}');
        if (responseData.containsKey('data')) {
          print('Data type: ${responseData['data'].runtimeType}');
        }
      }
      
      List<Mechanic> mechanics = [];
      
      // Handle different response structures
      if (responseData is List) {
        print('Response is a List');
        mechanics = responseData.map((item) {
          print('List item: $item');
          print('Item type: ${item.runtimeType}');
          return Mechanic.fromJson(item);
        }).toList();
      } else if (responseData is Map && responseData.containsKey('data')) {
        print('Response has data key');
        final data = responseData['data'];
        if (data is List) {
          mechanics = data.map((item) {
            print('Data item: $item');
            return Mechanic.fromJson(item);
          }).toList();
        }
      } else if (responseData is Map && responseData.containsKey('mechanics')) {
        print('Response has mechanics key');
        final mechanicsData = responseData['mechanics'];
        if (mechanicsData is List) {
          mechanics = mechanicsData.map((item) {
            print('Mechanics item: $item');
            return Mechanic.fromJson(item);
          }).toList();
        }
      }
      
      print('Final mechanics list: ${mechanics.length} items');
      for (var mechanic in mechanics) {
        print('Mechanic: ${mechanic.fullName}, First: ${mechanic.firstName}, Last: ${mechanic.lastName}');
      }
      
      mechanicCategories.assignAll(mechanics);
      
    } else if (response.statusCode == 401) {
      errorMessage.value = 'Authentication failed. Please login again.';
    } else {
      errorMessage.value = 'Failed to load mechanics: ${response.statusCode}';
    }
  } catch (e) {
    errorMessage.value = 'Error: $e';
    print('Network error: $e');
  } finally {
    isLoading.value = false;
  }
} 
  // Method to filter mechanics by expertise
  List<Mechanic> filterByExpertise(String category) {
    return mechanicCategories
        .where((mechanic) => mechanic.expertise.any((exp) => exp.toLowerCase().contains(category.toLowerCase())))
        .toList();
  }
  
  // Method to sort mechanics by distance
  List<Mechanic> sortByDistance(double userLat, double userLng) {
    final mechanics = mechanicCategories.toList();
    mechanics.sort((a, b) {
      final distanceA = a.calculateDistance(userLat, userLng);
      final distanceB = b.calculateDistance(userLat, userLng);
      return distanceA.compareTo(distanceB);
    });
    return mechanics;
  }
  
  @override
  void onInit() {
    super.onInit();
    fetchMechanics();
  }
}