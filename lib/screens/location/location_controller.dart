// import 'package:get/get.dart';

// class LocationController extends GetxController {
//   RxString userLocation = ''.obs;

//   void updateLocation(String newLocation) {
//     userLocation.value = newLocation;
//   }
// }
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationController extends GetxController {
  // Human-readable address
  final RxString userLocation = 'No location selected'.obs;

  Future<void> fetchCurrentLocation() async {
    try {
      // Request location permission
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

      // Get current coordinates
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Convert to address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        userLocation.value =
            '${place.name}, ${place.locality}, ${place.administrativeArea}';
      } else {
        userLocation.value = 'Address not found';
      }
    } catch (e) {
      userLocation.value = 'Failed to get location';
      print('Location Error: $e');
    }
  }

  // Optional: manually update location
  void updateLocation(String address) {
    userLocation.value = address;
  }
}
