// models/mechanic_model.dart
class Mechanic {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String cnic;
  final String province;
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> expertise;
  final int yearsOfExperience;
  final String profilePicture;
  final String cnicFront;
  final String cnicBack;
  final String workshopName;
  final List<String> workingDays;
  final String startTime;
  final String endTime;

  Mechanic({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.cnic,
    required this.province,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.expertise,
    required this.yearsOfExperience,
    required this.profilePicture,
    required this.cnicFront,
    required this.cnicBack,
    required this.workshopName,
    required this.workingDays,
    required this.startTime,
    required this.endTime,
  });

  String get fullName => '$firstName $lastName';

  factory Mechanic.fromJson(Map<String, dynamic> json) {
  print('Parsing mechanic JSON: $json'); // Add this debug print
  
  return Mechanic(
    id: json['id']?.toString() ?? '',
    firstName: _parseString(json['first_name']),
    lastName: _parseString(json['last_name']),
    email: _parseString(json['email']),
    phoneNumber: _parseString(json['phone_number']),
    cnic: _parseString(json['cnic']),
    province: _parseString(json['province']),
    city: _parseString(json['city']),
    address: _parseString(json['address']),
    latitude: _parseDouble(json['latitude']),
    longitude: _parseDouble(json['longitude']),
    expertise: _parseStringList(json['expertise']),
    yearsOfExperience: _parseInt(json['years_of_experience']),
    profilePicture: _parseString(json['profile_picture']),
    cnicFront: _parseString(json['cnic_front']),
    cnicBack: _parseString(json['cnic_back']),
    workshopName: _parseString(json['workshop_name']),
    workingDays: _parseStringList(json['working_days']),
    startTime: _parseString(json['start_time']),
    endTime: _parseString(json['end_time']),
  );
}

static String _parseString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  // Handle case where value might be a String object or other type
  return value.toString();
}

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return [];
  }

  // Helper method to calculate distance (you'll need to implement this based on user location)
  double calculateDistance(double userLat, double userLng) {
    // Implement distance calculation using Haversine formula or similar
    // This is a placeholder implementation
    final latDiff = (latitude - userLat).abs();
    final lngDiff = (longitude - userLng).abs();
    return (latDiff + lngDiff) * 111; // Rough approximation in kilometers
  }

  // Helper method to get expertise as comma-separated string
  String get expertiseString => expertise.join(', ');

  // Helper method to get working days as comma-separated string
  String get workingDaysString => workingDays.join(', ');

   bool get isNetworkImage => profilePicture.startsWith('http') || 
                            profilePicture.startsWith('https');


                            // In your Mechanic model
Mechanic cleanPlaceholders() {
  return Mechanic(
    id: id,
    firstName: _cleanValue(firstName),
    lastName: _cleanValue(lastName),
    email: _cleanValue(email),
    phoneNumber: _cleanValue(phoneNumber),
    cnic: _cleanValue(cnic),
    province: _cleanValue(province),
    city: _cleanValue(city),
    address: _cleanValue(address),
    latitude: latitude,
    longitude: longitude,
    expertise: expertise,
    yearsOfExperience: yearsOfExperience,
    profilePicture: profilePicture,
    cnicFront: cnicFront,
    cnicBack: cnicBack,
    workshopName: _cleanValue(workshopName),
    workingDays: workingDays,
    startTime: _cleanValue(startTime),
    endTime: _cleanValue(endTime),
  );
}

String _cleanValue(String value) {
  if (value.toLowerCase() == 'string' || value.isEmpty) {
    return 'N/A';
  }
  return value;
}
}