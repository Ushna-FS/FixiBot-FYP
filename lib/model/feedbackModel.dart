// models/feedback_model.dart
class FeedbackModel {
  final String? id;
  final String serviceId;
  final String mechanicId;
  final String mechanicName;
  final String serviceType;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String status; // 'pending', 'submitted', 'updated'

  FeedbackModel({
    this.id,
    required this.serviceId,
    required this.mechanicId,
    required this.mechanicName,
    required this.serviceType,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
    required this.status,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['_id'] ?? json['id'],
      serviceId: json['service_id'] ?? json['serviceId'],
      mechanicId: json['mechanic_id'] ?? json['mechanicId'],
      mechanicName: json['mechanic_name'] ?? json['mechanicName'],
      serviceType: json['service_type'] ?? json['serviceType'],
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'service_id': serviceId,
      'mechanic_id': mechanicId,
      'mechanic_name': mechanicName,
      'service_type': serviceType,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'status': status,
    };
  }

  FeedbackModel copyWith({
    String? id,
    String? serviceId,
    String? mechanicId,
    String? mechanicName,
    String? serviceType,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      mechanicId: mechanicId ?? this.mechanicId,
      mechanicName: mechanicName ?? this.mechanicName,
      serviceType: serviceType ?? this.serviceType,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}