import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_section.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/support_provider.dart';

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _detailsController = TextEditingController();

  void _handleNavigation(int index) {
    handleMainNavigation(context, index, currentIndex: 4);
  }

  void _sendFeedback() async {
    final provider = context.read<SupportProvider>();
    provider.clearError();

    if (_formKey.currentState?.validate() ?? false) {
      final success = await provider.submitRequest(
        subject: _subjectController.text,
        message: _detailsController.text,
      );

      if (!mounted) return;

      if (success) {
        _subjectController.clear();
        _detailsController.clear();
        FocusScope.of(context).unfocus();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.supportRequestSuccess),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        final error = provider.errorMessage ?? AppStrings.supportRequestError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupportProvider>();

    return AuthenticatedPageScaffold(
      currentIndex: 4,
      onNavigationTap: _handleNavigation,
      appBar: const AcademiaSubAppBar(title: AppStrings.helpSupportScreenTitle),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.screenVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Blue Hero Support Card
              _buildHeroCard(),
              const SizedBox(height: AppSpacing.large),

              // 2. FAQ Accordion Section
              _buildFaqSection(),
              const SizedBox(height: AppSpacing.large),

              // 3. Support Contact Form Card
              _buildContactFormCard(provider),

              // Bottom padding so send button is never covered by bottom navigation
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.support_agent_rounded,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.helpSupportHeroTitle,
            style: AppTextStyles.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    return AppSection(
      title: AppStrings.faqTitle,
      child: Column(
        children: [
          _buildFaqTile(
            question: AppStrings.faqQuestion1,
            answer: AppStrings.faqAnswer1,
          ),
          const Divider(height: 1, color: AppColors.divider),
          _buildFaqTile(
            question: AppStrings.faqQuestion2,
            answer: AppStrings.faqAnswer2,
          ),
          const Divider(height: 1, color: AppColors.divider),
          _buildFaqTile(
            question: AppStrings.faqQuestion3,
            answer: AppStrings.faqAnswer3,
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile({required String question, required String answer}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          question,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.right,
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 16),
        iconColor: AppColors.secondary,
        collapsedIconColor: AppColors.textSecondary,
        children: [
          Text(
            answer,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildContactFormCard(SupportProvider provider) {
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row with Orange Icon, Title, and Description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.contactSupportTitle,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.contactSupportDescription,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Note/Subject Field
            Text(
              AppStrings.feedbackSubject,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _subjectController,
              textAlign: TextAlign.right,
              enabled: !provider.isSubmitting,
              decoration: InputDecoration(
                hintText: AppStrings.feedbackSubjectHint,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDisabled,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              validator: (val) {
                final trimmed = val?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return AppStrings.supportRequestSubjectRequired;
                }
                if (trimmed.length < 3) {
                  return AppStrings.supportRequestSubjectTooShort;
                }
                if (trimmed.length > 120) {
                  return AppStrings.supportRequestSubjectTooLong;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Details Field
            Text(
              AppStrings.feedbackDetails,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _detailsController,
              maxLines: 5,
              textAlign: TextAlign.right,
              enabled: !provider.isSubmitting,
              decoration: InputDecoration(
                hintText: AppStrings.feedbackDetailsHint,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDisabled,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (val) {
                final trimmed = val?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return AppStrings.supportRequestMessageRequired;
                }
                if (trimmed.length < 10) {
                  return AppStrings.supportRequestMessageTooShort;
                }
                if (trimmed.length > 2000) {
                  return AppStrings.supportRequestMessageTooLong;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Send feedback action button
            AppPrimaryButton(
              label: AppStrings.sendFeedback,
              icon: Icons.send_outlined,
              isLoading: provider.isSubmitting,
              isEnabled: !provider.isSubmitting,
              onPressed: _sendFeedback,
            ),
          ],
        ),
      ),
    );
  }
}
