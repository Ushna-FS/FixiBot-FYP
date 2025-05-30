import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/screens/auth/controller/signUp_controller.dart';
import 'package:fixibot_app/widgets/custom_buttons.dart';
import 'package:fixibot_app/widgets/email_textField.dart';
import 'package:fixibot_app/widgets/password_textField.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SignupScreen extends StatelessWidget {
  SignupScreen({super.key});

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final SignupController controller = Get.find<SignupController>();

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
                      SizedBox(height: screenSize.height * 0.02),
                      Text("Sign Up For Smart Repairs!", style: AppFonts.montserratBlackHeading, textAlign: TextAlign.center,),
                      SizedBox(height: screenSize.height * 0.02),
                      
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromARGB(255, 129, 126, 126),
                              blurRadius: 5,
                              offset: Offset(2, 2)),
                          ],
                        ),
                        child: TextFormField(
                          controller: controller.usernameController,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            prefixIcon: Icon(Icons.person, color: AppColors.mainColor.withOpacity(0.8)),
                            hintText: "Username",
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.mainColor, width: 2.0),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter a username';
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: screenSize.height * 0.012),
                      EmailTextField(controller: controller.emailController),
                      SizedBox(height: screenSize.height * 0.012),
                      Obx(() => PasswordTextField(
                        controller: controller.passwordController,
                        isPasswordVisible: controller.isPasswordVisible.value,
                        hintText: "Password",
                      )),
                      SizedBox(height: screenSize.height * 0.012),
                      Obx(() => PasswordTextField(
                        controller: controller.confirmPasswordController,
                        isPasswordVisible: controller.isConfirmPasswordVisible.value,
                        hintText: "Confirm Password",
                      )),
                      SizedBox(height: screenSize.height * 0.012),
                      // Phone Field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromARGB(255, 129, 126, 126),
                              blurRadius: 5,
                              offset: Offset(2, 2)),
                          ],
                        ),
                        child: TextFormField(
                          controller: controller.phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            prefixIcon: Icon(Icons.phone, color: AppColors.mainColor.withOpacity(0.8)),
                            hintText: "Phone (Optional)",
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.mainColor, width: 2.0),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenSize.height * 0.001),
                      Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text("Save password", style: TextStyle(color: AppColors.mainColor)),
                          Switch(
                            inactiveThumbColor: AppColors.mainColor,
                            activeColor: AppColors.mainColor,
                            value: controller.savePassword.value,
                            onChanged: (value) => controller.toggleSavePassword(),
                          ),
                        ],
                      )),
                      SizedBox(height: screenSize.height * 0.001),
                      CustomButton(
                        text: "Sign Up",
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            controller.signup();
                          }
                        },
                        isLoading: controller.isLoading.value,
                      ),
                      SizedBox(height: screenSize.height * 0.015),
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
                      SizedBox(height: screenSize.height * 0.015),
                      CustomButton(
                        text: "Continue With Google",
                        onPressed: controller.googleSignIn,
                        isOutlined: true,
                        icon: Image.asset('assets/icons/google.png', width: 20, height: 20),
                      ),
                      SizedBox(height: screenSize.height * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account? ",
                            style: TextStyle(color: AppColors.textColor2, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: controller.signInNavigation,
                            child: const Text(
                              "LogIn",
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