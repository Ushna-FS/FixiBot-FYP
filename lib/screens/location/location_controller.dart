import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationController extends GetxController {
  final RxString userLocation = 'Fetching location...'.obs;

  // 1. Fetch Current Location with readable address
  Future<void> fetchCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          userLocation.value = 'Location permission denied';
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;
      print('Name: ${place.name}');
      print('Street: ${place.street}');
      print('SubLocality: ${place.subLocality}');
      print('Locality: ${place.locality}');
      print('Admin Area: ${place.administrativeArea}');

      userLocation.value =
          '${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
    } catch (e) {
      userLocation.value = 'Fail to get location';
    }
  }

  // 2. Update from Map Screen
  void updateLocationFromMap(String newAddress) {
    userLocation.value = newAddress;
  }
}
