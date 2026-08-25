import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_destructive_button.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../providers/study_session_provider.dart';
import '../widgets/study_timer.dart';

/// شاشة الجلسة الجارية.
///
/// شاشة فرعية لا تبويب: تُفتح فوق مركز المذاكرة بشريط علوي فيه زر رجوع،
/// ولا تحمل شريط تنقّل سفليًا ثانيًا.
///
/// الرجوع لا يُنهي الجلسة. المؤقّت يعيش في المزوّد لا في هذه الشاشة، فيبقى
/// جاريًا ويعود إليه الطالب من البانر في مركز المذاكرة. إنهاء الجلسة قرار
/// صريح بزر، لا أثر جانبي للتنقّل.
class ActiveSessionScreen extends StatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen>
    with WidgetsBindingObserver {
  bool _completing = false;

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
     * الانتهاء المخزَّنة في المزوّد، فهو صحيح مهما طال الغياب. ما تحتاجه
     * هذه الشاشة هو إعادة رسم فورية بدل انتظار التكّة التالية، ثم فحص ما
     * إذا كانت الجلسة قد بلغت نهايتها أثناء الغياب.
     */
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeComplete());
    }
  }

  /// يُغلق الجلسة تلقائيًا عند بلوغ الصفر — مرة واحدة.
  Future<void> _maybeComplete() async {
    if (_completing || !mounted) return;

    final provider = context.read<StudySessionProvider>();
    if (!provider.hasActiveSession || !provider.hasReachedZero) return;

    _completing = true;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await provider.complete();
    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? AppStrings.sessionCompletedBody
              : provider.errorMessage ?? AppStrings.studySessionCloseError,
        ),
      ),
    );
    if (ok && navigator.canPop()) navigator.pop();
    _completing = false;
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.keepStudyingAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _finishEarly() async {
    final confirmed = await _confirm(
      title: AppStrings.finishSessionConfirmTitle,
      body: AppStrings.finishSessionConfirmBody,
      confirmLabel: AppStrings.finishSessionAction,
    );
    if (!confirmed || !mounted) return;
    await _close(finish: true);
  }

  Future<void> _cancelSession() async {
    final confirmed = await _confirm(
      title: AppStrings.cancelSessionConfirmTitle,
      body: AppStrings.cancelSessionConfirmBody,
      confirmLabel: AppStrings.cancelSessionAction,
    );
    if (!confirmed || !mounted) return;
    await _close(finish: false);
  }

  Future<void> _close({required bool finish}) async {
    final provider = context.read<StudySessionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = finish ? await provider.finishEarly() : await provider.cancel();
    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (finish
                    ? AppStrings.sessionCompletedBody
                    : AppStrings.sessionCancelledMessage)
              : provider.errorMessage ?? AppStrings.studySessionCloseError,
        ),
      ),
    );
    if (ok && navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudySessionProvider>();

    // بلغت الصفر أثناء العرض: يُغلق بعد إتمام هذا الإطار لا أثناءه.
    if (provider.hasActiveSession && provider.hasReachedZero && !_completing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeComplete());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AcademiaSubAppBar(
        title: AppStrings.activeSessionTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: !provider.hasActiveSession
            ? _buildNoSession()
            : _buildSession(provider),
      ),
    );
  }

  Widget _buildNoSession() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Text(
          AppStrings.sessionCompletedTitle,
          style: AppTextStyles.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSession(StudySessionProvider provider) {
    final total = Duration(minutes: provider.plannedMinutes);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.large),
          Center(
            child: StudyTimer(
              remaining: provider.remaining,
              total: total,
              isPaused: provider.isPaused,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          if (provider.isPaused)
            Text(
              AppStrings.sessionPausedLabel,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: AppSpacing.extraLarge),

          if (provider.isPaused)
            AppPrimaryButton(
              label: AppStrings.resumeSessionAction,
              icon: Icons.play_arrow_rounded,
              onPressed: provider.resume,
            )
          else
            AppSecondaryButton(
              label: AppStrings.pauseSessionAction,
              icon: Icons.pause_rounded,
              onPressed: provider.pause,
            ),

          const SizedBox(height: AppSpacing.itemSpacing),
          AppSecondaryButton(
            label: AppStrings.finishSessionAction,
            icon: Icons.stop_rounded,
            isLoading: provider.isClosing,
            onPressed: provider.isClosing ? null : _finishEarly,
          ),

          const SizedBox(height: AppSpacing.itemSpacing),
          AppDestructiveButton(
            label: AppStrings.cancelSessionAction,
            icon: Icons.close_rounded,
            onPressed: provider.isClosing ? null : _cancelSession,
          ),
        ],
      ),
    );
  }
}
