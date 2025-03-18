import 'package:fixibot_app/screens/homeScreen.dart';
import 'package:fixibot_app/screens/vehicle/view/addVehicle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtpController extends GetxController {
  void verification() {
    Get.to(AddVehicle());
  }
}
