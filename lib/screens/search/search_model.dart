
import 'package:fixibot_app/screens/help/support.dart';
import 'package:fixibot_app/screens/homeScreen.dart';
import 'package:fixibot_app/screens/mechanics/view/mechanicsScreen.dart';
import 'package:fixibot_app/screens/profile/editProfile.dart';
import 'package:fixibot_app/screens/profile/view/profile.dart';
import 'package:fixibot_app/screens/selfHelpSolutionScreen.dart';
import 'package:fixibot_app/screens/vehicle/view/addVehicle.dart';
import 'package:fixibot_app/screens/vehicle/view/myVehicles.dart';
import 'package:flutter/material.dart';

class SearchModel {
  final String name;
  final Widget screen;

  SearchModel({required this.name, required this.screen});

  static List<SearchModel> modules = [
   SearchModel(name: 'Home', screen: const HomeScreen()),
    SearchModel(name: 'Profile', screen: const ProfileScreen()),
    SearchModel(name: 'Add Vehicle', screen: const AddVehicle()),
    SearchModel(name: 'My Vehicle', screen: const MyVehicleScreen()),
    SearchModel(name: 'Mechanic ', screen: const MechanicScreen()),
    SearchModel(name: 'Help', screen:  HelpSupportPage()),
  ];
}
