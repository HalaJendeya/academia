import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AcademiaBottomNavigation extends StatelessWidget {
  const AcademiaBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const int homeIndex = 0;
  static const int coursesIndex = 1;
  static const int tasksIndex = 2;
  static const int studyIndex = 3;
  static const int profileIndex = 4;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bottomNavigationBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.card),
          topRight: Radius.circular(AppRadius.card),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: AppSpacing.small,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildItem(
                index: homeIndex,
                icon: Icons.home_rounded,
                label: AppStrings.homeTab,
              ),
              _buildItem(
                index: coursesIndex,
                icon: Icons.school_rounded,
                label: AppStrings.coursesTab,
              ),
              _buildItem(
                index: tasksIndex,
                icon: Icons.assignment_outlined,
                label: AppStrings.tasksTab,
              ),
              _buildItem(
                index: studyIndex,
                icon: Icons.auto_stories_rounded,
                label: AppStrings.studyTab,
              ),
              _buildItem(
                index: profileIndex,
                icon: Icons.person_outline_rounded,
                label: AppStrings.profileTab,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    /*
     * العنصر المحدَّد وحده يعرض نصه، فيصبح أعرض من البقية. على شاشة بعرض
     * 360 لا يتسع الصف لخمسة عناصر أحدها بنص، لذلك يُجعل كل عنصر مرنًا
     * ليتقلّص النص عند الحاجة بدل أن يفيض الصف.
     */
    return Flexible(
      child: _AcademiaNavigationItem(
        icon: icon,
        label: label,
        selected: isSelected,
        onTap: () => onTap(index),
      ),
    );
  }
}

class _AcademiaNavigationItem extends StatelessWidget {
  const _AcademiaNavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.bottomNavigationSelectedBackground
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: selected
                      ? AppColors.bottomNavigationSelectedIcon
                      : AppColors.bottomNavigationUnselected,
                  size: 24,
                ),
                if (selected) ...[
                  const SizedBox(width: AppSpacing.extraSmall),
                  Flexible(
                    child: Text(
                      label,
                      style: AppTextStyles.bottomNavigationSelected.copyWith(
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
