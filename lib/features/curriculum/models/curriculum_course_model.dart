import 'package:cloud_firestore/cloud_firestore.dart';

/// صف واحد في الخطة الدراسية لتخصص معيّن.
///
/// الصف إمّا مساق محدد (entryType == course) أو خانة متطلب لم يُختَر لها
/// مساق بعد (entryType == slot) مثل "متطلب جامعة اختياري (1)".
/// خانات المتطلبات لا تُنشأ لها مستندات في مجموعة courses.
class CurriculumCourseModel {
  final String id;
  final String majorId;

  /// course | slot
  final String entryType;

  /// معرّف المساق — null عندما يكون الصف خانة متطلب.
  final String? courseId;

  /// نص الخانة كما ورد في الخطة — null عندما يكون الصف مساقًا محددًا.
  final String? slotLabel;

  /// المستوى في الخطة الدراسية: 1..8
  final int academicLevel;

  final String requirementType;

  /// عدد الساعات — يُخزَّن لخانات المتطلبات فقط، لأن المساقات المحددة
  /// ترث ساعاتها من مستند المساق نفسه.
  final int? creditHours;

  /// روابط المتطلبات السابقة المؤكدة فقط. غير مُفعَّلة في MVP.
  final List<String> prerequisiteCourseIds;

  /// النص الرسمي للمتطلب السابق كما ورد في الخطة، للعرض والمرجعية فقط.
  /// يُحتفظ به حتى عندما يتعذّر ربط المعرّف بثقة.
  final String? prerequisiteText;

  /// ترتيب الصف داخل المستوى.
  final int sequence;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CurriculumCourseModel({
    required this.id,
    required this.majorId,
    required this.entryType,
    this.courseId,
    this.slotLabel,
    required this.academicLevel,
    required this.requirementType,
    this.creditHours,
    this.prerequisiteCourseIds = const <String>[],
    this.prerequisiteText,
    this.sequence = 0,
    this.createdAt,
    this.updatedAt,
  });

  // ---- entry types ----
  static const String entryCourse = 'course';
  static const String entrySlot = 'slot';
  static const List<String> allowedEntryTypes = <String>[
    entryCourse,
    entrySlot,
  ];

  // ---- requirement types (من الخطة الرسمية) ----
  static const String majorRequired = 'major_required';
  static const String majorElective = 'major_elective';
  static const String collegeRequired = 'college_required';
  static const String universityRequired = 'university_required';
  static const String universityElective = 'university_elective';
  static const String freeElective = 'free_elective';

  static const List<String> allowedRequirementTypes = <String>[
    majorRequired,
    majorElective,
    collegeRequired,
    universityRequired,
    universityElective,
    freeElective,
  ];

  static const int minAcademicLevel = 1;
  static const int maxAcademicLevel = 8;

  bool get isCourseEntry => entryType == entryCourse;
  bool get isSlotEntry => entryType == entrySlot;

  /// مشتق ولا يُخزَّن: هل هذا المتطلب إجباري؟
  bool get isRequired => const <String>{
    majorRequired,
    collegeRequired,
    universityRequired,
  }.contains(requirementType);

  bool get hasResolvedPrerequisites => prerequisiteCourseIds.isNotEmpty;

  /// متطلب سابق مذكور نصيًا لكن بلا رابط مؤكد.
  bool get hasUnresolvedPrerequisiteText =>
      (prerequisiteText != null && prerequisiteText!.trim().isNotEmpty) &&
      prerequisiteCourseIds.isEmpty;

  /// معرّف صف المساق: {majorId}_{courseId}
  static String buildId(String majorId, String courseId) =>
      '${majorId}_$courseId';

  /// معرّف صف خانة المتطلب: {majorId}_slot_{level}_{sequence}
  static String buildSlotId(String majorId, int academicLevel, int sequence) =>
      '${majorId}_slot_${academicLevel}_$sequence';

  factory CurriculumCourseModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final rawCourseId = data['courseId'] as String?;
    final rawSlotLabel = data['slotLabel'] as String?;

    /*
     * توافق: إذا غاب entryType في مستند قديم نستنتجه من وجود courseId،
     * حتى لا يفشل التحويل.
     */
    final resolvedEntryType =
        data['entryType'] as String? ??
        ((rawCourseId != null && rawCourseId.trim().isNotEmpty)
            ? entryCourse
            : entrySlot);

    return CurriculumCourseModel(
      id: id,
      majorId: data['majorId'] as String? ?? '',
      entryType: resolvedEntryType,
      courseId: (rawCourseId != null && rawCourseId.trim().isNotEmpty)
          ? rawCourseId
          : null,
      slotLabel: (rawSlotLabel != null && rawSlotLabel.trim().isNotEmpty)
          ? rawSlotLabel.trim()
          : null,
      academicLevel: (data['academicLevel'] as num?)?.toInt() ?? 1,
      requirementType: data['requirementType'] as String? ?? majorRequired,
      creditHours: (data['creditHours'] as num?)?.toInt(),
      prerequisiteCourseIds:
          (data['prerequisiteCourseIds'] as List?)
              ?.whereType<String>()
              .toList() ??
          const <String>[],
      prerequisiteText: data['prerequisiteText'] as String?,
      sequence: (data['sequence'] as num?)?.toInt() ?? 0,
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'majorId': majorId,
      'entryType': entryType,
      if (courseId != null) 'courseId': courseId,
      if (slotLabel != null) 'slotLabel': slotLabel,
      'academicLevel': academicLevel,
      'requirementType': requirementType,
      if (creditHours != null) 'creditHours': creditHours,
      'prerequisiteCourseIds': prerequisiteCourseIds,
      if (prerequisiteText != null) 'prerequisiteText': prerequisiteText,
      'sequence': sequence,
    };
  }

  CurriculumCourseModel copyWith({
    String? id,
    String? majorId,
    String? entryType,
    String? courseId,
    String? slotLabel,
    int? academicLevel,
    String? requirementType,
    int? creditHours,
    List<String>? prerequisiteCourseIds,
    String? prerequisiteText,
    int? sequence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CurriculumCourseModel(
      id: id ?? this.id,
      majorId: majorId ?? this.majorId,
      entryType: entryType ?? this.entryType,
      courseId: courseId ?? this.courseId,
      slotLabel: slotLabel ?? this.slotLabel,
      academicLevel: academicLevel ?? this.academicLevel,
      requirementType: requirementType ?? this.requirementType,
      creditHours: creditHours ?? this.creditHours,
      prerequisiteCourseIds:
          prerequisiteCourseIds ?? this.prerequisiteCourseIds,
      prerequisiteText: prerequisiteText ?? this.prerequisiteText,
      sequence: sequence ?? this.sequence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
