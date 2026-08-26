import 'package:cloud_firestore/cloud_firestore.dart';

/// طرح مساق واحد في فصل دراسي واحد وشعبة واحدة.
///
/// معرّف المستند ثابت: {courseId}_{semesterId}_{section}
/// ملاحظة: لا تُحلَّل مكوّنات المعرّف نصيًا لأن semesterId نفسه يحتوي على
/// شرطات سفلية؛ اقرأ الحقول المخزَّنة دائمًا.
class CourseOfferingModel {
  final String id;
  final String courseId;
  final String semesterId;

  /// حساب المعلّم المسند إلى هذا الطرح، وهو مصدر الحقيقة للملكية.
  ///
  /// قابل لأن يكون null عمدًا: الطروحات التي أُنشئت قبل هذه المرحلة لا تحمل
  /// معلّمًا، و instructorName فيها نص حر لا يمكن مطابقته بحساب دون تخمين.
  /// الطرح بلا معلّم "غير مملوك": المشرف يديره كالمعتاد، ولا معلّم يملك عليه
  /// أي صلاحية.
  final String? teacherId;

  /// اسم المدرّس للعرض، منسوخ من اسم المعلّم عند الإسناد.
  ///
  /// يبقى موجودًا بعد إضافة teacherId لسببين: شاشات الطالب تعرضه دون قراءة
  /// مستند المستخدم، والطروحات القديمة لا تملك غيره.
  final String instructorName;

  final String section;
  final String status;
  final String source;
  final String? externalId;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CourseOfferingModel({
    required this.id,
    required this.courseId,
    required this.semesterId,
    this.teacherId,
    required this.instructorName,
    this.section = defaultSection,
    required this.status,
    this.source = sourceManual,
    this.externalId,
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
  });

  static const String defaultSection = '1';

  static const String statusActive = 'active';
  static const String statusArchived = 'archived';
  static const String statusCancelled = 'cancelled';
  static const List<String> allowedStatuses = <String>[
    statusActive,
    statusArchived,
    statusCancelled,
  ];

  static const String sourceManual = 'manual';
  static const String sourceApi = 'api';

  bool get isActive => status == statusActive;
  bool get isArchived => status == statusArchived;
  bool get isCancelled => status == statusCancelled;

  /// طرح مملوك لمعلّم. الطروحات القديمة تعيد false ولا تمنح أحدًا شيئًا.
  bool get hasTeacher => (teacherId ?? '').trim().isNotEmpty;

  /// معرّف الطرح الثابت.
  static String buildId(String courseId, String semesterId, String section) {
    final normalizedSection = section.trim().isEmpty
        ? defaultSection
        : section.trim();
    return '${courseId}_${semesterId}_$normalizedSection';
  }

  factory CourseOfferingModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return CourseOfferingModel(
      id: id,
      courseId: data['courseId'] as String? ?? '',
      semesterId: data['semesterId'] as String? ?? '',
      teacherId: (data['teacherId'] as String?)?.trim().isNotEmpty == true
          ? (data['teacherId'] as String).trim()
          : null,
      instructorName: data['instructorName'] as String? ?? '',
      section: (data['section'] as String? ?? defaultSection).trim(),
      status: data['status'] as String? ?? statusActive,
      source: data['source'] as String? ?? sourceManual,
      externalId: data['externalId'] as String?,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'semesterId': semesterId,
      // الحقل يُحذف ولا يُكتب فارغًا: القواعد تشترط لأي teacherId مكتوب أن
      // يشير إلى حساب معلّم فعلي، فالنص الفارغ يعني رفض الكتابة بأكملها.
      if (hasTeacher) 'teacherId': teacherId,
      'instructorName': instructorName,
      'section': section,
      'status': status,
      'source': source,
      'createdBy': createdBy,
      if (externalId != null) 'externalId': externalId,
    };
  }

  CourseOfferingModel copyWith({
    String? id,
    String? courseId,
    String? semesterId,
    String? teacherId,
    String? instructorName,
    String? section,
    String? status,
    String? source,
    String? externalId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearTeacher = false,
  }) {
    return CourseOfferingModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      // إلغاء الإسناد قرار صريح: بدون هذه الراية لا تستطيع copyWith أن تميّز
      // "لم يُمرَّر معلّم" عن "اجعل الطرح بلا معلّم".
      teacherId: clearTeacher ? null : (teacherId ?? this.teacherId),
      instructorName: instructorName ?? this.instructorName,
      section: section ?? this.section,
      status: status ?? this.status,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
