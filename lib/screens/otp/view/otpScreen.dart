import 'package:fixibot_app/screens/auth/view/signup.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../constants/app_fontStyles.dart';
import '../controller/otpController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/custom_buttons.dart';

class OtpScreen extends GetView<OtpController> {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    // ✅ Get email passed from Signup screen
    final String email = Get.arguments['email'] ?? "";

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      body: Stack(
        children: [
          Container(color: AppColors.secondaryColor),
          Positioned(
            top: 0,
            right: 0,
            child: Image.asset('assets/icons/upper.png'),
          ),
          Positioned(
            top: 15,
            left: 20,
            child: GestureDetector(
              onTap: () {
                // Back Button
                if (Get.key.currentState!.canPop()) {
                  Get.back();
                } else {
                  Get.off(SignupScreen()); // fallback
                }
              },
              child: Image.asset("assets/icons/backArrow.png"),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Image.asset('assets/icons/lower.png'),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.08,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.mainSwatch,
                            blurRadius: 10,
                            offset: Offset.zero,
                          )
                        ],
                      ),
                      child: const CircleAvatar(
                        backgroundColor: AppColors.secondaryColor,
                        radius: 50,
                        child: Icon(
                          Icons.mail,
                          size: 60,
                          color: AppColors.mainColor,
                        ),
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.02),
                    Text(
                      "Enter Passcode",
                      style: AppFonts.montserratAuthBlackHeading,
                    ),
                    SizedBox(height: screenSize.height * 0.02),
                    Text(
                      "OTP has been sent to your E-mail. Please enter ",
                      style: AppFonts.montserratGreyText14,
                    ),
                    Text(
                      "The Passcode. ",
                      style: AppFonts.montserratGreyText14,
                    ),
                    SizedBox(height: screenSize.height * 0.03),

                    PinCodeTextField(
                      appContext: context,
                      length: 6,  // 🔹 matches your backend OTP
                      keyboardType: TextInputType.number,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(8),
                        fieldHeight: 50,
                        fieldWidth: 40,
                        activeFillColor: Colors.white,
                      ),
                      onChanged: (value) {},
                      onCompleted: (verificationCode) {
                        controller.otpController.text = verificationCode;
                        controller.verifyEmailWithOtp(email);
                      },
                    ),

                    SizedBox(height: screenSize.height * 0.02),
                    Text(
                      "If you haven’t received a code! ",
                      style: AppFonts.montserratGreyText14,
                    ),
                    Obx(() => TextButton(
  onPressed: controller.canResend.value
      ? () => controller.resendOtp(email) // ✅ call resend
      : null, 
  child: controller.canResend.value
      ? Text(
          "Resend",
          style: AppFonts.montserratMainText14,
        )
      : Text(
          "Resend in ${controller.cooldownSeconds.value}s",
          style: AppFonts.montserratGreyText14,
        ),
)),

                    SizedBox(height: screenSize.height * 0.02),
                    CustomButton(
                      text: 'Verify',
                      onPressed: () {
                        controller.verifyEmailWithOtp(email); // ✅ fix
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
