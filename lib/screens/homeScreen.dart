import 'selfHelpSolutionScreen.dart';
import 'viewNotifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../constants/app_colors.dart';
import 'location/location_popup.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationPopup.showLocationPopup(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: 
      AppBar(
        title: Text('HomePage'),
      actions: [
          IconButton(
            onPressed: (){
              Get.to(ViewNotificationsScreen());
            }, 
            icon:Icon( Icons.notifications, color: AppColors.mainColor))
        ],),
      body: ElevatedButton(onPressed: () {
        Get.to(SelfHelpSolutions());
        }, 
        child: Text("Flat Tyre"))
    );
  }
}
