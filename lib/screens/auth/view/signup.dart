import 'package:fixibot_app/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/custom_buttons.dart';
import '../../../widgets/custom_textField.dart';
import '../controller/signUp_controller.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SignupController controller = Get.put(SignupController());
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: screenSize.width * 0.12,
                  backgroundColor: AppColors.secondaryColor,
                  child: Icon(Icons.person,
                      size: screenSize.width * 0.15,
                      color: AppColors.mainColor),
                ),
                SizedBox(height: screenSize.height * 0.02),
                Text(
                  "Sign Up For Smart Repairs!",
                  style: TextStyle(
                      fontSize: screenSize.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor2),
                ),
                SizedBox(height: screenSize.height * 0.02),
                CustomTextField(
                  hintText: "Username or Email",
                  icon: Icons.person,
                  controller: controller.usernameController,
                ),
                SizedBox(height: screenSize.height * 0.015),
                CustomTextField(
                  hintText: "E-mail",
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  controller: controller.emailController,
                ),
                SizedBox(height: screenSize.height * 0.015),
                Obx(() => CustomTextField(
                      hintText: "Password",
                      icon: Icons.lock,
                      isPassword: !controller.isPasswordVisible.value,
                      controller: controller.passwordController,
                    )),
                SizedBox(height: screenSize.height * 0.015),
                Obx(() => CustomTextField(
                      hintText: "Confirm Password",
                      icon: Icons.lock,
                      isPassword: !controller.isConfirmPasswordVisible.value,
                      controller: controller.confirmPasswordController,
                    )),
                SizedBox(height: screenSize.height * 0.015),
                CustomTextField(
                  hintText: "Phone (Optional)",
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  controller: controller.phoneController,
                ),
                SizedBox(height: screenSize.height * 0.015),
                Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Save password",
                            style: TextStyle(color: AppColors.mainColor)),
                        Switch(
                          inactiveThumbColor: AppColors.mainColor,
                          activeColor: AppColors.mainColor,
                          value: controller.savePassword.value,
                          onChanged: (value) => controller.toggleSavePassword(),
                        ),
                      ],
                    )),
                SizedBox(height: screenSize.height * 0.02),
                CustomButton(
                  text: "Sign Up",
                  onPressed: controller.signup,
                ),
                SizedBox(height: screenSize.height * 0.02),
                Row(
                  children: [
                    Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.02),
                      child: Text("Or"),
                    ),
                    Expanded(child: Divider(thickness: 1)),
                  ],
                ),
                SizedBox(height: screenSize.height * 0.02),
                CustomButton(
                  text: "Continue With Google",
                  onPressed: controller.googleSignIn,
                  isOutlined: true,
                  icon: Image.asset(
                    'assets/icons/google.png',
                    width: 20,
                    height: 20,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(
                          color: AppColors.textColor2,
                          fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: controller.signInNavigation,
                      child: const Text(
                        "Sign In",
                        style: TextStyle(
                            color: AppColors.mainColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenSize.height * 0.01),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
