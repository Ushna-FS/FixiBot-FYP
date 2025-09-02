class BreakdownModel {
  final String name;
  final Map<String, dynamic> categories;

  BreakdownModel({required this.name, required this.categories});

  factory BreakdownModel.fromJson(Map<String, dynamic> json) {
    return BreakdownModel(
      name: json['Name'],
      categories: {
        "Car": json["In Cars"],
        "Bike": json["In Bikes"],
        "Truck": json["In Trucks/Heavy Vehicles"],
      },
    );
  }
}
