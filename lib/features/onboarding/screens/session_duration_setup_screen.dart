import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/duration_option.dart';
import '../providers/onboarding_provider.dart';

class SessionDurationSetupScreen extends StatefulWidget {
  const SessionDurationSetupScreen({super.key});

  @override
  State<SessionDurationSetupScreen> createState() =>
      _SessionDurationSetupScreenState();
}

class _SessionDurationSetupScreenState
    extends State<SessionDurationSetupScreen> {
  bool _isNavigating = false;

  void _handleNext() {
    if (_isNavigating) return;
    setState(() {
      _isNavigating = true;
    });

    Navigator.pushNamed(context, AppRoutes.notificationPreferencesSetup).then((
      _,
    ) {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    });
  }

  void _handleBack() {
    Navigator.of(context).pop();
  }

  void _showCustomDurationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _OnboardingCustomDurationSheet(
          onConfirm: (val) {
            Provider.of<OnboardingProvider>(
              context,
              listen: false,
            ).setPreferredSessionDuration(val);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final selectedDuration = onboardingProvider.preferredSessionDuration;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.studySessionPreferencesTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.secondary),
          onPressed: _handleBack,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main White card container
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Decorative Light-blue upper section
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.08),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.secondary,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.timer_outlined,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Inner Content Card
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                AppStrings.studySessionDurationTitle,
                                style: AppTextStyles.headlineSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppStrings.studySessionDurationDescription,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              // Custom layout row matching visually 45 | 25
                              Row(
                                children: [
                                  Expanded(
                                    child: DurationOption(
                                      durationMinutes: 45,
                                      isSelected: selectedDuration == 45,
                                      onTap: () {
                                        onboardingProvider
                                            .setPreferredSessionDuration(45);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DurationOption(
                                      durationMinutes: 25,
                                      isSelected: selectedDuration == 25,
                                      onTap: () {
                                        onboardingProvider
                                            .setPreferredSessionDuration(25);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Second Row: 90 | 60
                              Row(
                                children: [
                                  Expanded(
                                    child: DurationOption(
                                      durationMinutes: 90,
                                      isSelected: selectedDuration == 90,
                                      onTap: () {
                                        onboardingProvider
                                            .setPreferredSessionDuration(90);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DurationOption(
                                      durationMinutes: 60,
                                      isSelected: selectedDuration == 60,
                                      onTap: () {
                                        onboardingProvider
                                            .setPreferredSessionDuration(60);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Custom Duration option card with dashed/subtle border
                              GestureDetector(
                                onTap: _showCustomDurationSheet,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 20,
                                  ),
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
                                      Text(
                                        selectedDuration != 25 &&
                                                selectedDuration != 45 &&
                                                selectedDuration != 60 &&
                                                selectedDuration != 90
                                            ? '${AppStrings.customDuration}: $selectedDuration ${AppStrings.minutes}'
                                            : AppStrings.customDuration,
                                        style: AppTextStyles.titleMedium
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Bottom Actions inside scroll view
                  ElevatedButton(
                    onPressed: _handleNext,
                    child: const Text(AppStrings.next),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  OutlinedButton(
                    onPressed: _handleBack,
                    child: const Text(AppStrings.back),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingCustomDurationSheet extends StatefulWidget {
  final ValueChanged<int> onConfirm;

  const _OnboardingCustomDurationSheet({required this.onConfirm});

  @override
  State<_OnboardingCustomDurationSheet> createState() =>
      _OnboardingCustomDurationSheetState();
}

class _OnboardingCustomDurationSheetState
    extends State<_OnboardingCustomDurationSheet> {
  final TextEditingController _textController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
              controller: _textController,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.left,
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
                    onPressed: () {
                      final text = _textController.text.trim();
                      final val = int.tryParse(text);
                      if (val == null || val < 5 || val > 180) {
                        setState(() {
                          _errorText = AppStrings.invalidCustomDuration;
                        });
                      } else {
                        widget.onConfirm(val);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(AppStrings.confirm),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
