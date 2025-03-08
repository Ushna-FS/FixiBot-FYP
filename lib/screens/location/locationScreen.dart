import 'package:fixibot_app/screens/location/location_popup.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_fontStyles.dart';
import '../../widgets/custom_buttons.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationPopup.showLocationPopup(context);
    });
  }
  
  @override
  Widget build(BuildContext context) {
  final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
        body: Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Stack(
          children: [
            Container(
              color: AppColors.secondaryColor,
              width: double.infinity, 
              height: screenSize.height * 0.7,
              child: Text("MAP", textAlign: TextAlign.center,),
              ),
              Positioned(
                bottom: 60,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: AppColors.textColor,
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.location_searching), 
                  color: AppColors.mainColor))
              )
          ],
        ),
        Container(
          color: AppColors.textColor,
          width: double.infinity,
          height: screenSize.height * 0.3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.mainSwatch.shade50,
                  child: Icon(Icons.location_on, color: AppColors.mainColor),
                ),
                title: Text("Current location from Map",
                style: AppFonts.customTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor2,
                ),),
                subtitle: Text("Other location Attributes",
                style: AppFonts.customTextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textColor3,
                ),),
                trailing: IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.edit),
                  color: AppColors.mainColor,
                ),
              ),
              SizedBox(
                height: 26
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.7,
                child: CustomButton(
                  text: "Confirm Your Location",
                  onPressed: () => Navigator.pop(context), 
                ),
              ),
              SizedBox(
                height: 26
              ),
            ],
          ),
        ),
      ],
    ));
  }
}
