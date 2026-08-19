import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../assignments/models/course_assignment_model.dart';
import '../../assignments/providers/course_assignment_provider.dart';
import '../../tasks/models/student_work_item.dart';
import '../../tasks/providers/task_provider.dart';
import '../../tasks/widgets/status_chip.dart';

/// ملخص عبء الطالب اليوم في لوحة التحكم.
///
/// تجميع عرضٍ لا مجال بيانات جديد: المصدران هما [TaskProvider] و
/// [CourseAssignmentProvider] نفساهما اللذان تعتمد عليهما شاشة «المهام
/// والواجبات»، فلا استعلام إضافي ولا نسخة ثانية من منطق التحميل. البطاقة
/// تقرأ الحالة وتعرضها فقط.
///
/// الدمج يتم عبر [StudentWorkItem] بالترتيب نفسه المستعمل في الشاشة، حتى لا
/// يقول الملخّص شيئًا وتقول الشاشة غيره.
///
/// «اليوم» و«المتأخرة» تُشتقّان من موعد الاستحقاق وقت العرض، ولا تُخزَّنان.
///
/// كل مصدر معزول عن الآخر: فشل تحميل الواجبات يترك ملخّص المهام كما هو،
/// وفشل المهام يبقى داخل هذه البطاقة ولا يُفرغ بقية اللوحة.
class TodayTasksCard extends StatelessWidget {
  const TodayTasksCard({super.key, this.now});

  /// اللحظة المرجعية للاشتقاق. تُحقن في الاختبارات حتى لا يتغيّر الناتج
  /// بتغيّر ساعة الجهاز أو بعبور منتصف الليل أثناء التنفيذ.
  final DateTime? now;

  /// أقصى عدد مهام في المعاينة. البطاقة ملخّص لا قائمة.
  static const int previewLimit = 3;

  void _openTasks(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.tasks);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    // الواجبات مصدر ثانٍ مستقل؛ فشله لا يُسقط ملخص المهام والعكس.
    final assignmentProvider = context.watch<CourseAssignmentProvider>();
    final reference = now ?? DateTime.now();

    return AppCard(
      onTap: () => _openTasks(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppSpacing.small),
          _buildBody(context, provider, assignmentProvider, reference),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondary.withValues(alpha: 0.08),
          ),
          child: const Icon(
            Icons.assignment_outlined,
            color: AppColors.secondary,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Text(
            AppStrings.dashboardTasksTitle,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        // وجهة واحدة للمهام: شاشة المهام القائمة، بلا شاشة خاصة باللوحة.
        TextButton(
          onPressed: () => _openTasks(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            AppStrings.dashboardTasksViewAll,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    TaskProvider provider,
    CourseAssignmentProvider assignmentProvider,
    DateTime reference,
  ) {
    /*
     * أثناء التحميل لا يُعرض عدد. صفرٌ مؤقت يقرأه الطالب كخبر ("لا مهام
     * اليوم") ثم يتبدّل، وهو رقم لا مصدر له بعد.
     */
    if (provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.small),
        child: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // الخطأ يبقى محصورًا في هذه البطاقة: بقية اللوحة لا تعتمد على المهام.
    if (provider.errorMessage != null) {
      return Text(
        provider.errorMessage!,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        textAlign: TextAlign.right,
      );
    }

    /*
     * العبء الدراسي اليوم = المهام الشخصية + الواجبات الأكاديمية.
     *
     * المصدران يبقيان منفصلين تمامًا في Firestore؛ الدمج هنا عرضٌ فقط عبر
     * [StudentWorkItem]، وهو نفسه المستعمل في شاشة «المهام والواجبات» حتى
     * لا يختلف ترتيب اللوحة عن ترتيب الشاشة.
     *
     * العناصر بلا موعد لا تدخل أي مجموعة زمنية: دوال النموذجين تعيد false
     * حين لا يوجد موعد، فلا تُحتسب «اليوم» ولا «متأخرة».
     */
    final items = StudentWorkItem.merge(
      tasks: provider.tasks,
      // فشل الواجبات لا يُسقط ملخّص المهام: تُعرض المهام وحدها.
      assignments: assignmentProvider.errorMessage != null
          ? const <CourseAssignmentModel>[]
          : assignmentProvider.activeAssignments,
      relativeTo: reference,
    );

    final overdueCount = items
        .where((item) => item.isOverdue(relativeTo: reference))
        .length;
    final todayCount = items
        .where((item) => item.isDueToday(relativeTo: reference))
        .length;

    /*
     * المعاينة زمنية: ما له موعد فقط.
     *
     * merge تُبقي العناصر بلا موعد في آخر القائمة لأنها عمل قائم فعلًا،
     * وتبويب «الكل» يعرضها. أما هذه البطاقة فتجيب عن «ما الذي يستحق
     * انتباهي الآن؟»، ومهمة بلا موعد لا تزاحم على هذا السؤال — وهو السلوك
     * الذي كانت عليه البطاقة قبل دمج الواجبات.
     */
    final preview = items
        .where((item) => item.dueAt != null)
        .take(previewLimit)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummaryLine(todayCount, overdueCount),
        if (preview.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.extraSmall),
            child: Text(
              AppStrings.dashboardTasksEmptyHint,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.right,
            ),
          )
        else ...[
          const SizedBox(height: AppSpacing.small),
          for (final item in preview)
            _WorkPreviewRow(item: item, reference: reference),
        ],
      ],
    );
  }

  Widget _buildSummaryLine(int todayCount, int overdueCount) {
    return Row(
      children: [
        Expanded(
          child: Text(
            AppStrings.dashboardTasksTodaySummary(todayCount),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // شارة التأخير تظهر فقط حين يوجد تأخير فعلي.
        if (overdueCount > 0) ...[
          const SizedBox(width: AppSpacing.small),
          StatusChip(
            label: AppStrings.dashboardTasksOverdueSummary(overdueCount),
            foreground: AppColors.danger,
            background: AppColors.danger.withValues(alpha: 0.12),
          ),
        ],
      ],
    );
  }

}

/// سطر عمل واحد في المعاينة — مهمة شخصية أو واجب أكاديمي.
///
/// مبسَّط عمدًا مقارنةً بـ TaskCard: البطاقة الكاملة تعرض الوصف والمساق
/// وأزرار الإجراءات، وهي أطول من أن تتسع في ملخص لوحة. العنوان والموعد
/// والحالة تكفي للإجابة عن "ما الذي يستحقّ انتباهي الآن؟".
///
/// المصدر مميَّز بشارة نصية: الطالب يملك مهمته الشخصية ويستطيع إنهاءها،
/// بينما الواجب مفروض عليه ولا يملك تغييره — والخلط بينهما يجعل الملخص
/// مضللًا.
class _WorkPreviewRow extends StatelessWidget {
  const _WorkPreviewRow({required this.item, required this.reference});

  final StudentWorkItem item;
  final DateTime reference;

  String _dueText() {
    final dueAt = item.dueAt;
    if (dueAt == null) return AppStrings.dashboardTasksNoDueDate;

    // ما يستحق اليوم: الساعة هي المعلومة المفيدة. غيره: التاريخ.
    final pattern = item.isDueToday(relativeTo: reference)
        ? 'hh:mm a'
        : 'yyyy/MM/dd';
    return DateFormat(pattern, 'ar').format(dueAt);
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = item.isOverdue(relativeTo: reference);
    final isAssignment = item.isAcademicAssignment;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              isOverdue
                  ? Icons.error_outline_rounded
                  : (isAssignment
                        ? Icons.assignment_outlined
                        : Icons.radio_button_unchecked_rounded),
              size: 14,
              color: isOverdue ? AppColors.danger : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  // المصدر ثم الموعد، حتى يُقرأ النوع قبل التاريخ.
                  '${isAssignment ? AppStrings.workKindAssignment : AppStrings.workKindPersonalTask}'
                  ' · ${_dueText()}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isOverdue ? AppColors.danger : AppColors.textMuted,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          /*
           * شارة الحالة تخص المهمة الشخصية وحدها: StatusChip.status مبنيّ
           * على TaskStatus، ولا حالة إنجاز للواجب الأكاديمي لكل طالب.
           */
          if (!isAssignment)
            StatusChip.status(
              item.task!.status,
              isOverdue: isOverdue,
              isToday: item.isDueToday(relativeTo: reference),
              isUpcoming: item.task!.isUpcoming(relativeTo: reference),
            ),
        ],
      ),
    );
  }
}
