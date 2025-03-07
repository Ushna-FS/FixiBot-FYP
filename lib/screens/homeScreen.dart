import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_fontStyles.dart';
import '../widgets/custom_buttons.dart';
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
      appBar: AppBar(title: Text('HomePage')),
    );
  }
}
