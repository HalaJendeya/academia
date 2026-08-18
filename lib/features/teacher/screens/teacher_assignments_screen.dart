import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_state.dart';

/// واجبات المعلّم.
///
/// فارغة عمدًا في المرحلة 8A: مجموعة الواجبات غير موجودة بعد. لا نعرض
/// نموذج إنشاء لا يحفظ شيئًا — تلك كانت مشكلة شاشات الواجبات القديمة.
class TeacherAssignmentsScreen extends StatelessWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.teacherAssignmentsTitle),
        automaticallyImplyLeading: false,
      ),
      body: const AppEmptyState(
        title: AppStrings.teacherAssignmentsDeferredTitle,
        description: AppStrings.teacherAssignmentsDeferredDesc,
        icon: Icons.assignment_outlined,
      ),
    );
  }
}
