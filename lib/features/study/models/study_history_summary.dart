import 'study_session_model.dart';
import 'study_week.dart';

/// نطاق التصفية في سجل الجلسات.
///
/// كل نطاق هنا قابل للحساب من `startedAt` المخزَّن وحده — لا يوجد فلتر
/// معروض لا تسنده البيانات.
enum StudyHistoryRange { all, week, month }

/// سجل الجلسات بعد التصفية، وملخّصه.
///
/// 🔴 الملخّص يتبع التصفية دائمًا. لو عُرض «مجموع الساعات» ثابتًا فوق قائمة
/// مصفّاة بالأسبوع لقرأه الطالب على أنه مجموع الأسبوع وهو مجموع العمر —
/// فالرقم يجب أن يقيس ما تعرضه القائمة تحته بالضبط.
class StudyHistorySummary {
  /// الجلسات المغلقة بعد التصفية، الأحدث أولًا.
  final List<StudySessionModel> sessions;

  /// المكتملة وحدها تدخل في المجاميع؛ الملغاة تُعرض ولا تُحتسب.
  final int completedSessions;
  final int cancelledSessions;
  final int totalMinutes;

  final int? bestWeekday;
  final int bestWeekdayMinutes;

  const StudyHistorySummary({
    this.sessions = const [],
    this.completedSessions = 0,
    this.cancelledSessions = 0,
    this.totalMinutes = 0,
    this.bestWeekday,
    this.bestWeekdayMinutes = 0,
  });

  bool get isEmpty => sessions.isEmpty;
  bool get hasBestDay => bestWeekday != null && bestWeekdayMinutes > 0;

  /// متوسط الجلسة المكتملة بالدقائق، أو null بلا جلسات مكتملة.
  int? get averageMinutes {
    if (completedSessions == 0) return null;
    return (totalMinutes / completedSessions).round();
  }

  /// يبني السجل المصفّى وملخّصه معًا.
  ///
  /// [courseId] يقيّد النتيجة بمساق واحد؛ null يعني كل المساقات. تصفية
  /// المساق مستقلة عن النطاق الزمني، فيمكن الجمع بينهما.
  factory StudyHistorySummary.from({
    required List<StudySessionModel> sessions,
    StudyHistoryRange range = StudyHistoryRange.all,
    String? courseId,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final week = StudyWeek.containing(reference);
    final monthStart = DateTime(reference.year, reference.month);
    final monthEnd = DateTime(reference.year, reference.month + 1);

    bool inRange(DateTime at) {
      switch (range) {
        case StudyHistoryRange.all:
          return true;
        case StudyHistoryRange.week:
          return week.contains(at);
        case StudyHistoryRange.month:
          return !at.isBefore(monthStart) && at.isBefore(monthEnd);
      }
    }

    final wanted = courseId?.trim();
    final filtered = <StudySessionModel>[];

    for (final session in sessions) {
      // الجارية ليست سجلًّا بعد.
      if (session.isActive) continue;
      if (!inRange(session.startedAt)) continue;
      if (wanted != null && wanted.isNotEmpty && session.courseId != wanted) {
        continue;
      }
      filtered.add(session);
    }

    filtered.sort((a, b) => b.startedAt.compareTo(a.startedAt));

    var completed = 0;
    var cancelled = 0;
    var minutes = 0;
    final perWeekday = <int, int>{};

    for (final session in filtered) {
      if (session.isCancelled) {
        cancelled++;
        continue;
      }
      completed++;
      final value = session.actualMinutes;
      if (value <= 0) continue;
      minutes += value;
      final weekday = session.startedAt.weekday;
      perWeekday[weekday] = (perWeekday[weekday] ?? 0) + value;
    }

    int? bestDay;
    var bestMinutes = 0;
    perWeekday.forEach((weekday, total) {
      if (total > bestMinutes) {
        bestMinutes = total;
        bestDay = weekday;
      }
    });

    return StudyHistorySummary(
      sessions: filtered,
      completedSessions: completed,
      cancelledSessions: cancelled,
      totalMinutes: minutes,
      bestWeekday: bestDay,
      bestWeekdayMinutes: bestMinutes,
    );
  }

  /// المساقات التي تحمل جلسات فعلًا، لبناء قائمة تصفية المساق.
  ///
  /// تُشتقّ من الجلسات لا من تسجيلات الطالب: مساق بلا جلسة واحدة لا معنى
  /// لعرضه كخيار تصفية يؤدي دائمًا إلى قائمة فارغة.
  static List<String> courseIdsIn(List<StudySessionModel> sessions) {
    final ids = <String>[];
    for (final session in sessions) {
      if (session.isActive) continue;
      final id = session.courseId?.trim();
      if (id == null || id.isEmpty) continue;
      if (!ids.contains(id)) ids.add(id);
    }
    return ids;
  }
}
