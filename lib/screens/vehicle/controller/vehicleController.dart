import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class VehicleController extends GetxController {
  var transmissionAuto = false.obs;
  final carManufacturer = TextEditingController();
  final carModel = TextEditingController();
  final carModelYear = TextEditingController();
  var image = Rx<File?>(null);

  void toggleTransmission() {
    transmissionAuto.value = !transmissionAuto.value;
  }

  Future<void> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      image.value = File(pickedFile.path);
    }
  }
}
