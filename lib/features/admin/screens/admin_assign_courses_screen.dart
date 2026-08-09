import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_destructive_button.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';
import '../../courses/models/course_model.dart';
import '../../courses/models/course_offering_model.dart';
import '../../courses/providers/course_provider.dart';
import '../../courses/providers/course_offering_provider.dart';
import '../../enrollments/models/enrollment_model.dart';
import '../../enrollments/providers/enrollment_provider.dart';
import '../../semesters/providers/semester_provider.dart';
import '../models/admin_student_model.dart';

class AdminAssignCoursesScreen extends StatefulWidget {
  const AdminAssignCoursesScreen({super.key});

  @override
  State<AdminAssignCoursesScreen> createState() =>
      _AdminAssignCoursesScreenState();
}

class _AdminAssignCoursesScreenState extends State<AdminAssignCoursesScreen> {
  bool _hasInitialized = false;
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_hasInitialized) {
      return;
    }

    final arguments = ModalRoute.of(context)?.settings.arguments;
    final student = arguments is AdminStudentModel
        ? arguments
        : context.read<EnrollmentProvider>().selectedStudent;

    if (student != null) {
      _hasInitialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        context.read<CourseProvider>().listenToCourses();
        context.read<SemesterProvider>().listenToSemesters();
        final enrollmentProvider = context.read<EnrollmentProvider>();

        if (enrollmentProvider.selectedStudent?.uid != student.uid) {
          enrollmentProvider.selectStudent(student);
        } else {
          enrollmentProvider.loadStudentEnrollments(student.uid);
        }
      });
    } else {
      _hasInitialized = true;
    }
  }

  /*
   * التسجيل يتم في طرح المساق ضمن الفصل الحالي، لا في المساق الدائم نفسه.
   * لذلك نتابع طروحات الفصل الحالي هنا، ونعيد الاشتراك عندما يتغيّر الفصل
   * الحالي فقط — المقارنة بـ semesterId تمنع إعادة الاشتراك في كل إعادة بناء.
   */
  void _syncOfferingsWithCurrentSemester(String? currentSemesterId) {
    if (currentSemesterId == null) return;

    final offeringProvider = context.read<CourseOfferingProvider>();
    if (offeringProvider.semesterId == currentSemesterId) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CourseOfferingProvider>().listenToSemesterOfferings(
        currentSemesterId,
      );
    });
  }

  void _showRemoveDialog(
    BuildContext context,
    EnrollmentModel enrollment,
    String courseTitle,
  ) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'إلغاء تسجيل المساق',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: Text(
          '${AppStrings.removeCourseConfirm}\n($courseTitle)',
          textAlign: TextAlign.right,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: AppDestructiveButton(
              label: AppStrings.confirmAction,
              filled: true,
              onPressed: () async {
                Navigator.of(ctx).pop();
                final provider = context.read<EnrollmentProvider>();
                final success = await provider.removeEnrollment(
                  enrollment.offeringId,
                );
                if (mounted) {
                  if (success) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text(AppStrings.courseRemovedSuccess),
                      ),
                    );
                  } else {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          provider.errorMessage ?? AppStrings.courseSaveError,
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancelAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnrollmentProvider>();
    final student = provider.selectedStudent;

    if (student == null) {
      return const AdminAccessGuard(child: Scaffold(body: AppLoadingState()));
    }

    final currentSemester = context.watch<SemesterProvider>().currentSemester;
    _syncOfferingsWithCurrentSemester(currentSemester?.id);

    final offeringProvider = context.watch<CourseOfferingProvider>();

    final courses = List<CourseModel>.from(
      context.watch<CourseProvider>().courses,
    );
    courses.sort((a, b) {
      if (a.isActive && !b.isActive) return -1;
      if (!a.isActive && b.isActive) return 1;
      return a.title.compareTo(b.title);
    });

    final filtered = courses.where((course) {
      return course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          course.courseCode.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تسجيل المساقات'),
          centerTitle: true,
          leading: const AdminBackButton(),
        ),
        body: currentSemester == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.screenHorizontal),
                  child: Text(
                    AppStrings.noCurrentSemesterForAssignment,
                    style: TextStyle(color: AppColors.warningDark),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : provider.isLoadingEnrollments
            ? const AppLoadingState()
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: AppStrings.searchCourseToAssignHint,
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.medium,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final course = filtered[index];

                        // الطرح الفعلي لهذا المساق في الفصل الحالي، إن وُجد.
                        final offering = offeringProvider
                            .activeOfferingForCourse(course.id);

                        // بحث قابل للإرجاع الفارغ بدل إنشاء كائن وهمي.
                        final enrollment = offering == null
                            ? null
                            : provider.enrollmentForOffering(offering.id);

                        return _buildCourseRow(
                          course,
                          offering,
                          enrollment,
                          provider,
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCourseRow(
    CourseModel course,
    CourseOfferingModel? offering,
    EnrollmentModel? enrollment,
    EnrollmentProvider provider,
  ) {
    String statusText;
    Color statusColor;
    if (enrollment == null) {
      statusText = AppStrings.notEnrolledStatus;
      statusColor = AppColors.textSecondary;
    } else if (enrollment.isActive) {
      statusText = AppStrings.activeEnrollmentStatus;
      statusColor = AppColors.activeStatus;
    } else if (enrollment.isCompleted) {
      statusText = AppStrings.completedEnrollmentStatus;
      statusColor = AppColors.secondary;
    } else {
      statusText = AppStrings.removedEnrollmentStatus;
      statusColor = AppColors.danger;
    }

    final statusBgColor = statusColor.withValues(alpha: 0.08);
    final courseStatusColor = course.isActive
        ? AppColors.activeStatus
        : AppColors.textMuted;
    final courseStatusBgColor = courseStatusColor.withValues(alpha: 0.08);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  course.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: course.isActive
                    ? AppStrings.activeStatus
                    : AppStrings.archivedStatus,
                backgroundColor: courseStatusBgColor,
                foregroundColor: courseStatusColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                course.courseCode,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppStatusBadge(
                label: statusText,
                backgroundColor: statusBgColor,
                foregroundColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          /*
           * اسم المدرّس يأتي من الطرح لا من المساق. غياب الطرح يعني أن المساق
           * غير مطروح هذا الفصل، ولا يمكن التسجيل فيه أصلًا.
           */
          Text(
            offering == null
                ? AppStrings.courseNotOfferedThisSemester
                : '${AppStrings.instructorNameLabel}: '
                      '${offering.instructorName}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: offering == null
                  ? AppColors.warningDark
                  : AppColors.textSecondary,
            ),
          ),
          const Divider(height: 24, color: AppColors.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (offering == null)
                const SizedBox.shrink()
              else if (enrollment == null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  onPressed: provider.isSaving
                      ? null
                      : () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          final success = await provider.assignToOffering(
                            offering.id,
                          );
                          if (mounted) {
                            if (success) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    AppStrings.courseAssignedSuccess,
                                  ),
                                ),
                              );
                            } else {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    provider.errorMessage ??
                                        AppStrings.courseSaveError,
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(AppStrings.assignCourseLabel),
                )
              else if (enrollment.isActive)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  onPressed: provider.isSaving
                      ? null
                      : () => _showRemoveDialog(
                          context,
                          enrollment,
                          course.title,
                        ),
                  icon: const Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 18,
                  ),
                  label: const Text('إلغاء التسجيل'),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  onPressed: provider.isSaving
                      ? null
                      : () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          final success = await provider.restoreEnrollment(
                            offering.id,
                          );
                          if (mounted) {
                            if (success) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    AppStrings.courseRestoredSuccess,
                                  ),
                                ),
                              );
                            } else {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    provider.errorMessage ??
                                        AppStrings.courseSaveError,
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('إعادة التسجيل'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
