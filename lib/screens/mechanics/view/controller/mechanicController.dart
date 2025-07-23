import 'package:fixibot_app/screens/location/location_controller.dart';
import 'package:get/get.dart';

class MechanicController extends GetxController {
  var mechanicCategories = [].obs;
  var isNotified = RxBool(false);
  final LocationController locationController = Get.put(LocationController());
   void notificationSelection() {
    print("category selection");
    if (isNotified.value == false) {
      isNotified.value = true;
    } else {
      isNotified.value = false;
      }
  }
@override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    
  final LocationController locationController = Get.put(LocationController());
  }
}
