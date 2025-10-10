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
  final String servicedVehicleTypes; // ✅ CHANGED TO STRING

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
    required this.servicedVehicleTypes, // ✅ CHANGED TO STRING
  });

  String get fullName => '$firstName $lastName';

  factory Mechanic.fromJson(Map<String, dynamic> json) {
    print('🔧 Parsing mechanic JSON - Available keys: ${json.keys}');
    print('🔧 _id field: ${json['_id']}');
    print('🔧 id field: ${json['id']}');

    return Mechanic(
      // ✅ FIX: Use _id as primary identifier
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
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
      // ✅ FIX: serviced_vehicle_types is a string, not a list
      servicedVehicleTypes: _parseString(json['serviced_vehicle_types']),
    );
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
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
      return value.map((e) => e.toString().trim()).toList();
    }
    return [];
  }

  // Distance calculator
  double calculateDistance(double userLat, double userLng) {
    final latDiff = (latitude - userLat).abs();
    final lngDiff = (longitude - userLng).abs();
    return (latDiff + lngDiff) * 111; // Approximate km distance
  }

  String get expertiseString => expertise.join(', ');
  String get workingDaysString => workingDays.join(', ');

  bool get isNetworkImage =>
      profilePicture.startsWith('http') || profilePicture.startsWith('https');

  // Clean placeholder data
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
      servicedVehicleTypes: servicedVehicleTypes,
    );
  }

  String _cleanValue(String value) {
    if (value.toLowerCase() == 'string' || value.isEmpty) {
      return 'N/A';
    }
    return value;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'cnic': cnic,
      'province': province,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'expertise': expertise,
      'years_of_experience': yearsOfExperience,
      'profile_picture': profilePicture,
      'cnic_front': cnicFront,
      'cnic_back': cnicBack,
      'workshop_name': workshopName,
      'working_days': workingDays,
      'start_time': startTime,
      'end_time': endTime,
      'serviced_vehicle_types': servicedVehicleTypes,
    };
  }
}




// // models/mechanic_model.dart
// class Mechanic {
//   final String id;
//   final String firstName;
//   final String lastName;
//   final String email;
//   final String phoneNumber;
//   final String cnic;
//   final String province;
//   final String city;
//   final String address;
//   final double latitude;
//   final double longitude;
//   final List<String> expertise;
//   final int yearsOfExperience;
//   final String profilePicture;
//   final String cnicFront;
//   final String cnicBack;
//   final String workshopName;
//   final List<String> workingDays;
//   final String startTime;
//   final String endTime;
//   final List<String> servicedVehicleTypes; // ✅ NEW FIELD

//   Mechanic({
//     required this.id,
//     required this.firstName,
//     required this.lastName,
//     required this.email,
//     required this.phoneNumber,
//     required this.cnic,
//     required this.province,
//     required this.city,
//     required this.address,
//     required this.latitude,
//     required this.longitude,
//     required this.expertise,
//     required this.yearsOfExperience,
//     required this.profilePicture,
//     required this.cnicFront,
//     required this.cnicBack,
//     required this.workshopName,
//     required this.workingDays,
//     required this.startTime,
//     required this.endTime,
//     required this.servicedVehicleTypes, // ✅ Include in constructor
//   });

//   String get fullName => '$firstName $lastName';

//   factory Mechanic.fromJson(Map<String, dynamic> json) {
//     print('Parsing mechanic JSON: $json'); // Debug print

//     return Mechanic(
//       id: json['id']?.toString() ?? '',
//       firstName: _parseString(json['first_name']),
//       lastName: _parseString(json['last_name']),
//       email: _parseString(json['email']),
//       phoneNumber: _parseString(json['phone_number']),
//       cnic: _parseString(json['cnic']),
//       province: _parseString(json['province']),
//       city: _parseString(json['city']),
//       address: _parseString(json['address']),
//       latitude: _parseDouble(json['latitude']),
//       longitude: _parseDouble(json['longitude']),
//       expertise: _parseStringList(json['expertise']),
//       yearsOfExperience: _parseInt(json['years_of_experience']),
//       profilePicture: _parseString(json['profile_picture']),
//       cnicFront: _parseString(json['cnic_front']),
//       cnicBack: _parseString(json['cnic_back']),
//       workshopName: _parseString(json['workshop_name']),
//       workingDays: _parseStringList(json['working_days']),
//       startTime: _parseString(json['start_time']),
//       endTime: _parseString(json['end_time']),
//       servicedVehicleTypes: _parseStringList(json['serviced_vehicle_types']), // ✅ Parse new field
//     );
//   }

//   static String _parseString(dynamic value) {
//     if (value == null) return '';
//     if (value is String) return value;
//     return value.toString();
//   }

//   static double _parseDouble(dynamic value) {
//     if (value == null) return 0.0;
//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     if (value is String) {
//       return double.tryParse(value) ?? 0.0;
//     }
//     return 0.0;
//   }

//   static int _parseInt(dynamic value) {
//     if (value == null) return 0;
//     if (value is int) return value;
//     if (value is double) return value.toInt();
//     if (value is String) {
//       return int.tryParse(value) ?? 0;
//     }
//     return 0;
//   }

//   static List<String> _parseStringList(dynamic value) {
//     if (value == null) return [];
//     if (value is List) {
//       return value.map((e) => e.toString()).toList();
//     }
//     return [];
//   }

//   // Distance calculator
//   double calculateDistance(double userLat, double userLng) {
//     final latDiff = (latitude - userLat).abs();
//     final lngDiff = (longitude - userLng).abs();
//     return (latDiff + lngDiff) * 111; // Approximate km distance
//   }

//   String get expertiseString => expertise.join(', ');
//   String get workingDaysString => workingDays.join(', ');

//   bool get isNetworkImage =>
//       profilePicture.startsWith('http') || profilePicture.startsWith('https');

//   // Clean placeholder data
//   Mechanic cleanPlaceholders() {
//     return Mechanic(
//       id: id,
//       firstName: _cleanValue(firstName),
//       lastName: _cleanValue(lastName),
//       email: _cleanValue(email),
//       phoneNumber: _cleanValue(phoneNumber),
//       cnic: _cleanValue(cnic),
//       province: _cleanValue(province),
//       city: _cleanValue(city),
//       address: _cleanValue(address),
//       latitude: latitude,
//       longitude: longitude,
//       expertise: expertise,
//       yearsOfExperience: yearsOfExperience,
//       profilePicture: profilePicture,
//       cnicFront: cnicFront,
//       cnicBack: cnicBack,
//       workshopName: _cleanValue(workshopName),
//       workingDays: workingDays,
//       startTime: _cleanValue(startTime),
//       endTime: _cleanValue(endTime),
//       servicedVehicleTypes: servicedVehicleTypes, // ✅ Retain new field
//     );
//   }

//   String _cleanValue(String value) {
//     if (value.toLowerCase() == 'string' || value.isEmpty) {
//       return 'N/A';
//     }
//     return value;
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'id': id,
//       'first_name': firstName,
//       'last_name': lastName,
//       'email': email,
//       'phone_number': phoneNumber,
//       'cnic': cnic,
//       'province': province,
//       'city': city,
//       'address': address,
//       'latitude': latitude,
//       'longitude': longitude,
//       'expertise': expertise,
//       'years_of_experience': yearsOfExperience,
//       'profile_picture': profilePicture,
//       'cnic_front': cnicFront,
//       'cnic_back': cnicBack,
//       'workshop_name': workshopName,
//       'working_days': workingDays,
//       'start_time': startTime,
//       'end_time': endTime,
//       'serviced_vehicle_types': servicedVehicleTypes,
//     };
//   }
// }


