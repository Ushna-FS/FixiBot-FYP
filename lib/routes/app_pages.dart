import 'package:fixibot_app/screens/searchScreen.dart';
import 'package:get/get.dart';

import '../screens/auth/view/login.dart';
import '../screens/auth/view/signup.dart';
import '../screens/splashScreen.dart';
import '../screens/user_journey.dart';
import 'app_routes.dart';

class AppPages {
  static final List<GetPage> pages = [
    GetPage(name: AppRoutes.splash, page: () => const Splashscreen()),
    GetPage(
        name: AppRoutes.signup,
        page: () => const SignupScreen(),),
    GetPage(
        name: AppRoutes.login,
        page: () => const Login(),),
    GetPage(
    name: AppRoutes.userJourney,
    page: () => const UserJourney(),),
    GetPage(
    name: AppRoutes.search,
    page: () => const SearchScreen(),),
  ];
}
