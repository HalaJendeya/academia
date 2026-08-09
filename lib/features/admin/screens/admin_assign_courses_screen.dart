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
  AdminStudentModel? _student;

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

    _student = student;

    if (student != null) {
      _hasInitialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        context.read<CourseProvider>().listenToCourses();
        context.read<SemesterProvider>().listenToSemesters();
        final enrollmentProvider = context.read<EnrollmentProvider>();

        enrollmentProvider.selectStudent(student);
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

  /// رقم المحاولة المتوقَّع، للعرض فقط.
  ///
  /// الرقم النهائي تحسبه الخدمة عند الكتابة (أكبر رقم موجود + 1، شاملًا
  /// المُزالة)؛ هذا مجرد معاينة للمشرف قبل الضغط.
  int _nextAttemptNumber(List<EnrollmentModel> previousAttempts) {
    var maxAttempt = 0;
    for (final attempt in previousAttempts) {
      if (maxAttempt < attempt.attemptNumber) {
        maxAttempt = attempt.attemptNumber;
      }
    }
    return maxAttempt + 1;
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

    final student = _student;

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

                        // محاولات الطالب السابقة في هذا المساق الدائم، أيًّا
                        // كان الفصل: هي ما يحدّد رقم المحاولة القادمة.
                        final previousAttempts = provider
                            .attemptsForCourse(course.id)
                            .where((a) => a.offeringId != offering?.id)
                            .toList();

                        return _buildCourseRow(
                          course,
                          offering,
                          enrollment,
                          previousAttempts,
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
    List<EnrollmentModel> previousAttempts,
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
          /*
           * إعادة الدراسة جزء معتمد من النظام: كل محاولة مستند مستقل يشير
           * إلى طرح مختلف. عرض المحاولات السابقة هنا يمنع المشرف من الظن
           * أنه يسجّل الطالب للمرة الأولى، ويُظهر رقم المحاولة القادمة.
           */
          if (previousAttempts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppStatusBadge(
                  label: AppStrings.retakeBadgeLabel,
                  backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                  foregroundColor: AppColors.warningDark,
                ),
                for (final attempt in previousAttempts)
                  AppStatusBadge(
                    label:
                        '${AppStrings.attemptLabel} ${attempt.attemptNumber}'
                        '${attempt.completionStatus != null ? ': ${AppStrings.completionStatusDisplay(attempt.completionStatus)}' : ''}',
                    backgroundColor: AppColors.surfaceSecondary,
                    foregroundColor: AppColors.textSecondary,
                  ),
              ],
            ),
            if (enrollment == null && offering != null) ...[
              const SizedBox(height: 6),
              Text(
                '${AppStrings.willBeAttemptPrefix} '
                '${_nextAttemptNumber(previousAttempts)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.warningDark,
                ),
              ),
            ],
          ],
          if (enrollment != null && enrollment.isRetake) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              '${AppStrings.attemptLabel} ${enrollment.attemptNumber}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.warningDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const Divider(height: 24, color: AppColors.divider),

          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: offering == null
                ? const SizedBox.shrink()
                : enrollment == null
                ? ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,

                      // IMPORTANT:
                      // Override any global button theme that requests full width.
                      minimumSize: const Size(0, 52),

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
                : enrollment.isActive
                ? OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),

                      // Same protection for the outlined button.
                      minimumSize: const Size(0, 52),

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
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,

                      // Same override here too.
                      minimumSize: const Size(0, 52),

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
          ),
        ],
      ),
    );
  }
}
