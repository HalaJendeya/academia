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

  /// اسم الجلسة كما كتبه الطالب، مثل «مراجعة نهائية».
  ///
  /// اختياري: الجلسة بلا اسم صالحة تمامًا، وتُعرض باسم مساقها. يُثبَّت عند
  /// الإنشاء ولا يتغيّر بعده — تسمية جلسة انتهت بأثر رجعي تُفسد السجل.
  final String? sessionName;

  /// هدف الجلسة كما كتبه الطالب، ويُعرض له أثناء المؤقّت.
  ///
  /// اختياري ومثبَّت عند الإنشاء، للسبب نفسه.
  final String? goal;

  /// ما أنجزه الطالب فعلًا، يكتبه بعد انتهاء الجلسة.
  ///
  /// 🔴 الحقل الوحيد القابل للكتابة بعد الإغلاق: شاشة «أحسنت، أنهيت جلستك»
  /// تسأل «ماذا أنجزت؟» بعد أن تكون الجلسة قد أُغلقت فعلًا. لذلك تسمح به
  /// القواعد بعد الاكتمال وحده، ولا تسمح بتعديل المدة أو الحالة معه.
  final String? reflection;

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
    this.sessionName,
    this.goal,
    this.reflection,
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

  /// حدود الطول، مطابقة لما تفرضه القواعد على الخادم.
  static const int maxSessionNameLength = 100;
  static const int maxGoalLength = 300;
  static const int maxReflectionLength = 1000;

  bool get hasSessionName => (sessionName?.trim().isNotEmpty ?? false);
  bool get hasGoal => (goal?.trim().isNotEmpty ?? false);
  bool get hasReflection => (reflection?.trim().isNotEmpty ?? false);

  /// ما يُعرض عنوانًا للجلسة: اسمها إن وُجد، وإلا يُترك للشاشة أن تعرض
  /// اسم المساق. لا نص بديل مخترع هنا.
  String? get displayName => hasSessionName ? sessionName!.trim() : null;

  /// نسبة ما أُنجز من المخطَّط، بين 0 و1. تُستعمل في شريط تقدّم السجل.
  double get completionRatio {
    if (plannedMinutes <= 0) return 0;
    final ratio = actualMinutes / plannedMinutes;
    return ratio.clamp(0.0, 1.0);
  }

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
      // غياب الحقول الثلاثة طبيعي: المستندات المنشأة قبل هذه الإضافة لا
      // تحملها، وتُقرأ null دون أي معالجة خاصة.
      sessionName: parseNullableString(data['sessionName']),
      goal: parseNullableString(data['goal']),
      reflection: parseNullableString(data['reflection']),
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
    String? sessionName,
    String? goal,
    String? reflection,
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
      sessionName: sessionName ?? this.sessionName,
      goal: goal ?? this.goal,
      reflection: reflection ?? this.reflection,
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
