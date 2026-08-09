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
import '../features/enrollments/providers/enrollment_provider.dart';
import '../features/enrollments/services/enrollment_service.dart';
import '../features/semesters/providers/semester_provider.dart';
import '../features/semesters/services/semester_service.dart';
import '../features/tasks/providers/task_provider.dart';
import '../features/tasks/services/task_service.dart';

final List<SingleChildWidget> appProviders = [
  ChangeNotifierProvider(create: (_) => AuthProvider()),
  ChangeNotifierProvider(create: (_) => OnboardingProvider()),
  ChangeNotifierProvider(create: (_) => ProfileProvider(ProfileService())),
  ChangeNotifierProvider(
    create: (_) => StudyPreferencesProvider(StudyPreferencesService()),
  ),
  ChangeNotifierProvider(create: (_) => SupportProvider(SupportService())),
  ChangeNotifierProvider(
    create: (_) => NotificationSettingsProvider(NotificationSettingsService()),
  ),
  /*
   * ترتيب مزوّدات المجال الأكاديمي يتبع اتجاه الاعتماد في العرض:
   * الفصول الدراسية ثم الهيكل الأكاديمي (الأقسام والتخصصات) ثم كتالوج
   * المساقات، فالطروحات التي تربط مساقًا بفصل، فالخطة الدراسية، ثم
   * التسجيلات التي تشير إلى طرح.
   */
  ChangeNotifierProvider(create: (_) => SemesterProvider(SemesterService())),
  ChangeNotifierProvider(
    create: (_) =>
        AcademicStructureProvider(DepartmentService(), MajorService()),
  ),
  ChangeNotifierProvider(create: (_) => CourseProvider(CourseService())),
  ChangeNotifierProvider(
    create: (_) => CourseOfferingProvider(CourseOfferingService()),
  ),
  ChangeNotifierProvider(create: (_) => CurriculumProvider(CurriculumService())),
  ChangeNotifierProvider(
    create: (_) => EnrollmentProvider(EnrollmentService()),
  ),
  /*
   * السجل الأكاديمي لطالب واحد في شاشة المشرف، منفصل عن EnrollmentProvider:
   * ذاك يشارك errorMessage بين القراءة والكتابة، فيكفي فشل إسناد مساق حتى
   * تعرض قائمة السجل خطأً رغم نجاح تحميلها.
   */
  ChangeNotifierProvider(
    create: (_) => AdminStudentRecordProvider(
      EnrollmentService(),
      CourseOfferingService(),
      CourseService(),
      SemesterService(),
      MajorService(),
    ),
  ),
  /*
   * واجهة مساقات الطالب تتبع الحساب المسجَّل تلقائيًا.
   *
   * ProxyProvider لا مجرد ChangeNotifierProvider: majorId و academicLevel
   * يخصان الطالب لا الشاشة، فلو انتظرنا أن تمرّرهما الشاشة لأمكن أن تعرض
   * شاشةٌ خطةَ تخصص لا ينتمي إليه الطالب. الربط هنا يجعل تسجيل الخروج
   * وتبديل الحساب يمسحان البيانات دون أن تتذكّر أي شاشة ذلك.
   */
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
  ChangeNotifierProxyProvider2<AuthProvider, StudentCoursesProvider, TaskProvider>(
    create: (_) => TaskProvider(TaskService()),
    update: (_, auth, studentCourses, taskProvider) {
      taskProvider!.syncWithUserAndCourses(
        userId: auth.currentUser?.uid,
        isLoggedIn: auth.isLoggedIn,
        currentCourses: studentCourses.currentCourses,
      );
      return taskProvider;
    },
  ),
];
