import 'package:fixibot_app/widgets/customAppBar.dart';

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
      appBar: CustomAppBar(
        
        title: "Notificatons",
        
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
                padding: const EdgeInsets.all(4),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 1,
                itemBuilder: (context, index) {
                  return const ListTile(
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