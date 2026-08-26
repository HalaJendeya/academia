import '../../assignments/models/assignment_progress_model.dart';
import '../../tasks/models/task_model.dart';
import 'study_session_model.dart';
import 'study_week.dart';

/// الملخّص الأسبوعي — كل رقم فيه محسوب من طوابع زمنية مخزَّنة فعلًا.
///
/// 🔴 ما لا يُحسب لا يوجد هنا. لا هدف أسبوعي (لا حقل له في النظام)، ولا
/// «أداء متميز»، ولا نسبة نمو مخترعة. أما المقارنة بالأسبوع الماضي فهي
/// محسوبة حقًّا: جلسات الأسبوعين موجودتان في القائمة نفسها، فالفرق بينهما
/// قياس لا تخمين — ومع ذلك تُحذف إذا لم يكن للأسبوع الماضي رصيد يُقاس عليه.
class WeeklyStudySummary {
  final StudyWeek week;

  /// دقائق الجلسات المكتملة التي بدأت داخل الأسبوع.
  final int studiedMinutes;

  /// دقائق الأسبوع السابق، للمقارنة.
  final int previousWeekMinutes;

  /// عدد الجلسات المكتملة داخل الأسبوع.
  final int completedSessions;

  /// اليوم الأكثر مذاكرةً (1=الاثنين … 7=الأحد بترقيم DateTime)، أو null.
  final int? bestWeekday;
  final int bestWeekdayMinutes;

  /// المهام الشخصية التي أُنجزت داخل الأسبوع، بحسب completedAt المخزَّن.
  final int completedTasks;

  /// الواجبات التي عُلِّمت مكتملة داخل الأسبوع، بحسب completedAt المخزَّن.
  final int completedAssignments;

  /// حالة المهام الآن — لقطة راهنة لا رقم أسبوعي، وتُسمّى كذلك في الواجهة.
  final int overdueTasks;
  final int pendingTasks;

  const WeeklyStudySummary({
    required this.week,
    this.studiedMinutes = 0,
    this.previousWeekMinutes = 0,
    this.completedSessions = 0,
    this.bestWeekday,
    this.bestWeekdayMinutes = 0,
    this.completedTasks = 0,
    this.completedAssignments = 0,
    this.overdueTasks = 0,
    this.pendingTasks = 0,
  });

  bool get hasStudyTime => studiedMinutes > 0;
  bool get hasBestDay => bestWeekday != null && bestWeekdayMinutes > 0;

  /// نسبة التغيّر عن الأسبوع الماضي، أو null إذا لم يكن هناك ما يُقارَن به.
  ///
  /// بلا رصيد سابق لا توجد نسبة: القسمة على صفر ليست «+100%»، وعرضها كذلك
  /// ادّعاء. الواجهة تحذف السطر كاملًا حينها.
  double? get trendRatio {
    if (previousWeekMinutes <= 0) return null;
    return (studiedMinutes - previousWeekMinutes) / previousWeekMinutes;
  }

  bool get hasTrend => trendRatio != null;

  int get totalCompletedWork => completedTasks + completedAssignments;

  bool get isEmpty =>
      studiedMinutes == 0 && completedSessions == 0 && totalCompletedWork == 0;

  factory WeeklyStudySummary.from({
    required List<StudySessionModel> sessions,
    required List<TaskModel> tasks,
    required Map<String, DateTime?> assignmentCompletionTimes,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final week = StudyWeek.containing(reference);
    final previous = week.previous;

    var minutes = 0;
    var previousMinutes = 0;
    var count = 0;
    final perWeekday = <int, int>{};

    for (final session in sessions) {
      if (!session.isCompleted) continue;
      final at = session.startedAt;
      final value = session.actualMinutes;
      if (value <= 0) continue;

      if (week.contains(at)) {
        minutes += value;
        count++;
        perWeekday[at.weekday] = (perWeekday[at.weekday] ?? 0) + value;
      } else if (previous.contains(at)) {
        previousMinutes += value;
      }
    }

    int? bestDay;
    var bestMinutes = 0;
    perWeekday.forEach((weekday, total) {
      if (total > bestMinutes) {
        bestMinutes = total;
        bestDay = weekday;
      }
    });

    /*
     * «أُنجزت هذا الأسبوع» تعني طابع إنجاز داخل الأسبوع، لا مجرّد كونها
     * مكتملة الآن. المهمة تحمل completedAt يكتبه الخادم عند الإنجاز
     * ويُحذف عند التراجع، فالسؤال قابل للإجابة بصدق. لولا هذا الحقل لَما
     * جاز عرض المؤشر أصلًا.
     */
    var completedTasks = 0;
    var overdue = 0;
    var pending = 0;
    for (final task in tasks) {
      if (task.isCompleted) {
        final at = task.completedAt;
        if (at != null && week.contains(at)) completedTasks++;
      } else {
        pending++;
        if (task.isOverdue(relativeTo: reference)) overdue++;
      }
    }

    var completedAssignments = 0;
    assignmentCompletionTimes.forEach((_, at) {
      if (at != null && week.contains(at)) completedAssignments++;
    });

    return WeeklyStudySummary(
      week: week,
      studiedMinutes: minutes,
      previousWeekMinutes: previousMinutes,
      completedSessions: count,
      bestWeekday: bestDay,
      bestWeekdayMinutes: bestMinutes,
      completedTasks: completedTasks,
      completedAssignments: completedAssignments,
      overdueTasks: overdue,
      pendingTasks: pending,
    );
  }

  /// نسخة فارغة لأسبوع بعينه، تُستعمل في حالات «لا بيانات».
  factory WeeklyStudySummary.empty([DateTime? now]) => WeeklyStudySummary(
    week: StudyWeek.containing(now ?? DateTime.now()),
  );

  /// موجود ليبقى الاستيراد صريحًا في الاختبارات التي تبني سجلات تقدّم.
  static Map<String, DateTime?> completionTimesOf(
    Iterable<AssignmentProgressModel> records,
  ) {
    final map = <String, DateTime?>{};
    for (final record in records) {
      if (record.isCompleted) map[record.assignmentId] = record.completedAt;
    }
    return map;
  }
}
