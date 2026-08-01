import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthenticatedPageScaffold(
      currentIndex: 0,
      onNavigationTap: (index) {
        handleMainNavigation(context, index, currentIndex: 0);
      },
      appBar: const AcademiaMainAppBar(
        title: AppStrings.appName,
        showProfile: true,
        showSearch: true,
        showNotifications: true,
      ),
      body: const Center(child: Text(AppStrings.dashboardTitle)),
    );
  }
}
