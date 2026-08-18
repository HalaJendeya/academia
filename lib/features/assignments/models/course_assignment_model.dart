import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// واجب أكاديمي واحد يخصّ طرح مساق.
///
/// الواجب ينتمي إلى طرح (offering) لا إلى مساق دائم: «قواعد بيانات، الفصل
/// الأول، شعبة 2» له واجباته، ولا تنتقل تلقائيًا إلى شعبة 3 التي يدرّسها
/// معلّم آخر. لذلك [offeringId] هو العلاقة الأكاديمية الوحيدة الموثوقة،
/// و[courseId] و[semesterId] حقلا سياق منسوخان من الطرح وتتحقق منهما
/// القواعد والخدمة معًا.
///
/// هذا ليس [TaskModel]: تلك مهام شخصية ينشئها الطالب لنفسه في مجموعة
/// أخرى، وهذه واجبات يفرضها المعلّم. المجموعتان لا تُدمجان.
class CourseAssignmentModel {
  final String id;
  final String offeringId;
  final String courseId;
  final String semesterId;
  final String title;
  final String description;
  final DateTime dueAt;
  final String priority;
  final String status;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CourseAssignmentModel({
    required this.id,
    required this.offeringId,
    required this.courseId,
    required this.semesterId,
    required this.title,
    this.description = '',
    required this.dueAt,
    this.priority = priorityMedium,
    this.status = statusActive,
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
  });

  // ---- lifecycle status ----
  static const String statusActive = 'active';
  static const String statusArchived = 'archived';
  static const List<String> allowedStatuses = <String>[
    statusActive,
    statusArchived,
  ];

  // ---- priority ----
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const List<String> allowedPriorities = <String>[
    priorityLow,
    priorityMedium,
    priorityHigh,
  ];

  bool get isActive => status == statusActive;
  bool get isArchived => status == statusArchived;

  bool get isHighPriority => priority == priorityHigh;

  factory CourseAssignmentModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final rawPriority = (data['priority'] as String?)?.trim();
    final rawStatus = (data['status'] as String?)?.trim();

    return CourseAssignmentModel(
      id: id,
      offeringId: data['offeringId'] as String? ?? '',
      courseId: data['courseId'] as String? ?? '',
      semesterId: data['semesterId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      /*
       * موعد التسليم مطلوب، لكن مستندًا تالفًا بلا موعد يجب ألا يُسقط
       * القائمة كلها. الحقبة (epoch) قيمة ظاهرة الخطأ تُقرأ فورًا كمتأخرة
       * بدل أن تبدو موعدًا معقولًا.
       */
      dueAt:
          parseDateTime(data['dueAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      priority: allowedPriorities.contains(rawPriority)
          ? rawPriority!
          : priorityMedium,
      status: allowedStatuses.contains(rawStatus) ? rawStatus! : statusActive,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }

  /// الحقول المخزَّنة فقط.
  ///
  /// لا يحتوي أي حالة زمنية مشتقّة (متأخر/مستحق اليوم/قريب) ولا أي تسمية
  /// عربية: تلك تُحسب عند العرض. تخزينها يعني أن تصبح خاطئة بمرور الوقت
  /// دون أن يكتبها أحد.
  Map<String, dynamic> toMap() {
    return {
      'offeringId': offeringId,
      'courseId': courseId,
      'semesterId': semesterId,
      'title': title,
      'description': description,
      'dueAt': Timestamp.fromDate(dueAt),
      'priority': priority,
      'status': status,
      'createdBy': createdBy,
    };
  }

  CourseAssignmentModel copyWith({
    String? id,
    String? offeringId,
    String? courseId,
    String? semesterId,
    String? title,
    String? description,
    DateTime? dueAt,
    String? priority,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseAssignmentModel(
      id: id ?? this.id,
      offeringId: offeringId ?? this.offeringId,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueAt: dueAt ?? this.dueAt,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ---------------------------------------------------- derived temporal state
  //
  // كل ما يلي يُحسب لحظة العرض ولا يُخزَّن. [relativeTo] موجود ليقيس
  // الاختبار حدودًا بعينها (منتصف الليل مثلًا) بدل أن يعتمد على الساعة.

  /// نافذة «قريب»: الواجب المستحق خلال هذه المدة ولم يتأخر بعد.
  static const Duration dueSoonWindow = Duration(hours: 24);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// فات موعده ولم يُؤرشف.
  ///
  /// المقارنة باللحظة لا باليوم، بخلاف المهام الشخصية: الواجب له وقت تسليم
  /// محدد، فواجب اليوم الساعة 9 صباحًا متأخر عند الثالثة عصرًا.
  bool isOverdue({DateTime? relativeTo}) {
    if (!isActive) return false;
    return dueAt.isBefore(relativeTo ?? DateTime.now());
  }

  /// يقع في اليوم التقويمي المحلي نفسه — سواء مرّ وقته أم لا.
  bool isDueToday({DateTime? relativeTo}) {
    if (!isActive) return false;
    return _isSameDay(dueAt, relativeTo ?? DateTime.now());
  }

  /// مستحق خلال [dueSoonWindow] ولم يتأخر.
  ///
  /// الحدّ محسوب بجمع المدة لا بقسمة الفرق على ساعات: `inHours` يقتطع
  /// الكسر، فيجعل واجبًا بعد 24 ساعة ونصف «قريبًا» وهو ليس كذلك.
  bool isDueSoon({DateTime? relativeTo}) {
    if (!isActive) return false;
    final now = relativeTo ?? DateTime.now();
    if (dueAt.isBefore(now)) return false;
    return !dueAt.isAfter(now.add(dueSoonWindow));
  }

  /// تسمية موعد التسليم للعرض، بالتنسيق العربي المعتمد في المهام والملفات.
  String get dueDateLabel =>
      DateFormat('yyyy/MM/dd · hh:mm a', 'ar').format(dueAt);

  /// تسمية اليوم وحده، حين لا يضيف الوقت شيئًا.
  String get dueDayLabel => DateFormat('yyyy/MM/dd', 'ar').format(dueAt);
}
