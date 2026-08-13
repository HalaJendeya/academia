import 'package:cloud_firestore/cloud_firestore.dart';

/// تخصص أكاديمي (برنامج دراسي) ينتمي إلى قسم، وله خطة دراسية خاصة به.
class MajorModel {
  final String id;
  final String name;
  final String code;
  final String departmentId;

  /// عدد المستويات في الخطة الدراسية (8 في خطة نظم المعلومات).
  final int totalLevels;

  final String status;
  final String source;
  final String? externalId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MajorModel({
    required this.id,
    required this.name,
    required this.code,
    required this.departmentId,
    this.totalLevels = defaultTotalLevels,
    required this.status,
    this.source = sourceManual,
    this.externalId,
    this.createdAt,
    this.updatedAt,
  });

  static const int defaultTotalLevels = 8;

  static const String statusActive = 'active';
  static const String statusArchived = 'archived';
  static const List<String> allowedStatuses = <String>[
    statusActive,
    statusArchived,
  ];

  static const String sourceManual = 'manual';
  static const String sourceApi = 'api';

  bool get isActive => status == statusActive;

  /// قائمة المستويات 1..totalLevels لعرض الخطة مجمّعة.
  List<int> get levels => List<int>.generate(totalLevels, (i) => i + 1);

  factory MajorModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return MajorModel(
      id: id,
      name: (data['name'] as String? ?? '').trim(),
      code: (data['code'] as String? ?? '').trim(),
      departmentId: data['departmentId'] as String? ?? '',
      totalLevels:
          (data['totalLevels'] as num?)?.toInt() ?? defaultTotalLevels,
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
      'departmentId': departmentId,
      'totalLevels': totalLevels,
      'status': status,
      'source': source,
      if (externalId != null) 'externalId': externalId,
    };
  }

  MajorModel copyWith({
    String? id,
    String? name,
    String? code,
    String? departmentId,
    int? totalLevels,
    String? status,
    String? source,
    String? externalId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MajorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      departmentId: departmentId ?? this.departmentId,
      totalLevels: totalLevels ?? this.totalLevels,
      status: status ?? this.status,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
