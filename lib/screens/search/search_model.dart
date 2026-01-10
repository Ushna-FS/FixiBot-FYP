import 'package:fixibot_app/routes/app_routes.dart';

class SearchModel {
  final String name;
  final String route; // Changed from Widget to String

  SearchModel({required this.name, required this.route});

  static List<SearchModel> modules = [
    SearchModel(name: 'Home', route: AppRoutes.home),
    SearchModel(name: 'Profile', route: AppRoutes.profile),
    SearchModel(name: 'Add Vehicle', route: AppRoutes.addVehicle),
    SearchModel(name: 'My Vehicles', route: AppRoutes.myVehicle),
    SearchModel(name: 'Mechanics', route: AppRoutes.mechanics),
    SearchModel(name: 'Chatbot', route: '/chat'), // Add this route
    SearchModel(name: 'Help', route: '/help'), // Add this route
  ];
}