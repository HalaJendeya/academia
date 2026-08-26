import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/onboarding/providers/onboarding_provider.dart';
import '../features/profile/providers/profile_provider.dart';
import '../features/profile/services/profile_service.dart';
import '../features/profile/providers/study_preferences_provider.dart';
import '../features/profile/services/study_preferences_service.dart';
import '../features/profile/providers/support_provider.dart';
import '../features/profile/services/support_service.dart';
import '../features/notifications/providers/notification_settings_provider.dart';
import '../features/notifications/services/notification_settings_service.dart';
import '../features/assignments/providers/assignment_progress_provider.dart';
import '../features/assignments/providers/course_assignment_provider.dart';
import '../features/assignments/services/assignment_progress_service.dart';
import '../features/assignments/services/course_assignment_service.dart';
import '../features/admin/providers/admin_teacher_provider.dart';
import '../features/admin/services/admin_teacher_service.dart';
import '../features/admin/providers/admin_support_provider.dart';
import '../features/admin/providers/admin_user_provider.dart';
import '../features/admin/services/admin_user_service.dart';
import '../features/academics/providers/academic_structure_provider.dart';
import '../features/academics/services/department_service.dart';
import '../features/academics/services/major_service.dart';
import '../features/courses/providers/course_provider.dart';
import '../features/courses/providers/course_offering_provider.dart';
import '../features/courses/providers/student_courses_provider.dart';
import '../features/courses/services/course_service.dart';
import '../features/courses/services/course_offering_service.dart';
import '../features/curriculum/providers/curriculum_provider.dart';
import '../features/curriculum/services/curriculum_service.dart';
import '../features/enrollments/providers/admin_student_record_provider.dart';
import '../features/files/providers/course_file_provider.dart';
import '../features/files/services/cloudinary_upload_service.dart';
import '../features/files/services/course_file_service.dart';
import '../features/enrollments/providers/enrollment_provider.dart';
import '../features/enrollments/services/enrollment_service.dart';
import '../features/semesters/providers/semester_provider.dart';
import '../features/semesters/services/semester_service.dart';
import '../features/teacher/providers/teacher_offerings_provider.dart';
import '../features/study/providers/study_session_provider.dart';
import '../features/study/services/study_session_service.dart';
import '../features/tasks/providers/task_provider.dart';
import '../features/tasks/services/task_service.dart';
import '../features/shared_space/providers/post_provider.dart';
import '../features/shared_space/services/post_service.dart';
import '../features/admin/providers/admin_post_reports_provider.dart';
import '../features/notifications/providers/notification_provider.dart';
import '../features/notifications/services/notification_service.dart';


bool _isActiveAdmin(AuthProvider auth) =>
    auth.isLoggedIn && auth.isAdmin && auth.isAccountActive;

final List<SingleChildWidget> appProviders = [
  ChangeNotifierProvider(create: (_) => AuthProvider()),
  ChangeNotifierProvider(create: (_) => OnboardingProvider()),

  ChangeNotifierProvider(
    create: (_) => ProfileProvider(ProfileService(), CloudinaryUploadService()),
  ),
  ChangeNotifierProvider(
    create: (_) => StudyPreferencesProvider(StudyPreferencesService()),
  ),
  ChangeNotifierProvider(create: (_) => SupportProvider(SupportService())),

  ChangeNotifierProxyProvider<AuthProvider, AdminSupportProvider>(
    create: (_) => AdminSupportProvider(SupportService()),
    update: (_, auth, provider) =>
        provider!..syncWithAuth(isActiveAdmin: _isActiveAdmin(auth)),
  ),

  ChangeNotifierProvider(
    create: (_) => AdminUserProvider(AdminUserService()),
  ),

  ChangeNotifierProvider(
    create: (_) => NotificationSettingsProvider(NotificationSettingsService()),
  ),

  ChangeNotifierProxyProvider<AuthProvider, SemesterProvider>(
    create: (_) => SemesterProvider(SemesterService()),
    update: (_, auth, provider) =>
        provider!..syncWithAuth(isActiveAdmin: _isActiveAdmin(auth)),
  ),

  ChangeNotifierProxyProvider<AuthProvider, AcademicStructureProvider>(
    create: (_) =>
        AcademicStructureProvider(DepartmentService(), MajorService()),
    update: (_, auth, provider) =>
        provider!..syncWithAuth(isActiveAdmin: _isActiveAdmin(auth)),
  ),

  ChangeNotifierProxyProvider<AuthProvider, CourseProvider>(
    create: (_) => CourseProvider(CourseService()),
    update: (_, auth, provider) =>
        provider!..syncWithAuth(isActiveAdmin: _isActiveAdmin(auth)),
  ),

  ChangeNotifierProxyProvider<AuthProvider, CourseOfferingProvider>(
    create: (_) => CourseOfferingProvider(CourseOfferingService()),
    update: (_, auth, provider) =>
        provider!..syncWithAuth(isActiveAdmin: _isActiveAdmin(auth)),
  ),

  ChangeNotifierProxyProvider<AuthProvider, CurriculumProvider>(
    create: (_) => CurriculumProvider(CurriculumService()),
    update: (_, auth, provider) =>
        provider!..syncWithAuth(isActiveAdmin: _isActiveAdmin(auth)),
  ),

  ChangeNotifierProxyProvider<AuthProvider, EnrollmentProvider>(
    create: (_) => EnrollmentProvider(EnrollmentService()),
    update: (_, auth, provider) =>
        provider!..syncWithAuth(isActiveAdmin: _isActiveAdmin(auth)),
  ),

  ChangeNotifierProxyProvider<AuthProvider, AdminTeacherProvider>(
    create: (_) =>
        AdminTeacherProvider(AdminTeacherService(), CourseOfferingService()),
    update: (_, auth, provider) =>
        provider!..syncWithAuth(isActiveAdmin: _isActiveAdmin(auth)),
  ),
  ChangeNotifierProxyProvider<AuthProvider, CourseFileProvider>(
    create: (_) =>
        CourseFileProvider(CourseFileService(), CloudinaryUploadService()),
    update: (_, auth, provider) => provider!
      ..syncWithAuth(
        isActiveUser: auth.isLoggedIn && auth.isAccountActive,
        role: auth.currentUserProfile?.role.name,
      ),
  ),

  ChangeNotifierProvider(
    create: (_) => AdminStudentRecordProvider(
      EnrollmentService(),
      CourseOfferingService(),
      CourseService(),
      SemesterService(),
      MajorService(),
    ),
  ),

  ChangeNotifierProxyProvider<AuthProvider, StudentCoursesProvider>(
    create: (_) => StudentCoursesProvider(
      SemesterService(),
      CurriculumService(),
      CourseService(),
      CourseOfferingService(),
      EnrollmentService(),
      MajorService(),
    ),
    update: (_, auth, studentCourses) {
      studentCourses!.syncWithUser(
        auth.currentUserProfile,
        isLoggedIn: auth.isLoggedIn,
      );
      return studentCourses;
    },
  ),
  /*
   * واجهة عمل المعلّم.
   */
  ChangeNotifierProxyProvider<AuthProvider, TeacherOfferingsProvider>(
    create: (_) => TeacherOfferingsProvider(
      CourseOfferingService(),
      CourseService(),
      SemesterService(),
      EnrollmentService(),
    ),
    update: (_, auth, provider) => provider!
      ..syncWithAuth(
        teacherUid: auth.isLoggedIn && auth.isTeacher && auth.isAccountActive
            ? auth.currentUser?.uid
            : null,
      ),
  ),

  ChangeNotifierProxyProvider2<AuthProvider, StudentCoursesProvider,
      CourseAssignmentProvider>(
    create: (_) => CourseAssignmentProvider(CourseAssignmentService()),
    update: (_, auth, studentCourses, provider) {
      provider!.syncWithAuth(
        isActiveUser: auth.isLoggedIn && auth.isAccountActive,
        role: auth.currentUserProfile?.role.name,
      );

      final isActiveStudent =
          auth.isLoggedIn && auth.isStudent && auth.isAccountActive;


      provider.syncStudentOfferings(
        isActiveStudent
            ? [
                for (final view in studentCourses.currentCourses)
                  view.offeringId,
              ]
            : null,
      );
      return provider;
    },
  ),

  ChangeNotifierProxyProvider<AuthProvider, AssignmentProgressProvider>(
    create: (_) => AssignmentProgressProvider(AssignmentProgressService()),
    update: (_, auth, provider) => provider!
      ..syncWithUser(

        studentId: auth.isLoggedIn && auth.isStudent && auth.isAccountActive
            ? auth.currentUserProfile?.uid
            : null,
      ),
  ),

  ChangeNotifierProxyProvider<AuthProvider, StudySessionProvider>(
    create: (_) => StudySessionProvider(StudySessionService()),
    update: (_, auth, provider) => provider!
      ..syncWithUser(
        studentId: auth.isLoggedIn && auth.isStudent && auth.isAccountActive
            ? auth.currentUserProfile?.uid
            : null,
      ),
  ),
  ChangeNotifierProxyProvider2<AuthProvider, StudentCoursesProvider, TaskProvider>(
    create: (_) => TaskProvider(TaskService()),
    update: (_, auth, studentCourses, taskProvider) {

      final isActiveStudent =
          auth.isLoggedIn && auth.isStudent && auth.isAccountActive;

      taskProvider!.syncWithUserAndCourses(
        userId: isActiveStudent ? auth.currentUser?.uid : null,
        isLoggedIn: isActiveStudent,
        currentCourses: studentCourses.currentCourses,
      );
      return taskProvider;
    },
  ),
  ChangeNotifierProvider(create: (_) => PostProvider(PostService())),

  ChangeNotifierProvider(
    create: (_) => AdminPostReportsProvider(PostService()),
  ),

  ChangeNotifierProvider(
    create: (_) => NotificationProvider(NotificationService()),
  ),
];
