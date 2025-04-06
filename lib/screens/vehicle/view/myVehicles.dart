import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/constants/app_fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyVehicleScreen extends StatefulWidget {
  const MyVehicleScreen({super.key});

  @override
  State<MyVehicleScreen> createState() => _MyVehicleScreenState();
}

class _MyVehicleScreenState extends State<MyVehicleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
    
        elevation: 1,
        title: Text("Vehicles Information", style: AppFonts.montserrathomecardText),
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
      body: Container(
        child: const Text('My vehicles'),
      ),
    );
  }
}