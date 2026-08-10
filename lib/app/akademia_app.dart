import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import 'app_routes.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/student_verification_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/onboarding/screens/onboarding_welcome_screen.dart';
import '../features/onboarding/screens/study_days_setup_screen.dart';
import '../features/onboarding/screens/session_duration_setup_screen.dart';
import '../features/onboarding/screens/notification_preferences_setup_screen.dart';
import '../features/onboarding/screens/setup_complete_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/notifications/screens/notification_settings_screen.dart';
import '../features/profile/screens/study_preferences_screen.dart';
import '../features/analytics/screens/analytics_screen.dart';
import '../features/profile/screens/help_faq_screen.dart';
import '../features/courses/screens/student_courses_screen.dart';
import '../features/courses/screens/student_course_detail_screen.dart';
import '../features/courses/screens/student_courses_archive_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/tasks/screens/tasks_screen.dart';
import '../features/tasks/screens/task_detail_screen.dart';
import '../features/tasks/screens/create_edit_task_screen.dart';
import '../features/admin/screens/admin_course_list_screen.dart';
import '../features/admin/screens/admin_course_form_screen.dart';
import '../features/admin/screens/admin_student_list_screen.dart';
import '../features/admin/screens/admin_student_details_screen.dart';
import '../features/admin/screens/admin_assign_courses_screen.dart';
import '../features/admin/screens/admin_shell_screen.dart';
import '../features/admin/screens/admin_course_details_screen.dart';
import '../features/admin/screens/admin_assignment_list_screen.dart';
import '../features/admin/screens/admin_assignment_form_screen.dart';
import '../features/admin/screens/admin_assignment_details_screen.dart';
import '../features/admin/screens/admin_course_files_screen.dart';
import '../features/admin/screens/admin_upload_file_screen.dart';
import '../features/admin/screens/admin_content_screen.dart';
import '../features/admin/screens/admin_announcements_screen.dart';
import '../features/admin/screens/admin_announcement_form_screen.dart';
import '../features/admin/screens/admin_reported_posts_screen.dart';
import '../features/admin/screens/admin_settings_screen.dart';
import '../features/admin/screens/admin_profile_screen.dart';
import '../features/admin/screens/admin_semester_list_screen.dart';
import '../features/admin/screens/admin_semester_form_screen.dart';
import '../features/admin/screens/admin_department_list_screen.dart';
import '../features/admin/screens/admin_department_form_screen.dart';
import '../features/admin/screens/admin_major_list_screen.dart';
import '../features/admin/screens/admin_major_form_screen.dart';
import '../features/admin/screens/admin_curriculum_screen.dart';
import '../features/admin/screens/admin_curriculum_entry_form_screen.dart';
import '../features/admin/screens/admin_offering_list_screen.dart';
import '../features/admin/screens/admin_offering_form_screen.dart';
import '../features/admin/screens/admin_offering_roster_screen.dart';
import '../features/admin/models/admin_student_model.dart';

class AkademiaApp extends StatelessWidget {
  const AkademiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'أكاديميا',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('ar'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: AppRoutes.splash,
      routes: {
        // auth Routes
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.welcome: (context) => const WelcomeScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.studentVerification: (context) =>
            const StudentVerificationScreen(),
        AppRoutes.dashboard: (context) => const DashboardScreen(),
        AppRoutes.adminDashboard: (context) => const AdminDashboardScreen(),
        AppRoutes.resetPassword: (context) => const ResetPasswordScreen(),

        // Onboarding Routes
        AppRoutes.onboardingWelcome: (context) =>
            const OnboardingWelcomeScreen(),
        AppRoutes.studyDaysSetup: (context) => const StudyDaysSetupScreen(),
        AppRoutes.sessionDurationSetup: (context) =>
            const SessionDurationSetupScreen(),
        AppRoutes.notificationPreferencesSetup: (context) =>
            const NotificationPreferencesSetupScreen(),
        AppRoutes.setupComplete: (context) => const SetupCompleteScreen(),

        //Profile Routes
        AppRoutes.profile: (context) => const ProfileScreen(),
        AppRoutes.editProfile: (context) => const EditProfileScreen(),
        AppRoutes.profileNotificationSettings: (context) =>
            const NotificationSettingsScreen(),
        AppRoutes.studyPreferences: (context) => const StudyPreferencesScreen(),
        AppRoutes.profileAnalytics: (context) => const AnalyticsScreen(),
        AppRoutes.helpSupport: (context) => const HelpFaqScreen(),

        //Courses Routes
        AppRoutes.courses: (context) => const StudentCoursesScreen(),
        AppRoutes.courseDetail: (context) => const StudentCourseDetailScreen(),
        AppRoutes.coursesArchive: (context) =>
            const StudentCoursesArchiveScreen(),

        //Student Tasks Routes
        AppRoutes.tasks: (context) => const TasksScreen(),
        AppRoutes.taskDetail: (context) => const TaskDetailScreen(),
        AppRoutes.createEditTask: (context) => const CreateEditTaskScreen(),

        //admin Routes
        AppRoutes.adminCourses: (context) => const AdminCourseListScreen(),
        AppRoutes.adminAddCourse: (context) => const AdminCourseFormScreen(),
        AppRoutes.adminEditCourse: (context) => const AdminCourseFormScreen(),
        AppRoutes.adminStudents: (context) => const AdminStudentListScreen(),
        AppRoutes.adminStudentDetails: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;

          if (arguments is! AdminStudentModel) {
            return Scaffold(
              appBar: AppBar(title: const Text('تفاصيل الطالب')),
              body: const Center(child: Text('تعذر تحميل بيانات الطالب.')),
            );
          }

          return AdminStudentDetailsScreen(student: arguments);
        },
        AppRoutes.adminAssignCourses: (context) =>
            const AdminAssignCoursesScreen(),
        AppRoutes.adminShell: (context) => const AdminShellScreen(),
        AppRoutes.adminCourseDetails: (context) =>
            const AdminCourseDetailsScreen(),
        AppRoutes.adminAssignments: (context) =>
            const AdminAssignmentListScreen(),
        AppRoutes.adminAddAssignment: (context) =>
            const AdminAssignmentFormScreen(),
        AppRoutes.adminAssignmentDetails: (context) =>
            const AdminAssignmentDetailsScreen(),
        AppRoutes.adminCourseFiles: (context) => const AdminCourseFilesScreen(),
        AppRoutes.adminUploadFile: (context) => const AdminUploadFileScreen(),
        AppRoutes.adminContent: (context) => const AdminContentScreen(),
        AppRoutes.adminAnnouncements: (context) =>
            const AdminAnnouncementsScreen(),
        AppRoutes.adminAddAnnouncement: (context) =>
            const AdminAnnouncementFormScreen(),
        AppRoutes.adminReportedPosts: (context) =>
            const AdminReportedPostsScreen(),
        AppRoutes.adminSettings: (context) => const AdminSettingsScreen(),
        AppRoutes.adminProfile: (context) => const AdminProfileScreen(),
        AppRoutes.adminSemesters: (context) => const AdminSemesterListScreen(),
        AppRoutes.adminAddSemester: (context) =>
            const AdminSemesterFormScreen(),
        AppRoutes.adminDepartments: (context) =>
            const AdminDepartmentListScreen(),
        AppRoutes.adminAddDepartment: (context) =>
            const AdminDepartmentFormScreen(),
        AppRoutes.adminMajors: (context) => const AdminMajorListScreen(),
        AppRoutes.adminAddMajor: (context) => const AdminMajorFormScreen(),
        AppRoutes.adminCurriculum: (context) => const AdminCurriculumScreen(),
        AppRoutes.adminCurriculumEntry: (context) =>
            const AdminCurriculumEntryFormScreen(),
        AppRoutes.adminOfferings: (context) => const AdminOfferingListScreen(),
        AppRoutes.adminAddOffering: (context) =>
            const AdminOfferingFormScreen(),
        AppRoutes.adminOfferingRoster: (context) =>
            const AdminOfferingRosterScreen(),
      },
    );
  }
}
