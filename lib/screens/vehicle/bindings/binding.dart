// Add this binding class
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';
import 'package:get/get.dart';

class VehicleBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => VehicleController());
  }
}