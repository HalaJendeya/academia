import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Brand colors
  // ---------------------------------------------------------------------------

  static const Color primary = Color(0xFFFF8B00);
  static const Color primaryDark = Color(0xFFC27803);
  static const Color primaryDarker = Color(0xFF713B00);
  static const Color primaryDarkest = Color(0xFF380D00);
  static const Color primaryLight = Color(0xFFFDA458);

  static const Color secondary = Color(0xFF002B80);

  // ---------------------------------------------------------------------------
  // Background colors
  // ---------------------------------------------------------------------------

  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFE8E7F1);
  static const Color surfaceMuted = Color(0xFFE2E1EB);

  // Used for light transparent surfaces.
  static const Color surfaceWhite60 = Color(0x99FFFFFF);
  static const Color surfaceWhite20 = Color(0x33FFFFFF);

  // ---------------------------------------------------------------------------
  // Text colors
  // ---------------------------------------------------------------------------

  static const Color textPrimary = Color(0xFF1A1B22);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF747685);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textLink = Color(0xFF002B80);

  // ---------------------------------------------------------------------------
  // Border and divider colors
  // ---------------------------------------------------------------------------

  static const Color border = Color(0xFFC4C6D6);
  static const Color borderLight = Color(0xFFE2E1EB);
  static const Color borderMuted = Color(0x4DC4C6D6);
  static const Color divider = Color(0xFFE8E7F1);

  // ---------------------------------------------------------------------------
  // Status colors
  // ---------------------------------------------------------------------------

  static const Color error = Color(0xFFE02424);
  static const Color danger = Color(0xFFE02424);

  static const Color warning = Color(0xFFFF8B00);
  static const Color warningDark = Color(0xFFC27803);

  // ---------------------------------------------------------------------------
  // Home screen colors
  // ---------------------------------------------------------------------------

  static const Color homeBackground = Color(0xFFF5F7FA);
  static const Color homeCard = Color(0xFFFFFFFF);

  static const Color appBarBackground = Color(0xFFFFFFFF);
  static const Color appBarIcon = Color(0xFF002B80);
  static const Color appBarTitle = Color(0xFF002B80);

  static const Color offlineBannerBackground = Color(0xFFFFF3CD);
  static const Color offlineBannerText = Color(0xFFC27803);
  static const Color offlineBannerIcon = Color(0xFFFF8B00);

  // ---------------------------------------------------------------------------
  // Welcome card
  // ---------------------------------------------------------------------------

  static const Color welcomeCardStart = Color(0xFFFF8B00);
  static const Color welcomeCardEnd = Color(0xFFC27803);

  static const LinearGradient welcomeCardGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [welcomeCardStart, welcomeCardEnd],
  );

  static const Color welcomeTitle = Color(0xFFFFFFFF);
  static const Color welcomeSubtitle = Color(0xFFFFFFFF);
  static const Color welcomeChipBackground = Color(0x99FFFFFF);
  static const Color welcomeChipText = Color(0xFF713B00);

  // ---------------------------------------------------------------------------
  // Smart recommendation card
  // ---------------------------------------------------------------------------

  static const Color recommendationBackground = Color(0xFFFFF3CD);
  static const Color recommendationIconBackground = Color(0x33C27803);
  static const Color recommendationIcon = Color(0xFFC27803);
  static const Color recommendationTitle = Color(0xFFC27803);
  static const Color recommendationText = Color(0xFF4B5563);

  // ---------------------------------------------------------------------------
  // Task colors
  // ---------------------------------------------------------------------------

  static const Color taskCardBackground = Color(0xFFFFFFFF);
  static const Color taskTitle = Color(0xFF1A1B22);
  static const Color taskSubtitle = Color(0xFF9CA3AF);
  static const Color taskCheckboxBorder = Color(0xFF747685);

  static const Color urgentBadgeBackground = Color(0xFFFFDBCF);
  static const Color urgentBadgeText = Color(0xFFE02424);

  // ---------------------------------------------------------------------------
  // Competition colors
  // ---------------------------------------------------------------------------

  static const Color competitionCardBackground = Color(0xFFFFFFFF);
  static const Color competitionTitle = Color(0xFF1A1B22);
  static const Color competitionInstructor = Color(0xFF4B5563);

  static const Color competitionIconOrangeBackground = Color(0xFFFDA458);
  static const Color competitionIconOrange = Color(0xFF713B00);

  static const Color competitionIconPinkBackground = Color(0xFFFFDBCF);
  static const Color competitionIconPink = Color(0xFF380D00);

  static const Color competitionProgressBackground = Color(0xFFE8E7F1);
  static const Color competitionProgress = Color(0xFFFF8B00);

  // ---------------------------------------------------------------------------
  // Bottom navigation
  // ---------------------------------------------------------------------------

  static const Color bottomNavigationBackground = Color(0xFFFFFFFF);
  static const Color bottomNavigationSelectedBackground = Color(0xFFFF8B00);
  static const Color bottomNavigationSelectedIcon = Color(0xFFFFFFFF);
  static const Color bottomNavigationSelectedText = Color(0xFFFF8B00);
  static const Color bottomNavigationUnselected = Color(0xFF434653);

  // ---------------------------------------------------------------------------
  // Floating action button
  // ---------------------------------------------------------------------------

  static const Color floatingActionButtonBackground = Color(0xFFFF8B00);
  static const Color floatingActionButtonForeground = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Splash screen
  // ---------------------------------------------------------------------------

  static const Color splashGradientTop = Color(0xFFF5F7FA);
  static const Color splashGradientMiddle = Color(0xFFFFF3CD);
  static const Color splashGradientBottom = Color(0xFFFFDBCF);

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [splashGradientTop, splashGradientMiddle, splashGradientBottom],
  );

  // ---------------------------------------------------------------------------
  // Shadows
  // ---------------------------------------------------------------------------

  static const Color shadow = Color(0x33434653);
  static const Color lightShadow = Color(0x1A434653);

  // ---------------------------------------------------------------------------
  // Material color scheme
  // ---------------------------------------------------------------------------

  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    secondary: secondary,
    onSecondary: Colors.white,
    error: error,
    onError: Colors.white,
    surface: surface,
    onSurface: textPrimary,
  );

  // ---------------------------------------------------------------------------
  // Admin UI Accents and Status Colors
  // ---------------------------------------------------------------------------
  static const Color activeStatus = Color(0xFF4CAF50);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentPurpleLight = Color(0xFFF3E5F5);
  static const Color accentTeal = Color(0xFF009688);
  static const Color accentTealLight = Color(0xFFE0F2F1);
}
