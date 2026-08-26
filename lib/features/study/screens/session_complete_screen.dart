import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../analytics/models/study_duration_format.dart';
import '../../courses/providers/student_courses_provider.dart';
import '../models/study_session_model.dart';
import '../providers/study_session_provider.dart';

/// نتيجة الجلسة — إطار Figma‏ 96:379.
///
/// تُعرض بعد إغلاق الجلسة فعلًا، وكل رقم فيها مقروء من الجلسة المخزَّنة:
/// المدة المخطَّطة، والمدة الفعلية، والمساق، والحالة. لا نقاط ولا أوسمة
/// ولا تقييم آلي — لا مصدر لأيٍّ منها في النظام.
///
/// «ماذا أنجزت؟» هو الحقل الوحيد القابل للكتابة هنا، ويُحفظ في الجلسة
/// نفسها. تخطّيه لا يكلّف كتابة إطلاقًا.
class SessionCompleteScreen extends StatefulWidget {
  const SessionCompleteScreen({super.key});

  @override
  State<SessionCompleteScreen> createState() => _SessionCompleteScreenState();
}

class _SessionCompleteScreenState extends State<SessionCompleteScreen> {
  /// يملكه هذا State ويُتلف في dispose — لا إتلاف في رد نداء تنقّل.
  final TextEditingController _reflectionController = TextEditingController();

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<StudySessionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final text = _reflectionController.text;

    final ok = await provider.saveReflection(text);
    if (!mounted) return;

    if (!ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? AppStrings.studySessionCloseError,
          ),
        ),
      );
      return;
    }

    if (text.trim().isNotEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.reflectionSaved)),
      );
    }
    // العودة إلى مركز المذاكرة، لا إلى المؤقّت الذي انتهى.
    navigator.popUntil((route) => route.isFirst);
  }

  void _startAnother() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.createStudySession);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudySessionProvider>();
    final session = provider.lastFinishedSession;
    final courses = context.watch<StudentCoursesProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: session == null
            ? _buildNoSession(context)
            : _buildResult(context, provider, session, courses),
      ),
    );
  }

  /// لا جلسة مرجعية: يحدث فقط لو فُتحت الشاشة مباشرةً. رسالة صادقة بدل
  /// دوّامة انتظار لا تنتهي.
  Widget _buildNoSession(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.noStudySessionsTitle,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.large),
            AppSecondaryButton(
              label: AppStrings.back,
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(
    BuildContext context,
    StudySessionProvider provider,
    StudySessionModel session,
    StudentCoursesProvider courses,
  ) {
    final cancelled = session.isCancelled;

    String courseTitle = AppStrings.studyGeneralSession;
    for (final course in courses.currentCourses) {
      if (course.courseId == session.courseId) {
        courseTitle = course.title.isEmpty ? course.courseCode : course.title;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.large,
        AppSpacing.screenHorizontal,
        AppSpacing.huge,
      ),
      children: [
        _SuccessHeader(cancelled: cancelled),
        const SizedBox(height: AppSpacing.large),

        Text(
          cancelled
              ? AppStrings.sessionCancelledHeadline
              : AppStrings.sessionCompleteHeadline,
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.large),

        AppCard(
          child: Column(
            children: [
              _StatRow(
                icon: Icons.schedule_rounded,
                label: AppStrings.sessionDurationRowLabel,
                value: StudyDurationFormat.format(session.actualMinutes),
                valueColor: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.small),
              _StatRow(
                icon: Icons.menu_book_rounded,
                label: AppStrings.sessionCourseRowLabel,
                value: courseTitle,
              ),
              const SizedBox(height: AppSpacing.small),
              // «45/45 دقيقة» — الفعلي من المخطَّط، كلاهما مخزَّن.
              _StatRow(
                icon: Icons.check_circle_outline_rounded,
                label: AppStrings.sessionAchievedRowLabel,
                value:
                    '${session.actualMinutes}/${session.plannedMinutes} '
                    '${AppStrings.minutesUnit}',
                valueColor: cancelled ? AppColors.textSecondary : AppColors.success,
              ),
            ],
          ),
        ),

        // الانعكاس يخصّ ما أُنجز؛ الجلسة الملغاة لم يُنجز فيها شيء يُوصف،
        // والقاعدة ترفضه عليها أصلًا.
        if (!cancelled) ...[
          const SizedBox(height: AppSpacing.large),
          Text(
            AppStrings.reflectionQuestion,
            style: AppTextStyles.labelMedium,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: AppSpacing.small),
          TextField(
            controller: _reflectionController,
            maxLines: 4,
            maxLength: StudySessionModel.maxReflectionLength,
            decoration: InputDecoration(
              hintText: AppStrings.reflectionHint,
              counterText: '',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.large),
        AppPrimaryButton(
          label: AppStrings.saveSessionAction,
          isLoading: provider.isSavingReflection,
          onPressed: provider.isSavingReflection ? null : _save,
        ),
        const SizedBox(height: AppSpacing.itemSpacing),
        AppSecondaryButton(
          label: AppStrings.startNewSessionAction,
          icon: Icons.play_arrow_rounded,
          onPressed: _startAnother,
        ),
      ],
    );
  }
}

/// دائرة النجاح أعلى الشاشة.
///
/// بلا رسم قصاصات ملوّنة: التصميم يضعها كزينة، وإضافة أصل صورة لها توسيع
/// لا يخدم معنى الشاشة. الدائرة والأيقونة تنقلان الرسالة نفسها.
class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader({required this.cancelled});

  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    final color = cancelled ? AppColors.textSecondary : AppColors.success;
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          cancelled ? Icons.close_rounded : Icons.check_rounded,
          color: color,
          size: 48,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.itemSpacing,
        vertical: AppSpacing.itemSpacing,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.small),
          // Flexible على الطرفين: أسماء المساقات تطول، وعرض 360 لا يسامح.
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
