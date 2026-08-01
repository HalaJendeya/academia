import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  String? _passwordError;
  bool _nameHasError = false;
  bool _idHasError = false;
  bool _emailHasError = false;
  bool _confirmPasswordHasError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _nameHasError = false;
      _idHasError = false;
      _emailHasError = false;
      _passwordError = null;
      _confirmPasswordHasError = false;
    });

    final name = _nameController.text.trim();
    final id = _idController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    bool hasValidationErrors = false;

    if (name.isEmpty) {
      setState(() => _nameHasError = true);
      hasValidationErrors = true;
    }

    if (id.isEmpty) {
      setState(() => _idHasError = true);
      hasValidationErrors = true;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      setState(() => _emailHasError = true);
      hasValidationErrors = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = AppStrings.errorPasswordRequired);
      hasValidationErrors = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = AppStrings.errorPasswordTooShort);
      hasValidationErrors = true;
    } else if (password != confirmPassword) {
      setState(() {
        _confirmPasswordHasError = true;
        _passwordError = AppStrings.errorPasswordMismatch;
      });
      hasValidationErrors = true;
    }

    if (hasValidationErrors) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      email: email,
      password: password,
      fullName: name,
      studentId: id,
    );

    if (success && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_account', true);

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.studentVerification,
        arguments: email,
      );
    } else if (mounted) {
      setState(() {
        _passwordError = authProvider.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.background,
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
                // Brand Title & Logo
                Center(
                  child: Column(
                    children: [
                      const Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.registerSubtitle,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Form Card
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Full Name Label
                        const Text(
                          AppStrings.fullNameLabel,
                          style: AppTextStyles.titleSmall,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 8),
                        // Full Name Input
                        TextFormField(
                          controller: _nameController,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: AppStrings.fullNameHint,
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textDisabled,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _nameHasError
                                    ? AppColors.error
                                    : AppColors.border,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _nameHasError
                                    ? AppColors.error
                                    : AppColors.borderLight,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _nameHasError
                                    ? AppColors.error
                                    : AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Student ID Label
                        const Text(
                          AppStrings.studentIdLabel,
                          style: AppTextStyles.titleSmall,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 8),
                        // Student ID Input
                        TextFormField(
                          controller: _idController,
                          textAlign: TextAlign.right,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: AppStrings.studentIdHint,
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textDisabled,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _idHasError
                                    ? AppColors.error
                                    : AppColors.border,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _idHasError
                                    ? AppColors.error
                                    : AppColors.borderLight,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _idHasError
                                    ? AppColors.error
                                    : AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Student Email Label
                        const Text(
                          AppStrings.emailLabel,
                          style: AppTextStyles.titleSmall,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 8),
                        // Student Email Input
                        TextFormField(
                          controller: _emailController,
                          textAlign: TextAlign.left,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: AppStrings.emailHintUniversity,
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textDisabled,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _emailHasError
                                    ? AppColors.error
                                    : AppColors.border,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _emailHasError
                                    ? AppColors.error
                                    : AppColors.borderLight,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _emailHasError
                                    ? AppColors.error
                                    : AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Password Label
                        const Text(
                          AppStrings.passwordLabel,
                          style: AppTextStyles.titleSmall,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 8),
                        // Password Input
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: AppStrings.passwordHint,
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textDisabled,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _passwordError != null
                                    ? AppColors.error
                                    : AppColors.border,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _passwordError != null
                                    ? AppColors.error
                                    : AppColors.borderLight,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _passwordError != null
                                    ? AppColors.error
                                    : AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        if (_passwordError != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                _passwordError!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Confirm Password Label
                        const Text(
                          AppStrings.confirmPasswordLabel,
                          style: AppTextStyles.titleSmall,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 8),
                        // Confirm Password Input
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscurePassword,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: AppStrings.confirmPasswordHint,
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textDisabled,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _confirmPasswordHasError
                                    ? AppColors.error
                                    : AppColors.border,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _confirmPasswordHasError
                                    ? AppColors.error
                                    : AppColors.borderLight,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _confirmPasswordHasError
                                    ? AppColors.error
                                    : AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Register/Submit Button
                        authProvider.isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _handleRegister,
                                child: const Text(AppStrings.createAccount),
                              ),
                        const SizedBox(height: 16),
                        // Terms & Conditions Disclaimer
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              Text(
                                AppStrings.termsText,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Text(
                                  AppStrings.termsLink,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Footer Navigation to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.hasAccountText,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      key: const Key('register_to_login_btn'),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.login);
                      },
                      child: const Text(
                        AppStrings.loginTitle,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
