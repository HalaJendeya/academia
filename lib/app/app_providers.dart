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
import '../features/profile/providers/email_settings_provider.dart';
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
import '../features/notifications/providers/notification_events_provider.dart';
import '../features/notifications/services/firebase_notification_event_feeds.dart';
import '../features/notifications/services/notification_event_ports.dart';
import '../core/services/auth_service.dart';
import '../features/notifications/services/notification_service.dart';


bool _isActiveAdmin(AuthProvider auth) =>
    auth.isLoggedIn && auth.isAdmin && auth.isAccountActive;

/*
 * نسخة واحدة من NotificationService يتشاركها AuthService وNotificationProvider.
 *
 * 🔴 ليست تحسينًا للأداء — بل شرط لصحة تنظيف رمز الدفع.
 *
 * NotificationProvider هو من يفتح جلسة الرمز عند الدخول، فيحتفظ باشتراك
 * onTokenRefresh وبمعرّف صاحب الجلسة داخل نسخته من الخدمة. وAuthService هو
 * من يغلق الجلسة عند الخروج. لو أخذ كلٌّ منهما نسخة خاصة، لأغلق AuthService
 * جلسةً فارغة لا اشتراك فيها، وبقي اشتراك المزوّد حيًّا بعد الخروج.
 *
 * متغيّر عام مُهيَّأ كسولًا (Dart lazy): لا يُبنى — ولا يلمس Firebase — إلا
 * عند أول قراءة لـ appProviders، وهي بعد Firebase.initializeApp في main.
 */
final NotificationService _sharedNotificationService = NotificationService();

/// نسخة AuthService واحدة: AuthProvider يملك الدخول/الخروج، وشاشة إدارة
/// البريد تحتاج العمليات نفسها على مستخدم Firebase ذاته.
final AuthService _sharedAuthService =
    AuthService(notificationService: _sharedNotificationService);

final List<SingleChildWidget> appProviders = [
  ChangeNotifierProvider(
    create: (_) => AuthProvider(
      authService: _sharedAuthService,
    ),
  ),
  ChangeNotifierProvider(create: (_) => OnboardingProvider()),

  ChangeNotifierProvider(
    create: (_) => ProfileProvider(ProfileService(), CloudinaryUploadService()),
  ),
  ChangeNotifierProvider(
    create: (_) => StudyPreferencesProvider(StudyPreferencesService()),
  ),
  ChangeNotifierProvider(create: (_) => SupportProvider(SupportService())),

  ChangeNotifierProvider(
    create: (_) => EmailSettingsProvider(_sharedAuthService, ProfileService()),
  ),

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

  notificationProviderEntry(_sharedNotificationService),
  notificationEventsProviderEntry(
    FirebaseNotificationEventFeeds(),
    const SharedPreferencesCheckpointStore(),
  ),
];

/*
 * كشف الأحداث الأكاديمية — مثل مزوّد الإشعارات، lazy: false إجباريًا.
 *
 * 🔴 لا تقرأ أي شاشة هذا المزوّد إطلاقًا: عمله كلّه في الخلفية. ومزوّدات
 * provider كسولة افتراضيًا، فبدون lazy: false لن يُبنى أبدًا ولن يُكشف
 * حدث واحد — وهو العطل نفسه الذي أصاب مزوّد الإشعارات سابقًا.
 *
 * البوّابة نفسها المستعملة هناك: مستخدم مسجَّل وحسابه فعّال.
 */
ChangeNotifierProxyProvider<AuthProvider, NotificationEventsProvider>
    notificationEventsProviderEntry(
  NotificationEventFeeds feeds,
  NotificationCheckpointStore checkpoints,
) {
  return ChangeNotifierProxyProvider<AuthProvider, NotificationEventsProvider>(
    lazy: false,
    create: (_) => NotificationEventsProvider(feeds, checkpoints),
    update: (_, auth, provider) {
      provider!.syncWithAuth(
        uid: auth.isLoggedIn && auth.isAccountActive ? auth.currentUser?.uid : null,
      );
      return provider;
    },
  );
}

/*
 * تسجيل NotificationProvider — معرَّف هنا بدالة واحدة يستعملها التطبيق
 * والاختبار معًا، حتى لا يوجد تعريفان قد ينحرف أحدهما عن الآخر.
 *
 * 🔴 lazy: false ليست تحسينًا — بدونها لا يعمل الدفع إطلاقًا.
 *
 * مزوّدات provider كسولة افتراضيًا: لا تُبنى حتى يقرأها أحد. وهذا المزوّد
 * لا يقرأه شيء في التطبيق كلّه سوى شاشة الإشعارات. فكان لا يُبنى أصلًا بعد
 * تسجيل الدخول، ولا تعمل update، ولا تصل الهوية إلى syncWithAuth، ولا
 * تبدأ جلسة رمز الدفع — فلا يُكتب fcmToken ولا تظهر ولو رسالة تشخيص
 * واحدة، لأن الشيفرة لم تُنفَّذ من الأساس. (ظهر الرمز فقط لمن فتح شاشة
 * الإشعارات، وهي اللحظة التي يُبنى فيها المزوّد.)
 *
 * الدرس: تسجيل الدفع أثر جانبي على مستوى التطبيق، وقد كان معلَّقًا بمزوّد
 * واجهة يُبنى عند الطلب. المزوّدات الأخرى المرتبطة بالمصادقة تبقى كسولة
 * عن حق — كلٌّ منها يخدم شاشة تقرأه.
 */
ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>
    notificationProviderEntry(NotificationService service) {
  return ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
    lazy: false,
    create: (_) => NotificationProvider(service),
    update: (_, auth, provider) {
      provider!.syncWithAuth(
        uid: auth.isLoggedIn && auth.isAccountActive ? auth.currentUser?.uid : null,
      );
      return provider;
    },
  );
}
