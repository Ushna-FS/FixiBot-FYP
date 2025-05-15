import 'homeScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';
import '../constants/app_fontStyles.dart';

class SelfHelpSolutions extends StatelessWidget {
  final String issueTitle;

  SelfHelpSolutions({Key? key, required this.issueTitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.secondaryColor,
        title: Text(issueTitle), // Use dynamic title
        titleTextStyle: AppFonts.customTextStyle(
            fontSize: 20,
            color: AppColors.mainColor,
            fontWeight: FontWeight.bold),
        leading: IconButton(
          onPressed: () {
            Get.to(HomeScreen());
          },
          icon: Image.asset('assets/icons/back.png', width: 30, height: 30),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: AppColors.secondaryColor,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/solution.jpg',
                  fit: BoxFit.cover,
                  height: 200,
                  width: double.infinity,
                ),
                const SizedBox(height: 8.0),
                Text(
                  "Description",
                  style: AppFonts.customTextStyle(
                    color: AppColors.textColor2,
                    fontSize: 16
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Steps to Follow:',
                  style:  AppFonts.customTextStyle(
                    color: AppColors.textColor2,
                    fontSize: 20
                  ),
                ),
                const SizedBox(height: 8.0),
                Container(
                  decoration: BoxDecoration(
                  color: AppColors.textColor3,
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(4),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 2,
                    itemBuilder: (context, index) {
                      return const ListTile(
                        leading: Icon(Icons.arrow_forward, color:AppColors.mainColor),
                        title: Text("Step 1"),
                        subtitle: Text("Step Detail"),
                      );
                    },
                  ),
                ),       
              ],
            ),
          ),
        ),
      ),
    );
  }
}