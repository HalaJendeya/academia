import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../courses/providers/course_provider.dart';
import '../../curriculum/models/curriculum_course_model.dart';
import '../../curriculum/providers/curriculum_provider.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';

/// وسيطات الشاشة: الخطة التي يُضاف إليها الصف، والصف المُعدَّل إن وُجد.
class CurriculumEntryFormArgs {
  const CurriculumEntryFormArgs({required this.majorId, this.entry});

  final String majorId;
  final CurriculumCourseModel? entry;
}

/// شاشة واحدة تخدم إضافة صف الخطة وتعديله، بنوعيه: مساق محدد أو خانة متطلب.
class AdminCurriculumEntryFormScreen extends StatefulWidget {
  const AdminCurriculumEntryFormScreen({super.key});

  @override
  State<AdminCurriculumEntryFormScreen> createState() =>
      _AdminCurriculumEntryFormScreenState();
}

class _AdminCurriculumEntryFormScreenState
    extends State<AdminCurriculumEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _slotLabelController = TextEditingController();
  final _prerequisiteTextController = TextEditingController();
  final _sequenceController = TextEditingController(text: '1');

  String _entryType = CurriculumCourseModel.entryCourse;
  String? _selectedCourseId;
  int _academicLevel = 1;
  String _requirementType = CurriculumCourseModel.majorRequired;
  int _slotCreditHours = 3;

  String _majorId = '';
  CurriculumCourseModel? _editing;
  bool _isEditMode = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is CurriculumEntryFormArgs) {
      _majorId = arguments.majorId;
      final entry = arguments.entry;
      if (entry != null) {
        _editing = entry;
        _isEditMode = true;
        _entryType = entry.entryType;
        _selectedCourseId = entry.courseId;
        _academicLevel = entry.academicLevel;
        _requirementType = entry.requirementType;
        _slotLabelController.text = entry.slotLabel ?? '';
        _prerequisiteTextController.text = entry.prerequisiteText ?? '';
        _sequenceController.text = entry.sequence.toString();
        if (entry.creditHours != null) _slotCreditHours = entry.creditHours!;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CourseProvider>().listenToCourses();
    });

    _initialized = true;
  }

  @override
  void dispose() {
    _slotLabelController.dispose();
    _prerequisiteTextController.dispose();
    _sequenceController.dispose();
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

  bool get _isCourseEntry => _entryType == CurriculumCourseModel.entryCourse;

  /// المساقات المتاحة للاختيار: كل الكتالوج ما عدا ما هو مضاف بالفعل إلى
  /// خطة هذا التخصص، مع إبقاء المساق الحالي متاحًا أثناء التعديل.
  List<DropdownMenuItem<String>> _courseItems(
    CourseProvider courseProvider,
    CurriculumProvider curriculumProvider,
  ) {
    final used = curriculumProvider.entries
        .where((e) => e.isCourseEntry && e.id != _editing?.id)
        .map((e) => e.courseId)
        .toSet();

    return courseProvider.courses
        .where((course) => !used.contains(course.id))
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

  CurriculumCourseModel _buildEntry() {
    final sequence = int.tryParse(_sequenceController.text.trim()) ?? 0;
    final prerequisiteText = _prerequisiteTextController.text.trim();

    if (_isCourseEntry) {
      return CurriculumCourseModel(
        id: CurriculumCourseModel.buildId(_majorId, _selectedCourseId!),
        majorId: _majorId,
        entryType: CurriculumCourseModel.entryCourse,
        courseId: _selectedCourseId,
        academicLevel: _academicLevel,
        requirementType: _requirementType,
        prerequisiteCourseIds: _editing?.prerequisiteCourseIds ?? const [],
        prerequisiteText: prerequisiteText.isEmpty ? null : prerequisiteText,
        sequence: sequence,
      );
    }

    return CurriculumCourseModel(
      id: CurriculumCourseModel.buildSlotId(_majorId, _academicLevel, sequence),
      majorId: _majorId,
      entryType: CurriculumCourseModel.entrySlot,
      slotLabel: _slotLabelController.text.trim(),
      academicLevel: _academicLevel,
      requirementType: _requirementType,
      creditHours: _slotCreditHours,
      prerequisiteCourseIds: const [],
      sequence: sequence,
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isCourseEntry && _selectedCourseId == null) return;

    final provider = context.read<CurriculumProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final entry = _buildEntry();

    /*
     * معرّف صف الخطة توليدي، والمستند لا يمكن أن ينتقل إلى معرّف آخر.
     * لذلك نتعامل مع الحالتين صراحةً: إذا لم يتغيّر المعرّف نحدّث في مكانه،
     * وإذا تغيّر ننشئ الصف الجديد ثم نحذف القديم.
     */
    final bool success;
    if (!_isEditMode) {
      success = _isCourseEntry
          ? await provider.addCourseEntry(entry)
          : await provider.addSlotEntry(entry);
    } else if (entry.id == _editing!.id) {
      success = await provider.updateEntry(entry);
    } else {
      success = await provider.replaceEntry(
        oldEntryId: _editing!.id,
        entry: entry,
      );
    }

    if (!mounted) return;

    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? AppStrings.curriculumEntryUpdatedSuccess
                : AppStrings.curriculumEntryAddedSuccess,
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? AppStrings.curriculumSaveError,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final curriculumProvider = context.watch<CurriculumProvider>();
    final courseProvider = context.watch<CourseProvider>();
    final courseItems = _courseItems(courseProvider, curriculumProvider);

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditMode
                ? AppStrings.editCurriculumEntryLabel
                : AppStrings.addCurriculumEntryLabel,
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
                      _buildLabel(AppStrings.curriculumEntryTypeLabel),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: CurriculumCourseModel.entryCourse,
                            label: Text(AppStrings.entryTypeCourseLabel),
                          ),
                          ButtonSegment(
                            value: CurriculumCourseModel.entrySlot,
                            label: Text(AppStrings.entryTypeSlotLabel),
                          ),
                        ],
                        selected: {_entryType},
                        onSelectionChanged: (selection) {
                          setState(() => _entryType = selection.first);
                        },
                      ),

                      if (_isCourseEntry) ...[
                        _buildLabel(AppStrings.curriculumCoursePickerLabel),
                        if (courseProvider.courses.isEmpty)
                          Text(
                            AppStrings.noCoursesForCurriculum,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warningDark,
                            ),
                          )
                        else if (courseItems.isEmpty)
                          Text(
                            AppStrings.allCurriculumCoursesUsed,
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
                            onChanged: (value) {
                              setState(() => _selectedCourseId = value);
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppStrings.curriculumCourseRequired;
                              }
                              return null;
                            },
                          ),
                      ] else ...[
                        _buildLabel(AppStrings.slotLabelFieldLabel),
                        TextFormField(
                          controller: _slotLabelController,
                          decoration: const InputDecoration(
                            hintText: AppStrings.slotLabelHint,
                          ),
                          validator: (value) {
                            if (_isCourseEntry) return null;
                            if (value == null || value.trim().isEmpty) {
                              return AppStrings.curriculumSlotLabelRequired;
                            }
                            return null;
                          },
                        ),

                        _buildLabel(AppStrings.creditHoursLabel),
                        DropdownButtonFormField<int>(
                          initialValue: _slotCreditHours,
                          items: [1, 2, 3, 4, 5]
                              .map(
                                (hours) => DropdownMenuItem<int>(
                                  value: hours,
                                  child: Text(
                                    '$hours ${AppStrings.creditHoursSuffix}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _slotCreditHours = value);
                          },
                        ),
                      ],

                      _buildLabel(AppStrings.academicLevelLabel),
                      DropdownButtonFormField<int>(
                        initialValue: _academicLevel,
                        items: AppStrings.academicLevelValues
                            .map(
                              (level) => DropdownMenuItem<int>(
                                value: level,
                                child: Text(
                                  AppStrings.academicLevelDisplay(level),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _academicLevel = value);
                        },
                      ),

                      _buildLabel(AppStrings.requirementTypeLabel),
                      DropdownButtonFormField<String>(
                        initialValue: _requirementType,
                        isExpanded: true,
                        items: CurriculumCourseModel.allowedRequirementTypes
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(
                                  AppStrings.requirementTypeDisplay(type),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _requirementType = value);
                        },
                      ),

                      _buildLabel(AppStrings.sequenceLabel),
                      TextFormField(
                        controller: _sequenceController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final parsed = int.tryParse(
                            (value ?? '').trim(),
                          );
                          if (parsed == null || parsed < 0) {
                            return AppStrings.sequenceInvalid;
                          }
                          return null;
                        },
                      ),

                      if (_isCourseEntry) ...[
                        _buildLabel(AppStrings.prerequisiteTextLabel),
                        TextFormField(
                          controller: _prerequisiteTextController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: AppStrings.prerequisiteTextHint,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Text(
                          AppStrings.prerequisiteNotEnforcedNote,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],

                      if (_isEditMode) ...[
                        const SizedBox(height: AppSpacing.medium),
                        const Divider(color: AppColors.divider),
                        Text(
                          AppStrings.curriculumIdentityChangeNote,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.extraLarge),

                AppPrimaryButton(
                  label: _isEditMode
                      ? AppStrings.saveChanges
                      : AppStrings.addCurriculumEntryLabel,
                  isLoading: curriculumProvider.isSaving,
                  isEnabled: !curriculumProvider.isSaving,
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
