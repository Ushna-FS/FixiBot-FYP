// import 'package:fixibot_app/screens/auth/controller/password_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../constants/app_colors.dart';
// import '../../../constants/app_fontStyles.dart';
// import 'package:fixibot_app/widgets/custom_buttons.dart';
// import 'package:fixibot_app/widgets/custom_textField.dart';


// class ForgotPasswordConfirmScreen extends StatelessWidget {
//   final ForgotPasswordController controller = Get.find();

//   ForgotPasswordConfirmScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: AppColors.secondaryColor,
//       appBar: AppBar(
//         backgroundColor: AppColors.secondaryColor,
//         title: Text("Reset Password", style: AppFonts.montserrathomecardText),
//         centerTitle: true,
//         leading: IconButton(
//           onPressed: () => Get.back(),
//           icon: Icon(Icons.arrow_back, color: Colors.white),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Center(
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 const CircleAvatar(
//                   backgroundColor: AppColors.mainColor,
//                   radius: 50,
//                   child: Icon(Icons.lock_open, size: 60, color: Colors.white),
//                 ),
//                 SizedBox(height: screenSize.height * 0.05),

//                 CustomTextField(
//                   controller: controller.otpController,
//                   hintText: "Enter OTP",
//                   icon: Icons.security,
//                   keyboardType: TextInputType.number,
//                 ),
//                 const SizedBox(height: 20),

//                 CustomTextField(
//                   controller: controller.passwordController,
//                   hintText: "Enter New Password",
//                   icon: Icons.lock,
//                   keyboardType: TextInputType.visiblePassword,
//                 ),
//                 const SizedBox(height: 30),

//                 Obx(() => CustomButton(
//                       text: "Confirm Reset",
//                       onPressed: controller.isLoading.value
//                           ? () {}
//                           : controller.confirmReset,
//                       color: AppColors.mainColor,
//                       textColor: Colors.white,
//                       isOutlined: false,
//                       icon: controller.isLoading.value
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : null,
//                     )),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }





import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/screens/auth/controller/password_controller.dart';
import 'package:fixibot_app/widgets/custom_buttons.dart';
import 'package:fixibot_app/widgets/custom_textField.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConfirmResetScreen extends StatelessWidget {
  ConfirmResetScreen({super.key});

  final ForgotPasswordController controller = Get.find<ForgotPasswordController>();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryColor,
        title: Text("Reset Password", style: AppFonts.montserrathomecardText),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Image.asset('assets/icons/back.png', width: 30, height: 30),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.mainColor,
                  radius: 50,
                  child: Icon(Icons.lock, size: 60, color: Colors.white),
                ),
                SizedBox(height: screenSize.height * 0.05),
                Text("Enter OTP & New Password", style: AppFonts.montserratBlackHeading),
                SizedBox(height: screenSize.height * 0.04),

                // Email
                CustomTextField(
                  controller: controller.emailController,
                  hintText: "Enter Email",
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // OTP
                CustomTextField(
                  controller: controller.otpController,
                  hintText: "Enter OTP",
                  icon: Icons.security,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                // New Password
                CustomTextField(
                  controller: controller.newPasswordController,
                  hintText: "Enter New Password",
                  icon: Icons.lock,
                  keyboardType: TextInputType.visiblePassword,
                ),

                SizedBox(height: screenSize.height * 0.04),
                Obx(() => CustomButton(
                      text: "Reset Password",
                      onPressed: controller.isLoading.value ? () {} : controller.confirmReset,
                      color: AppColors.mainColor,
                      textColor: Colors.white,
                      icon: controller.isLoading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : null,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
