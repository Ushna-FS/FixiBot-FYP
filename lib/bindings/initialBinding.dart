import 'package:fixibot_app/screens/otp/controller/otpController.dart';
import 'package:fixibot_app/screens/vehicle/controller/vehicleController.dart';

import '../screens/mechanics/view/controller/mechanicController.dart';
import 'package:get/get.dart';

import '../screens/auth/controller/login_controller.dart';
import '../screens/auth/controller/signUp_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    print('InitialBinding dependencies called');
    Get.lazyPut<LoginController>(() => LoginController(), fenix: true);
    Get.lazyPut<SignupController>(() => SignupController(), fenix: true);
    Get.lazyPut<MechanicController>(() => MechanicController(), fenix: true);
    Get.lazyPut<OtpController>(() => OtpController(), fenix: true);
    Get.lazyPut<VehicleController>(()=>VehicleController(),fenix: true);
    Get.lazyPut<MechanicController>(()=>MechanicController(),fenix: true);

  }
}
