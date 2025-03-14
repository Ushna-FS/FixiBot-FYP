import '../constants/app_colors.dart';
import 'homeScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_fontStyles.dart';

class ViewNotificationsScreen extends StatefulWidget {
  const ViewNotificationsScreen({super.key});

  @override
  State<ViewNotificationsScreen> createState() => _ViewNotificationsScreenState();
}

class _ViewNotificationsScreenState extends State<ViewNotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.secondaryColor,
        title: const Text("Notificatons"),
        titleTextStyle: AppFonts.customTextStyle(fontSize: 20, color: AppColors.mainColor, fontWeight: FontWeight.bold),
        leading: IconButton(
                    onPressed: () {
                      Get.to(HomeScreen());
                    }, 
                    icon: Image.asset('assets/icons/back.png',
                    width: 30,
                    height:30),
                    ),
        centerTitle: true,
      ),
      body: Container(
        height: screenSize.height * 1,
        color: AppColors.secondaryColor,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
              color: AppColors.textColor3,
                borderRadius: BorderRadius.circular(8)
              ),
              child: ListView.builder(
                padding: EdgeInsets.all(4),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text("notification"),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}