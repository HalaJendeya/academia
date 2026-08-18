import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../widgets/teacher_access_guard.dart';
import 'teacher_assignments_screen.dart';
import 'teacher_courses_screen.dart';
import 'teacher_dashboard_screen.dart';
import 'teacher_profile_screen.dart';

/// واجهة المعلّم.
///
/// تتبع نمط AdminShellScreen — IndexedStack مع شريط سفلي — لا نمط تنقّل
/// الطالب: ذاك يحمل فهارس ووجهات خاصة بالطالب مثبَّتة في الشيفرة، وإعادة
/// استعماله هنا تُدخل المعلّم في شاشات الطالب.
class TeacherShellScreen extends StatefulWidget {
  const TeacherShellScreen({super.key});

  @override
  State<TeacherShellScreen> createState() => _TeacherShellScreenState();
}

class _TeacherShellScreenState extends State<TeacherShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return TeacherAccessGuard(
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            TeacherDashboardScreen(),
            TeacherCoursesScreen(),
            TeacherAssignmentsScreen(),
            TeacherProfileScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: AppStrings.teacherHomeTab,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: AppStrings.teacherCoursesTab,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              label: AppStrings.teacherAssignmentsTab,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: AppStrings.teacherProfileTab,
            ),
          ],
        ),
      ),
    );
  }
}
