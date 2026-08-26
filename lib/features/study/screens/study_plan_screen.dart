import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../courses/providers/student_courses_provider.dart';

/// خطة المذاكرة — إطار Figma‏ 96:763.
///
/// 🔴 النموذج حقيقي، والتوليد غير مفعَّل — عن قصد.
///
/// التصميم يقدّم «مساعدًا أكاديميًا يحلّل مهامك ومواعيدك ويولّد خطة». لا
/// يملك المشروع أي بنية لذلك: لا نموذج لغوي، ولا دوال سحابية، ولا خطة
/// Firebase مدفوعة. وتوليد جدول بقواعد بسيطة ثم تقديمه كتحليل ذكي ادّعاء،
/// كما أن جدولًا لا يُحفَظ ولا يُذكِّر ليس منتجًا — النظام لا يعرف الجلسات
/// المجدولة أصلًا، بل الجلسات التي تبدأ الآن.
///
/// لذلك: تُحفظ الاختيارات في الشاشة، ويقول زر التوليد الحقيقة عند ضغطه.
/// لا نص هنا يزعم أن شيئًا «حُلِّل» أو «اقتُرح».
class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

enum _PlanPeriod { week, twoWeeks, month }

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  _PlanPeriod _period = _PlanPeriod.week;
  final Set<String> _selectedCourseIds = <String>{};
  double _dailyHours = 4;

  static const _periodLabels = {
    _PlanPeriod.week: AppStrings.planPeriodWeek,
    _PlanPeriod.twoWeeks: AppStrings.planPeriodTwoWeeks,
    _PlanPeriod.month: AppStrings.planPeriodMonth,
  };

  void _showUnavailable() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.planUnavailableTitle),
        content: const Text(AppStrings.planUnavailableBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<StudentCoursesProvider>().currentCourses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AcademiaSubAppBar(
        title: AppStrings.studyPlanTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.medium,
            AppSpacing.screenHorizontal,
            AppSpacing.huge,
          ),
          children: [
            // تنبيه مقدَّم لا مُخبَّأ خلف الزر: الطالب يعرف قبل أن يملأ.
            AppCard(
              backgroundColor: AppColors.secondary.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Text(
                      AppStrings.planUnavailableBody,
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.large),

            Text(
              AppStrings.planPeriodLabel,
              style: AppTextStyles.labelMedium,
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: [
                for (final entry in _periodLabels.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: entry.key == _period,
                    onSelected: (_) => setState(() => _period = entry.key),
                    selectedColor: AppColors.primary,
                    labelStyle: AppTextStyles.labelMedium.copyWith(
                      color: entry.key == _period
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),

            Text(
              AppStrings.planCoursesLabel,
              style: AppTextStyles.labelMedium,
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: AppSpacing.small),
            if (courses.isEmpty)
              Text(
                AppStrings.noEnrolledCoursesForSession,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              // المساقات المسجَّلة فعلًا وحدها — لا أمثلة.
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  for (final course in courses)
                    FilterChip(
                      label: Text(
                        course.title.isEmpty ? course.courseCode : course.title,
                      ),
                      selected: _selectedCourseIds.contains(course.courseId),
                      onSelected: (on) => setState(() {
                        if (on) {
                          _selectedCourseIds.add(course.courseId);
                        } else {
                          _selectedCourseIds.remove(course.courseId);
                        }
                      }),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.large),

            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.planDailyHoursLabel,
                    style: AppTextStyles.labelMedium,
                  ),
                ),
                Text(
                  '${_dailyHours.round()} ${AppStrings.planHoursUnit}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _dailyHours,
              min: 1,
              max: 8,
              divisions: 7,
              activeColor: AppColors.primary,
              label: '${_dailyHours.round()}',
              onChanged: (v) => setState(() => _dailyHours = v),
            ),
            const SizedBox(height: AppSpacing.extraLarge),

            AppPrimaryButton(
              label: AppStrings.planGenerateAction,
              onPressed: _showUnavailable,
            ),
          ],
        ),
      ),
    );
  }
}
