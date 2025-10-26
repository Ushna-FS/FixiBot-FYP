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
    final String baseUrl = "https://chalky-anjelica-bovinely.ngrok-free.dev";
  RxList<Map<String,dynamic>> userVehicles = <Map<String,dynamic>>[].obs;
  
  var transmissionAuto = false.obs;
  final carModelYear = TextEditingController();
  final carMileage = TextEditingController();
  final registrationNumber = TextEditingController();
  
  var selectedModel = ''.obs;
  var selectedBrand = ''.obs;
  var selectedVehicleType = ''.obs;
  var selectedSubType = ''.obs;
  var selectedFuelType = ''.obs;
  var selectedTransmission = ''.obs;
  
  var isLoading = false.obs;
  var image = Rx<File?>(null);
  var imageBytes = Rx<Uint8List?>(null);

  void notifyVehicleDataChanged() {
    update();
  }

  void resetForm() {
    print('🔄 Resetting form...');
    
    // Clear Rx values
    selectedBrand.value = '';
    selectedModel.value = '';
    selectedVehicleType.value = '';
    selectedSubType.value = '';
    selectedFuelType.value = '';
    selectedTransmission.value = '';
    transmissionAuto.value = false;
    
    // Clear text controllers
    carModelYear.clear();
    carMileage.clear();
    registrationNumber.clear();
    
    // Clear images
    image.value = null;
    imageBytes.value = null;
    
    // Reset loading state
    isLoading.value = false;
    
    print('✅ Form cleared successfully');
  }

  Future<void> saveVehicle({
    required String userId,
    required bool isPrimary,
    required bool isActive,
  }) async {
    isLoading.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        Get.snackbar('Error', 'No authentication token found');
        isLoading.value = false;
        return;
      }

      // Debug: Print all form data
      print('📋 Vehicle Data to be sent:');
      print('user_id: $userId');
      print('model: ${selectedModel.value}');
      print('brand: ${selectedBrand.value}');
      print('year: ${carModelYear.text.trim()}');
      print('category: ${selectedVehicleType.value}');
      print('sub_type: ${selectedSubType.value}');
      print('fuel_type: ${selectedFuelType.value}');
      print('transmission: ${selectedTransmission.value}');
      print('mileage_km: ${carMileage.text.trim()}');
      print('registration_number: ${registrationNumber.text.trim()}');

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/vehicles/create'));
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Add required form fields
      request.fields['user_id'] = userId;
      request.fields['model'] = selectedModel.value;
      request.fields['category'] = selectedVehicleType.value;
      request.fields['fuel_type'] = selectedFuelType.value;
      request.fields['transmission'] = selectedTransmission.value;
      request.fields['mileage_km'] = carMileage.text.trim().isEmpty ? '0' : carMileage.text.trim();
      request.fields['is_primary'] = isPrimary.toString();
      request.fields['is_active'] = isActive.toString();

      // Add optional fields if they have values
      if (selectedBrand.value.isNotEmpty) {
        request.fields['brand'] = selectedBrand.value;
      }
      if (carModelYear.text.trim().isNotEmpty) {
        request.fields['year'] = carModelYear.text.trim();
      }
      if (selectedSubType.value.isNotEmpty) {
        request.fields['sub_type'] = selectedSubType.value;
      }
      if (registrationNumber.text.trim().isNotEmpty) {
        request.fields['registration_number'] = registrationNumber.text.trim();
      }

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
      }

      print('📦 Sending form data with fields: ${request.fields}');

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // SUCCESS - Clear form and show success message
        resetForm();
        
        Get.snackbar(
          "Success",
          "Vehicle saved successfully!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Refresh the vehicles list
        await fetchUserVehicles();
        
        // Navigate back after a short delay
        Future.delayed(Duration(milliseconds: 500), () {
          Get.back();
        });
        
      } else {
        // Server error
        String errorMessage = "Failed to save vehicle (Error: ${response.statusCode})";
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = "Server error: ${response.statusCode}\n${response.body}";
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
      
    } catch (e) {
      print('❌ Error saving vehicle: $e');
      Get.snackbar(
        "Error",
        "Failed to connect to server: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // FIXED API CALL - Use the correct endpoint
Future<List<dynamic>> getUserVehicles(String userId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    
    if (accessToken == null) {
      print('❌ No access token in getUserVehicles');
      throw Exception('No authentication token found. Please login again.');
    }

    print('🔍 Debug Info:');
    print('🔍 User ID: $userId');
    print('🔍 Access Token: ${accessToken.substring(0, 20)}...'); // First 20 chars for security
    print('🌐 Calling API: $baseUrl/vehicles/all');
    
    final response = await http.get(
      Uri.parse('$baseUrl/vehicles/all'),
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
      },
    ).timeout(Duration(seconds: 30));

    print('🌐 API Response Status: ${response.statusCode}');
    print('🌐 API Response Headers: ${response.headers}');
    print('🌐 API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Successfully parsed response data');
      
      userVehicles.assignAll(
        (data as List).map((e) => e as Map<String, dynamic>).toList(),
      );

      print('✅ Successfully loaded ${userVehicles.length} vehicles');
      return data is List ? data : [];
      
    } else if (response.statusCode == 401) {
      print('❌ Unauthorized - token may be expired or invalid');
      throw Exception('Authentication failed. Please login again.');
      
    } else if (response.statusCode == 404) {
      print('❌ Endpoint not found - trying alternative endpoints');
      // Try alternative endpoints
      return await _tryAlternativeEndpoints(userId, accessToken);
      
    } else if (response.statusCode == 500) {
      print('❌ Server error 500 - Backend issue');
      // Try to parse the error detail
      try {
        final errorData = jsonDecode(response.body);
        final errorDetail = errorData['detail'] ?? 'Internal server error';
        print('❌ Server error detail: $errorDetail');
        throw Exception('Server error: $errorDetail');
      } catch (e) {
        throw Exception('Internal server error. Please try again later.');
      }
    } else {
      print('❌ Unexpected error: ${response.statusCode}');
      throw Exception('Unexpected error: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Exception in getUserVehicles: $e');
    rethrow;
  }
}

// Try alternative endpoints if /vehicles/all fails
Future<List<dynamic>> _tryAlternativeEndpoints(String userId, String accessToken) async {
  final alternativeEndpoints = [
    '$baseUrl/vehicles',
    '$baseUrl/vehicles/user/$userId',
    '$baseUrl/vehicles?user_id=$userId',
  ];

  for (var endpoint in alternativeEndpoints) {
    try {
      print('🔄 Trying alternative endpoint: $endpoint');
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        userVehicles.assignAll(
          (data as List).map((e) => e as Map<String, dynamic>).toList(),
        );
        print('✅ Successfully loaded ${userVehicles.length} vehicles from $endpoint');
        return data is List ? data : [];
      }
    } catch (e) {
      print('❌ Failed with endpoint $endpoint: $e');
      continue;
    }
  }
  
  throw Exception('No working endpoint found for fetching vehicles');
}
  Future<void> fetchUserVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id");

      if (userId == null) {
        throw Exception("No userId found in storage");
      }

      await getUserVehicles(userId);
    } catch (e) {
      print("❌ fetchUserVehicles error: $e");
      // Show error to user
      Get.snackbar(
        "Error",
        "Failed to load vehicles: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
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

  // // Add these methods to your VehicleController class
  // Future<void> updateVehicle({
  //   required String vehicleId,
  //   required String userId,
  //   String? model,
  //   String? brand,
  //   int? year,
  //   String? type,
  //   String? fuelType,
  //   String? transmission,
  //   int? mileageKm,
  //   bool? isPrimary,
  //   bool? isActive,
  // }) async {
  //   isLoading.value = true;

  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final accessToken = prefs.getString('access_token');

  //     if (accessToken == null) {
  //       throw Exception('No authentication token found');
  //     }

  //     // Prepare update data - ensure lowercase transmission
  //     final Map<String, dynamic> body = {
  //       "user_id": userId,
  //       if (model != null) "model": model,
  //       if (brand != null) "brand": brand,
  //       if (year != null) "year": year,
  //       if (type != null) "type": type,
  //       if (fuelType != null) "fuel_type": fuelType,
  //       if (transmission != null) "transmission": transmission.toLowerCase(),
  //       if (mileageKm != null) "mileage_km": mileageKm,
  //       if (isPrimary != null) "is_primary": isPrimary,
  //       if (isActive != null) "is_active": isActive,
  //     };

  //     final headers = {
  //       "Content-Type": "application/json",
  //       "Authorization": "Bearer $accessToken",
  //     };

  //     final response = await http
  //         .put(
  //           Uri.parse('$baseUrl/vehicles/$vehicleId'),
  //           headers: headers,
  //           body: jsonEncode(body),
  //         )
  //         .timeout(Duration(seconds: 30));

  //     if (response.statusCode == 200) {
  //       // Success - no need to show snackbar here, let the UI handle it
  //       print('✅ Vehicle updated successfully');
  //     } else {
  //       throw Exception(
  //           'Failed to update vehicle: ${response.statusCode} - ${response.body}');
  //     }

  //     notifyVehicleDataChanged();
  //   } catch (e) {
  //     print('❌ Update vehicle error: $e');
  //     rethrow;
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }


Future<void> updateVehicle({
  required String vehicleId,
  required String userId,
  String? model,
  String? brand,
  int? year,
  String? category,
  String? subType,
  String? fuelType,
  String? transmission,
  int? mileageKm,
  String? registrationNumber,
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

    // Prepare update data
    final Map<String, dynamic> body = {
      "user_id": userId,
      if (model != null) "model": model,
      if (brand != null) "brand": brand,
      if (year != null) "year": year,
      if (category != null) "category": category,
      if (subType != null) "sub_type": subType,
      if (fuelType != null) "fuel_type": fuelType,
      if (transmission != null) "transmission": transmission,
      if (mileageKm != null) "mileage_km": mileageKm,
      if (registrationNumber != null) "registration_number": registrationNumber,
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
