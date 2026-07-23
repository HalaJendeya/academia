import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Tajawal';

  // ---------------------------------------------------------------------------
  // Display text
  // Used for very large page titles, onboarding, and hero sections.
  // ---------------------------------------------------------------------------

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 57,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.12,
    letterSpacing: -0.25,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 45,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.22,
  );

  // ---------------------------------------------------------------------------
  // Headlines
  // Used for main screen and section headings.
  // ---------------------------------------------------------------------------

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.33,
  );

  // ---------------------------------------------------------------------------
  // Titles
  // Used for cards, dialogs, app bars, and list items.
  // ---------------------------------------------------------------------------

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.43,
    letterSpacing: 0.1,
  );

  // ---------------------------------------------------------------------------
  // Body text
  // Used for paragraphs, descriptions, and supporting content.
  // ---------------------------------------------------------------------------

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.43,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.33,
    letterSpacing: 0.4,
  );

  // ---------------------------------------------------------------------------
  // Labels
  // Used for buttons, tabs, chips, badges, and navigation items.
  // ---------------------------------------------------------------------------

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.33,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 1.45,
    letterSpacing: 0.5,
  );

  // ---------------------------------------------------------------------------
  // Splash screen
  // ---------------------------------------------------------------------------

  static const TextStyle splashTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.secondary,
    height: 1.25,
  );

  static const TextStyle splashSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ---------------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------------

  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.appBarTitle,
    height: 1.27,
  );

  // ---------------------------------------------------------------------------
  // Buttons
  // ---------------------------------------------------------------------------

  static const TextStyle primaryButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
    height: 1.25,
  );

  static const TextStyle secondaryButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.25,
  );

  static const TextStyle textButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.43,
  );

  // ---------------------------------------------------------------------------
  // Home screen
  // ---------------------------------------------------------------------------

  static const TextStyle welcomeTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.welcomeTitle,
    height: 1.27,
  );

  static const TextStyle welcomeSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.welcomeSubtitle,
    height: 1.5,
  );

  static const TextStyle welcomeChip = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.welcomeChipText,
    height: 1.33,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle sectionAction = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.43,
  );

  static const TextStyle recommendationTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.recommendationTitle,
    height: 1.5,
  );

  static const TextStyle recommendationBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.recommendationText,
    height: 1.43,
  );

  static const TextStyle taskTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.taskTitle,
    height: 1.5,
  );

  static const TextStyle taskSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.taskSubtitle,
    height: 1.43,
  );

  static const TextStyle urgentBadge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.urgentBadgeText,
    height: 1.45,
  );

  static const TextStyle competitionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.competitionTitle,
    height: 1.5,
  );

  static const TextStyle competitionInstructor = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.competitionInstructor,
    height: 1.43,
  );

  static const TextStyle competitionProgress = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textDisabled,
    height: 1.33,
  );

  // ---------------------------------------------------------------------------
  // Bottom navigation
  // ---------------------------------------------------------------------------

  static const TextStyle bottomNavigationSelected = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.bottomNavigationSelectedText,
    height: 1.33,
  );

  static const TextStyle bottomNavigationUnselected = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.bottomNavigationUnselected,
    height: 1.33,
  );

  // ---------------------------------------------------------------------------
  // Status and helper text
  // ---------------------------------------------------------------------------

  static const TextStyle errorText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
    height: 1.33,
  );

  static const TextStyle helperText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.33,
  );

  static const TextStyle offlineBanner = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.offlineBannerText,
    height: 1.43,
  );
}
