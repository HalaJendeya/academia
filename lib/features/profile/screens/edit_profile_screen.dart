import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/student_profile.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _studentIdController;
  late final TextEditingController _emailController;

  String? _selectedMajor;

  /// المستوى الأكاديمي رقم صحيح؛ النص العربي يُبنى عند العرض فقط.
  int? _selectedAcademicLevel;

  bool _initialized = false;

  final List<String> _majors = AppStrings.majorsList;

  final List<int> _academicLevels = AppStrings.academicLevelValues;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _studentIdController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final profile = context.read<ProfileProvider>().profile;
      if (profile != null) {
        _fullNameController.text = profile.fullName;
        _studentIdController.text = profile.studentId;
        _emailController.text = profile.email;
        _selectedMajor = profile.major;
        _selectedAcademicLevel = profile.academicLevel;
        _initialized = true;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<ProfileProvider>().loadProfile();
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleNavigation(int index) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;

    if (profile == null) {
      if (profileProvider.isLoading) {
        return AuthenticatedPageScaffold(
          currentIndex: 4,
          showBottomNavigation: true,
          onNavigationTap: _handleNavigation,
          appBar: const AcademiaSubAppBar(title: AppStrings.editProfileTitle),
          body: const AppLoadingState(message: AppStrings.profileLoadError),
        );
      }

      if (profileProvider.errorMessage != null) {
        return AuthenticatedPageScaffold(
          currentIndex: 4,
          showBottomNavigation: true,
          onNavigationTap: _handleNavigation,
          appBar: const AcademiaSubAppBar(title: AppStrings.editProfileTitle),
          body: AppErrorState(
            message: profileProvider.errorMessage!,
            onRetry: () {
              context.read<ProfileProvider>().loadProfile(forceRefresh: true);
            },
          ),
        );
      }

      return AuthenticatedPageScaffold(
        currentIndex: 4,
        showBottomNavigation: true,
        onNavigationTap: _handleNavigation,
        appBar: const AcademiaSubAppBar(title: AppStrings.editProfileTitle),
        body: AppErrorState(
          message: AppStrings.profileNotFound,
          onRetry: () {
            context.read<ProfileProvider>().loadProfile(forceRefresh: true);
          },
        ),
      );
    }

    if (!_initialized) {
      _fullNameController.text = profile.fullName;
      _studentIdController.text = profile.studentId;
      _emailController.text = profile.email;
      _selectedMajor = profile.major;
      _selectedAcademicLevel = profile.academicLevel;
      _initialized = true;
    }

    final List<String> dropdownMajors = List.from(_majors);
    if (_selectedMajor != null && !_majors.contains(_selectedMajor)) {
      dropdownMajors.add(_selectedMajor!);
    }

    // Dynamic academic levels dropdown mapping
    final List<int> dropdownLevels = List.from(_academicLevels);
    if (_selectedAcademicLevel != null &&
        !_academicLevels.contains(_selectedAcademicLevel)) {
      dropdownLevels.add(_selectedAcademicLevel!);
      dropdownLevels.sort();
    }

    return AuthenticatedPageScaffold(
      currentIndex: 4,
      showBottomNavigation: true,
      onNavigationTap: _handleNavigation,
      appBar: const AcademiaSubAppBar(title: AppStrings.editProfileTitle),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.screenVertical,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar edit area with ImagePicker flow
              _buildAvatarEditArea(context, profileProvider, profile),
              const SizedBox(height: AppSpacing.large),

              // Full Name Field
              _buildLabel(AppStrings.fullNameLabel),
              TextFormField(
                controller: _fullNameController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: AppStrings.fullNameLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                validator: (value) {
                  final trimmed = value?.trim();
                  if (trimmed == null || trimmed.isEmpty) {
                    return AppStrings.fullNameRequired;
                  }
                  if (trimmed.length < 2) {
                    return AppStrings.fullNameTooShort;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.medium),

              // Student ID Field (Read-only)
              _buildLabel(AppStrings.studentIdLabel),
              TextFormField(
                controller: _studentIdController,
                readOnly: true,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  fillColor: AppColors.borderLight.withValues(alpha: 0.2),
                  filled: true,
                  helperText: AppStrings.studentIdReadOnlyHint,
                  helperStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),

              // Email Field (Read-only)
              _buildLabel(AppStrings.universityEmailLabel),
              TextFormField(
                controller: _emailController,
                readOnly: true,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  fillColor: AppColors.borderLight.withValues(alpha: 0.2),
                  filled: true,
                  helperText: AppStrings.emailReadOnlyHint,
                  helperStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),

              // Major Dropdown Selector
              _buildLabel(AppStrings.majorLabel),
              DropdownButtonFormField<String>(
                initialValue: _selectedMajor,
                alignment: Alignment.centerRight,
                hint: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    AppStrings.majorLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDisabled,
                    ),
                  ),
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                items: dropdownMajors.map((String major) {
                  return DropdownMenuItem<String>(
                    value: major,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(major),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMajor = newValue;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.medium),

              // Academic Level Dropdown Selector (Level 1 to 5)
              _buildLabel(AppStrings.academicLevelLabel),
              DropdownButtonFormField<int>(
                initialValue:
                    _selectedAcademicLevel ??
                    AppStrings.academicLevelValues.first,
                alignment: Alignment.centerRight,
                hint: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    AppStrings.academicLevelLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDisabled,
                    ),
                  ),
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                items: dropdownLevels.map((int level) {
                  return DropdownMenuItem<int>(
                    value: level,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(AppStrings.academicLevelDisplay(level)),
                    ),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedAcademicLevel = newValue;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.extraLarge),

              // Save Changes Button
              AppPrimaryButton(
                label: AppStrings.saveChanges,
                isLoading: profileProvider.isSaving,
                isEnabled: !profileProvider.isSaving,
                onPressed: _saveProfile,
              ),
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: AppTextStyles.titleSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildAvatarEditArea(
    BuildContext context,
    ProfileProvider profileProvider,
    StudentProfile profile,
  ) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Semantics(
                label: AppStrings.studentAvatarSemantics,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                  backgroundImage: profileProvider.localPhotoBytes != null
                      ? MemoryImage(profileProvider.localPhotoBytes!)
                      : (profile.photoUrl != null &&
                            profile.photoUrl!.trim().isNotEmpty)
                      ? NetworkImage(profile.photoUrl!) as ImageProvider
                      : null,
                  child:
                      (profileProvider.localPhotoBytes != null ||
                          (profile.photoUrl != null &&
                              profile.photoUrl!.trim().isNotEmpty))
                      ? null
                      : const Icon(
                          Icons.person_rounded,
                          color: AppColors.secondary,
                          size: 56,
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          TextButton(
            onPressed: _pickAndUploadImage,
            child: Text(
              AppStrings.changeProfilePicture,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
            child: Text(
              AppStrings.profileImageTemporaryNote,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (!mounted) return;

      final success = await context
          .read<ProfileProvider>()
          .uploadProfilePicture(bytes);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.profileImageUpdatedLocally),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.profileImagePickOrUploadError),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await context.read<ProfileProvider>().updateProfile(
        fullName: _fullNameController.text,
        major: _selectedMajor,
        academicLevel: _selectedAcademicLevel,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.profileUpdatedSuccessfully),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop();
      } else {
        final error =
            context.read<ProfileProvider>().errorMessage ??
            AppStrings.profileUpdateError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
