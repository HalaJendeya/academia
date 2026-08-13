import 'package:cloud_firestore/cloud_firestore.dart';

/// قسم أكاديمي يملك المساقات وتنتمي إليه التخصصات.
class DepartmentModel {
  final String id;
  final String name;
  final String code;
  final String status;
  final String source;
  final String? externalId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DepartmentModel({
    required this.id,
    required this.name,
    this.code = '',
    required this.status,
    this.source = sourceManual,
    this.externalId,
    this.createdAt,
    this.updatedAt,
  });

  static const String statusActive = 'active';
  static const String statusArchived = 'archived';
  static const List<String> allowedStatuses = <String>[
    statusActive,
    statusArchived,
  ];

  static const String sourceManual = 'manual';
  static const String sourceApi = 'api';

  bool get isActive => status == statusActive;

  factory DepartmentModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return DepartmentModel(
      id: id,
      name: (data['name'] as String? ?? '').trim(),
      code: (data['code'] as String? ?? '').trim(),
      status: data['status'] as String? ?? statusActive,
      source: data['source'] as String? ?? sourceManual,
      externalId: data['externalId'] as String?,
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'status': status,
      'source': source,
      if (externalId != null) 'externalId': externalId,
    };
  }

  DepartmentModel copyWith({
    String? id,
    String? name,
    String? code,
    String? status,
    String? source,
    String? externalId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DepartmentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      status: status ?? this.status,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
