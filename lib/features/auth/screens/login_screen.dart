import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/services/onboarding_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isResolvingDestination = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _passwordError;
  bool _emailHasError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _passwordError = null;
      _emailHasError = false;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool hasValidationErrors = false;

    if (email.isEmpty) {
      setState(() {
        _emailHasError = true;
      });
      hasValidationErrors = true;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = AppStrings.errorPasswordRequired;
      });
      hasValidationErrors = true;
    }

    if (hasValidationErrors) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(email, password);

    if (success && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_account', true);

      if (!mounted) return;

      setState(() {
        _isResolvingDestination = true;
      });

      try {
        // Admin goes directly to the admin dashboard.
        if (authProvider.isAdmin) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.adminDashboard,
            (route) => false,
          );
          return;
        }

        // Only students continue through verification and onboarding.
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          throw StateError('No authenticated user found.');
        }

        if (!user.emailVerified) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.studentVerification,
            (route) => false,
            arguments: email,
          );
          return;
        }

        final onboardingCompleted =
            authProvider.onboardingCompleted ||
            await OnboardingService().isOnboardingCompleted();

        if (!mounted) return;

        Provider.of<OnboardingProvider>(
          context,
          listen: false,
        ).initializeForUser(user.uid);

        if (onboardingCompleted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.dashboard,
            (route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.onboardingWelcome,
            (route) => false,
          );
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isResolvingDestination = false;
            _passwordError = AppStrings.onboardingStatusError;
          });
        }
      }
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
      body: Stack(
        children: [
          // Background Orange Circle top-right
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
          // Background Orange Circle middle-left
          Positioned(
            top: 240,
            left: -80,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
          // Scrollable Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.screenVertical,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Logo Icon & App Title
                    Center(
                      child: Column(
                        children: [
                          Image.asset(
                            AppAssets.logo,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: AppSpacing.itemSpacing),
                          const Text(
                            AppStrings.appName,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          const Text(
                            AppStrings.loginTitle,
                            style: AppTextStyles.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.small),
                          Text(
                            AppStrings.loginSubtitle,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.extraLarge),
                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.large),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.large),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Student ID Label
                            const Text(
                              AppStrings.studentIdLabel,
                              style: AppTextStyles.titleSmall,
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: AppSpacing.small),
                            // Student ID Input (Now University Email Input)
                            TextFormField(
                              controller: _emailController,
                              textAlign: TextAlign.right,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: AppStrings.emailHint,
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textDisabled,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  color: AppColors.textSecondary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.input,
                                  ),
                                  borderSide: BorderSide(
                                    color: _emailHasError
                                        ? AppColors.error
                                        : AppColors.border,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.input,
                                  ),
                                  borderSide: BorderSide(
                                    color: _emailHasError
                                        ? AppColors.error
                                        : AppColors.borderLight,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.input,
                                  ),
                                  borderSide: BorderSide(
                                    color: _emailHasError
                                        ? AppColors.error
                                        : AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.large),
                            // Password Label
                            const Text(
                              AppStrings.passwordLabel,
                              style: AppTextStyles.titleSmall,
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: AppSpacing.small),
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
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: AppColors.textSecondary,
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
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.input,
                                  ),
                                  borderSide: BorderSide(
                                    color: _passwordError != null
                                        ? AppColors.error
                                        : AppColors.border,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.input,
                                  ),
                                  borderSide: BorderSide(
                                    color: _passwordError != null
                                        ? AppColors.error
                                        : AppColors.borderLight,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.input,
                                  ),
                                  borderSide: BorderSide(
                                    color: _passwordError != null
                                        ? AppColors.error
                                        : AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.itemSpacing),
                            // Error message and Forgot password row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Password Error Message on the right (first child in RTL)
                                if (_passwordError != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: AppColors.error,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _passwordError!,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  const SizedBox.shrink(),
                                // Forgot Password Link on the left (second child in RTL)
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.forgotPassword,
                                    );
                                  },
                                  child: Text(
                                    AppStrings.forgotPassword,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textLink,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.large),
                            // Login Button
                            (authProvider.isLoading || _isResolvingDestination)
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _handleLogin,
                                    child: const Text(AppStrings.loginTitle),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.extraLarge),
                    // Footer Link: Register Screen (Row of Texts)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.noAccount,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          key: const Key('login_to_register_btn'),
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.register);
                          },
                          child: const Text(
                            AppStrings.createAccount,
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
        ],
      ),
    );
  }
}
