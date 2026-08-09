import 'package:cloud_firestore/cloud_firestore.dart';

/// محاولة واحدة لطالب في طرح مساق محدد.
///
/// معرّف المستند ثابت: {userId}_{offeringId}
/// وبما أن الطرح خاص بفصل دراسي واحد، فإن إعادة دراسة المساق نفسه في فصل
/// لاحق تنتج طرحًا مختلفًا ومن ثم مستندًا مختلفًا، فتبقى المحاولة السابقة
/// كما هي دون استبدال.
class EnrollmentModel {
  final String id;
  final String userId;
  final String offeringId;

  /// منسوخ من الطرح لتجميع المحاولات حسب المساق الدائم دون قراءات إضافية.
  final String courseId;

  /// منسوخ من الطرح للفصل بين المساقات الحالية والسجل السابق باستعلام واحد.
  final String semesterId;

  /// رقم المحاولة لهذا الطالب في هذا المساق الدائم، يبدأ من 1.
  final int attemptNumber;

  final String status;

  /// نتيجة المحاولة الأكاديمية، تبقى null ما دامت المحاولة نشطة.
  final String? completionStatus;

  /// تقدير للعرض فقط؛ لا يوجد نظام تقديرات أو حساب معدل في هذه المرحلة.
  final String? grade;

  final String assignedBy;
  final DateTime? assignedAt;
  final DateTime? updatedAt;

  const EnrollmentModel({
    required this.id,
    required this.userId,
    required this.offeringId,
    required this.courseId,
    required this.semesterId,
    this.attemptNumber = 1,
    required this.status,
    this.completionStatus,
    this.grade,
    required this.assignedBy,
    this.assignedAt,
    this.updatedAt,
  });

  // ---- lifecycle status ----
  static const String statusActive = 'active';
  static const String statusCompleted = 'completed';
  static const String statusRemoved = 'removed';
  static const List<String> allowedStatuses = <String>[
    statusActive,
    statusCompleted,
    statusRemoved,
  ];

  // ---- academic outcome ----
  static const String completionPassed = 'passed';
  static const String completionFailed = 'failed';
  static const String completionIncomplete = 'incomplete';
  static const List<String> allowedCompletionStatuses = <String>[
    completionPassed,
    completionFailed,
    completionIncomplete,
  ];

  bool get isActive => status == statusActive;
  bool get isCompleted => status == statusCompleted;
  bool get isRemoved => status == statusRemoved;

  bool get isPassed => completionStatus == completionPassed;
  bool get isFailed => completionStatus == completionFailed;
  bool get isIncomplete => completionStatus == completionIncomplete;

  bool get isRetake => attemptNumber > 1;

  /// معرّف المستند الثابت.
  static String buildId(String userId, String offeringId) =>
      '${userId}_$offeringId';

  factory EnrollmentModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final rawCompletion = data['completionStatus'] as String?;

    return EnrollmentModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      /*
       * توافق انتقالي: السجلات التي أُنشئت قبل فصل المساقات عن الطروحات
       * لا تحتوي على offeringId. نقرأها كسلسلة فارغة بدل الفشل، بينما
       * تفرض الخدمة وجود طرح صالح عند كل كتابة جديدة.
       */
      offeringId: data['offeringId'] as String? ?? '',
      courseId: data['courseId'] as String? ?? '',
      semesterId: data['semesterId'] as String? ?? '',
      attemptNumber: (data['attemptNumber'] as num?)?.toInt() ?? 1,
      status: data['status'] as String? ?? statusActive,
      completionStatus:
          (rawCompletion != null && rawCompletion.trim().isNotEmpty)
          ? rawCompletion
          : null,
      grade: data['grade'] as String?,
      assignedBy: data['assignedBy'] as String? ?? '',
      assignedAt: parseDateTime(data['assignedAt']),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }

  bool get hasOffering => offeringId.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'offeringId': offeringId,
      'courseId': courseId,
      'semesterId': semesterId,
      'attemptNumber': attemptNumber,
      'status': status,
      if (completionStatus != null) 'completionStatus': completionStatus,
      if (grade != null) 'grade': grade,
      'assignedBy': assignedBy,
    };
  }

  EnrollmentModel copyWith({
    String? id,
    String? userId,
    String? offeringId,
    String? courseId,
    String? semesterId,
    int? attemptNumber,
    String? status,
    String? completionStatus,
    String? grade,
    String? assignedBy,
    DateTime? assignedAt,
    DateTime? updatedAt,
  }) {
    return EnrollmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      offeringId: offeringId ?? this.offeringId,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      status: status ?? this.status,
      completionStatus: completionStatus ?? this.completionStatus,
      grade: grade ?? this.grade,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedAt: assignedAt ?? this.assignedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
