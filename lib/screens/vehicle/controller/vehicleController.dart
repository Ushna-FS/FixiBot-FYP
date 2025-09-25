import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

class VehicleController extends GetxController {
   final String baseUrl = "http://127.0.0.1:8000";
    RxList<Map<String,dynamic>> userVehicles = <Map<String,dynamic>>[].obs;

  // final String baseUrl = "http://10.135.54.128:8000";
  var transmissionAuto = false.obs;

  final carModelYear = TextEditingController();
  final carMileage = TextEditingController();
  final fuelType = TextEditingController();
var selectedModel = ''.obs;
var selectedBrand= ''.obs;
  var selectedVehicleType = ''.obs;
  var isLoading = false.obs;
  
  Future<SharedPreferences> get sharedPrefs async => await SharedPreferences.getInstance();

  var image = Rx<File?>(null);
  var imageBytes = Rx<Uint8List?>(null);

    void notifyVehicleDataChanged() {
    update(); // This will notify all listeners
  }


  void _debugJsonBody(String jsonBody) {
    print('🔍 JSON Body Debug:');
    print('   Contains user_id: ${jsonBody.contains('user_id')}');
    print('   Contains model: ${jsonBody.contains('model')}');
    print('   Contains type: ${jsonBody.contains('type')}');

    // Check if values are properly quoted
    final user_idMatch = RegExp(r'"user_id":"([^"]+)"').firstMatch(jsonBody);
    final modelMatch = RegExp(r'"model":"([^"]+)"').firstMatch(jsonBody);
    final typeMatch = RegExp(r'"type":"([^"]+)"').firstMatch(jsonBody);

    print('   user_id value: ${user_idMatch?.group(1)}');
    print('   model value: ${modelMatch?.group(1)}');
    print('   type value: ${typeMatch?.group(1)}');
    print('   Full JSON length: ${jsonBody.length} characters');
  }

  void toggleTransmission() {
    transmissionAuto.value = !transmissionAuto.value;
  }

  Future<void> saveVehicle({
    required String userId,
    required bool isPrimary,
    required bool isActive,
  }) async {
    isLoading.value = true;

    // Input validation
    if (userId.trim().isEmpty) {
      Get.snackbar('Error', 'User ID is required');
      isLoading.value = false;
      return;
    }
    if (selectedVehicleType.value.isEmpty) {
      Get.snackbar('Error', 'Please select a vehicle type');
      isLoading.value = false;
      return;
    }
    if (selectedModel.value.isEmpty) {
      Get.snackbar('Error', 'Vehicle model is required');
      isLoading.value = false;
      return;
    }

    // Debug: Print all form data
    print('📋 Vehicle Data to be sent:');
    print('user_id: $userId');
    print('model: ${selectedModel}');
    print('brand: ${selectedBrand}');
    print('year: ${carModelYear.text.trim()}');
    print('type: ${selectedVehicleType.value}');
    print('fuel_type: ${fuelType.text.trim()}');
    print('transmission: ${transmissionAuto.value ? "automatic" : "manual"}');
    print('is_primary: $isPrimary');
    print('is_active: $isActive');
    print('mileage_km: ${carMileage.text.trim()}');

    final List<String> possibleEndpoints = ['$baseUrl/vehicles/create'];
    http.Response? response;

    for (var endpoint in possibleEndpoints) {
      try {
        final uri = Uri.parse(endpoint);
        print('🔄 Trying endpoint: $endpoint');

        // Get access token for authentication
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString('access_token');

        // Create multipart request instead of JSON
        var request = http.MultipartRequest('POST', uri);

        // Add headers
        if (accessToken != null) {
          request.headers['Authorization'] = 'Bearer $accessToken';
        }

        // Add required form fields
        request.fields['user_id'] = userId;
        request.fields['model'] = selectedModel.value;
        request.fields['type'] = selectedVehicleType.value;

        // Add optional fields if they have values
        if (selectedBrand.value.isNotEmpty) {
          request.fields['brand'] = selectedBrand.value;
        }
        if (carModelYear.text.trim().isNotEmpty) {
          request.fields['year'] = carModelYear.text.trim();
        }
        if (fuelType.text.trim().isNotEmpty) {
          request.fields['fuel_type'] = fuelType.text.trim();
        }
        if (carMileage.text.trim().isNotEmpty) {
          request.fields['mileage_km'] = carMileage.text.trim();
        }

        request.fields['transmission'] =
            transmissionAuto.value ? "automatic" : "manual";
        request.fields['is_primary'] = isPrimary.toString();
        request.fields['is_active'] = isActive.toString();

        // Add image if available
        if (kIsWeb && imageBytes.value != null) {
          final multipartFile = http.MultipartFile.fromBytes(
            'images',
            imageBytes.value!,
            filename: 'vehicle_image.jpg',
            contentType: MediaType('image', 'jpeg'),
          );
          request.files.add(multipartFile);
          print('📸 Web image added to request');
        } else if (!kIsWeb && image.value != null) {
          final multipartFile = await http.MultipartFile.fromPath(
            'images',
            image.value!.path,
            contentType: MediaType('image', 'jpeg'),
          );
          request.files.add(multipartFile);
          print('📸 Mobile image added to request: ${image.value!.path}');
        } else {
          print('📸 No image selected');
        }

        print('📦 Sending form data with fields: ${request.fields}');
        if (request.files.isNotEmpty) {
          print('📦 With ${request.files.length} image files');
        }

        // Send the request
        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);

        print('📡 Response status: ${response.statusCode}');
        print('📡 Response body: ${response.body}');

        // If we get a successful response, break the loop
        if (response.statusCode == 200 || response.statusCode == 201) {
          break;
        }
        
      notifyVehicleDataChanged();
      } catch (e) {
        print('❌ Error with endpoint $endpoint: $e');
        continue; // Try next endpoint
      }
    }

    isLoading.value = false;

    // Handle response
    if (response != null) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        try {
          final responseData = jsonDecode(response.body);
          Get.snackbar(
            "Success",
            "Vehicle saved successfully!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );


      Get.back(); 
          // Clear form after successful submission
          clearForm();
        } catch (e) {
          Get.snackbar(
            "Success",
            "Vehicle saved successfully!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      } else {
        // Server error - show detailed error message
        String errorMessage =
            "Failed to save vehicle (Error: ${response.statusCode})";

        try {
          final errorData = jsonDecode(response.body);
          if (errorData['detail'] != null) {
            errorMessage = errorData['detail'];
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          errorMessage =
              "Server error: ${response.statusCode}\n${response.body}";
        }

        Get.snackbar(
          "Error",
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );
      }
    } else {
      // No successful response from any endpoint
      Get.snackbar(
        "Error",
        "Failed to connect to server. Please check your connection and try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void clearForm() {
    selectedBrand.value = '';
    selectedModel.value = '';
    carModelYear.clear();
    carMileage.clear();
    fuelType.clear();
    selectedVehicleType.value = '';
    image.value = null;
    imageBytes.value = null;
    transmissionAuto.value = false;
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          imageBytes.value = bytes;
          image.value = null;
          print('📸 Web image selected: ${bytes.length} bytes');
        } else {
          image.value = File(pickedFile.path);
          imageBytes.value = null;
          print('📸 Mobile image selected: ${pickedFile.path}');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

Future<List<dynamic>> getUserVehicles(String userId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    
    if (accessToken == null) {
      print('❌ No access token in getUserVehicles');
      throw Exception('No authentication token found');
    }

    print('🌐 Calling API: $baseUrl/vehicles');
    
    final response = await http.get(
      Uri.parse('$baseUrl/vehicles/all'),
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
      },
    ).timeout(Duration(seconds: 30));

    print('🌐 API Response: ${response.statusCode}');
    print('🌐 API Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
    userVehicles.assignAll(
  (jsonDecode(response.body) as List)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
);

      return data is List ? data : [];
    } else if (response.statusCode == 401) {
      print('❌ Unauthorized - token may be expired');
      throw Exception('Authentication failed. Please login again.');
    } else if (response.statusCode == 404) {
      print('❌ Endpoint not found');
      throw Exception('Server endpoint not found');
    } else {
      print('❌ Server error: ${response.statusCode}');
      throw Exception('Server error: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Exception in getUserVehicles: $e');
    rethrow; // Re-throw to see the exact error in the UI
  }
}


  Future<void> deleteVehicle(String vehicleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      final response = await http.delete(
        Uri.parse('$baseUrl/vehicles/$vehicleId'),
        headers: {
          "Authorization": "Bearer $accessToken",
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete vehicle: ${response.statusCode}');
      }
      
      notifyVehicleDataChanged();
    } catch (e) {
      throw Exception('Failed to delete vehicle: $e');
    }
  }

  // Add these methods to your VehicleController class
Future<void> updateVehicle({
  required String vehicleId,
  required String userId,
  String? model,
  String? brand,
  int? year,
  String? type,
  String? fuelType,
  String? transmission,
  int? mileageKm,
  bool? isPrimary,
  bool? isActive,
}) async {
  isLoading.value = true;

  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    
    if (accessToken == null) {
      throw Exception('No authentication token found');
    }

    // Prepare update data - ensure lowercase transmission
    final Map<String, dynamic> body = {
      "user_id": userId,
      if (model != null) "model": model,
      if (brand != null) "brand": brand,
      if (year != null) "year": year,
      if (type != null) "type": type,
      if (fuelType != null) "fuel_type": fuelType,
      if (transmission != null) "transmission": transmission.toLowerCase(),
      if (mileageKm != null) "mileage_km": mileageKm,
      if (isPrimary != null) "is_primary": isPrimary,
      if (isActive != null) "is_active": isActive,
    };

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken",
    };

    final response = await http.put(
      Uri.parse('$baseUrl/vehicles/$vehicleId'),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      // Success - no need to show snackbar here, let the UI handle it
      print('✅ Vehicle updated successfully');
    } else {
      throw Exception('Failed to update vehicle: ${response.statusCode} - ${response.body}');
    }
    
      notifyVehicleDataChanged();
  } catch (e) {
    print('❌ Update vehicle error: $e');
    rethrow;
  } finally {
    isLoading.value = false;
  }
}
Future<void> fetchUserVehicles() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id"); // make sure you save this at login

    if (userId == null) {
      throw Exception("No userId found in storage");
    }

    await getUserVehicles(userId); // reuse your existing method
  } catch (e) {
    print("❌ fetchUserVehicles error: $e");
  }
}


Future<Map<String, dynamic>?> getVehicleById(String vehicleId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    
    if (accessToken == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/vehicles/$vehicleId'),
      headers: {
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch vehicle: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to fetch vehicle: $e');
  }
}

  @override
  void onClose() {
    super.onClose();
  }
}
