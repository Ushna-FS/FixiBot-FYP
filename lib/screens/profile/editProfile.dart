import 'package:fixibot_app/widgets/custom_buttons.dart';
import 'package:fixibot_app/widgets/custom_textField.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_fontStyles.dart';

class EditProfile extends StatefulWidget {
  final String currentName;
  final String currentEmail;

  const EditProfile({super.key, required this.currentName, required this.currentEmail});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late TextEditingController nameController;
  late TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: AppBar(
        elevation: 1,
     backgroundColor: AppColors.secondaryColor,
        title: Text("Edit Profile", style: AppFonts.montserrathomecardText),
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  backgroundColor: AppColors.textColor4,
                  radius: 40,
                  child: Image.asset("assets/icons/profileImg.png"),
                ),
              ),
              const SizedBox(height: 20),
              Text("Name", style: AppFonts.montserratText),
          CustomTextField(
            controller: nameController,
            hintText: "Enter your name",
            icon: Icons.person,
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 20),
          Text("Email", style: AppFonts.montserratText3),
          CustomTextField(
            controller: emailController,
            hintText: "Enter your email",
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 40),
          Align(
            alignment: Alignment.center,
            child: CustomButton(
              text: "Save Changes",
              onPressed: () {
                Get.back(result: {
          'name': nameController.text,
          'email': emailController.text,
                });
                Get.snackbar("Profile Updated", "Your profile has been updated successfully.",colorText: Colors.white,backgroundColor: AppColors.minorColor);
              },
            ),
          ),          ],
          ),
        ),
      ),
    );
  }
}

