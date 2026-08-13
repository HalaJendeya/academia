import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/providers/task_provider.dart';
import '../../tasks/widgets/status_chip.dart';

/// ملخص مهام الطالب في لوحة التحكم.
///
/// شاشة تجميع لا مجال بيانات جديد: المصدر الوحيد هو [TaskProvider] الذي
/// تعتمد عليه شاشة المهام نفسها، فلا استعلام إضافي ولا نسخة ثانية من منطق
/// التحميل. البطاقة تقرأ الحالة وتعرضها فقط.
///
/// «اليوم» و«المتأخرة» و«القادمة» تُشتق من dueAt وقت العرض عبر دوال
/// [TaskModel]، ولا تُخزَّن في Firestore.
///
/// البطاقة تراقب مزوّد المهام بنفسها: خطأ في تحميل المهام يبقى داخل هذه
/// البطاقة ولا يُفرغ بقية اللوحة.
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
    final reference = now ?? DateTime.now();

    return AppCard(
      onTap: () => _openTasks(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppSpacing.small),
          _buildBody(context, provider, reference),
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

    final pending = provider.tasks.where((task) => task.isPending).toList();

    /*
     * المهام بلا موعد تسليم لا تدخل أي مجموعة: دوال TaskModel تعيد false
     * حين يكون dueAt فارغًا، فلا تُحتسب "اليوم" ولا "متأخرة".
     */
    final overdue = _sortedByDue(
      pending.where((task) => task.isOverdue(relativeTo: reference)),
    );
    final today = _sortedByDue(
      pending.where((task) => task.isToday(relativeTo: reference)),
    );
    final upcoming = _sortedByDue(
      pending.where((task) => task.isUpcoming(relativeTo: reference)),
    );

    // ترتيب الأهمية: المتأخر أولًا، ثم اليوم، ثم الأقرب قدومًا.
    final preview = <TaskModel>[
      ...overdue,
      ...today,
      ...upcoming,
    ].take(previewLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummaryLine(today.length, overdue.length),
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
          for (final task in preview)
            _TaskPreviewRow(task: task, reference: reference),
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

  static List<TaskModel> _sortedByDue(Iterable<TaskModel> tasks) {
    final list = tasks.toList();
    // الأقرب موعدًا أولًا. كلها تحمل dueAt هنا بحكم شروط الاشتقاق.
    list.sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    return list;
  }
}

/// سطر مهمة واحد في المعاينة.
///
/// مبسَّط عمدًا مقارنةً بـ TaskCard: البطاقة الكاملة تعرض الوصف والمساق
/// وأزرار الإجراءات، وهي أطول من أن تتسع في ملخص لوحة. العنوان والموعد
/// والحالة تكفي للإجابة عن "ما الذي يستحقّ انتباهي الآن؟".
class _TaskPreviewRow extends StatelessWidget {
  const _TaskPreviewRow({required this.task, required this.reference});

  final TaskModel task;
  final DateTime reference;

  String _dueText() {
    final dueAt = task.dueAt;
    if (dueAt == null) return AppStrings.dashboardTasksNoDueDate;

    // مهام اليوم: الساعة هي المعلومة المفيدة. غيرها: التاريخ.
    final pattern = task.isToday(relativeTo: reference)
        ? 'hh:mm a'
        : 'yyyy/MM/dd';
    return DateFormat(pattern, 'ar').format(dueAt);
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue(relativeTo: reference);

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
                  : Icons.radio_button_unchecked_rounded,
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
                  task.title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _dueText(),
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
          StatusChip.status(
            task.status,
            isOverdue: isOverdue,
            isToday: task.isToday(relativeTo: reference),
            isUpcoming: task.isUpcoming(relativeTo: reference),
          ),
        ],
      ),
    );
  }
}
