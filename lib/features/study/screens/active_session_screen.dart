import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../courses/providers/student_courses_provider.dart';
import '../providers/study_session_provider.dart';
import '../widgets/study_timer.dart';

/// مؤقّت التركيز — إطار Figma‏ 161:831.
///
/// وضع تركيز كامل الشاشة: لا شريط تطبيق ولا تنقّل سفلي، فقط شارة الحالة
/// وزر إغلاق. هذا هو معنى «التركيز» في التصميم، وإبقاء أشرطة التنقّل كان
/// سيناقضه.
///
/// 🔴 منطق الوقت لم يُمسّ. المتبقي ما زال يُشتقّ من لحظة الانتهاء المخزَّنة
/// في المزوّد لا من عدّاد يُنقَص، ولا تزال Firestore تُكتب مرتين فقط طوال
/// عمر الجلسة. التغيير هنا بصري بحت.
///
/// زر الإغلاق (×) يخرج ولا يُنهي: الجلسة تبقى جارية ويعود إليها الطالب من
/// بانر المركز. الإنهاء قرار صريح بزر.
class ActiveSessionScreen extends StatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen>
    with WidgetsBindingObserver {
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /*
     * العودة من الخلفية لا تحتاج تصحيحًا للوقت — المتبقي يُحسب من لحظة
     * الانتهاء المخزَّنة، فهو صحيح مهما طال الغياب. المطلوب هنا إعادة رسم
     * فورية بدل انتظار التكّة، ثم فحص ما إذا كانت الجلسة انتهت أثناء ذلك.
     */
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeComplete());
    }
  }

  /// يُغلق الجلسة تلقائيًا عند بلوغ الصفر — مرة واحدة.
  Future<void> _maybeComplete() async {
    if (_closing || !mounted) return;
    final provider = context.read<StudySessionProvider>();
    if (!provider.hasActiveSession || !provider.hasReachedZero) return;

    _closing = true;
    final ok = await provider.complete();
    if (!mounted) {
      _closing = false;
      return;
    }
    if (ok) {
      _goToResult();
    } else {
      _showError(provider);
    }
    _closing = false;
  }

  void _goToResult() {
    // استبدال: المؤقّت انتهى، والرجوع إليه بلا جلسة لا معنى له.
    Navigator.of(context).pushReplacementNamed(AppRoutes.sessionComplete);
  }

  void _showError(StudySessionProvider provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.errorMessage ?? AppStrings.studySessionCloseError,
        ),
      ),
    );
  }

  /// حوار الإنهاء.
  ///
  /// التصميم يضع زرًّا أحمر واحدًا للإنهاء، بينما النظام يميّز بين إنهاء
  /// يُحتسب وإلغاء لا يُحتسب — وهو تمييز حقيقي في البيانات لا يصح إسقاطه.
  /// فيُعرض الخياران داخل الحوار بدل ازدحام الشاشة بثلاثة أزرار.
  Future<void> _confirmEnd() async {
    final provider = context.read<StudySessionProvider>();
    final choice = await showDialog<_EndChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.finishSessionConfirmTitle),
        content: const Text(AppStrings.finishSessionConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(_EndChoice.keep),
            child: const Text(AppStrings.keepStudyingAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(_EndChoice.cancel),
            child: const Text(
              AppStrings.cancelSessionAction,
              style: TextStyle(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(_EndChoice.finish),
            child: const Text(AppStrings.finishSessionAction),
          ),
        ],
      ),
    );

    if (!mounted || choice == null || choice == _EndChoice.keep) return;

    final ok = choice == _EndChoice.finish
        ? await provider.finishEarly()
        : await provider.cancel();

    if (!mounted) return;
    if (ok) {
      _goToResult();
    } else {
      _showError(provider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudySessionProvider>();

    if (provider.hasActiveSession && provider.hasReachedZero && !_closing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeComplete());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: !provider.hasActiveSession
            ? _buildNoSession()
            : _buildSession(context, provider),
      ),
    );
  }

  Widget _buildNoSession() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Text(
          AppStrings.noStudySessionsTitle,
          style: AppTextStyles.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSession(BuildContext context, StudySessionProvider provider) {
    final courses = context.watch<StudentCoursesProvider>();

    // عنوان الجلسة: اسمها إن سمّاها الطالب، وإلا اسم مساقها، وإلا «مذاكرة
    // عامة». لا نص مخترع في أي حال.
    String title = provider.activeSessionName ?? '';
    if (title.trim().isEmpty) {
      for (final course in courses.currentCourses) {
        if (course.courseId == provider.activeCourseId) {
          title = course.title.isEmpty ? course.courseCode : course.title;
        }
      }
    }
    if (title.trim().isEmpty) title = AppStrings.studyGeneralSession;

    final goal = provider.activeGoal;

    return Column(
      children: [
        _TimerHeader(
          paused: provider.isPaused,
          onClose: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.large),
                Text(
                  title,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (goal != null && goal.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.itemSpacing),
                  _GoalChip(goal: goal),
                ],
                const SizedBox(height: AppSpacing.extraLarge),
                StudyTimer(
                  remaining: provider.remaining,
                  total: Duration(minutes: provider.plannedMinutes),
                  isPaused: provider.isPaused,
                ),
                const SizedBox(height: AppSpacing.large),
              ],
            ),
          ),
        ),
        _FooterControls(
          paused: provider.isPaused,
          busy: provider.isClosing,
          onToggle: provider.isPaused ? provider.resume : provider.pause,
          onEnd: provider.isClosing ? null : _confirmEnd,
        ),
      ],
    );
  }
}

enum _EndChoice { keep, finish, cancel }

/// شارة «جلسة تركيز نشطة» وزر الإغلاق.
class _TimerHeader extends StatelessWidget {
  const _TimerHeader({required this.paused, required this.onClose});

  final bool paused;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.medium,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: AppStrings.back,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textSecondary,
            onPressed: onClose,
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.itemSpacing,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: paused
                            ? AppColors.textSecondary
                            : AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Flexible(
                      child: Text(
                        paused
                            ? AppStrings.sessionPausedLabel
                            : AppStrings.focusSessionActive,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // مساحة مكافئة لزر الإغلاق حتى تبقى الشارة في المنتصف بصريًا.
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.goal});

  final String goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.itemSpacing,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        '${AppStrings.goalPrefix} $goal',
        style: AppTextStyles.bodySmall,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// زرّا التذييل: إنهاء (أحمر) وإيقاف/استئناف (محدَّد).
class _FooterControls extends StatelessWidget {
  const _FooterControls({
    required this.paused,
    required this.busy,
    required this.onToggle,
    required this.onEnd,
  });

  final bool paused;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.small,
        AppSpacing.screenHorizontal,
        AppSpacing.large,
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onEnd,
              icon: const Icon(Icons.stop_circle_outlined, size: 20),
              label: const Text(
                AppStrings.endSessionAction,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.itemSpacing),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: busy ? null : onToggle,
              icon: Icon(
                paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: 20,
              ),
              label: Text(
                paused
                    ? AppStrings.resumeSessionAction
                    : AppStrings.pauseSessionAction,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
