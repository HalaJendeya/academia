import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmNewPassword = true;

  String? _newPasswordError;
  String? _confirmPasswordError;
  bool _isSaving = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSavePassword() {
    setState(() {
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    bool hasErrors = false;

    if (newPassword.isEmpty) {
      setState(() {
        _newPasswordError = AppStrings.errorPasswordRequired;
      });
      hasErrors = true;
    } else if (newPassword.length < 8) {
      setState(() {
        _newPasswordError = AppStrings.errorPasswordTooShort8;
      });
      hasErrors = true;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        _confirmPasswordError = AppStrings.errorConfirmPasswordRequired;
      });
      hasErrors = true;
    } else if (newPassword != confirmPassword) {
      setState(() {
        _confirmPasswordError = AppStrings.errorPasswordMismatch;
      });
      hasErrors = true;
    }

    if (hasErrors) return;

    setState(() {
      _isSaving = true;
    });

    // Simulate saving delay
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      _showSuccessDialog();
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppColors.surface,
          title: const Text(
            AppStrings.successDialogTitle,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            AppStrings.successDialogBody,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss Dialog
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text(AppStrings.backToLogin),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.resetPasswordTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.screenVertical,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.medium),
                // Circular graphic lock-reset icon
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary.withValues(alpha: 0.08),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_reset,
                        size: 56,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.extraLarge),
                // Heading Title
                Text(
                  AppStrings.resetPasswordHeading,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.medium),
                // Subtitle Instruction description
                Text(
                  AppStrings.resetPasswordSubtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.extraLarge),
                // Input Form Card Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderLight, width: 1),
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
                      // New Password Label
                      const Text(
                        AppStrings.newPasswordLabel,
                        style: AppTextStyles.titleSmall,
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 8),
                      // New Password Input field
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        textAlign: TextAlign.left,
                        decoration: InputDecoration(
                          hintText: AppStrings.newPasswordHint,
                          errorText: _newPasswordError,
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textDisabled,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.textSecondary,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.input,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.input,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.input,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Confirm Password Label
                      const Text(
                        AppStrings.confirmNewPasswordLabel,
                        style: AppTextStyles.titleSmall,
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 8),
                      // Confirm Password Input field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmNewPassword,
                        textAlign: TextAlign.left,
                        decoration: InputDecoration(
                          hintText: AppStrings.confirmNewPasswordHint,
                          errorText: _confirmPasswordError,
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textDisabled,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.textSecondary,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmNewPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmNewPassword =
                                    !_obscureConfirmNewPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.input,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.input,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.input,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Password Length Warning/Notice
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              AppStrings.passwordLengthNotice,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Save Password Button
                      _isSaving
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _handleSavePassword,
                              child: const Text(AppStrings.savePasswordButton),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
