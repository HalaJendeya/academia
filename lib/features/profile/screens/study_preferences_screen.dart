import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_section.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../onboarding/widgets/duration_option.dart';
import '../../onboarding/widgets/study_day_chip.dart';
import '../models/study_preferences.dart';
import '../providers/study_preferences_provider.dart';

class StudyPreferencesScreen extends StatefulWidget {
  const StudyPreferencesScreen({super.key});

  @override
  State<StudyPreferencesScreen> createState() => _StudyPreferencesScreenState();
}

class _StudyPreferencesScreenState extends State<StudyPreferencesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StudyPreferencesProvider>();
      if (!provider.isSaving) {
        provider.loadPreferences(forceRefresh: true);
      }
    });
  }

  void _handleNavigation(int index) {
    handleMainNavigation(context, index, currentIndex: 4);
  }

  Future<void> _pickCustomDuration(int currentDuration) async {
    final provider = context.read<StudyPreferencesProvider>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomDurationSheet(
        onConfirm: provider.setPreferredSessionDuration,
      ),
    );
  }

  void _savePreferences() async {
    final provider = context.read<StudyPreferencesProvider>();
    final success = await provider.savePreferences();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.studyPreferencesSavedSuccessfully),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final error =
          provider.errorMessage ?? AppStrings.studyPreferencesSaveError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyPreferencesProvider>();
    final preferences = provider.preferences;

    if (provider.isLoading && preferences == null) {
      return AuthenticatedPageScaffold(
        currentIndex: 4,
        onNavigationTap: _handleNavigation,
        appBar: const AcademiaSubAppBar(
          title: AppStrings.studyPreferencesTitle,
        ),
        body: const AppLoadingState(message: AppStrings.loadingProfileData),
      );
    }

    if (provider.errorMessage != null && preferences == null) {
      return AuthenticatedPageScaffold(
        currentIndex: 4,
        onNavigationTap: _handleNavigation,
        appBar: const AcademiaSubAppBar(
          title: AppStrings.studyPreferencesTitle,
        ),
        body: AppErrorState(
          message: provider.errorMessage!,
          onRetry: () {
            context.read<StudyPreferencesProvider>().loadPreferences(
              forceRefresh: true,
            );
          },
        ),
      );
    }

    if (preferences == null) {
      return AuthenticatedPageScaffold(
        currentIndex: 4,
        onNavigationTap: _handleNavigation,
        appBar: const AcademiaSubAppBar(
          title: AppStrings.studyPreferencesTitle,
        ),
        body: AppErrorState(
          message: AppStrings.studyPreferencesNotAvailable,
          onRetry: () {
            context.read<StudyPreferencesProvider>().loadPreferences(
              forceRefresh: true,
            );
          },
        ),
      );
    }

    return AuthenticatedPageScaffold(
      currentIndex: 4,
      onNavigationTap: _handleNavigation,
      appBar: const AcademiaSubAppBar(title: AppStrings.studyPreferencesTitle),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.screenVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Study Days Section
              _buildStudyDaysSection(provider, preferences),
              const SizedBox(height: AppSpacing.large),

              // 2. Preferred Study Session Duration Section
              _buildDurationSection(provider, preferences),
              const SizedBox(height: AppSpacing.large),

              // 3. Information Card Section
              _buildInfoCard(),
              const SizedBox(height: AppSpacing.extraLarge),

              // 4. Save Button
              AppPrimaryButton(
                label: AppStrings.saveStudyPreferences,
                isLoading: provider.isSaving,
                isEnabled: provider.hasUnsavedChanges && !provider.isSaving,
                onPressed: _savePreferences,
              ),
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudyDaysSection(
    StudyPreferencesProvider provider,
    StudyPreferences preferences,
  ) {
    return AppSection(
      title: AppStrings.studyDaysTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.studyDaysSectionDescription,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          // Sunday, Monday, Tuesday, Wednesday
          Row(
            children: [
              Expanded(
                child: StudyDayChip(
                  label: AppStrings.sunday,
                  isSelected: preferences.studyDays.contains(AppStrings.sunday),
                  onTap: () => provider.toggleStudyDay(AppStrings.sunday),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StudyDayChip(
                  label: AppStrings.monday,
                  isSelected: preferences.studyDays.contains(AppStrings.monday),
                  onTap: () => provider.toggleStudyDay(AppStrings.monday),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StudyDayChip(
                  label: AppStrings.tuesday,
                  isSelected: preferences.studyDays.contains(
                    AppStrings.tuesday,
                  ),
                  onTap: () => provider.toggleStudyDay(AppStrings.tuesday),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StudyDayChip(
                  label: AppStrings.wednesday,
                  isSelected: preferences.studyDays.contains(
                    AppStrings.wednesday,
                  ),
                  onTap: () => provider.toggleStudyDay(AppStrings.wednesday),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Thursday, Friday, Saturday
          Row(
            children: [
              Expanded(
                child: StudyDayChip(
                  label: AppStrings.thursday,
                  isSelected: preferences.studyDays.contains(
                    AppStrings.thursday,
                  ),
                  onTap: () => provider.toggleStudyDay(AppStrings.thursday),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StudyDayChip(
                  label: AppStrings.friday,
                  isSelected: preferences.studyDays.contains(AppStrings.friday),
                  onTap: () => provider.toggleStudyDay(AppStrings.friday),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StudyDayChip(
                  label: AppStrings.saturday,
                  isSelected: preferences.studyDays.contains(
                    AppStrings.saturday,
                  ),
                  onTap: () => provider.toggleStudyDay(AppStrings.saturday),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSection(
    StudyPreferencesProvider provider,
    StudyPreferences preferences,
  ) {
    final selectedDuration = preferences.preferredSessionDuration;

    return AppSection(
      title: AppStrings.studySessionDurationSectionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.studySessionDurationSectionDescription,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: [
              Expanded(
                child: DurationOption(
                  durationMinutes: 25,
                  isSelected: selectedDuration == 25,
                  onTap: () => provider.setPreferredSessionDuration(25),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DurationOption(
                  durationMinutes: 45,
                  isSelected: selectedDuration == 45,
                  onTap: () => provider.setPreferredSessionDuration(45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DurationOption(
                  durationMinutes: 60,
                  isSelected: selectedDuration == 60,
                  onTap: () => provider.setPreferredSessionDuration(60),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DurationOption(
                  durationMinutes: 90,
                  isSelected: selectedDuration == 90,
                  onTap: () => provider.setPreferredSessionDuration(90),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _pickCustomDuration(selectedDuration),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  // Flexible لا Text عارٍ: عند اختيار مدة مخصّصة يصير النص
                  // «مدة مخصصة: 50 دقيقة» فيتجاوز عرض 360 ويفيض الصف.
                  // Flexible لا Expanded حتى يبقى النص القصير في الوسط.
                  Flexible(
                    child: Text(
                      selectedDuration != 25 &&
                              selectedDuration != 45 &&
                              selectedDuration != 60 &&
                              selectedDuration != 90
                          ? '${AppStrings.customDuration}: $selectedDuration ${AppStrings.minutes}'
                          : AppStrings.customDuration,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return AppCard(
      backgroundColor: AppColors.secondary.withValues(alpha: 0.08),
      borderColor: AppColors.secondary.withValues(alpha: 0.15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.secondary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Text(
              AppStrings.studyPreferencesInfo,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// محتوى ورقة «مدة مخصّصة».
///
/// 🔴 StatefulWidget لا StatefulBuilder، والسبب هو عمر المتحكّم.
///
/// كان المتحكّم يُنشأ داخل _pickCustomDuration ويُتلَف في
/// `showModalBottomSheet(...).then((_) => controller.dispose())`. لكن
/// مستقبل الورقة يكتمل لحظة `Navigator.pop`، بينما محتواها يبقى مركَّبًا
/// طوال حركة الإغلاق. فيُتلَف المتحكّم و TextFormField ما زال يشير إليه،
/// ثم تعيد زخرفة الحقل المتحرّكة الاشتراكَ عليه في الإطار التالي
/// (_AnimatedState.didUpdateWidget ← _MergingListenable.addListener) فترمي
/// «A TextEditingController was used after being disposed»، وما يليها من
/// أخطاء متتالية في الشجرة.
///
/// المالك الآن واحد وواضح: هذا State ينشئ المتحكّم مرة، ويُتلفه مرة عند
/// فكّ التركيب الفعلي — بعد انتهاء الحركة لا قبلها.
class _CustomDurationSheet extends StatefulWidget {
  const _CustomDurationSheet({required this.onConfirm});

  /// تُستدعى بالقيمة الصالحة وحدها؛ الورقة لا تعرف المزوّد ولا تكتب فيه.
  final void Function(int minutes) onConfirm;

  @override
  State<_CustomDurationSheet> createState() => _CustomDurationSheetState();
}

class _CustomDurationSheetState extends State<_CustomDurationSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final value = int.tryParse(_controller.text.trim());

    // نفس الحدود التي كانت في الدالة الأصلية، وهي حدود
    // StudyPreferencesService نفسها.
    if (value == null || value < 5 || value > 180) {
      setState(() => _errorText = AppStrings.invalidCustomDuration);
      return;
    }

    widget.onConfirm(value);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.customDurationTitle,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.left,
              onFieldSubmitted: (_) => _confirm(),
              decoration: InputDecoration(
                hintText: '5 - 180',
                errorText: _errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirm,
                    child: const Text(AppStrings.confirm),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(AppStrings.cancel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
