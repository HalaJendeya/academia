import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../courses/models/student_course_view.dart';
import '../../courses/providers/student_courses_provider.dart';
import '../models/course_assignment_model.dart';
import '../providers/assignment_progress_provider.dart';
import '../providers/course_assignment_provider.dart';
import '../widgets/assignment_status_chips.dart';

/// وسيطات شاشة تفاصيل الواجب للطالب.
///
/// يُمرَّر النموذج كاملًا لا معرّفه، بخلاف شاشة المعلّم: الواجب موجود
/// بالفعل في يد البطاقة التي فُتحت منها الشاشة، فقراءته من Firestore مرة
/// أخرى طلب شبكة لا يضيف معلومة.
class StudentAssignmentDetailsArgs {
  const StudentAssignmentDetailsArgs({required this.assignment});

  final CourseAssignmentModel assignment;
}

/// تفاصيل واجب أكاديمي من منظور الطالب — قراءة فقط.
///
/// لا تعديل ولا أرشفة ولا تسليم. الواجب يملكه معلّم المساق، والقواعد لا
/// تمنح الطالب أي كتابة على `/assignments`؛ عرض زرّ لأيٍّ من ذلك وعدٌ بما
/// لا وجود له. شاشة المعلّم TeacherAssignmentDetailsScreen هي التي تحمل
/// الأفعال، وهذه الشاشة تشترك معها في البنية والشارات وتنسيق التاريخ فقط.
class StudentAssignmentDetailsScreen extends StatelessWidget {
  const StudentAssignmentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final passed = arguments is StudentAssignmentDetailsArgs
        ? arguments.assignment
        : null;

    if (passed == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AcademiaSubAppBar(
          title: AppStrings.assignmentDetailsScreenTitle,
        ),
        body: AppEmptyState(
          title: AppStrings.assignmentUnavailableTitle,
          description: AppStrings.assignmentUnavailableDesc,
          icon: Icons.assignment_late_outlined,
          actionLabel: AppStrings.backToAssignmentsAction,
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }

    final assignment = _freshest(context, passed);
    final courseView = _findCourseView(context, assignment.offeringId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AcademiaSubAppBar(
        title: AppStrings.assignmentDetailsScreenTitle,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(context, assignment, courseView),
            const SizedBox(height: AppSpacing.large),
            _buildInstructionsCard(assignment),
            const SizedBox(height: AppSpacing.large),
            _buildCompletionSection(context, assignment),
            _buildReadOnlyNote(),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }

  /// أحدث نسخة متاحة من الواجب دون أي قراءة إضافية.
  ///
  /// المزوّد يبثّ الواجبات أصلًا لشاشة «المهام والواجبات» (نطاق التجميع)
  /// ولتبويب واجبات المساق (نطاق الطرح المختار)، فتعديل المعلّم لعنوان أو
  /// موعد يظهر هنا فورًا. غياب الواجب عن البثّ لا يُقرأ حذفًا: النسخة
  /// المُمرَّرة تبقى معروضة، وإلا لأفرغت الأرشفةُ شاشةً يقرؤها الطالب.
  static CourseAssignmentModel _freshest(
    BuildContext context,
    CourseAssignmentModel passed,
  ) {
    final provider = context.watch<CourseAssignmentProvider>();

    for (final live in provider.assignments) {
      if (live.id == passed.id) return live;
    }
    for (final live in provider.selectedAssignments) {
      if (live.id == passed.id) return live;
    }
    return passed;
  }

  /// المساق الذي ينتمي إليه الواجب، من تسجيلات الطالب نفسه.
  ///
  /// السجل يُفتَّش أيضًا لا الفصل الحالي وحده: تفاصيل مساق منتهٍ تعرض
  /// واجباته، ومنها تُفتح هذه الشاشة.
  static StudentCourseView? _findCourseView(
    BuildContext context,
    String offeringId,
  ) {
    if (offeringId.trim().isEmpty) return null;

    final provider = context.watch<StudentCoursesProvider>();

    for (final view in provider.currentCourses) {
      if (view.offeringId == offeringId) return view;
    }
    for (final view in provider.history) {
      if (view.offeringId == offeringId) return view;
    }
    return null;
  }

  /// «رمز المساق — اسمه»، أو null إن تعذّر حلّه.
  ///
  /// الواجب يحمل معرّفات لا أسماء. تعذّر الحلّ يعني إخفاء السطر بدل عرض
  /// معرّف خام لا يعني للطالب شيئًا.
  static String? _courseLabel(StudentCourseView? view) {
    if (view == null) return null;

    final code = view.courseCode.trim();
    final title = view.title.trim();

    if (code.isNotEmpty && title.isNotEmpty) return '$code — $title';
    if (title.isNotEmpty) return title;
    if (code.isNotEmpty) return code;
    return null;
  }

  Widget _buildHeaderCard(
    BuildContext context,
    CourseAssignmentModel assignment,
    StudentCourseView? courseView,
  ) {
    final completed = _isCompleted(context, assignment.id);
    final courseLabel = _courseLabel(courseView);
    final section = courseView?.section.trim() ?? '';
    final teacherName = courseView?.instructorName.trim() ?? '';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            assignment.title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          if (courseLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              section.isEmpty
                  ? courseLabel
                  : '$courseLabel · ${AppStrings.offeringSectionLabel} $section',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ],
          const Divider(height: 24, color: AppColors.divider),
          // Wrap لا Row: شارتان بنص عربي قد لا تتسعان في صف واحد على عرض 360.
          //
          // شارة الإنجاز تحلّ محل الحالة الزمنية ولا تُضاف إليها: «مُنجَز
          // ومتأخر» معًا رسالة متناقضة، والإنجاز هو الأحدث والأهم للطالب.
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AssignmentPriorityBadge(priority: assignment.priority),
              if (completed)
                AppStatusBadge(
                  label: AppStrings.assignmentCompletedBadge,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.secondary,
                  icon: Icons.task_alt_rounded,
                )
              else
                AssignmentDueStateBadge(assignment: assignment),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          _infoLine(
            Icons.event_rounded,
            AppStrings.assignmentDueAtLabel,
            assignment.dueDateLabel,
          ),
          _infoLine(
            assignment.isActive
                ? Icons.check_circle_outline_rounded
                : Icons.archive_outlined,
            AppStrings.statusLabel,
            assignment.isActive
                ? AppStrings.activeStatus
                : AppStrings.archivedStatus,
          ),
          // الأسطر التالية اختيارية: تُعرض حين يمكن حلّها فعلًا فقط.
          if (teacherName.isNotEmpty)
            _infoLine(
              Icons.co_present_rounded,
              AppStrings.assignmentTeacherLabel,
              teacherName,
            ),
          if (assignment.createdAt != null)
            _infoLine(
              Icons.schedule_rounded,
              AppStrings.assignmentCreatedAtLabel,
              DateFormat('yyyy/MM/dd', 'ar').format(assignment.createdAt!),
            ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(CourseAssignmentModel assignment) {
    final hasInstructions = assignment.description.trim().isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.assignmentInstructionsSectionTitle,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const Divider(color: AppColors.divider),
          // نص للعرض لا حقل إدخال: الطالب لا يملك تعديله.
          Text(
            hasInstructions
                ? assignment.description
                : AppStrings.assignmentNoInstructions,
            style: AppTextStyles.bodyMedium.copyWith(
              color: hasInstructions
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------- علامة الإنجاز الشخصية

  /// جلسة طالب نشط. غيرها لا ترى زرّ الإنجاز إطلاقًا.
  ///
  /// المسار وحده يكفي عمليًا — المعلّم والمشرف لهما شاشات تفاصيل أخرى —
  /// لكن الشرط مكتوب صراحةً حتى لا يفتح تغييرُ تنقّلٍ لاحقًا زرًّا تكتب
  /// خلفَه قاعدةُ Firestore رفضًا.
  static bool _isStudentSession(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isLoggedIn && auth.isStudent && auth.isAccountActive;
  }

  static bool _isCompleted(BuildContext context, String assignmentId) {
    if (!_isStudentSession(context)) return false;
    return context.watch<AssignmentProgressProvider>().isCompleted(
      assignmentId,
    );
  }

  /// زرّ «تم الإنجاز»، أو بطاقة الإنجاز مع إمكانية التراجع.
  ///
  /// 🔴 ليس تسليمًا: لا يرفع ملفًا ولا يُعلم المعلّم ولا ينشئ درجة. كل ما
  /// يكتبه مستند في /assignmentProgress يخصّ هذا الطالب وحده، ولا يمسّ
  /// مستند الواجب المشترك — لا status ولا dueAt ولا priority.
  Widget _buildCompletionSection(
    BuildContext context,
    CourseAssignmentModel assignment,
  ) {
    if (!_isStudentSession(context)) return const SizedBox.shrink();

    final progress = context.watch<AssignmentProgressProvider>();
    final completed = progress.isCompleted(assignment.id);
    final saving = progress.isSaving(assignment.id);

    /*
     * الواجب المؤرشف سحبه المعلّم، فلا معنى لبدء إنجازه الآن. لكن علامة
     * وُضعت قبل الأرشفة تبقى ظاهرة مع إمكانية التراجع: إخفاؤها كان سيبدو
     * كأن عمل الطالب اختفى.
     */
    if (!completed && assignment.isArchived) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.large),
      child: completed
          ? _buildCompletedCard(context, assignment, progress, saving)
          : AppPrimaryButton(
              label: AppStrings.assignmentMarkDoneAction,
              icon: Icons.check_rounded,
              isLoading: saving,
              // التعطيل أثناء الحفظ هو حارس النقر المزدوج في الواجهة؛
              // المزوّد يحمل الحارس الثاني، فالضغطتان المتلاحقتان لا
              // تنتجان كتابتين مهما كان توقيتهما.
              onPressed: saving
                  ? null
                  : () => _toggleCompletion(context, assignment.id, true),
            ),
    );
  }

  Widget _buildCompletedCard(
    BuildContext context,
    CourseAssignmentModel assignment,
    AssignmentProgressProvider progress,
    bool saving,
  ) {
    /*
     * التاريخ قد يكون null بعد الضغط مباشرةً ودون اتصال: الطابع الزمني
     * يأتي من الخادم، والنسخة المحلية تصل بلا قيمة حتى تتم المزامنة.
     * الحالة "منجَز" صحيحة فورًا، والسطر الزمني وحده هو ما ينتظر.
     */
    final completedAt = progress.completedAt(assignment.id);

    return AppCard(
      backgroundColor: AppColors.secondary.withValues(alpha: 0.06),
      borderColor: AppColors.secondary.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.task_alt_rounded,
                size: 20,
                color: AppColors.secondary,
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  AppStrings.assignmentCompletedTitle,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          if (completedAt != null) ...[
            const SizedBox(height: AppSpacing.small),
            _infoLine(
              Icons.schedule_rounded,
              AppStrings.assignmentCompletedAtLabel,
              DateFormat('yyyy/MM/dd · hh:mm a', 'ar').format(completedAt),
            ),
          ],
          const SizedBox(height: AppSpacing.medium),
          AppSecondaryButton(
            label: AppStrings.assignmentUndoDoneAction,
            icon: Icons.undo_rounded,
            isLoading: saving,
            onPressed: saving
                ? null
                : () => _toggleCompletion(context, assignment.id, false),
          ),
        ],
      ),
    );
  }

  /// يكتب العلامة ويعطي تغذية راجعة بنمط التطبيق المعتاد.
  ///
  /// لا تحديث متفائل هنا: البثّ الحيّ للمزوّد يعيد الحالة — من الذاكرة
  /// المحلية فورًا حين لا يوجد اتصال — فلا تتعارض حالتان. عند الفشل تبقى
  /// الواجهة على الحالة الصحيحة تلقائيًا لأنها لم تتغيّر أصلًا.
  Future<void> _toggleCompletion(
    BuildContext context,
    String assignmentId,
    bool completed,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = context.read<AssignmentProgressProvider>();

    final success = await provider.setCompleted(assignmentId, completed);

    // ضغطة مكرَّرة أثناء الحفظ يبتلعها المزوّد ولا تستحق رسالة.
    if (!success && provider.errorMessage == null) return;

    scaffoldMessenger.showSnackBar(
      success
          ? SnackBar(
              content: Text(
                completed
                    ? AppStrings.assignmentMarkedDoneSuccess
                    : AppStrings.assignmentUndoneSuccess,
              ),
            )
          : SnackBar(
              // نص عربي من الخدمة، لا نص استثناء Firebase الخام.
              content: Text(
                provider.errorMessage ??
                    AppStrings.assignmentProgressSaveError,
              ),
              backgroundColor: AppColors.error,
            ),
    );
  }

  /// يشرح غياب الأزرار مرة واحدة، بدل عرض أزرار معطَّلة لا تفسّر نفسها.
  Widget _buildReadOnlyNote() {
    return AppCard(
      backgroundColor: AppColors.surfaceSecondary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              '${AppStrings.assignmentStudentReadOnlyNote}\n'
              '${AppStrings.assignmentCompletionPrivateNote}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
