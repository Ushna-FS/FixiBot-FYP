import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/widgets/custom_textField.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:fixibot_app/screens/auth/controller/login_controller.dart';
import '../../../widgets/custom_buttons.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final LoginController controller = Get.put((LoginController()));

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      body: Stack(
        children: [
          Container(
            color: AppColors.secondaryColor,
          ),
          Positioned(
              top: 0,
              right: 0,
              child: Image.asset('assets/icons/upperTyre.png')),
          Positioned(
              bottom: 0,
              left: 0,
              child: Image.asset('assets/icons/lowerTyre.png')),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.symmetric(horizontal: screenSize.width * 0.08),
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
                        child: Icon(Icons.person,
                            size: 60, color: AppColors.mainColor),
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.05),
                    const Text(
                      "Start Your Journey Here!",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor2),
                    ),
                    SizedBox(height: screenSize.height * 0.04),
                    const CustomTextField(
                      hintText: "Username or Email",
                      icon: Icons.person,
                    ),
                    SizedBox(height: screenSize.height * 0.015),
                    Obx(() => CustomTextField(
                          hintText: "Password",
                          icon: Icons.lock,
                          isPassword: !controller.isPasswordVisible.value,
                          controller: controller.passwordController,
                        )),
                    SizedBox(height: screenSize.height * 0.015),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("Forget password",
                            style: TextStyle(color: AppColors.mainColor)),
                      ],
                    ),
                    SizedBox(height: screenSize.height * 0.02),
                    CustomButton(
                      text: "Login",
                      onPressed: controller.login,
                    ),
                    SizedBox(height: screenSize.height * 0.02),
                    Row(
                      children: [
                        const Expanded(child: Divider(thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenSize.width * 0.02),
                          child: const Text("Or"),
                        ),
                        const Expanded(child: Divider(thickness: 1)),
                      ],
                    ),
                    SizedBox(height: screenSize.height * 0.02),
                    CustomButton(
                      text: "Continue With Google",
                      isOutlined: true,
                      icon: Image.asset(
                        'assets/icons/google.png',
                        width: 20,
                        height: 20,
                      ),
                      onPressed: () {},
                    ),
                    SizedBox(height: screenSize.height * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                              color: AppColors.textColor2,
                              fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: controller.LogInNavigation,
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                                color: AppColors.mainColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenSize.height * 0.001),
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
