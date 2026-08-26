import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../analytics/models/study_duration_format.dart';
import '../../courses/providers/student_courses_provider.dart';
import '../models/study_history_summary.dart';
import '../models/study_week.dart';
import '../providers/study_session_provider.dart';
import '../widgets/study_session_card.dart';

/// سجل الجلسات — إطار Figma‏ 96:608.
///
/// 🔴 لا مستمع جديد هنا. [StudySessionProvider] يحمل كل جلسات الطالب أصلًا
/// (الاستعلام غير محدود بعدد)، فالسجل تصفية في الذاكرة لا قراءة ثانية من
/// Firestore.
///
/// الملخّص أعلى الشاشة يتبع التصفية المختارة: عرض مجموع العمر فوق قائمة
/// مقصورة على الأسبوع كان سيجعل الطالب ينسب الرقم إلى الأسبوع.
class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  StudyHistoryRange _range = StudyHistoryRange.all;
  String? _courseId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudySessionProvider>();
    final courses = context.watch<StudentCoursesProvider>();

    final summary = StudyHistorySummary.from(
      sessions: provider.sessions,
      range: _range,
      courseId: _courseId,
    );

    final courseIds = StudyHistorySummary.courseIdsIn(provider.sessions);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AcademiaSubAppBar(
        title: AppStrings.sessionHistoryTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(child: _buildBody(provider, summary, courses, courseIds)),
    );
  }

  Widget _buildBody(
    StudySessionProvider provider,
    StudyHistorySummary summary,
    StudentCoursesProvider courses,
    List<String> courseIds,
  ) {
    // التحميل يظهر فقط ولا شيء بعد ليُعرض؛ السجل الفارغ ليس انتظارًا.
    if (provider.isLoading && provider.sessions.isEmpty) {
      return const AppLoadingState();
    }
    if (provider.errorMessage != null && provider.sessions.isEmpty) {
      return AppErrorState(message: provider.errorMessage!);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.medium,
        AppSpacing.screenHorizontal,
        AppSpacing.huge,
      ),
      children: [
        _SummaryHeader(summary: summary),
        const SizedBox(height: AppSpacing.large),

        _RangeFilters(
          range: _range,
          onChanged: (r) => setState(() => _range = r),
        ),
        if (courseIds.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.small),
          _CourseFilter(
            courseIds: courseIds,
            selected: _courseId,
            courses: courses,
            onChanged: (id) => setState(() => _courseId = id),
          ),
        ],
        const SizedBox(height: AppSpacing.large),

        Text(
          AppStrings.recentSessionsHeading,
          style: AppTextStyles.sectionTitle,
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: AppSpacing.itemSpacing),

        if (summary.isEmpty)
          AppEmptyState(
            title: provider.finishedSessions.isEmpty
                ? AppStrings.noStudySessionsTitle
                : AppStrings.historyEmptyForFilter,
            description: provider.finishedSessions.isEmpty
                ? AppStrings.noStudySessionsDesc
                : null,
            icon: Icons.history_rounded,
          )
        else
          for (final session in summary.sessions) ...[
            StudySessionCard(
              session: session,
              courseTitle: _titleFor(session.courseId, courses),
            ),
            if (session != summary.sessions.last)
              const SizedBox(height: AppSpacing.itemSpacing),
          ],
      ],
    );
  }

  String? _titleFor(String? courseId, StudentCoursesProvider courses) {
    if (courseId == null) return null;
    for (final course in courses.currentCourses) {
      if (course.courseId == courseId) {
        return course.title.isEmpty ? course.courseCode : course.title;
      }
    }
    return null;
  }
}

/// بطاقات الملخّص، محسوبة على النطاق المختار.
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.summary});

  final StudyHistorySummary summary;

  @override
  Widget build(BuildContext context) {
    final bestDay = ArabicWeekday.name(summary.bestWeekday);

    return Column(
      children: [
        AppCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.itemSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.totalStudyTimeLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      StudyDurationFormat.format(summary.totalMinutes),
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.itemSpacing),
        // Wrap لا Row: بطاقتان جنبًا إلى جنب تضيقان كثيرًا على 360.
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: AppStrings.sessionsCountLabel,
                value:
                    '${summary.completedSessions} '
                    '${AppStrings.sessionsCountUnit}',
              ),
            ),
            const SizedBox(width: AppSpacing.itemSpacing),
            Expanded(
              child: _MiniStat(
                label: AppStrings.bestDayLabel,
                // لا يوم أفضل بلا دقائق تُقارَن — تُعرض شرطة لا يوم مخترع.
                value: bestDay ?? '—',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RangeFilters extends StatelessWidget {
  const _RangeFilters({required this.range, required this.onChanged});

  final StudyHistoryRange range;
  final ValueChanged<StudyHistoryRange> onChanged;

  static const _labels = {
    StudyHistoryRange.all: AppStrings.filterAll,
    StudyHistoryRange.week: AppStrings.filterWeek,
    StudyHistoryRange.month: AppStrings.filterMonth,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: [
        for (final entry in _labels.entries)
          ChoiceChip(
            label: Text(entry.value),
            selected: entry.key == range,
            onSelected: (_) => onChanged(entry.key),
            selectedColor: AppColors.primary,
            labelStyle: AppTextStyles.labelMedium.copyWith(
              color: entry.key == range ? Colors.white : AppColors.textSecondary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
      ],
    );
  }
}

/// تصفية المساق — تُبنى من المساقات التي لها جلسات فعلًا.
class _CourseFilter extends StatelessWidget {
  const _CourseFilter({
    required this.courseIds,
    required this.selected,
    required this.courses,
    required this.onChanged,
  });

  final List<String> courseIds;
  final String? selected;
  final StudentCoursesProvider courses;
  final ValueChanged<String?> onChanged;

  String _title(String courseId) {
    for (final course in courses.currentCourses) {
      if (course.courseId == courseId) {
        return course.title.isEmpty ? course.courseCode : course.title;
      }
    }
    return AppStrings.studyGeneralSession;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.filter_alt_outlined, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.itemSpacing,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text(AppStrings.filterByCourse),
        ),
        for (final id in courseIds)
          DropdownMenuItem<String?>(
            value: id,
            child: Text(_title(id), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
