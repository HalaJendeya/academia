abstract final class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String studentVerification = '/student-verification';
  static const String dashboard = '/dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String resetPassword = '/reset-password';
  static const String onboardingWelcome = '/onboarding-welcome';
  static const String studyDaysSetup = '/study-days-setup';
  static const String sessionDurationSetup = '/session-duration-setup';
  static const String notificationPreferencesSetup =
      '/notification-preferences-setup';
  static const String setupComplete = '/setup-complete';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String profileNotificationSettings =
      '/profile/notification-settings';
  static const String studyPreferences = '/profile/study-preferences';
  static const String profileAnalytics = '/profile/analytics';
  static const String helpSupport = '/profile/help-support';

  static const String adminCourses = '/admin/courses';
  static const String adminAddCourse = '/admin/courses/add';
  static const String adminEditCourse = '/admin/courses/edit';

  static const String adminStudents = '/admin/students';
  static const String adminStudentDetails = '/admin/students/details';
  static const String adminAssignCourses = '/admin/students/assign-courses';

  static const String adminShell = '/admin/shell';
  static const String adminCourseDetails = '/admin/courses/details';
  static const String adminAssignments = '/admin/assignments';
  static const String adminAddAssignment = '/admin/assignments/add';
  static const String adminAssignmentDetails = '/admin/assignments/details';
  static const String adminCourseFiles = '/admin/files';
  static const String adminUploadFile = '/admin/files/upload';
  static const String adminContent = '/admin/content';
  static const String adminAnnouncements = '/admin/announcements';
  static const String adminAddAnnouncement = '/admin/announcements/add';
  static const String adminReportedPosts = '/admin/reported-posts';
  static const String adminSettings = '/admin/settings';
  static const String adminProfile = '/admin/profile';
}
