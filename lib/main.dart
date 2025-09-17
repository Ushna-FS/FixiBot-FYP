import 'package:fixibot_app/screens/homeScreen.dart';
import 'package:fixibot_app/screens/location/location_controller.dart';
import 'package:fixibot_app/screens/profile/controller/userController.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bindings/initialBinding.dart';
import 'screens/splashScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'constants/app_colors.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs);

  Get.put(LocationController()); 
  Get.put(UserController()); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialBinding: InitialBinding(),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      getPages: AppPages.pages,
      initialRoute: AppRoutes.splash,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        primarySwatch: AppColors.mainSwatch,
      ),
    );
  }
}
