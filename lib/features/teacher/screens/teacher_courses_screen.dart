import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_state.dart';

/// مساقات المعلّم.
///
/// فارغة عمدًا في المرحلة 8A: الطروح لا تحمل بعد حقل teacherId، فلا توجد
/// علاقة يمكن الاستعلام بها. الحالة الفارغة تقول ذلك صراحةً بدل عرض قائمة
/// مصطنعة.
class TeacherCoursesScreen extends StatelessWidget {
  const TeacherCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.teacherCoursesTitle),
        automaticallyImplyLeading: false,
      ),
      body: const AppEmptyState(
        title: AppStrings.teacherCoursesDeferredTitle,
        description: AppStrings.teacherCoursesDeferredDesc,
        icon: Icons.menu_book_outlined,
      ),
    );
  }
}
