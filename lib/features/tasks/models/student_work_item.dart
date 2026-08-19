import '../../assignments/models/course_assignment_model.dart';
import 'task_model.dart';

/// نوع العمل من منظور الطالب.
enum StudentWorkKind {
  /// مهمة شخصية أنشأها الطالب لنفسه — مجموعة /tasks.
  personalTask,

  /// واجب أكاديمي فرضه معلّم المساق — مجموعة /assignments.
  academicAssignment,
}

/// عنصر عمل واحد في شاشة «المهام والواجبات» الموحَّدة.
///
/// 🔴 نموذج عرض فقط. لا يُخزَّن ولا يُقرأ من Firestore، ولا يحلّ محل
/// [TaskModel] ولا [CourseAssignmentModel]: يلفّ أحدهما ويترك الحقيقة في
/// نموذجها الأصلي. المجموعتان تبقيان منفصلتين تمامًا في قاعدة البيانات —
/// المهام الشخصية يملكها الطالب، والواجبات يملكها المعلّم — والدمج يحدث
/// هنا فقط، لحظة العرض.
///
/// وجوده يمنع تكرار منطق الترتيب والحالة الزمنية في كل تبويب: التبويبات
/// الأربعة تسأل عن `dueAt` و`isOverdue` بلا أن تعرف أي نموذج تحمل.
class StudentWorkItem {
  const StudentWorkItem._({
    required this.kind,
    required this.id,
    required this.title,
    required this.dueAt,
    this.task,
    this.assignment,
  });

  factory StudentWorkItem.fromTask(TaskModel task) {
    return StudentWorkItem._(
      kind: StudentWorkKind.personalTask,
      // البادئة تمنع تصادم معرّفات بين مجموعتين مستقلتين.
      id: 'task:${task.id}',
      title: task.title,
      dueAt: task.dueAt,
      task: task,
    );
  }

  factory StudentWorkItem.fromAssignment(CourseAssignmentModel assignment) {
    return StudentWorkItem._(
      kind: StudentWorkKind.academicAssignment,
      id: 'assignment:${assignment.id}',
      title: assignment.title,
      dueAt: assignment.dueAt,
      assignment: assignment,
    );
  }

  final StudentWorkKind kind;
  final String id;
  final String title;

  /// موعد الاستحقاق. null ممكن للمهام الشخصية وحدها — الواجب الأكاديمي
  /// يحمل موعدًا دائمًا.
  final DateTime? dueAt;

  /// أحدهما غير null بالضبط، بحسب [kind].
  final TaskModel? task;
  final CourseAssignmentModel? assignment;

  bool get isPersonalTask => kind == StudentWorkKind.personalTask;
  bool get isAcademicAssignment => kind == StudentWorkKind.academicAssignment;

  /// هل يظهر هذا العنصر ضمن العمل المفتوح؟
  ///
  /// المهمة المكتملة والواجب المؤرشف كلاهما خارج «الكل»: الأول أنهاه
  /// الطالب، والثاني سحبه المعلّم.
  bool get isOpen {
    switch (kind) {
      case StudentWorkKind.personalTask:
        return task!.isPending;
      case StudentWorkKind.academicAssignment:
        return assignment!.isActive;
    }
  }

  bool isOverdue({DateTime? relativeTo}) {
    switch (kind) {
      case StudentWorkKind.personalTask:
        return task!.isOverdue(relativeTo: relativeTo);
      case StudentWorkKind.academicAssignment:
        return assignment!.isOverdue(relativeTo: relativeTo);
    }
  }

  bool isDueToday({DateTime? relativeTo}) {
    switch (kind) {
      case StudentWorkKind.personalTask:
        return task!.isToday(relativeTo: relativeTo);
      case StudentWorkKind.academicAssignment:
        return assignment!.isDueToday(relativeTo: relativeTo);
    }
  }

  /*
   * الحالتان ليستا متطابقتين بين النموذجين، وهذا مقصود لا إهمال:
   *
   *   - المهمة الشخصية يومية الدقة: `isOverdue` فيها لا يشمل اليوم نفسه،
   *     فمهمة اليوم ليست متأخرة مهما تأخرت الساعة.
   *   - الواجب الأكاديمي له وقت تسليم محدد، فواجب اليوم التاسعة صباحًا
   *     متأخر عند الثالثة عصرًا.
   *
   * كل نموذج يجيب بدلالته الخاصة، ولا يُفرض تعريف أحدهما على الآخر.
   */

  /// رتبة الإلحاح للترتيب: الأصغر أعلى.
  ///
  /// 0 متأخر · 1 مستحق اليوم · 2 قادم بموعد · 3 بلا موعد.
  int urgencyRank({DateTime? relativeTo}) {
    if (isOverdue(relativeTo: relativeTo)) return 0;
    if (isDueToday(relativeTo: relativeTo)) return 1;
    return dueAt == null ? 3 : 2;
  }

  /// ترتيب حتمي: الإلحاح، ثم الأقرب موعدًا، ثم المعرّف.
  ///
  /// المعرّف فاصل أخير حتى لا يهتزّ ترتيب القائمة بين بثّين متتاليين حين
  /// يتساوى كل ما قبله — وهو ما يحدث فعلًا مع مهام بلا موعد.
  static int compare(
    StudentWorkItem a,
    StudentWorkItem b, {
    DateTime? relativeTo,
  }) {
    final byUrgency = a
        .urgencyRank(relativeTo: relativeTo)
        .compareTo(b.urgencyRank(relativeTo: relativeTo));
    if (byUrgency != 0) return byUrgency;

    final aDue = a.dueAt;
    final bDue = b.dueAt;
    if (aDue != null && bDue != null) {
      final byDue = aDue.compareTo(bDue);
      if (byDue != 0) return byDue;
    } else if (aDue != null) {
      return -1;
    } else if (bDue != null) {
      return 1;
    }

    return a.id.compareTo(b.id);
  }

  /// دمج المصدرين في قائمة عمل واحدة مرتَّبة.
  ///
  /// [tasks] و[assignments] تُقرآن من مزوّديهما دون تعديل: هذه الدالة لا
  /// تملك أيًّا منهما ولا تكتب فيهما.
  static List<StudentWorkItem> merge({
    required Iterable<TaskModel> tasks,
    required Iterable<CourseAssignmentModel> assignments,
    DateTime? relativeTo,
    bool openOnly = true,
  }) {
    final items = <StudentWorkItem>[
      ...tasks.map(StudentWorkItem.fromTask),
      ...assignments.map(StudentWorkItem.fromAssignment),
    ];

    final filtered = openOnly
        ? items.where((item) => item.isOpen).toList()
        : items;

    filtered.sort((a, b) => compare(a, b, relativeTo: relativeTo));
    return filtered;
  }
}
