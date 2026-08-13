import 'package:cloud_firestore/cloud_firestore.dart';

/// مساق دائم في دليل المساقات (الكتالوج).
///
/// يمثّل المادة الأكاديمية نفسها ولا يرتبط بفصل دراسي أو مدرّس؛ تلك
/// تفاصيل خاصة بالطرح وتوجد في CourseOfferingModel.
///
/// معرّف المستند تلقائي، و courseCode حقل عمل فريد يُتحقَّق منه في الخدمة.
class CourseModel {
  final String id;
  final String courseCode;
  final String title;
  final String description;
  final int creditHours;
  final String departmentId;
  final String status;
  final String source;
  final String? externalId;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CourseModel({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.description,
    required this.creditHours,
    required this.departmentId,
    required this.status,
    this.source = sourceManual,
    this.externalId,
    this.createdBy = '',
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
  bool get isArchived => status == statusArchived;

  /// توحيد رمز المساق للمقارنة والتخزين.
  static String normalizeCode(String code) => code.trim().toUpperCase();

  factory CourseModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return CourseModel(
      id: id,
      courseCode: (data['courseCode'] as String? ?? '').trim(),
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      creditHours: (data['creditHours'] as num?)?.toInt() ?? 3,
      /*
       * توافق انتقالي حتى ترحيل البيانات: المستندات القديمة تحتوي على
       * الحقل النصي department بدل departmentId. نقرأ الفارغ بدل الفشل،
       * بينما تفرض الخدمة وجود departmentId عند الكتابة.
       */
      departmentId: data['departmentId'] as String? ?? '',
      status: data['status'] as String? ?? statusActive,
      source: data['source'] as String? ?? sourceManual,
      externalId: data['externalId'] as String?,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }

  bool get hasDepartment => departmentId.trim().isNotEmpty;

  /// الحقول التي تُكتب إلى Firestore.
  ///
  /// الحقول القديمة semesterId و instructorName و academicYear و semester
  /// لم تعد تُكتب؛ فهي خاصة بالطرح وليست بالمساق الدائم.
  Map<String, dynamic> toMap() {
    return {
      'courseCode': courseCode,
      'title': title,
      'description': description,
      'creditHours': creditHours,
      'departmentId': departmentId,
      'status': status,
      'source': source,
      'createdBy': createdBy,
      if (externalId != null) 'externalId': externalId,
    };
  }

  CourseModel copyWith({
    String? id,
    String? courseCode,
    String? title,
    String? description,
    int? creditHours,
    String? departmentId,
    String? status,
    String? source,
    String? externalId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseModel(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      title: title ?? this.title,
      description: description ?? this.description,
      creditHours: creditHours ?? this.creditHours,
      departmentId: departmentId ?? this.departmentId,
      status: status ?? this.status,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
