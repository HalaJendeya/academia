import 'package:cloud_firestore/cloud_firestore.dart';

/// يمثّل فصلًا دراسيًا واحدًا داخل مجموعة semesters.
///
/// معرّف المستند توليدي وثابت: semester_{academicYear}_{semesterNumber}
class SemesterModel {
  final String id;
  final String academicYear;
  final int semesterNumber;
  final String semesterName;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String source;
  final String? externalId;

  const SemesterModel({
    required this.id,
    required this.academicYear,
    required this.semesterNumber,
    required this.semesterName,
    required this.status,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
    this.source = sourceManual,
    this.externalId,
  });

  // حالات الفصل الدراسي المسموح بها.
  static const String statusUpcoming = 'upcoming';
  static const String statusCurrent = 'current';
  static const String statusCompleted = 'completed';

  static const List<String> allowedStatuses = <String>[
    statusUpcoming,
    statusCurrent,
    statusCompleted,
  ];

  // مصدر البيانات: إدخال يدوي من المشرف أو مزامنة مستقبلية مع واجهة الجامعة.
  static const String sourceManual = 'manual';
  static const String sourceApi = 'api';

  bool get isCurrent => status == statusCurrent;
  bool get isUpcoming => status == statusUpcoming;
  bool get isCompleted => status == statusCompleted;

  /// توليد معرّف المستند الثابت.
  ///
  /// buildId('2026', 1) => 'semester_2026_1'
  static String buildId(String academicYear, int semesterNumber) {
    return 'semester_${academicYear.trim()}_$semesterNumber';
  }

  factory SemesterModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return SemesterModel(
      id: id,
      academicYear: (data['academicYear'] as String? ?? '').trim(),
      semesterNumber: (data['semesterNumber'] as num?)?.toInt() ?? 1,
      // بعض المستندات القديمة تحتوي على مسافات زائدة في بداية الاسم.
      semesterName: (data['semesterName'] as String? ?? '').trim(),
      status: data['status'] as String? ?? statusUpcoming,
      startDate: parseDateTime(data['startDate']),
      endDate: parseDateTime(data['endDate']),
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
      source: data['source'] as String? ?? sourceManual,
      externalId: data['externalId'] as String?,
    );
  }

  /// الحقول التي تُكتب إلى Firestore.
  ///
  /// الطوابع الزمنية createdAt/updatedAt تضيفها الخدمة عبر serverTimestamp،
  /// تمامًا كما هو الحال في CourseModel.
  Map<String, dynamic> toMap() {
    return {
      'academicYear': academicYear,
      'semesterNumber': semesterNumber,
      'semesterName': semesterName,
      'status': status,
      'source': source,
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      if (externalId != null) 'externalId': externalId,
    };
  }

  SemesterModel copyWith({
    String? id,
    String? academicYear,
    int? semesterNumber,
    String? semesterName,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? source,
    String? externalId,
  }) {
    return SemesterModel(
      id: id ?? this.id,
      academicYear: academicYear ?? this.academicYear,
      semesterNumber: semesterNumber ?? this.semesterNumber,
      semesterName: semesterName ?? this.semesterName,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
    );
  }
}
