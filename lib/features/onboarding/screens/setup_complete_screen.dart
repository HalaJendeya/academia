import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class SetupCompleteScreen extends StatefulWidget {
  const SetupCompleteScreen({super.key});

  @override
  State<SetupCompleteScreen> createState() => _SetupCompleteScreenState();
}

class _SetupCompleteScreenState extends State<SetupCompleteScreen> {
  bool _isNavigating = false;

  void _handleGoToDashboard() {
    if (_isNavigating) return;
    setState(() {
      _isNavigating = true;
    });

    // TODO: Persist onboardingCompleted before navigating to the dashboard.

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Static Confetti Elements
            Positioned(
              top: 80,
              left: 50,
              child: _buildConfettiSquare(AppColors.primary, 10, 0.4),
            ),
            Positioned(
              top: 140,
              right: 60,
              child: _buildConfettiSquare(AppColors.secondary, 12, -0.6),
            ),
            Positioned(
              top: 200,
              left: 120,
              child: _buildConfettiSquare(const Color(0xFF10B981), 8, 0.2),
            ),
            Positioned(
              top: 280,
              right: 140,
              child: _buildConfettiSquare(AppColors.primaryLight, 14, 0.8),
            ),
            Positioned(
              bottom: 120,
              left: 80,
              child: _buildConfettiSquare(AppColors.secondary, 10, -0.3),
            ),
            Positioned(
              bottom: 180,
              right: 70,
              child: _buildConfettiSquare(const Color(0xFF10B981), 12, 0.5),
            ),
            Positioned(
              bottom: 240,
              left: 150,
              child: _buildConfettiSquare(AppColors.primary, 8, -0.1),
            ),

            // Centered Success Card
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Container(
                  padding: const EdgeInsets.all(32),
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Large Green Circular Success Icon
                      Center(
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_circle,
                              size: 52,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Success Title
                      Text(
                        AppStrings.setupCompleteTitle,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Success Description
                      Text(
                        AppStrings.setupCompleteDescription,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Primary action button (Arabic RTL arrow forward)
                      ElevatedButton(
                        onPressed: _handleGoToDashboard,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons
                                  .arrow_back, // Represents forward in RTL direction
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(AppStrings.goToDashboard),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfettiSquare(Color color, double size, double rotation) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
