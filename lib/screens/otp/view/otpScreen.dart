import '../../../constants/app_fontStyles.dart';
import '../controller/otpController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/custom_buttons.dart';

class OtpScreen extends GetView<OtpController> {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: AppColors.secondaryColor,
        body: Stack(children: [
          Container(
            color: AppColors.secondaryColor,
          ),
          Positioned(
              top: 0,
              right: 0,
              child: Image.asset('assets/icons/upperTyre.png')),
          Positioned(
            top: 15,
            left: 20,
            child: GestureDetector(
              onTap: () {
                //Back Button
                Get.back();
              },
              child: Image.asset("assets/icons/backArrow.png"),
            ),
          ),
          Positioned(
              bottom: 0,
              left: 0,
              child: Image.asset('assets/icons/lowerTyre.png')),
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                  child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.08),
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
                                        offset: Offset.zero)
                                  ]),
                              child: const CircleAvatar(
                                backgroundColor: AppColors.secondaryColor,
                                radius: 50,
                                child: Icon(Icons.mail,
                                    size: 60, color: AppColors.mainColor),
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
                            OtpTextField(
                              numberOfFields: 5,
                              focusedBorderColor: AppColors.mainColor,
                              borderColor: AppColors.textColor2,
                              enabledBorderColor: AppColors.textColor2,
                              showFieldAsBox: true,
                              borderWidth: 1,
                              onCodeChanged: (String code) {},
                              //runs when every textfield is filled
                              onSubmit: (String verificationCode) {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text("Verification Code"),
                                        content: Text(
                                            'Code entered is $verificationCode'),
                                      );
                                    });
                              },
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            Text(
                              "If you haven’t received a code! ",
                              style: AppFonts.montserratGreyText14,
                            ),
                            TextButton(
                              child: Text(
                                "Resend",
                                style: AppFonts.montserratMainText14,
                              ),
                              onPressed: () {
                                // TODO: Resend Verification Code function
                              },
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            CustomButton(
                              text: 'Verify',
                              onPressed: () {
                                // TODO: Call Verification function
                                controller.verification();
                              },
                            ),
                          ]))))
        ]));
  }
}
