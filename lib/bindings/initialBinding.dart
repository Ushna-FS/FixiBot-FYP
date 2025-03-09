import 'package:fixibot_app/screens/mechanics/view/controller/mechanicController.dart';
import 'package:get/get.dart';

import '../screens/auth/controller/login_controller.dart';
import '../screens/auth/controller/signUp_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController(), fenix: true);
    Get.lazyPut<SignupController>(() => SignupController(), fenix: true);
    Get.lazyPut<MechanicController>(() => MechanicController(), fenix: true);
  }
}
