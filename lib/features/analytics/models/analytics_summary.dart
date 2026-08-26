import '../../assignments/models/course_assignment_model.dart';
import '../../study/models/study_session_model.dart';
import '../../tasks/models/task_model.dart';

/// إحصاءات الطالب، محسوبة من البيانات المخزَّنة فعلًا.
///
/// 🔴 صنف حسابي خالص: لا خدمة، ولا مزوّد، ولا قراءة من Firestore. المصادر
/// كلها مزوّدات قائمة ومحمَّلة أصلًا لجلسة الطالب، وهذا الصنف يجمع بينها
/// فقط. جُعل مستقلًا عن الشاشة ليكون قابلًا للاختبار وحده — الحساب هو ما
/// يجب أن يُختبر، لا ترتيب البطاقات.
///
/// القاعدة الحاكمة: لا يُعرض مؤشر لا يمكن حسابه حسابًا صحيحًا. لذلك كل حقل
/// هنا مشتق من مستندات حقيقية، وما لا مصدر له — كهدف ساعات المذاكرة أو
/// اتجاه الأسبوع — لا وجود له في هذا الصنف أصلًا.
class AnalyticsSummary {
  /// المهام الشخصية التي علّمها الطالب مكتملة.
  final int completedTasks;

  /// الواجبات الأكاديمية التي علّمها الطالب مكتملة.
  final int completedAssignments;

  /// كل المهام الشخصية، مكتملة أو لا.
  final int totalTasks;

  /// الواجبات النشطة المتاحة للطالب. المؤرشفة لا تُحتسب: أزالها المعلّم
  /// من الطرح، فلا يصح أن تظل تُثقل مقام النسبة.
  final int totalAssignments;

  /// مجموع الدقائق من الجلسات المكتملة وحدها.
  final int studiedMinutes;

  /// أكثر مساق ذاكره الطالب، أو null إن لم توجد جلسة مكتملة مرتبطة بمساق.
  final String? mostStudiedCourseId;

  /// دقائق أكثر مساق مذاكرةً.
  final int mostStudiedCourseMinutes;

  const AnalyticsSummary({
    this.completedTasks = 0,
    this.completedAssignments = 0,
    this.totalTasks = 0,
    this.totalAssignments = 0,
    this.studiedMinutes = 0,
    this.mostStudiedCourseId,
    this.mostStudiedCourseMinutes = 0,
  });

  /// إجمالي ما أنجزه الطالب: مهام شخصية + واجبات أكاديمية.
  ///
  /// يُسمّى «أعمال» لا «مهام» لأنه يضم النوعين، وتسميته مهامًا تجعل الرقم
  /// يكذب على الطالب.
  int get completedWork => completedTasks + completedAssignments;

  /// كل ما هو مطلوب من الطالب، وهو مقام نسبة الإنجاز.
  int get totalWork => totalTasks + totalAssignments;

  /// هل للنسبة مقام حقيقي؟ بلا عمل مطلوب لا توجد نسبة، ولا تُعرض.
  bool get hasCompletionRate => totalWork > 0;

  /// نسبة الإنجاز بين 0 و1، أو null إذا لم يكن هناك ما يُنسب إليه.
  ///
  /// البسط جزء من المقام دائمًا بحكم طريقة الحساب في [from]، فلا يمكن أن
  /// تتجاوز النسبة 100%.
  double? get completionRate {
    if (!hasCompletionRate) return null;
    return completedWork / totalWork;
  }

  bool get hasStudyTime => studiedMinutes > 0;

  bool get hasMostStudiedCourse =>
      mostStudiedCourseId != null && mostStudiedCourseMinutes > 0;

  /// لا بيانات على الإطلاق: طالب جديد لم يبدأ بعد.
  bool get isEmpty => completedWork == 0 && totalWork == 0 && !hasStudyTime;

  /// يحسب الملخّص من مخرجات المزوّدات كما هي.
  ///
  /// [assignments] يجب أن تكون الواجبات النشطة المتاحة للطالب، و
  /// [completedAssignmentIds] مجموعة علامات الإنجاز الخاصة به. البسط
  /// يُشتقّ بتقاطع الاثنين لا بعدّ العلامات وحدها: علامة على واجب لم يعد
  /// نشطًا كانت سترفع البسط فوق المقام وتنتج نسبة تفوق 100%.
  factory AnalyticsSummary.from({
    required List<TaskModel> tasks,
    required List<CourseAssignmentModel> assignments,
    required Set<String> completedAssignmentIds,
    required List<StudySessionModel> sessions,
  }) {
    var completedTasks = 0;
    for (final task in tasks) {
      if (task.isCompleted) completedTasks++;
    }

    var completedAssignments = 0;
    for (final assignment in assignments) {
      if (completedAssignmentIds.contains(assignment.id)) {
        completedAssignments++;
      }
    }

    /*
     * الجلسات المكتملة وحدها.
     *
     * الملغاة لم تُذاكَر، والجارية لم تنتهِ بعد — واحتساب أيٍّ منهما يجعل
     * الرقم يسبق الواقع. والمجموع من actualMinutes لا plannedMinutes:
     * المخطَّط نيّة، والفعلي هو ما حدث.
     */
    var studiedMinutes = 0;
    final byCourse = <String, int>{};

    for (final session in sessions) {
      if (!session.isCompleted) continue;

      final minutes = session.actualMinutes;
      if (minutes <= 0) continue;

      studiedMinutes += minutes;

      final courseId = session.courseId?.trim();
      if (courseId != null && courseId.isNotEmpty) {
        byCourse[courseId] = (byCourse[courseId] ?? 0) + minutes;
      }
    }

    String? topCourseId;
    var topMinutes = 0;
    byCourse.forEach((courseId, minutes) {
      if (minutes > topMinutes) {
        topMinutes = minutes;
        topCourseId = courseId;
      }
    });

    return AnalyticsSummary(
      completedTasks: completedTasks,
      completedAssignments: completedAssignments,
      totalTasks: tasks.length,
      totalAssignments: assignments.length,
      studiedMinutes: studiedMinutes,
      mostStudiedCourseId: topCourseId,
      mostStudiedCourseMinutes: topMinutes,
    );
  }
}
