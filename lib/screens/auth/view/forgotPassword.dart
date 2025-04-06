import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/screens/auth/controller/password_controller.dart';
import 'package:fixibot_app/widgets/custom_buttons.dart';
import 'package:fixibot_app/widgets/custom_textField.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';



class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key});

  final ForgotPasswordController controller = Get.put(ForgotPasswordController());

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: AppBar(backgroundColor: AppColors.secondaryColor,title: Text("Forgot Password",style: AppFonts.montserrathomecardText,),
      centerTitle: true, leading: IconButton(
                    onPressed: () {
                      Get.back();
                    }, 
                    icon: Image.asset('assets/icons/back.png',
                    width: 30,
                    height:30),
                    ),),
      
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
                  child: Icon(Icons.lock_reset, size: 60, color: Colors.white),
                ),
                SizedBox(height: screenSize.height * 0.05),
                Text(
                  "Forgot your password?",
                  style: AppFonts.montserratBlackHeading,
                ),
                SizedBox(height: screenSize.height * 0.04),
                CustomTextField(
  controller: controller.emailController, 
  hintText: "Enter Email",
  icon: Icons.email,
  keyboardType: TextInputType.emailAddress, 
),

                SizedBox(height: screenSize.height * 0.02),
Container(
  margin: EdgeInsets.symmetric(horizontal: 60,vertical: 20), // Add horizontal margin
  child: Obx(() => CustomButton(
        text: "Send Reset Link",
        onPressed: controller.isLoading.value ? () {} : controller.resetPassword,
        color: AppColors.mainColor,
        textColor: Colors.white,
        isOutlined: false,
        icon: controller.isLoading.value
            ? const CircularProgressIndicator(color: Colors.white)
            : null,
      )),
),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
