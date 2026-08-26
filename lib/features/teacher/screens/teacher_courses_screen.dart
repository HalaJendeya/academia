import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../providers/teacher_offerings_provider.dart';
import '../widgets/teacher_offering_card.dart';

/// مساقات المعلّم: الطروحات المسندة إليه وحدها.
///
/// القائمة كلها من courseOfferings حيث teacherId يساوي معرّفه؛ لا يظهر هنا
/// أي طرح لا يملكه، ولا يمكن أن يظهر — الاستعلام نفسه مقيَّد بالملكية.
class TeacherCoursesScreen extends StatelessWidget {
  const TeacherCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherOfferingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.teacherCoursesTitle),
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, TeacherOfferingsProvider provider) {
    if (provider.isLoading && provider.offerings.isEmpty) {
      return const AppLoadingState();
    }

    if (provider.errorMessage != null && provider.offerings.isEmpty) {
      return AppErrorState(message: provider.errorMessage!);
    }

    final offerings = provider.offerings;

    if (offerings.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.teacherCoursesDeferredTitle,
        description: AppStrings.teacherCoursesDeferredDesc,
        icon: Icons.menu_book_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.huge,
      ),
      itemCount: offerings.length,
      itemBuilder: (context, index) {
        final view = offerings[index];
        return TeacherOfferingCard(
          view: view,
          onTap: () {
            context.read<TeacherOfferingsProvider>().listenToOfferingRoster(
              view.offeringId,
            );
            Navigator.of(context).pushNamed(AppRoutes.teacherOfferingDetail);
          },
        );
      },
    );
  }
}
