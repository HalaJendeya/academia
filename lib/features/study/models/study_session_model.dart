import 'package:cloud_firestore/cloud_firestore.dart';

/// حالة جلسة المذاكرة.
///
/// [active] جلسة بدأت ولم تُغلق بعد، [completed] بلغت مدتها أو أنهاها الطالب
/// مبكرًا فاحتُسب ما ذاكره فعلًا، [cancelled] ألغاها الطالب فلا تُحتسب.
enum StudySessionStatus { active, completed, cancelled }

/// جلسة مذاكرة واحدة يملكها طالب واحد.
///
/// 🔴 بيانات شخصية بحتة: لا يقرؤها طالب آخر ولا معلّم ولا مشرف. لا علاقة
/// لها بالتقييم الأكاديمي، وليست تسليمًا ولا درجة — هي أداة تنظيم وقت
/// يملكها الطالب وحده، تمامًا كالمهمة الشخصية في `/tasks`.
///
/// الربط بمساق اختياري ويمرّ عبر تسجيل فعلي: [offeringId] لا يُقبل إلا إذا
/// كان الطالب مسجَّلًا في ذلك الطرح، وتتحقق قواعد Firestore من ذلك.
class StudySessionModel {
  final String id;
  final String userId;

  /// الطرح الدراسي المرتبط بالجلسة، أو null لجلسة مذاكرة عامة.
  final String? offeringId;

  /// مشتق من الطرح، للعرض دون قراءة إضافية. يرافق [offeringId] دائمًا.
  final String? courseId;

  /// المدة المخطَّطة بالدقائق كما اختارها الطالب عند البدء.
  final int plannedMinutes;

  /// ما ذاكره الطالب فعلًا. صفر ما دامت الجلسة جارية.
  ///
  /// يُحسب عند الإغلاق لا أثناء العدّ: الكتابة كل ثانية في Firestore كلفة
  /// بلا فائدة، والمؤقّت الحيّ حالة محلية لا حالة مخزَّنة.
  final int actualMinutes;

  final StudySessionStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudySessionModel({
    required this.id,
    required this.userId,
    this.offeringId,
    this.courseId,
    required this.plannedMinutes,
    this.actualMinutes = 0,
    this.status = StudySessionStatus.active,
    required this.startedAt,
    this.endedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == StudySessionStatus.active;
  bool get isCompleted => status == StudySessionStatus.completed;
  bool get isCancelled => status == StudySessionStatus.cancelled;

  /// جلسة مرتبطة بمساق. الحقلان يُكتبان معًا أو يُتركان معًا.
  bool get hasCourse =>
      (offeringId?.trim().isNotEmpty ?? false) &&
      (courseId?.trim().isNotEmpty ?? false);

  static const int minMinutes = 5;
  static const int maxMinutes = 180;

  /// المدة المقبولة، بالحدود نفسها التي يفرضها [StudyPreferences].
  static bool isValidDuration(int minutes) =>
      minutes >= minMinutes && minutes <= maxMinutes;

  static String statusToString(StudySessionStatus status) => status.name;

  /// تحليل يفشل مغلقًا: أي حالة لا يعرفها هذا الإصدار تُقرأ كـ [cancelled]
  /// لا كـ [active]، فلا يظهر مستند تالف كجلسة جارية تمنع بدء جلسة جديدة.
  static StudySessionStatus statusFromString(dynamic value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'active':
        return StudySessionStatus.active;
      case 'completed':
        return StudySessionStatus.completed;
      default:
        return StudySessionStatus.cancelled;
    }
  }

  factory StudySessionModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 0;
    }

    String? parseNullableString(dynamic value) {
      if (value == null) return null;
      final result = value.toString().trim();
      return result.isEmpty ? null : result;
    }

    return StudySessionModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      offeringId: parseNullableString(data['offeringId']),
      courseId: parseNullableString(data['courseId']),
      plannedMinutes: parseInt(data['plannedMinutes']),
      actualMinutes: parseInt(data['actualMinutes']),
      status: statusFromString(data['status']),
      startedAt: parseDateTime(data['startedAt']) ?? DateTime.now(),
      endedAt: parseDateTime(data['endedAt']),
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }

  StudySessionModel copyWith({
    String? id,
    String? userId,
    String? offeringId,
    String? courseId,
    int? plannedMinutes,
    int? actualMinutes,
    StudySessionStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudySessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      offeringId: offeringId ?? this.offeringId,
      courseId: courseId ?? this.courseId,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
