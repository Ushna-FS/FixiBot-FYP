import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/screens/auth/controller/google_sign_in_helper.dart';
import 'package:fixibot_app/screens/auth/controller/signUp_controller.dart';
import 'package:fixibot_app/widgets/custom_buttons.dart';
import 'package:fixibot_app/widgets/email_textField.dart';
import 'package:fixibot_app/widgets/password_textField.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SignupScreen extends StatefulWidget {
  SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final SignupController controller;
  late final GoogleSignInController googleController;

  @override
  void initState() {
    super.initState();
    // Register both controllers
    controller = Get.put(SignupController());
    googleController = Get.put(GoogleSignInController());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

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

                      // Username
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

                      // Email
                      EmailTextField(controller: controller.emailController),
                      SizedBox(height: screenSize.height * 0.012),

                      // Passwords (reactive toggles)
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text("Save password", style: TextStyle(color: AppColors.mainColor)),
                        ],
                      ),
                      SizedBox(height: screenSize.height * 0.001),

                      // Sign Up button
                      Obx(() => CustomButton(
                        onPressed: () {
                          if (!controller.isLoading.value) {
                            if (_formKey.currentState?.validate() ?? false) {
                              controller.signup();
                            }
                          }
                        },
                        text: "Sign Up",
                        isLoading: controller.isLoading.value,
                      )),

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

                      // Google Sign-In Button - SIMPLIFIED VERSION
                      Obx(() => CustomButton(
                        text: "Continue With Google",
                        onPressed: () {
                          if (!googleController.isLoading.value) {
                            googleController.signInWithGoogle();
                          }
                        },
                        isOutlined: true,
                        isLoading: googleController.isLoading.value,
                        icon: googleController.isLoading.value 
                            ? null 
                            : Image.asset('assets/icons/google.png', width: 20, height: 20),
                      )),
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












// import 'package:fixibot_app/constants/app_fontStyles.dart';
// import 'package:fixibot_app/constants/app_colors.dart';
// import 'package:fixibot_app/screens/auth/controller/google_sign_in_helper.dart';
// import 'package:fixibot_app/screens/auth/controller/signUp_controller.dart';
// import 'package:fixibot_app/widgets/custom_buttons.dart';
// import 'package:fixibot_app/widgets/email_textField.dart';
// import 'package:fixibot_app/widgets/password_textField.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';

// class SignupScreen extends StatefulWidget {
//   SignupScreen({super.key});

//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late final SignupController controller;

//   @override
//   void initState() {
//     super.initState();
//     // Register / get the controller exactly once
//     controller = Get.put(SignupController());
//   }

//   @override
//   void dispose() {
    
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final Size screenSize = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: AppColors.secondaryColor,
//       body: Stack(
//         children: [
//           Container(color: AppColors.secondaryColor),
//           Positioned(top: 0, right: 0, child: Image.asset('assets/icons/upper.png', height: 230)),
//           Positioned(bottom: 0, left: 0, child: Image.asset('assets/icons/lower.png', height: 230)),
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Center(
//               child: SingleChildScrollView(
//                 padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Container(
//                         decoration: const BoxDecoration(
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color: AppColors.mainSwatch,
//                               blurRadius: 10,
//                               offset: Offset.zero)
//                           ]),
//                         child: const CircleAvatar(
//                           backgroundColor: AppColors.secondaryColor,
//                           radius: 50,
//                           child: Icon(Icons.person, size: 60, color: AppColors.mainColor),
//                         ),
//                       ),
//                       SizedBox(height: screenSize.height * 0.02),
//                       Text("Sign Up For Smart Repairs!", style: AppFonts.montserratBlackHeading, textAlign: TextAlign.center,),
//                       SizedBox(height: screenSize.height * 0.02),

//                       // Username
//                       Container(
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(12),
//                           boxShadow: const [
//                             BoxShadow(
//                               color: Color.fromARGB(255, 129, 126, 126),
//                               blurRadius: 5,
//                               offset: Offset(2, 2)),
//                           ],
//                         ),
//                         child: TextFormField(
//                           controller: controller.usernameController,
//                           decoration: InputDecoration(
//                             contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
//                             prefixIcon: Icon(Icons.person, color: AppColors.mainColor.withOpacity(0.8)),
//                             hintText: "Username",
//                             hintStyle: TextStyle(color: Colors.grey.shade400),
//                             filled: true,
//                             fillColor: Colors.white,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide.none,
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(color: Colors.grey.shade300),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(color: AppColors.mainColor, width: 2.0),
//                             ),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) return 'Please enter a username';
//                             return null;
//                           },
//                         ),
//                       ),
//                       SizedBox(height: screenSize.height * 0.012),

//                       // Email
//                       EmailTextField(controller: controller.emailController),
//                       SizedBox(height: screenSize.height * 0.012),


// // Passwords (reactive toggles)
// Obx(() => PasswordTextField(
//   controller: controller.passwordController,
//   isPasswordVisible: controller.isPasswordVisible.value,
//   hintText: "Password",
// )),
// SizedBox(height: screenSize.height * 0.012),
// Obx(() => PasswordTextField(
//   controller: controller.confirmPasswordController,
//   isPasswordVisible: controller.isConfirmPasswordVisible.value,
//   hintText: "Confirm Password",
// )),
// SizedBox(height: screenSize.height * 0.012),

//   Container(
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(12),
//                           boxShadow: const [
//                             BoxShadow(
//                               color: Color.fromARGB(255, 129, 126, 126),
//                               blurRadius: 5,
//                               offset: Offset(2, 2)),
//                           ],
//                         ),
//                         child: TextFormField(
//                           controller: controller.phoneController,
//                           keyboardType: TextInputType.phone,
//                           inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                           decoration: InputDecoration(
//                             contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
//                             prefixIcon: Icon(Icons.phone, color: AppColors.mainColor.withOpacity(0.8)),
//                             hintText: "Phone (Optional)",
//                             hintStyle: TextStyle(color: Colors.grey.shade400),
//                             filled: true,
//                             fillColor: Colors.white,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide.none,
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(color: Colors.grey.shade300),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(color: AppColors.mainColor, width: 2.0),
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: screenSize.height * 0.001),

//       Row(
//   mainAxisAlignment: MainAxisAlignment.end,
//   children: [
//     const Text("Save password", style: TextStyle(color: AppColors.mainColor)),
//     // add a Switch here if you bind to an observable later
//   ],
// ),
// SizedBox(height: screenSize.height * 0.001),

// // Sign Up button (reactive on isLoading)
// Obx(() => CustomButton(
//   onPressed: () {
//     if (!controller.isLoading.value) {
//       if (_formKey.currentState?.validate() ?? false) {
//         controller.signup();
//       }
//     }
//   },
//   text: "Sign Up",
//   isLoading: controller.isLoading.value,
// )),

//                       SizedBox(height: screenSize.height * 0.015),

//                       Row(
//                         children: [
//                           const Expanded(child: Divider(thickness: 1)),
//                           Padding(
//                             padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.02),
//                             child: const Text("Or"),
//                           ),
//                           const Expanded(child: Divider(thickness: 1)),
//                         ],
//                       ),
//                       SizedBox(height: screenSize.height * 0.015),
//                       // In your SignupScreen, replace the Google button with:
// Obx(() => CustomButton(
//   text: "Continue With Google",
//   onPressed: () {
//     final googleController = Get.find<GoogleSignInController>();
//     if (!googleController.isLoading.value) {
//       googleController.signInWithGoogle();
//     }
//   },
//   isOutlined: true,
//   isLoading: Get.find<GoogleSignInController>().isLoading.value,
//   icon: Get.find<GoogleSignInController>().isLoading.value 
//       ? null 
//       : Image.asset('assets/icons/google.png', width: 20, height: 20),
// )),

//                       // CustomButton(
//                       //   text: "Continue With Google",
//                       //   onPressed: () {
//                       //     final googleController = Get.put(GoogleSignInController());
//                       //     googleController.signInWithGoogle();
//                       //   },
//                       //   isOutlined: true,
//                       //   icon: Image.asset('assets/icons/google.png', width: 20, height: 20),
//                       // ),

//                       SizedBox(height: screenSize.height * 0.02),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Text(
//                             "Already have an account? ",
//                             style: TextStyle(color: AppColors.textColor2, fontWeight: FontWeight.bold),
//                           ),
//                           GestureDetector(
//                             onTap: controller.signInNavigation,
//                             child: const Text(
//                               "LogIn",
//                               style: TextStyle(color: AppColors.mainColor, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
