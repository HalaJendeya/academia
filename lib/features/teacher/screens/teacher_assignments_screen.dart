import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../assignments/models/course_assignment_model.dart';
import '../../assignments/providers/course_assignment_provider.dart';
import '../../assignments/widgets/assignment_list_card.dart';
import '../models/teacher_offering_view.dart';
import '../providers/teacher_offerings_provider.dart';

/// واجبات المعلّم عبر كل طروحه.
///
/// المصدر هو مستمع لكل طرح يملكه المعلّم، مدموجة في الذاكرة — لا استعلام
/// عالمي يُصفّى محليًا. القواعد تقيّد القراءة بالملكية، فالاستعلام غير
/// المقيَّد يُرفض من الخادم لا من الواجهة.
class TeacherAssignmentsScreen extends StatefulWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  State<TeacherAssignmentsScreen> createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  /// معرّفات الطروح المشترَك بها حاليًا، لتفادي إعادة الاشتراك في كل بناء.
  List<String> _subscribedIds = const <String>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSubscriptions();
  }

  /// يتبع قائمة طروح المعلّم: الإسناد قد يتغيّر والشاشة مفتوحة.
  void _syncSubscriptions() {
    final offeringIds =
        context
            .read<TeacherOfferingsProvider>()
            .offerings
            .map((view) => view.offeringId)
            .toList()
          ..sort();

    if (_listEquals(offeringIds, _subscribedIds)) return;
    _subscribedIds = offeringIds;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CourseAssignmentProvider>().listenToOfferingsAssignments(
        offeringIds,
      );
    });
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final offeringsProvider = context.watch<TeacherOfferingsProvider>();
    final assignmentProvider = context.watch<CourseAssignmentProvider>();

    // إسناد الطروح قد يصل بعد أول بناء؛ الاشتراك يتبعه.
    _syncSubscriptions();

    final hasOfferings = offeringsProvider.offerings.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.teacherAssignmentsTitle),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: hasOfferings
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(
                context,
              ).pushNamed(AppRoutes.teacherAddAssignment),
              icon: const Icon(Icons.add_rounded),
              label: const Text(AppStrings.addAssignmentTitle),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: _buildBody(offeringsProvider, assignmentProvider),
    );
  }

  Widget _buildBody(
    TeacherOfferingsProvider offeringsProvider,
    CourseAssignmentProvider assignmentProvider,
  ) {
    if (offeringsProvider.isLoading && offeringsProvider.offerings.isEmpty) {
      return const AppLoadingState();
    }

    /*
     * لا طروح يعني لا واجبات ممكنة أصلًا، وهي حالة مختلفة عن «لا واجبات
     * بعد»: الأولى تُحلّ بإسناد من مدير النظام، والثانية بإضافة واجب.
     */
    if (offeringsProvider.offerings.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.teacherAssignmentsNoOfferingsTitle,
        description: AppStrings.teacherAssignmentsNoOfferingsDesc,
        icon: Icons.menu_book_outlined,
      );
    }

    if (assignmentProvider.isLoading && assignmentProvider.assignments.isEmpty) {
      return const AppLoadingState();
    }

    if (assignmentProvider.errorMessage != null &&
        assignmentProvider.assignments.isEmpty) {
      return AppErrorState(
        message: assignmentProvider.errorMessage!,
        onRetry: () {
          _subscribedIds = const <String>[];
          _syncSubscriptions();
        },
      );
    }

    final assignments = assignmentProvider.assignments;

    if (assignments.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.teacherAssignmentsEmptyTitle,
        description: AppStrings.teacherAssignmentsEmptyDesc,
        icon: Icons.assignment_outlined,
      );
    }

    final offeringsById = {
      for (final view in offeringsProvider.offerings) view.offeringId: view,
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
          contextLabel: _contextLabelFor(offeringsById[assignment.offeringId]),
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.teacherAssignmentDetails,
            arguments: TeacherAssignmentDetailsArgs(assignmentId: assignment.id),
          ),
        );
      },
    );
  }

  /// «المساق — الشعبة»، أو null إن لم يصل الطرح بعد.
  static String? _contextLabelFor(TeacherOfferingView? view) {
    if (view == null) return null;
    return '${view.displayTitle} · '
        '${AppStrings.offeringSectionLabel} ${view.section}';
  }
}

/// وسيطات شاشة تفاصيل الواجب.
///
/// يُمرَّر المعرّف لا النموذج: الواجب قد يُعدَّل أو يُؤرشف بينما الشاشة
/// مفتوحة، والتفاصيل تقرأ دائمًا من القائمة الحيّة.
class TeacherAssignmentDetailsArgs {
  const TeacherAssignmentDetailsArgs({required this.assignmentId});

  final String assignmentId;
}

/// وسيطات شاشة إضافة/تعديل واجب.
///
/// [assignment] غير null يعني تعديلًا؛ null يعني إنشاءً.
class TeacherAssignmentFormArgs {
  const TeacherAssignmentFormArgs({this.assignment});

  final CourseAssignmentModel? assignment;
}
