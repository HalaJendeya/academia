import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import 'admin_dashboard_screen.dart';
import 'admin_course_list_screen.dart';
import 'admin_student_list_screen.dart';
import 'admin_content_screen.dart';
import 'admin_settings_screen.dart';
import '../widgets/admin_access_guard.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AdminAccessGuard(
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            AdminDashboardScreen(
              onTabSelect: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            const AdminCourseListScreen(),
            const AdminStudentListScreen(),
            const AdminContentScreen(),
            const AdminSettingsScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: AppStrings.adminDashboardTab,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: AppStrings.adminCoursesTab,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_rounded),
              label: AppStrings.adminStudentsTab,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_copy_rounded),
              label: AppStrings.adminContentTab,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: AppStrings.adminSettingsTab,
            ),
          ],
        ),
      ),
    );
  }
}
