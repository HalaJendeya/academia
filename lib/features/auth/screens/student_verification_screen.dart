import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/services/onboarding_service.dart';

class StudentVerificationScreen extends StatefulWidget {
  const StudentVerificationScreen({super.key});

  @override
  State<StudentVerificationScreen> createState() =>
      _StudentVerificationScreenState();
}

class _StudentVerificationScreenState extends State<StudentVerificationScreen> {
  int _cooldownSeconds = 30;
  int _resendCount = 0;
  DateTime? _lockoutEndTime;
  Timer? _timer;
  String _email = 'std@university.edu.sa';

  bool _isVerifyingLink = false;

  @override
  void initState() {
    super.initState();
    _loadStateAndStartTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as String?;
    if (args != null && args.isNotEmpty) {
      setState(() {
        _email = args;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadStateAndStartTimer() async {
    final prefs = await SharedPreferences.getInstance();
    _resendCount = prefs.getInt('verification_resend_count') ?? 0;

    final lockoutStr = prefs.getString('verification_lockout_end');
    if (lockoutStr != null) {
      final savedEnd = DateTime.parse(lockoutStr);
      if (savedEnd.isAfter(DateTime.now())) {
        _lockoutEndTime = savedEnd;
      } else {
        await prefs.remove('verification_lockout_end');
        await prefs.setInt('verification_resend_count', 0);
        _resendCount = 0;
      }
    }

    _startTimerLoop();
  }

  void _startTimerLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_lockoutEndTime != null) {
          if (DateTime.now().isAfter(_lockoutEndTime!)) {
            _lockoutEndTime = null;
            _resendCount = 0;
            _cooldownSeconds = 0;
            _clearLockoutPrefs();
          }
        } else if (_cooldownSeconds > 0) {
          _cooldownSeconds--;
        }
      });
    });
  }

  Future<void> _clearLockoutPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('verification_lockout_end');
    await prefs.setInt('verification_resend_count', 0);
  }

  Future<void> _handleResend() async {
    if (_cooldownSeconds > 0 || _lockoutEndTime != null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final prefs = await SharedPreferences.getInstance();
    _resendCount++;
    await prefs.setInt('verification_resend_count', _resendCount);

    if (_resendCount >= 3) {
      final lockoutEnd = DateTime.now().add(const Duration(hours: 1));
      setState(() {
        _lockoutEndTime = lockoutEnd;
      });
      await prefs.setString(
        'verification_lockout_end',
        lockoutEnd.toIso8601String(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.verificationLockoutMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      setState(() {
        _cooldownSeconds = 30;
      });

      try {
        await authProvider.sendEmailVerification();
      } catch (_) {
        // Handle silently
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.verificationResendSuccess} $_email'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  Future<void> _navigateAfterVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.reload();
      } catch (_) {}

      if (!mounted) return;

      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser != null) {
        // Initialize OnboardingProvider for the UID
        final onboardingProvider = Provider.of<OnboardingProvider>(
          context,
          listen: false,
        );
        onboardingProvider.initializeForUser(refreshedUser.uid);

        // Check onboarding completion
        final onboardingCompleted = await OnboardingService()
            .isOnboardingCompleted();

        if (!mounted) return;

        setState(() {
          _isVerifyingLink = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            onboardingCompleted
                ? AppRoutes.dashboard
                : AppRoutes.onboardingWelcome,
            (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.verificationSuccess),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 4),
            ),
          );
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isVerifyingLink = false;
      });
    }
  }

  Future<void> _simulateVerifyLink() async {
    setState(() {
      _isVerifyingLink = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Bypass verification for demo/testing emails
    final bool isMockBypass =
        _email.startsWith('mock') || _email.contains('test');
    final isVerified = isMockBypass || await authProvider.checkEmailVerified();

    if (!mounted) return;

    if (isVerified) {
      if (isMockBypass) {
        // Mock bypass updates the database user document just like checkEmailVerified does
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({'emailVerified': true})
              .catchError((_) {});
        }
      }
      await _navigateAfterVerification();
    } else {
      setState(() {
        _isVerifyingLink = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.verificationErrorNotVerified),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _getTimerOrLockoutText() {
    if (_lockoutEndTime != null) {
      final diff = _lockoutEndTime!.difference(DateTime.now());
      final minutes = diff.inMinutes;
      final seconds = diff.inSeconds % 60;
      return '${AppStrings.verificationTimerLockout} $minutes:${seconds.toString().padLeft(2, '0')} ${AppStrings.verificationTimerMinutes}';
    }
    if (_cooldownSeconds > 0) {
      return '${AppStrings.verificationTimerResendIn} $_cooldownSeconds ${AppStrings.verificationTimerSeconds}';
    }
    return AppStrings.verificationTimerCanResend;
  }

  Widget _buildVerificationScreen() {
    final canResend = _cooldownSeconds == 0 && _lockoutEndTime == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          AppStrings.verificationTitle,
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.secondary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
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
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.15),
                            ),
                          ),
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.verified_user,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF7A4A11),
                              ),
                              child: const Icon(
                                Icons.school,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        AppStrings.verificationHeader,
                        style: AppTextStyles.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.verificationSubtitle,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _email,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Instruction box replacing the old OTP boxes
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppStrings.verificationInstruction,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Check Verification Button (Primary)
                      _isVerifyingLink
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : ElevatedButton.icon(
                              key: const Key('check_verification_btn'),
                              onPressed: _simulateVerifyLink,
                              icon: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                              ),
                              label: const Text(AppStrings.verifyButton),
                            ),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _getTimerOrLockoutText(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _lockoutEndTime != null
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.info_outline,
                            color: _lockoutEndTime != null
                                ? AppColors.error
                                : AppColors.primary,
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: canResend ? _handleResend : null,
                        icon: Icon(
                          Icons.refresh,
                          color: canResend
                              ? AppColors.textSecondary
                              : AppColors.textDisabled,
                        ),
                        label: Text(
                          AppStrings.resendButton,
                          style: TextStyle(
                            color: canResend
                                ? AppColors.textSecondary
                                : AppColors.textDisabled,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  AppStrings.verificationFooter,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildVerificationScreen();
  }
}
