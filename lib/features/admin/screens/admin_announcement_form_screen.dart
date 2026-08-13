import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';
import '../../courses/providers/course_provider.dart';

class AdminAnnouncementFormScreen extends StatefulWidget {
  const AdminAnnouncementFormScreen({super.key});

  @override
  State<AdminAnnouncementFormScreen> createState() =>
      _AdminAnnouncementFormScreenState();
}

class _AdminAnnouncementFormScreenState
    extends State<AdminAnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedTarget = 'all';
  String? _selectedCourseId;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<CourseProvider>().courses;

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.createNewAnnouncementAction),
          leading: const AdminBackButton(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Warning info banner
                AppCard(
                  backgroundColor: AppColors.warning.withValues(alpha: 0.05),
                  borderColor: AppColors.warning.withValues(alpha: 0.2),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.warningDark,
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: Text(
                          AppStrings.announcementFeatureNotConnected,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.warningDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.large),

                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.announcementTitleLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.announcementTitleHint,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.assignmentTitleRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Text(
                        AppStrings.announcementTargetLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTarget,
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(AppStrings.announcementTargetAll),
                          ),
                          DropdownMenuItem(
                            value: 'courses',
                            child: Text(AppStrings.announcementTargetCourses),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedTarget = val;
                            });
                          }
                        },
                      ),
                      if (_selectedTarget == 'courses') ...[
                        const SizedBox(height: AppSpacing.medium),
                        Text(
                          AppStrings.targetCourseLabel,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCourseId,
                          decoration: const InputDecoration(
                            hintText: AppStrings.targetCourseSelectHint,
                          ),
                          items: courses.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c.title),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCourseId = val;
                            });
                          },
                          validator: (value) {
                            if (_selectedTarget == 'courses' && value == null) {
                              return AppStrings.assignmentCourseRequired;
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: AppSpacing.medium),
                      Text(
                        AppStrings.announcementBodyLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _bodyController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: AppStrings.announcementBodyHint,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.announcementBodyRequired;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.extraLarge),

                AppPrimaryButton(
                  label: AppStrings.announcementPublishAction,
                  isEnabled: false, // mock-only
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.medium),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(AppStrings.cancelAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
