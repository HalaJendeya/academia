import '../../../core/constants/app_strings.dart';

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
      studyDays: [
        AppStrings.sunday,
        AppStrings.monday,
        AppStrings.tuesday,
        AppStrings.wednesday,
        AppStrings.thursday,
      ],
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
        'taskReminders': taskReminders,
        'studySessionReminders': studySessionReminders,
        'deadlineReminders': deadlineReminders,
        'dailySummary': dailySummary,
        'courseNotifications': courseNotifications,
      },
    };
  }
}
