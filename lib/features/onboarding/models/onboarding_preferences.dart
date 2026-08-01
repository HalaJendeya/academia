import '../../../core/constants/notification_preference_keys.dart';
import '../../../core/constants/study_day_constants.dart';

class OnboardingPreferences {
  final List<String> studyDays;
  final int preferredSessionDuration;
  final bool taskReminders;
  final bool studySessionReminders;
  final bool deadlineReminders;
  final bool dailySummary;
  final bool courseNotifications;

  const OnboardingPreferences({
    required this.studyDays,
    required this.preferredSessionDuration,
    required this.taskReminders,
    required this.studySessionReminders,
    required this.deadlineReminders,
    required this.dailySummary,
    required this.courseNotifications,
  });

  factory OnboardingPreferences.defaults() {
    return OnboardingPreferences(
      studyDays: StudyDayConstants.defaultStudyDays,
      preferredSessionDuration: 45,
      taskReminders: true,
      studySessionReminders: true,
      deadlineReminders: true,
      dailySummary: false,
      courseNotifications: true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studyDays': studyDays,
      'preferredSessionDuration': preferredSessionDuration,
      'notificationPreferences': {
        NotificationPreferenceKeys.taskReminders: taskReminders,
        NotificationPreferenceKeys.studySessionReminders: studySessionReminders,
        NotificationPreferenceKeys.deadlineReminders: deadlineReminders,
        NotificationPreferenceKeys.dailySummary: dailySummary,
        NotificationPreferenceKeys.courseNotifications: courseNotifications,
      },
    };
  }
}
