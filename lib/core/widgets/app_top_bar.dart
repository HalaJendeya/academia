// lib/core/widgets/app_top_bar.dart

import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AcademiaMainAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const AcademiaMainAppBar({
    super.key,
    required this.title,
    this.onSearchPressed,
    this.onNotificationsPressed,
    this.onProfilePressed,
    this.showSearch = true,
    this.showNotifications = true,
    this.showProfile = true,
    this.hasUnreadNotifications = false,
    this.showBackButton = false,
    this.onBackPressed,
  });

  final String title;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onProfilePressed;
  final bool showSearch;
  final bool showNotifications;
  final bool showProfile;
  final bool hasUnreadNotifications;

  /// When true, shows a back button in the leading slot instead of
  /// the profile avatar. Used by sub-screens (e.g. Files) that need
  /// to visually match the main app bar while still allowing
  /// navigation back. Defaults to false so all existing screens
  /// using this app bar are unaffected.
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.appBarBackground,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      shape: const Border(
        bottom: BorderSide(color: AppColors.borderLight, width: 1.0),
      ),
      title: Text(title, style: AppTextStyles.appBarTitle),
      leading: showBackButton
          ? IconButton(
        tooltip: AppStrings.back,
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.secondary,
        ),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      )
          : showProfile
          ? IconButton(
        tooltip: AppStrings.profile,
        icon: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.secondary.withValues(
            alpha: 0.1,
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppColors.secondary,
            size: 20,
          ),
        ),
        onPressed: onProfilePressed,
      )
          : null,
      actions: [
        if (showSearch)
          IconButton(
            tooltip: AppStrings.search,
            icon: const Icon(Icons.search_rounded, color: AppColors.appBarIcon),
            onPressed: onSearchPressed,
          ),
        if (showNotifications)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: AppStrings.notifications,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.appBarIcon,
                ),
                onPressed: onNotificationsPressed,
              ),
              if (hasUnreadNotifications)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(width: AppSpacing.small),
      ],
    );
  }
}

class AcademiaSubAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AcademiaSubAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.action,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? action;

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.appBarBackground,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      shape: const Border(
        bottom: BorderSide(color: AppColors.borderLight, width: 1.0),
      ),
      title: Text(title, style: AppTextStyles.appBarTitle),
      leading: IconButton(
        tooltip: AppStrings.back,
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.secondary),
        onPressed: onBack ?? () => Navigator.of(context).pop(),
      ),
      actions: [
        if (action != null) ...[
          action!,
          const SizedBox(width: AppSpacing.small),
        ],
      ],
    );
  }
}