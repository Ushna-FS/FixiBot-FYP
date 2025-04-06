import 'package:get/get.dart';

class MechanicController extends GetxController {
  var mechanicCategories = [].obs;
  var isNotified = RxBool(false);
  var location = 'COMSATS UNIVERSITY ISLAMABAD'.obs;
   void notificationSelection() {
    print("category selection");
    if (isNotified.value == false) {
      isNotified.value = true;
    } else {
      isNotified.value = false;
      }
  }

}
