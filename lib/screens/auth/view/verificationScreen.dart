// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:fixibot_app/widgets/custom_buttons.dart';
// import '../../../constants/app_colors.dart';
// import '../controller/signUp_controller.dart';
// import 'login.dart';

// class VerificationSentScreen extends StatelessWidget {
//   const VerificationSentScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final SignupController controller = Get.find<SignupController>();


//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.mark_email_read_outlined,
//                 size: 100,
//                 color: AppColors.mainColor,
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 "Verification Email Sent!",
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey[800],
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 "We've sent a verification link to your email address. "
//                 "Please check your inbox and click on the link to verify your account.",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 32),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       "Didn't receive the email?",
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Obx(() => Column(
//                       children: [
//                         if (!controller.canResendEmail.value)
//                           Text(
//                             "You can resend in",
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         if (!controller.canResendEmail.value)
//                           Text(
//                             "${controller.cooldownSeconds.value} seconds",
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: AppColors.mainColor,
//                             ),
//                           ),
//                         const SizedBox(height: 8),
//                         TextButton(
//                           onPressed: controller.canResendEmail.value
//                               ? controller.resendVerificationEmail
//                               : null,
//                           child: Text(
//                             "Resend Verification Email",
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                               color: controller.canResendEmail.value
//                                   ? AppColors.mainColor
//                                   : Colors.grey,
//                             ),
//                           ),
//                         ),
//                       ],
//                     )),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 32),
//               SizedBox(
//                 width: double.infinity,
//                 child: CustomButton(
//                   onPressed: () {
//                     Get.offAll(() =>  Login());
//                   },
//                   text: "Back to Login",
//                   isLoading: false,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

