import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../courses/models/student_course_view.dart';
import '../../courses/providers/student_courses_provider.dart';
import '../../profile/providers/study_preferences_provider.dart';
import '../models/study_session_model.dart';
import '../providers/study_session_provider.dart';
import '../widgets/session_duration_picker.dart';

/// إنشاء جلسة مذاكرة — إطار Figma‏ 96:515.
///
/// شاشة فرعية بشريط رجوع، بلا شريط تنقّل سفلي: الجلسة تُنشأ ثم يُنتقل إلى
/// المؤقّت، وليست وجهة تصفّح يعود إليها الطالب من التبويبات.
///
/// كل خيار هنا حقيقي: المساقات من تسجيلات الطالب الفعلية، والمدة الافتراضية
/// من تفضيلاته المخزَّنة. لا بيانات مثال.
class CreateStudySessionScreen extends StatefulWidget {
  const CreateStudySessionScreen({super.key});

  @override
  State<CreateStudySessionScreen> createState() =>
      _CreateStudySessionScreenState();
}

class _CreateStudySessionScreenState extends State<CreateStudySessionScreen> {
  /*
   * المتحكّمان يملكهما هذا State وحده ويُتلفان في dispose.
   *
   * نفس الدرس المستفاد من ورقة «مدة مخصّصة»: لا يُتلف متحكّم في رد نداء
   * تنقّل أو في then() لمستقبل مسار، بل عند فكّ التركيب الفعلي.
   */
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();

  String? _selectedOfferingId;
  int? _selectedMinutes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StudyPreferencesProvider>().loadPreferences();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  int _duration(StudyPreferencesProvider prefs) =>
      _selectedMinutes ?? prefs.preferences?.preferredSessionDuration ?? 45;

  Future<void> _start(List<StudentCourseView> courses, int minutes) async {
    final provider = context.read<StudySessionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // جلسة واحدة في كل مرة — يُفحص قبل أي كتابة.
    if (provider.hasActiveSession) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.studySessionAlreadyRunning)),
      );
      return;
    }

    StudentCourseView? course;
    for (final c in courses) {
      if (c.offeringId == _selectedOfferingId) course = c;
    }

    final started = await provider.startSession(
      plannedMinutes: minutes,
      offeringId: course?.offeringId,
      courseId: course?.courseId,
      sessionName: _nameController.text,
      goal: _goalController.text,
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

    // استبدال لا دفع: العودة من المؤقّت يجب أن تصل إلى المركز، لا إلى
    // نموذج إنشاء جلسة صارت جارية بالفعل.
    navigator.pushReplacementNamed(AppRoutes.activeStudySession);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<StudyPreferencesProvider>();
    final sessions = context.watch<StudySessionProvider>();
    final courses = context.watch<StudentCoursesProvider>().currentCourses;
    final minutes = _duration(prefs);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AcademiaSubAppBar(
        title: AppStrings.createSessionTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.medium,
            AppSpacing.screenHorizontal,
            AppSpacing.huge,
          ),
          children: [
            const _FocusHeroCard(),
            const SizedBox(height: AppSpacing.large),

            _label(AppStrings.selectCourseLabel),
            const SizedBox(height: AppSpacing.small),
            _CoursePicker(
              courses: courses,
              selectedOfferingId: _selectedOfferingId,
              onChanged: (v) => setState(() => _selectedOfferingId = v),
            ),
            if (courses.isEmpty) ...[
              const SizedBox(height: AppSpacing.small),
              Text(
                AppStrings.noEnrolledCoursesForSession,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.large),

            _label(AppStrings.sessionNameLabel),
            const SizedBox(height: AppSpacing.small),
            TextField(
              controller: _nameController,
              maxLength: StudySessionModel.maxSessionNameLength,
              decoration: InputDecoration(
                hintText: AppStrings.sessionNameHint,
                counterText: '',
                prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.large),

            _label(AppStrings.sessionDurationSectionLabel),
            const SizedBox(height: AppSpacing.small),
            SessionDurationPicker(
              selectedMinutes: minutes,
              onSelected: (v) => setState(() => _selectedMinutes = v),
            ),
            const SizedBox(height: AppSpacing.large),

            _label(AppStrings.sessionGoalLabel),
            const SizedBox(height: AppSpacing.small),
            TextField(
              controller: _goalController,
              maxLines: 4,
              maxLength: StudySessionModel.maxGoalLength,
              decoration: InputDecoration(
                hintText: AppStrings.sessionGoalHint,
                counterText: '',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.extraLarge),

            AppPrimaryButton(
              label: AppStrings.startNowAction,
              icon: Icons.play_arrow_rounded,
              isLoading: sessions.isStarting,
              onPressed: sessions.isStarting
                  ? null
                  : () => _start(courses, minutes),
            ),
            const SizedBox(height: AppSpacing.itemSpacing),
            AppSecondaryButton(
              label: AppStrings.cancelAction,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: AppTextStyles.labelMedium,
    textAlign: TextAlign.right,
  );
}

/// بطاقة «وقت التركيز» البرتقالية أعلى النموذج.
class _FocusHeroCard extends StatelessWidget {
  const _FocusHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFFFF9800)],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded, color: Colors.white, size: 40),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.createSessionHeroTitle,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.createSessionHeroSubtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    // المسجَّلة حاليًا وحدها. والقاعدة تتحقق من التسجيل عند الكتابة أيضًا،
    // فلا يمكن إسناد جلسة إلى طرح لا يملك فيه الطالب تسجيلًا.
    return DropdownButtonFormField<String?>(
      initialValue: selectedOfferingId,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.menu_book_outlined, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
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
