import '../../../core/constants/notification_preference_keys.dart';

class NotificationSettings {
  final bool assignmentReminders;
  final bool lectureReminders;
  final bool studySessionReminders;
  final bool fileNotifications;
  final bool sharedSpaceNotifications;
  final bool dailySummary;
  final bool quietHoursEnabled;
  final int quietHoursStartMinutes;
  final int quietHoursEndMinutes;

  const NotificationSettings({
    required this.assignmentReminders,
    required this.lectureReminders,
    required this.studySessionReminders,
    required this.fileNotifications,
    required this.sharedSpaceNotifications,
    required this.dailySummary,
    required this.quietHoursEnabled,
    required this.quietHoursStartMinutes,
    required this.quietHoursEndMinutes,
  });

  factory NotificationSettings.defaults() {
    return const NotificationSettings(
      assignmentReminders: true,
      lectureReminders: true,
      studySessionReminders: false,
      fileNotifications: true,
      sharedSpaceNotifications: false,
      dailySummary: true,
      quietHoursEnabled: true,
      quietHoursStartMinutes: 780,
      quietHoursEndMinutes: 420,
    );
  }

  factory NotificationSettings.fromFirestore(Map<String, dynamic> data) {
    final prefs = data['notificationPreferences'] as Map? ?? const {};
    final quiet = data['quietHours'] as Map? ?? const {};

    // Helper function to extract bool safely
    bool getBool(dynamic val, bool defaultValue) {
      if (val is bool) return val;
      return defaultValue;
    }

    // Helper function to extract valid quiet hour minutes safely
    int getValidMinutes(dynamic val, int defaultValue) {
      if (val is int && val >= 0 && val <= 1439) return val;
      return defaultValue;
    }

    return NotificationSettings(
      assignmentReminders: getBool(
        prefs[NotificationPreferenceKeys.taskReminders],
        true,
      ),
      lectureReminders: getBool(
        prefs[NotificationPreferenceKeys.lectureReminders],
        true,
      ),
      studySessionReminders: getBool(
        prefs[NotificationPreferenceKeys.studySessionReminders],
        false,
      ),
      fileNotifications: getBool(
        prefs[NotificationPreferenceKeys.fileNotifications],
        true,
      ),
      sharedSpaceNotifications: getBool(
        prefs[NotificationPreferenceKeys.sharedSpaceNotifications],
        false,
      ),
      dailySummary: getBool(
        prefs[NotificationPreferenceKeys.dailySummary],
        true,
      ),
      quietHoursEnabled: getBool(quiet['enabled'], true),
      quietHoursStartMinutes: getValidMinutes(quiet['startMinutes'], 780),
      quietHoursEndMinutes: getValidMinutes(quiet['endMinutes'], 420),
    );
  }

  NotificationSettings copyWith({
    bool? assignmentReminders,
    bool? lectureReminders,
    bool? studySessionReminders,
    bool? fileNotifications,
    bool? sharedSpaceNotifications,
    bool? dailySummary,
    bool? quietHoursEnabled,
    int? quietHoursStartMinutes,
    int? quietHoursEndMinutes,
  }) {
    return NotificationSettings(
      assignmentReminders: assignmentReminders ?? this.assignmentReminders,
      lectureReminders: lectureReminders ?? this.lectureReminders,
      studySessionReminders:
          studySessionReminders ?? this.studySessionReminders,
      fileNotifications: fileNotifications ?? this.fileNotifications,
      sharedSpaceNotifications:
          sharedSpaceNotifications ?? this.sharedSpaceNotifications,
      dailySummary: dailySummary ?? this.dailySummary,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStartMinutes:
          quietHoursStartMinutes ?? this.quietHoursStartMinutes,
      quietHoursEndMinutes: quietHoursEndMinutes ?? this.quietHoursEndMinutes,
    );
  }

  Map<String, bool> toVisiblePreferenceMap() {
    return {
      NotificationPreferenceKeys.taskReminders: assignmentReminders,
      NotificationPreferenceKeys.lectureReminders: lectureReminders,
      NotificationPreferenceKeys.studySessionReminders: studySessionReminders,
      NotificationPreferenceKeys.fileNotifications: fileNotifications,
      NotificationPreferenceKeys.sharedSpaceNotifications:
          sharedSpaceNotifications,
      NotificationPreferenceKeys.dailySummary: dailySummary,
    };
  }

  Map<String, dynamic> toQuietHoursMap() {
    return {
      'enabled': quietHoursEnabled,
      'startMinutes': quietHoursStartMinutes,
      'endMinutes': quietHoursEndMinutes,
    };
  }
}
