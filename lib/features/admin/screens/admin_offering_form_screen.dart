import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../courses/models/course_model.dart';
import '../../courses/models/course_offering_model.dart';
import '../../courses/providers/course_offering_provider.dart';
import '../../courses/providers/course_provider.dart';
import '../../semesters/providers/semester_provider.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';

/// وسيطات الشاشة: الفصل الذي يُطرح فيه المساق، والطرح المُعدَّل إن وُجد.
class OfferingFormArgs {
  const OfferingFormArgs({required this.semesterId, this.offering});

  final String semesterId;
  final CourseOfferingModel? offering;
}

/// شاشة واحدة تخدم إنشاء الطرح وتعديله.
///
/// المساق والفصل والشعبة تشكّل معرّف المستند، لذلك تُقفل عند التعديل:
/// المستند لا ينتقل إلى معرّف آخر، ولتغييرها يُنشأ طرح جديد.
class AdminOfferingFormScreen extends StatefulWidget {
  const AdminOfferingFormScreen({super.key});

  @override
  State<AdminOfferingFormScreen> createState() =>
      _AdminOfferingFormScreenState();
}

class _AdminOfferingFormScreenState extends State<AdminOfferingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _instructorController = TextEditingController();
  final _sectionController = TextEditingController(
    text: CourseOfferingModel.defaultSection,
  );

  String _semesterId = '';
  String? _selectedCourseId;
  String _selectedStatus = CourseOfferingModel.statusActive;

  CourseOfferingModel? _editing;
  bool _isEditMode = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is OfferingFormArgs) {
      _semesterId = arguments.semesterId;
      final offering = arguments.offering;
      if (offering != null) {
        _editing = offering;
        _isEditMode = true;
        _semesterId = offering.semesterId;
        _selectedCourseId = offering.courseId;
        _instructorController.text = offering.instructorName;
        _sectionController.text = offering.section;
        _selectedStatus = offering.status;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CourseProvider>().listenToCourses();
      context.read<SemesterProvider>().listenToSemesters();
    });

    _initialized = true;
  }

  @override
  void dispose() {
    _instructorController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 10.0),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// المساقات المتاحة للطرح: النشطة فقط.
  ///
  /// طرح مساق مؤرشف يناقض معنى الأرشفة، لكن المساق المختار حاليًا يبقى
  /// معروضًا أثناء التعديل حتى لو أُرشف بعد إنشاء الطرح.
  List<DropdownMenuItem<String>> _courseItems(List<CourseModel> courses) {
    return courses
        .where((course) => course.isActive || course.id == _selectedCourseId)
        .map(
          (course) => DropdownMenuItem<String>(
            value: course.id,
            child: Text(
              '${course.courseCode} — ${course.title}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCourseId == null) return;

    final provider = context.read<CourseOfferingProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final section = _sectionController.text.trim();

    final offering = CourseOfferingModel(
      id: _isEditMode
          ? _editing!.id
          : CourseOfferingModel.buildId(
              _selectedCourseId!,
              _semesterId,
              section,
            ),
      courseId: _selectedCourseId!,
      semesterId: _semesterId,
      instructorName: _instructorController.text.trim(),
      section: section,
      status: _selectedStatus,
      source: _isEditMode
          ? _editing!.source
          : CourseOfferingModel.sourceManual,
      externalId: _isEditMode ? _editing!.externalId : null,
      createdBy: _isEditMode ? _editing!.createdBy : '',
    );

    final success = _isEditMode
        ? await provider.updateOffering(offering)
        : await provider.createOffering(offering);

    if (!mounted) return;

    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? AppStrings.offeringUpdatedSuccess
                : AppStrings.offeringAddedSuccess,
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? AppStrings.offeringSaveError),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseOfferingProvider>();
    final courses = context.watch<CourseProvider>().courses;
    final semesterName = context
        .watch<SemesterProvider>()
        .semesterNameFor(_semesterId);
    final courseItems = _courseItems(courses);

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditMode
                ? AppStrings.editOfferingLabel
                : AppStrings.addOfferingLabel,
          ),
          centerTitle: true,
          leading: const AdminBackButton(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(AppStrings.courseSemesterLabel),
                      // الفصل يأتي من الشاشة السابقة ولا يُختار هنا.
                      InputDecorator(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.event_note_rounded),
                        ),
                        child: Text(
                          semesterName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      _buildLabel(AppStrings.offeringCourseLabel),
                      if (courseItems.isEmpty)
                        Text(
                          AppStrings.noCoursesForCurriculum,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.warningDark,
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue:
                              courseItems.any(
                                (item) => item.value == _selectedCourseId,
                              )
                              ? _selectedCourseId
                              : null,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            hintText: AppStrings.curriculumCoursePickerHint,
                          ),
                          items: courseItems,
                          // المساق جزء من معرّف المستند: يُقفل بعد الإنشاء.
                          onChanged: _isEditMode
                              ? null
                              : (value) =>
                                    setState(() => _selectedCourseId = value),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppStrings.offeringCourseRequired;
                            }
                            return null;
                          },
                        ),

                      _buildLabel(AppStrings.offeringSectionLabel),
                      TextFormField(
                        controller: _sectionController,
                        readOnly: _isEditMode,
                        decoration: const InputDecoration(
                          hintText: AppStrings.offeringSectionHint,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.offeringSectionRequired;
                          }
                          return null;
                        },
                      ),

                      _buildLabel(AppStrings.offeringInstructorLabel),
                      TextFormField(
                        controller: _instructorController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.offeringInstructorHint,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.offeringInstructorRequired;
                          }
                          return null;
                        },
                      ),

                      _buildLabel(AppStrings.statusLabel),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: CourseOfferingModel.statusActive,
                            child: Text(AppStrings.activeStatus),
                          ),
                          DropdownMenuItem(
                            value: CourseOfferingModel.statusArchived,
                            child: Text(AppStrings.archivedStatus),
                          ),
                          DropdownMenuItem(
                            value: CourseOfferingModel.statusCancelled,
                            child: Text(AppStrings.offeringStatusCancelled),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedStatus = value);
                        },
                        validator: (value) {
                          if (value == null ||
                              !CourseOfferingModel.allowedStatuses.contains(
                                value,
                              )) {
                            return AppStrings.offeringStatusInvalid;
                          }
                          return null;
                        },
                      ),

                      if (_isEditMode) ...[
                        const SizedBox(height: AppSpacing.medium),
                        const Divider(color: AppColors.divider),
                        Text(
                          AppStrings.offeringIdentityLockedNote,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.extraLarge),

                AppPrimaryButton(
                  label: _isEditMode
                      ? AppStrings.saveChanges
                      : AppStrings.addOfferingLabel,
                  isLoading: provider.isSaving,
                  isEnabled: !provider.isSaving && courseItems.isNotEmpty,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.medium),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(AppStrings.cancelAction),
                ),
                const SizedBox(height: AppSpacing.large),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
