import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class VehicleController extends GetxController {
  var transmissionAuto = false.obs;
  final carManufacturer = TextEditingController();
  final carModel = TextEditingController();
  final carModelYear = TextEditingController();
  var image = Rx<File?>(null);
  var imageBytes = Rx<Uint8List?>(null); // For web support

  void toggleTransmission() {
    transmissionAuto.value = !transmissionAuto.value;
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile != null) {
        if (kIsWeb) {
          // For web
          final bytes = await pickedFile.readAsBytes();
          imageBytes.value = bytes;
          image.value = null;
        } else {
          // For mobile
          image.value = File(pickedFile.path);
          imageBytes.value = null;
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

  @override
  void onClose() {
    carManufacturer.dispose();
    carModel.dispose();
    carModelYear.dispose();
    super.onClose();
  }
}