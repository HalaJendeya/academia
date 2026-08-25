import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_section.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../courses/models/student_course_view.dart';
import '../../courses/providers/student_courses_provider.dart';
import '../../profile/providers/study_preferences_provider.dart';
import '../models/study_session_model.dart';
import '../providers/study_session_provider.dart';
import '../widgets/study_session_card.dart';

/// مركز المذاكرة — تبويب «المذاكرة» في شريط التنقّل السفلي.
///
/// النسخة الأولى تقدّم ما يمكن بناؤه على بيانات حقيقية فقط: تفضيلات
/// الطالب المخزَّنة، وبدء جلسة تركيز، وسجل الجلسات السابقة. لا خطة ذكية
/// ولا رسوم بيانية ولا مؤشرات التزام — تلك تحتاج بيانات لا يملكها النظام
/// بعد، وعرضها بأرقام مختلقة يجعل الشاشة تكذب على الطالب.
class StudyHubScreen extends StatefulWidget {
  const StudyHubScreen({super.key});

  @override
  State<StudyHubScreen> createState() => _StudyHubScreenState();
}

class _StudyHubScreenState extends State<StudyHubScreen> {
  /// المدة المختارة لهذه الجلسة. null يعني «اتبع التفضيلات المخزَّنة».
  int? _selectedMinutes;

  /// الطرح المختار. null يعني مذاكرة عامة.
  String? _selectedOfferingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StudyPreferencesProvider>().loadPreferences();
    });
  }

  int _durationFor(StudyPreferencesProvider prefs) {
    final selected = _selectedMinutes;
    if (selected != null) return selected;
    return prefs.preferences?.preferredSessionDuration ??
        StudySessionModel.minMinutes * 9; // 45 — نفس افتراضي التفضيلات
  }

  Future<void> _start(
    BuildContext context,
    List<StudentCourseView> courses,
    int minutes,
  ) async {
    final provider = context.read<StudySessionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    StudentCourseView? course;
    for (final c in courses) {
      if (c.offeringId == _selectedOfferingId) course = c;
    }

    final started = await provider.startSession(
      plannedMinutes: minutes,
      offeringId: course?.offeringId,
      courseId: course?.courseId,
    );

    if (!mounted) return;

    if (!started) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? AppStrings.studySessionStartError,
          ),
        ),
      );
      return;
    }

    navigator.pushNamed(AppRoutes.activeStudySession);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<StudyPreferencesProvider>();
    final sessions = context.watch<StudySessionProvider>();
    final coursesProvider = context.watch<StudentCoursesProvider>();

    return AuthenticatedPageScaffold(
      currentIndex: AcademiaBottomNavigation.studyIndex,
      onNavigationTap: (index) => handleMainNavigation(
        context,
        index,
        currentIndex: AcademiaBottomNavigation.studyIndex,
      ),
      // بلا إجراءات في الشريط: لا بحث ولا إشعارات ولا ملف شخصي هنا، تمامًا
      // كشاشة المهام. زر بلا وجهة يَعِد بفعل لا يحدث، ويزاحم العنوان على
      // عرض 360.
      appBar: const AcademiaMainAppBar(
        title: AppStrings.studyHubTitle,
        showSearch: false,
        showNotifications: false,
        showProfile: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.medium,
          AppSpacing.screenHorizontal,
          AppSpacing.huge,
        ),
        children: [
          Text(AppStrings.studyHubIntro, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.sectionSpacing),

          _buildSessionSection(context, prefs, sessions, coursesProvider),
          const SizedBox(height: AppSpacing.sectionSpacing),

          _buildPreferencesSection(context, prefs),
          const SizedBox(height: AppSpacing.sectionSpacing),

          _buildHistorySection(sessions),
        ],
      ),
    );
  }

  // -------------------------------------------------------- جلسة المذاكرة
  Widget _buildSessionSection(
    BuildContext context,
    StudyPreferencesProvider prefs,
    StudySessionProvider sessions,
    StudentCoursesProvider coursesProvider,
  ) {
    final minutes = _durationFor(prefs);
    final courses = coursesProvider.currentCourses;

    return AppSection(
      title: AppStrings.studySessionSectionTitle,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sessions.hasActiveSession) ...[
              _ActiveSessionBanner(
                onOpen: () =>
                    Navigator.of(context).pushNamed(AppRoutes.activeStudySession),
              ),
              const SizedBox(height: AppSpacing.medium),
            ],

            Text(
              AppStrings.studySessionDurationLabel,
              style: AppTextStyles.labelMedium,
            ),
            const SizedBox(height: AppSpacing.small),
            _DurationChips(
              selected: minutes,
              onSelected: (value) => setState(() => _selectedMinutes = value),
            ),

            const SizedBox(height: AppSpacing.medium),
            Text(AppStrings.studySessionCourseLabel, style: AppTextStyles.labelMedium),
            const SizedBox(height: AppSpacing.small),
            _CoursePicker(
              courses: courses,
              selectedOfferingId: _selectedOfferingId,
              onChanged: (value) =>
                  setState(() => _selectedOfferingId = value),
            ),

            const SizedBox(height: AppSpacing.medium),
            AppPrimaryButton(
              label: AppStrings.startStudySession,
              icon: Icons.play_arrow_rounded,
              isLoading: sessions.isStarting,
              // جلسة واحدة في كل مرة: الزر معطَّل ما دامت هناك جلسة جارية،
              // والبانر أعلاه هو طريق العودة إليها.
              onPressed: sessions.hasActiveSession
                  ? null
                  : () => _start(context, courses, minutes),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- التفضيلات
  Widget _buildPreferencesSection(
    BuildContext context,
    StudyPreferencesProvider prefs,
  ) {
    Widget content;

    if (prefs.isLoading && prefs.preferences == null) {
      content = const AppLoadingState();
    } else if (prefs.preferences == null) {
      content = AppErrorState(
        message: prefs.errorMessage ?? AppStrings.studyPreferencesLoadError,
        onRetry: () => prefs.loadPreferences(forceRefresh: true),
      );
    } else {
      final p = prefs.preferences!;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PreferenceRow(
            label: AppStrings.defaultSessionDurationLabel,
            value: '${p.preferredSessionDuration} '
                '${AppStrings.studySessionMinutesUnit}',
          ),
          const SizedBox(height: AppSpacing.small),
          _PreferenceRow(
            label: AppStrings.preferredStudyDaysLabel,
            value: p.studyDays.join('، '),
          ),
          const SizedBox(height: AppSpacing.medium),
          AppSecondaryButton(
            label: AppStrings.editStudyPreferencesAction,
            icon: Icons.tune_rounded,
            // لا نموذج تفضيلات ثانٍ هنا: التعديل يفتح الشاشة القائمة.
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.studyPreferences),
          ),
        ],
      );
    }

    return AppSection(
      title: AppStrings.studyPreferencesSectionTitle,
      child: AppCard(child: content),
    );
  }

  // ---------------------------------------------------------------- السجل
  Widget _buildHistorySection(StudySessionProvider sessions) {
    Widget content;

    if (sessions.isLoading && sessions.sessions.isEmpty) {
      content = const AppLoadingState();
    } else if (sessions.errorMessage != null && sessions.sessions.isEmpty) {
      content = AppErrorState(message: sessions.errorMessage!);
    } else {
      final recent = sessions.recentSessions();
      if (recent.isEmpty) {
        content = const AppEmptyState(
          title: AppStrings.noStudySessionsTitle,
          description: AppStrings.noStudySessionsDesc,
          icon: Icons.history_rounded,
        );
      } else {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final session in recent) ...[
              StudySessionCard(session: session),
              if (session != recent.last)
                const SizedBox(height: AppSpacing.itemSpacing),
            ],
          ],
        );
      }
    }

    return AppSection(title: AppStrings.recentSessionsTitle, child: content);
  }
}

// ---------------------------------------------------------------- عناصر فرعية

class _ActiveSessionBanner extends StatelessWidget {
  const _ActiveSessionBanner({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.itemSpacing),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                AppStrings.activeSessionTitle,
                style: AppTextStyles.labelMedium,
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _DurationChips extends StatelessWidget {
  const _DurationChips({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  /// خيارات ثابتة قصيرة. المدة المخصَّصة تُضبط من شاشة التفضيلات، فلا
  /// حاجة لحقل إدخال حر هنا.
  static const List<int> _options = [15, 25, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    // Wrap لا Row: ستة خيارات لا تتسع في صف واحد على عرض 360.
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: [
        for (final option in _options)
          ChoiceChip(
            label: Text('$option'),
            selected: option == selected,
            onSelected: (_) => onSelected(option),
          ),
        // المدة المخزَّنة قد تخرج عن الخيارات الثابتة؛ تُعرض كخيار إضافي
        // بدل أن تختفي بصمت ويظهر الطالب كأنه لم يختر شيئًا.
        if (!_options.contains(selected))
          ChoiceChip(
            label: Text('$selected'),
            selected: true,
            onSelected: (_) => onSelected(selected),
          ),
      ],
    );
  }
}

class _CoursePicker extends StatelessWidget {
  const _CoursePicker({
    required this.courses,
    required this.selectedOfferingId,
    required this.onChanged,
  });

  final List<StudentCourseView> courses;
  final String? selectedOfferingId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    /*
     * المساقات المسجَّلة حاليًا وحدها.
     *
     * المصدر StudentCoursesProvider نفسه الذي تعرضه شاشة المساقات، فلا
     * منطق تحميل ثانٍ. والقاعدة تتحقق من التسجيل عند الكتابة أيضًا، فحتى
     * لو تلاعب أحد بالقائمة لن يُقبل طرح لا يملك فيه تسجيلًا.
     */
    return DropdownButtonFormField<String?>(
      initialValue: selectedOfferingId,
      isExpanded: true,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text(AppStrings.studySessionNoCourse),
        ),
        for (final course in courses)
          DropdownMenuItem<String?>(
            value: course.offeringId,
            child: Text(
              course.title.isEmpty ? course.courseCode : course.title,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.labelMedium,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
