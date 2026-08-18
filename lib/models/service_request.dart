import 'package:flutter/material.dart';

enum RequestCategory { complaint, inspection, panelWashing }

enum RequestStatus { pending, inProgress, resolved }

class ServiceRequest {
  final String id;
  final String userEmail;
  final String userName;
  final RequestCategory category;
  final String subCategory;
  final String priority;
  final String description;
  final RequestStatus status;
  final DateTime createdAt;
  final String assignedTo;
  final String assignedByName;
  final double rating;
  final String review;
  final DateTime? ratedAt;
  final String address;
  final String phone;

  const ServiceRequest({
    required this.id,
    required this.userEmail,
    required this.userName,
    required this.category,
    required this.subCategory,
    required this.priority,
    required this.description,
    required this.status,
    required this.createdAt,
    this.assignedTo = '',
    this.assignedByName = '',
    this.rating = 0,
    this.review = '',
    this.ratedAt,
    this.address = '',
    this.phone = '',
  });

  bool get isRated => rating > 0;

  ServiceRequest copyWith({
    RequestStatus? status,
    String? assignedTo,
    String? assignedByName,
    double? rating,
    String? review,
    DateTime? ratedAt,
    String? address,
    String? phone,
  }) {
    return ServiceRequest(
      id: id,
      userEmail: userEmail,
      userName: userName,
      category: category,
      subCategory: subCategory,
      priority: priority,
      description: description,
      status: status ?? this.status,
      createdAt: createdAt,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedByName: assignedByName ?? this.assignedByName,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      ratedAt: ratedAt ?? this.ratedAt,
      address: address ?? this.address,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userEmail': userEmail,
        'userName': userName,
        'category': category.name,
        'subCategory': subCategory,
        'priority': priority,
        'description': description,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'assignedTo': assignedTo,
        'assignedByName': assignedByName,
        if (rating > 0) 'rating': rating,
        if (review.isNotEmpty) 'review': review,
        if (ratedAt != null) 'ratedAt': ratedAt!.toIso8601String(),
        if (address.isNotEmpty) 'address': address,
        if (phone.isNotEmpty) 'phone': phone,
      };

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'],
      userEmail: json['userEmail'],
      userName: json['userName'],
      category: RequestCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => RequestCategory.complaint,
      ),
      subCategory: json['subCategory'] ?? '',
      priority: json['priority'] ?? 'Normal',
      description: json['description'] ?? '',
      status: RequestStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      assignedTo: json['assignedTo'] ?? '',
      assignedByName: json['assignedByName'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      review: json['review'] ?? '',
      ratedAt: json['ratedAt'] != null
          ? DateTime.parse(json['ratedAt'] as String)
          : null,
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

extension RequestCategoryX on RequestCategory {
  String get label {
    switch (this) {
      case RequestCategory.complaint:
        return 'Complaint';
      case RequestCategory.inspection:
        return 'Inspection';
      case RequestCategory.panelWashing:
        return 'Panel Washing';
    }
  }

  IconData get icon {
    switch (this) {
      case RequestCategory.complaint:
        return Icons.report_problem_outlined;
      case RequestCategory.inspection:
        return Icons.search_outlined;
      case RequestCategory.panelWashing:
        return Icons.water_drop_outlined;
    }
  }
}

extension RequestStatusX on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.inProgress:
        return 'In Progress';
      case RequestStatus.resolved:
        return 'Resolved';
    }
  }

  Color get color {
    switch (this) {
      case RequestStatus.pending:
        return const Color(0xFFF57C00);
      case RequestStatus.inProgress:
        return const Color(0xFF1976D2);
      case RequestStatus.resolved:
        return const Color(0xFF2E7D32);
    }
  }
}
