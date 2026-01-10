import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:fixibot_app/constants/appConfig.dart';
import 'package:fixibot_app/constants/app_errors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

class VehicleController extends GetxController {
  final baseUrl = AppConfig.baseUrl;

  RxList<Map<String, dynamic>> userVehicles = <Map<String, dynamic>>[].obs;
  
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
  var hasError = false.obs;
var errorMessage = ''.obs;

  void notifyVehicleDataChanged() {
    update();
  }

  void resetForm() {
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
  }

  Future<void> saveVehicle({
    required bool isPrimary,
    required bool isActive,
  }) async {
    isLoading.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final userId = await getValidUserId();

      // Use AppErrors for validation messages
      if (accessToken == null || accessToken.isEmpty) {
        AppErrors.showError("Please login first");
        isLoading.value = false;
        return;
      }

      if (userId == null || userId.isEmpty) {
        AppErrors.showError("User session expired. Please login again.");
        isLoading.value = false;
        return;
      }

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

      // Add optional fields
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
        request.files.add(
          http.MultipartFile.fromBytes(
            'images',
            imageBytes.value!,
            filename: 'vehicle_image.jpg',
            contentType: MediaType('image', 'jpeg'),
          )
        );
      } else if (!kIsWeb && image.value != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            image.value!.path,
            contentType: MediaType('image', 'jpeg'),
          )
        );
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // SUCCESS
        resetForm();
        Get.back();
        
        // Use AppErrors for success message
        AppErrors.showSuccess("Vehicle saved successfully!");
        
        // Refresh the vehicles list
        await fetchUserVehicles();
      } else {
        // Use AppErrors for error handling
        AppErrors.showError(
          AppErrors.parseServerError(response.body),
          statusCode: response.statusCode
        );
      }
    } catch (e) {
      // Use AppErrors for exception handling
      AppErrors.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> getValidUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null || userId.isEmpty) {
        return null;
      }
      
      // Validate MongoDB ObjectId format
      final isValidObjectId = RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(userId);
      if (!isValidObjectId) {
        return null;
      }
      
      return userId;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      return userId;
    } catch (e) {
      return null;
    }}
  // In VehicleController.dart, update getUserVehicles method:
Future<List<dynamic>> getUserVehicles(String userId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    
    // Check connectivity first
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception("Please login again");
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/vehicles/all'),
      headers: {
        "Authorization": "Bearer $accessToken",
      },
    ).timeout(Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      userVehicles.assignAll(
        (data as List).map((e) => e as Map<String, dynamic>).toList(),
      );
      
      return data is List ? data : [];
    } else {
      throw Exception("Failed to load vehicles");
    }
  } catch (e) {
    // Re-throw to be handled by UI
    throw Exception(e);
  }
}

Future<void> fetchUserVehicles() async {
  try {
    hasError.value = false;
    errorMessage.value = '';
    isLoading.value = true;
    
    final userId = await getCurrentUserId();
    
    if (userId == null) {
      throw Exception("User not logged in");
    }
    
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception("No authentication token found");
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/vehicles/all'),
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
      },
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Check if response is valid
      if (data is! List) {
        throw Exception("Invalid response format");
      }
      
      userVehicles.assignAll(
        data.map((e) => e as Map<String, dynamic>).toList(),
      );
      
      hasError.value = false;
      errorMessage.value = '';
    } else {
      // SERVER ERROR - status code not 200
      hasError.value = true;
      
      // Check for server error status codes
      if (response.statusCode >= 500 && response.statusCode < 600) {
        errorMessage.value = "Server error. Please try later.";
      } else {
        errorMessage.value = "Failed to load vehicles ( Server Error ${response.statusCode})";
      }
      
      // Don't clear vehicles - show cached data if available
    }
  } catch (e) {
    hasError.value = true;
    
    // IMPORTANT: Check for server-related errors FIRST
    final errorStr = e.toString().toLowerCase();
    
    // Check for SocketException with server-related messages
    if (errorStr.contains('failed host lookup') || 
        errorStr.contains('connection refused') ||
        errorStr.contains('connection reset') ||
        errorStr.contains('software caused connection abort')) {
      // These are server connection errors, not internet errors
      errorMessage.value = "Cannot connect to server. Server may be down.";
    } 
    // Check for timeout (could be server busy)
    else if (errorStr.contains('timeout')) {
      errorMessage.value = "Server is taking too long to respond.";
    }
    // Check for HTTP errors
    else if (errorStr.contains('http') && errorStr.contains('5')) {
      errorMessage.value = "Server error. Please try later.";
    }
    // Check for internet connectivity errors
    else if (errorStr.contains('socket') || 
             errorStr.contains('network is unreachable') ||
             e is SocketException) {
      errorMessage.value = "No internet connection";
    }
    // Default error
    else {
      errorMessage.value = AppErrors.humanReadableError(e);
    }
    
    // Show snackbar
    AppErrors.showError(errorMessage.value);
  } finally {
    isLoading.value = false;
  }
}

  Future<void> _tryAlternativeEndpoints(String userId, String accessToken) async {
    final alternativeEndpoints = [
      '$baseUrl/vehicles',
      '$baseUrl/vehicles/user/$userId',
      '$baseUrl/vehicles?user_id=$userId',
    ];

    for (var endpoint in alternativeEndpoints) {
      try {
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
          return;
        }
      } catch (e) {
        continue;
      }
    }
    
    throw Exception('No working endpoint found for fetching vehicles');
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
        } else {
          image.value = File(pickedFile.path);
          imageBytes.value = null;
        }
      }
    } catch (e) {
      // Use AppErrors for image picking errors
      AppErrors.showError("Failed to pick image: ${e.toString()}");
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

      if (response.statusCode == 200 || response.statusCode == 204) {
        notifyVehicleDataChanged();
        AppErrors.showSuccess("Vehicle deleted successfully!");
        await fetchUserVehicles();
      } else {
        throw Exception(AppErrors.parseServerError(response.body));
      }
    } catch (e) {
      AppErrors.showError(e);
    }
  }

  Future<void> loadVehicleImage(String imageUrl) async {
    try {
      if (kIsWeb) {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          imageBytes.value = response.bodyBytes;
          image.value = null;
        }
      } else {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          final appDir = await getTemporaryDirectory();
          final filePath = '${appDir.path}/vehicle_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);
          image.value = file;
          imageBytes.value = null;
        }
      }
    } catch (e) {
      // Reset image states if loading fails
      image.value = null;
      imageBytes.value = null;
    }
  }

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
    File? imageFile,
    Uint8List? imageBytes,
    String? existingImageUrl,
  }) async {
    isLoading.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken == null) {
        throw Exception('No authentication token found');
      }

      final hasNewImage = (!kIsWeb && imageFile != null) || (kIsWeb && imageBytes != null);
      
      if (hasNewImage) {
        await _updateVehicleWithImage(
          vehicleId: vehicleId,
          userId: userId,
          accessToken: accessToken,
          model: model,
          brand: brand,
          year: year,
          category: category,
          subType: subType,
          fuelType: fuelType,
          transmission: transmission,
          mileageKm: mileageKm,
          registrationNumber: registrationNumber,
          isPrimary: isPrimary,
          isActive: isActive,
          imageFile: imageFile,
          imageBytes: imageBytes,
        );
      } else {
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

        if (response.statusCode != 200) {
          throw Exception(AppErrors.parseServerError(response.body));
        }
      }
      
      notifyVehicleDataChanged();
      AppErrors.showSuccess("Vehicle updated successfully!");
    } catch (e) {
      AppErrors.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateVehicleWithImage({
    required String vehicleId,
    required String userId,
    required String accessToken,
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
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/vehicles/$vehicleId'),
    );

    request.headers['Authorization'] = 'Bearer $accessToken';

    request.fields['user_id'] = userId;
    if (model != null) request.fields['model'] = model;
    if (brand != null) request.fields['brand'] = brand;
    if (year != null) request.fields['year'] = year.toString();
    if (category != null) request.fields['category'] = category;
    if (subType != null) request.fields['sub_type'] = subType;
    if (fuelType != null) request.fields['fuel_type'] = fuelType;
    if (transmission != null) request.fields['transmission'] = transmission;
    if (mileageKm != null) request.fields['mileage_km'] = mileageKm.toString();
    if (registrationNumber != null) request.fields['registration_number'] = registrationNumber;
    if (isPrimary != null) request.fields['is_primary'] = isPrimary.toString();
    if (isActive != null) request.fields['is_active'] = isActive.toString();

    if (!kIsWeb && imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'images',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        )
      );
    } else if (kIsWeb && imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          imageBytes,
          filename: 'vehicle_image.jpg',
          contentType: MediaType('image', 'jpeg'),
        )
      );
    }

    final streamedResponse = await request.send().timeout(Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(AppErrors.parseServerError(response.body));
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
        throw Exception(AppErrors.parseServerError(response.body));
      }
    } catch (e) {
      AppErrors.showError(e);
      return null;
    }
  }

  @override
  void onClose() {
    carModelYear.dispose();
    carMileage.dispose();
    registrationNumber.dispose();
    super.onClose();
  }
}