import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../assignments/models/course_assignment_model.dart';
import '../../assignments/providers/course_assignment_provider.dart';
import '../../assignments/widgets/assignment_list_card.dart';
import '../../courses/providers/course_provider.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';

/// إشراف المشرف على الواجبات الأكاديمية.
///
/// قراءة عالمية حقيقية، بلا زر إنشاء: المشرف يملك الهيكل الأكاديمي، أما
/// المحتوى التعليمي فيؤلّفه معلّم المساق. القواعد ترفض إنشاء المشرف صراحةً،
/// وزرٌّ يقود إلى رفضٍ مؤكَّد ليس ميزة.
class AdminAssignmentListScreen extends StatefulWidget {
  const AdminAssignmentListScreen({super.key});

  @override
  State<AdminAssignmentListScreen> createState() =>
      _AdminAssignmentListScreenState();
}

class _AdminAssignmentListScreenState extends State<AdminAssignmentListScreen> {
  CourseAssignmentProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<CourseAssignmentProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // أسماء المساقات تأتي من مزوّدها؛ الواجب يحمل المعرّفات فقط.
      context.read<CourseProvider>().listenToCourses();
      context.read<CourseAssignmentProvider>().listenToAllActiveAssignments();
    });
  }

  @override
  void dispose() {
    // الاستماع العالمي خاص بهذه الشاشة ولا يجوز أن يبقى بعد مغادرتها.
    _provider?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseAssignmentProvider>();

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.adminAssignmentsOversightTitle),
          leading: const AdminBackButton(),
        ),
        body: Column(
          children: [
            _buildOversightNote(),
            Expanded(child: _buildBody(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildOversightNote() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.medium,
        0,
      ),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                AppStrings.adminAssignmentsOversightNote,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CourseAssignmentProvider provider) {
    if (provider.isLoading && provider.assignments.isEmpty) {
      return const AppLoadingState();
    }

    if (provider.errorMessage != null && provider.assignments.isEmpty) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: () {
          final assignmentProvider = context.read<CourseAssignmentProvider>();
          assignmentProvider.stopListening();
          assignmentProvider.listenToAllActiveAssignments();
        },
      );
    }

    final assignments = provider.assignments;

    if (assignments.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.adminAssignmentsEmptyTitle,
        description: AppStrings.adminAssignmentsEmptyDesc,
        icon: Icons.assignment_outlined,
      );
    }

    final courses = context.watch<CourseProvider>().courses;
    final courseTitles = {
      for (final course in courses)
        course.id: '${course.courseCode} — ${course.title}',
    };

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.huge,
      ),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        return AssignmentListCard(
          assignment: assignment,
          // null لا نص فارغ: المساق قد لا يكون قد وصل بعد.
          contextLabel: courseTitles[assignment.courseId],
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.adminAssignmentDetails,
            arguments: AdminAssignmentDetailsArgs(assignment: assignment),
          ),
        );
      },
    );
  }
}

/// وسيطات شاشة تفاصيل الواجب للمشرف.
class AdminAssignmentDetailsArgs {
  const AdminAssignmentDetailsArgs({required this.assignment});

  final CourseAssignmentModel assignment;
}
