import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:fixibot_app/widgets/custom_buttons.dart';
import 'package:fixibot_app/widgets/custom_textField.dart';
import 'package:flutter/material.dart';
import 'package:fixibot_app/constants/app_colors.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class HelpSupportPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Text("Help Center", style: AppFonts.montserrathomecardText),
        centerTitle: true,
        leading: IconButton(
                    onPressed: () {
                      Get.back();
                    }, 
                    icon: Image.asset('assets/icons/back.png',
                    width: 30,
                    height:30),
                    ),
      ),
      backgroundColor: AppColors.secondaryColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        
        child: Column(
          
        
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Need Help?',
              style:AppFonts.montserratBlackHeading,
            ),
            const SizedBox(height: 10),
            
            Text(
              'If you have any issues, feel free to reach out to us.',
              style: TextStyle(fontSize: 16, color: AppColors.textColor),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              hintText: 'Your Name',
              icon: Icons.person,
              controller: nameController,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 15),
            CustomTextField(
              hintText: 'Your Email',
              icon: Icons.email,
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),
            CustomTextField(
              hintText: 'Your Message',
              icon: Icons.message,
              controller: messageController,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Submit',
              onPressed: () {
                // Handle form submission logic
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'You can also contact us at support@fixibot.com',
                style: TextStyle(fontSize: 14, color: AppColors.textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
