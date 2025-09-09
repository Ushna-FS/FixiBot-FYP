import 'package:fixibot_app/bindings/initialBinding.dart';
import 'package:fixibot_app/screens/auth/view/verificationScreen.dart';
import 'package:fixibot_app/screens/mechanics/view/mechanicsScreen.dart';
import 'package:fixibot_app/screens/otp/controller/otpController.dart';
import 'package:fixibot_app/screens/otp/view/otpScreen.dart';
import 'package:fixibot_app/screens/profile/view/profile.dart';
import 'package:fixibot_app/screens/self-helpguide/selfHelpSolutionScreen.dart';
import 'package:fixibot_app/screens/vehicle/bindings/binding.dart';
import 'package:fixibot_app/screens/vehicle/view/addVehicle.dart';
import 'package:get/get.dart';
import '../screens/auth/view/login.dart';
import '../screens/auth/view/signup.dart';
import '../screens/homeScreen.dart';
import '../screens/location/locationScreen.dart';
import '../screens/search/searchScreen.dart';
import '../screens/splashScreen.dart';
import '../screens/userJourney.dart';
import 'app_routes.dart';

class AppPages {
  static final List<GetPage> pages = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(
      name: AppRoutes.signup,
      page: () => SignupScreen(),
      binding: InitialBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => Login(),
      binding: InitialBinding(),
    ),
    GetPage(
      name: AppRoutes.userJourney,
      page: () => const UserJourney(),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchScreen(),
    ),
    GetPage(
      name: AppRoutes.location,
      page: () => const LocationScreen(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
    ),
    // GetPage(
    //     name: AppRoutes.verification,
    //     page: () => const VerificationSentScreen()),
  GetPage(
  name: AppRoutes.selfhelp,
  page: () => SelfHelpSolutions(issueData: Get.arguments as Map<String, dynamic>),
),


GetPage(
      name: AppRoutes.addVehicle,
      page: () => AddVehicle(),
      binding: VehicleBinding(),
    ),

 GetPage(
      name: AppRoutes.mechanics,
      page: () => const MechanicScreen(),
    ),
     GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
    ),
GetPage(
  name: AppRoutes.otp,
  page: () => const OtpScreen(),
  binding: BindingsBuilder(() {
    Get.put(OtpController());
  }),
),


  ];
}