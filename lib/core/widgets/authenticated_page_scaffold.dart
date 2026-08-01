import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_bottom_navigation.dart';

class AuthenticatedPageScaffold extends StatelessWidget {
  const AuthenticatedPageScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onNavigationTap,
    this.appBar,
    this.showBottomNavigation = true,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
  });

  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onNavigationTap;
  final PreferredSizeWidget? appBar;
  final bool showBottomNavigation;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      body: SafeArea(child: body),
      bottomNavigationBar: showBottomNavigation
          ? AcademiaBottomNavigation(
              currentIndex: currentIndex,
              onTap: onNavigationTap,
            )
          : null,
      floatingActionButton: floatingActionButton,
    );
  }
}
