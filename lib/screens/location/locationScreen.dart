import 'dart:async';
import 'dart:convert';
import 'package:fixibot_app/screens/location/location_controller.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart' show Get, ExtensionSnackbar, GetNavigation;
import 'package:get/get_instance/get_instance.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_popup.dart';
import 'package:flutter_google_places_hoc081098/google_maps_webservice_places.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_fontStyles.dart';
import '../../widgets/custom_buttons.dart';
import 'package:location/location.dart' as location;
import 'package:http/http.dart' as http;

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  GoogleMapController? _controller;
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _currentLocation;
  final locationController = Get.find<LocationController>();
  final location.Location _locationService = location.Location();
  final Set<Marker> _markers = {};
  bool _isCameraMoving = false;
  double _currentZoomLevel = 10.0;
  final prefs = Get.find<SharedPreferences>();
  StreamSubscription<location.LocationData>? _locationSubscription;
  String _locationName = "Unknown Location";
  final String _apiKey =
      "AIzaSyBQqPT4G8aMXgtpcYk1gM3OPO1xh1UkJCs"; // Replace with your API key
  final places =
      GoogleMapsPlaces(apiKey: "AIzaSyBQqPT4G8aMXgtpcYk1gM3OPO1xh1UkJCs");

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _controller = null;
    super.dispose();
  }

  Future<void> _checkPermissionsAndGetLocation() async {
    bool serviceEnabled;
    location.PermissionStatus permissionGranted;

    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == location.PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != location.PermissionStatus.granted) return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      location.LocationData locationData = await _locationService.getLocation();
      if (!mounted) return; // Ensure widget is mounted before updating state
      setState(() {
        _currentLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        _updateMarkers();
        _moveCameraToCurrentLocation();
        _getLocationName(_currentLocation!); // Fetch location name
      });
    } catch (e) {
      print("Error getting current location: $e");
    }
  }

  void _updateMarkers() {
    if (_currentLocation != null) {
      if (!mounted) return;
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: _currentLocation!,
            infoWindow: InfoWindow(
                title: _locationName), // Show location name in marker
          ),
        );
      });
    }
  }

  Future<void> _moveCameraToCurrentLocation() async {
    if (_controller == null || _currentLocation == null) return;

    _isCameraMoving = true;
    await _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentLocation!,
          zoom: _currentZoomLevel,
        ),
      ),
    );
    _isCameraMoving = false;
  }

  Future<void> _handleSearch() async {
    Prediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey: _apiKey,
      mode: Mode.overlay,
      language: 'en',
    );

    if (p != null) {
      final details = await places.getDetailsByPlaceId(p.placeId!);
      final geometry = details.result.geometry!;
      final lat = geometry.location.lat;
      final lng = geometry.location.lng;

      setState(() {
        _currentLocation = LatLng(lat, lng);
        _updateMarkers();
        _moveCameraToCurrentLocation();
        _getLocationName(_currentLocation!); // Fetch location name
      });
    }
  }

  Future<void> _getLocationName(LatLng latLng) async {
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          if (!mounted)
            return; // Check if the widget is still mounted before updating the state
          setState(() {
            _locationName = data['results'][0]['formatted_address'];
          });
        }
      }
    } catch (e) {
      print('Error fetching location name: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndGetLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationPopup.showLocationPopup(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;

    return Scaffold(
        body: Container(
      margin: EdgeInsets.only(top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Positioned(
            top: 63,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.textColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryColor,
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Image.asset(
                      'assets/icons/back.png',
                      width: isSmallScreen ? 24 : 30,
                      height: isSmallScreen ? 24 : 30,
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        child: Text(
                          "Search",
                          style: TextStyle(color: AppColors.textColor2),
                        ),
                        onPressed: _handleSearch,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _handleSearch,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _currentLocation == null
                ? Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(37.7749, -122.4194),
                      zoom: 14.0,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _mapController.complete(controller);
                      _controller = controller;
                    },
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onCameraMove: (CameraPosition position) {
                      if (!mounted) return;
                      setState(() {
                        _currentZoomLevel = position.zoom;
                      });
                    },
                    onTap: (LatLng latLng) {
                      setState(() {
                        _currentLocation = latLng;
                        _updateMarkers();
                        _getLocationName(
                            _currentLocation!); // Fetch location name
                      });
                    },
                  ),
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
                    child: const Icon(Icons.location_on,
                        color: AppColors.mainColor),
                  ),
                  title: Text(
                    "$_locationName",
                    style: AppFonts.customTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor2,
                    ),
                  ),
                  subtitle: Text(
                    "${_currentLocation?.latitude.toStringAsFixed(6) ?? "N/A"}",
                    style: AppFonts.customTextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textColor3,
                    ),
                  ),
                  // trailing: IconButton(
                  //   onPressed: () async {
                  //     await prefs.setDouble(
                  //         "updatedLatitude", _currentLocation!.latitude);
                  //     await prefs.setDouble(
                  //         "updatedLongitude", _currentLocation!.longitude);
                  //     Get.snackbar(
                  //         "Location Updated", "Location updated successfully");
                  //     Get.back();
                  //   },
                  //   icon: const Icon(Icons.edit),
                  //   color: AppColors.mainColor,
                  // ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: CustomButton(
                    text: "Confirm Location",
                    onPressed: () async {
                      LatLng selectedLatLng =
                          _currentLocation!; // from your map
                      List<Placemark> placemarks =
                          await placemarkFromCoordinates(
                              selectedLatLng.latitude,
                              selectedLatLng.longitude);
                      Placemark place = placemarks[0];
                      String address =
                          '${place.name}, ${place.locality}, ${place.administrativeArea}';

                      locationController.updateLocation(address);
                      Navigator.pop(context);
                      // locationController.updateLocation(
                      //   _locationName); // replace with actual value
                      //   Get.back();
                    },
                  ),
                ),
                const SizedBox(height: 26),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}

class LocationDataModel {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool status;

  LocationDataModel({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.status,
  });
}
