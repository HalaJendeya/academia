import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_navigation.dart';

void handleMainNavigation(
  BuildContext context,
  int index, {
  required int currentIndex,
}) {
  if (index == currentIndex) return;

  switch (index) {
    case AcademiaBottomNavigation.homeIndex:
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      break;

    case AcademiaBottomNavigation.coursesIndex:
      Navigator.pushReplacementNamed(context, AppRoutes.courses);
      break;

    case AcademiaBottomNavigation.tasksIndex:
      _navigateOrShowUnderDevelopment(context, AppRoutes.tasks);
      break;

    case AcademiaBottomNavigation.studyIndex:
      _navigateOrShowUnderDevelopment(context, '/study');
      break;

    case AcademiaBottomNavigation.profileIndex:
      _navigateOrShowUnderDevelopment(context, AppRoutes.profile);
      break;
  }
}

void _navigateOrShowUnderDevelopment(BuildContext context, String routeName) {
  final widgetsApp = context.findAncestorWidgetOfExactType<WidgetsApp>();
  final isRegistered = widgetsApp?.routes?.containsKey(routeName) ?? false;

  if (isRegistered) {
    Navigator.pushReplacementNamed(context, routeName);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.screenUnderDevelopment),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
