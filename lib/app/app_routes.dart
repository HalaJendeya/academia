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

  // Student courses (Phase 7S2).
  // أسماء المسارات مطابقة لما اعتمده فرع واجهة المساقات حتى لا تتغيّر
  // الروابط التي بُنيت عليها الشاشات.
  static const String courses = '/courses';
  static const String courseDetail = '/courses/detail';
  static const String coursesArchive = '/courses/archive';

  // Files feature.
  //
  // لا مسار للملفات غير المتصلة: التنزيل مؤجَّل، ومسار بلا شاشة قابلة
  // للوصول هو دَين لا ميزة.
  static const String allFiles = '/files';
  static const String filePreview = '/files/preview';

  // Student tasks (Phase 7T1B).
  static const String tasks = '/tasks';
  static const String taskDetail = '/tasks/detail';
  static const String createEditTask = '/tasks/create-edit';

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

  // Semesters (Phase 6B).
  // adminAddSemester يخدم الإنشاء والتعديل معًا: يُمرَّر SemesterModel
  // عبر arguments للتعديل ويُترك فارغًا للإنشاء.
  static const String adminSemesters = '/admin/semesters';
  static const String adminAddSemester = '/admin/semesters/add';

  // Academic structure (Phase 7D).
  // كل شاشة "add" تخدم الإنشاء والتعديل معًا: يُمرَّر النموذج عبر arguments
  // للتعديل ويُترك فارغًا للإنشاء، كما في شاشة الفصول الدراسية.
  static const String adminDepartments = '/admin/departments';
  static const String adminAddDepartment = '/admin/departments/add';
  static const String adminMajors = '/admin/majors';
  static const String adminAddMajor = '/admin/majors/add';
  static const String adminCurriculum = '/admin/curriculum';
  static const String adminCurriculumEntry = '/admin/curriculum/entry';

  // Course offerings (Phase 7E): مساق × فصل × شعبة.
  static const String adminOfferings = '/admin/offerings';
  static const String adminAddOffering = '/admin/offerings/add';
  static const String adminOfferingRoster = '/admin/offerings/roster';
}