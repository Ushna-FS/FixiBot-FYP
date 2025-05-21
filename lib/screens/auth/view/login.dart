import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/widgets/custom_buttons.dart';
import 'package:fixibot_app/widgets/email_textField.dart';
import 'package:fixibot_app/widgets/password_textField.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/login_controller.dart';

class Login extends StatelessWidget {
  Login({super.key});

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final LoginController controller = Get.find<LoginController>();

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      body: Stack(
        children: [
          Container(color: AppColors.secondaryColor),
          Positioned(top: 0, right: 0, child: Image.asset('assets/icons/upper.png', height: 230)),
          Positioned(bottom: 0, left: 0, child: Image.asset('assets/icons/lower.png', height: 230)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08),
                child: Form(
                  key: _formKey,
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
                          child: Icon(Icons.person, size: 60, color: AppColors.mainColor),
                        ),
                      ),
                      SizedBox(height: screenSize.height * 0.05),
                      Text("Start Your Journey Here!", style: AppFonts.montserratBlackHeading, textAlign: TextAlign.center,),
                      SizedBox(height: screenSize.height * 0.04),
                      EmailTextField(
                        controller: controller.emailController,
                        hintText: "Username or Email",
                      ),
                      SizedBox(height: screenSize.height * 0.015),
                      Obx(() => PasswordTextField(
                        controller: controller.passwordController,
                        isPasswordVisible: controller.isPasswordVisible.value,
                      )),
                      SizedBox(height: screenSize.height * 0.015),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text("Forget password", style: TextStyle(color: AppColors.mainColor)),
                        ],
                      ),
                      SizedBox(height: screenSize.height * 0.02),
                      CustomButton(
                        text: "Login",
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            controller.login();
                          }
                        },
                        isLoading: controller.isLoading.value,
                      ),
                      SizedBox(height: screenSize.height * 0.02),
                      Row(
                        children: [
                          const Expanded(child: Divider(thickness: 1)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.02),
                            child: const Text("Or"),
                          ),
                          const Expanded(child: Divider(thickness: 1)),
                        ],
                      ),
                      SizedBox(height: screenSize.height * 0.02),
                      CustomButton(
                        text: "Continue With Google",
                        isOutlined: true,
                        icon: Image.asset('assets/icons/google.png', width: 20, height: 20),
                        onPressed: controller.googleSignIn,
                      ),
                      SizedBox(height: screenSize.height * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: AppColors.textColor2, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: controller.LogInNavigation,
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(color: AppColors.mainColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}