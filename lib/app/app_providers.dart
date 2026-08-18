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
import '../features/admin/providers/admin_teacher_provider.dart';
import '../features/admin/services/admin_teacher_service.dart';
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
import '../features/tasks/providers/task_provider.dart';
import '../features/tasks/services/task_service.dart';

/// مشرف نشط ومسجَّل الدخول فعلًا.
///
/// شرط واحد لكل المزوّدات الإدارية: أي شيء دون ذلك — خروج، أو حساب طالب،
/// أو حساب غير نشط — يعني إيقاف الاستماع.
bool _isActiveAdmin(AuthProvider auth) =>
    auth.isLoggedIn && auth.isAdmin && auth.isAccountActive;

final List<SingleChildWidget> appProviders = [
  ChangeNotifierProvider(create: (_) => AuthProvider()),
  ChangeNotifierProvider(create: (_) => OnboardingProvider()),
  /*
   * الملف الشخصي يرفع الصورة إلى Cloudinary نفسها التي ترفع إليها ملفات
   * المساقات، ويكتب الرابط في مستند المستخدم — لا تخزين ثانٍ ولا مجموعة
   * جديدة.
   */
  ChangeNotifierProvider(
    create: (_) => ProfileProvider(ProfileService(), CloudinaryUploadService()),
  ),
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
  /*
   * كل مزوّد إداري يستمع إلى Firestore مربوط بـ AuthProvider.
   *
   * هذه المزوّدات مركَّبة عالميًا فوق MaterialApp، فلا يُستدعى dispose
   * أثناء عمل التطبيق. قبل هذا الربط كان الاستماع إلى courses و users و
   * departments يبقى حيًّا بعد تسجيل الخروج، فتعيد القواعد المشدَّدة تقييمه
   * بلا مصادقة وتظهر PERMISSION_DENIED متكررة. الحل إيقاف المستمع لا
   * إضعاف القاعدة.
   */
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
  /*
   * حسابات المعلّمين: استعلام قائمة على users مسموح للمشرف وحده، فيتبع
   * الشرط الإداري نفسه ويتوقف عند الخروج أو تبديل الحساب.
   */
  ChangeNotifierProxyProvider<AuthProvider, AdminTeacherProvider>(
    create: (_) =>
        AdminTeacherProvider(AdminTeacherService(), CourseOfferingService()),
    update: (_, auth, provider) =>
        provider!..syncWithAuth(isActiveAdmin: _isActiveAdmin(auth)),
  ),
  /*
   * السجل الأكاديمي لطالب واحد في شاشة المشرف، منفصل عن EnrollmentProvider:
   * ذاك يشارك errorMessage بين القراءة والكتابة، فيكفي فشل إسناد مساق حتى
   * تعرض قائمة السجل خطأً رغم نجاح تحميلها.
   */
  /*
   * ملفات المساقات: البيانات الوصفية في Firestore والملف الثنائي في
   * Cloudinary. المزوّد يجمع الخدمتين ليضمن الترتيب — الرفع أولًا، ثم
   * كتابة البيانات الوصفية — فلا يوجد مستند يشير إلى ملف غير مرفوع.
   */
  /*
   * ملفات المساقات يخدم الدورين: المشرف يرفع ويدير، والطالب يقرأ ملفات
   * الطروح المسجَّل فيها. لذلك شرطه "مستخدم نشط" لا "مشرف" — وإلا لأفرغنا
   * ملفات الطالب فور تحميلها.
   */
  ChangeNotifierProxyProvider<AuthProvider, CourseFileProvider>(
    create: (_) =>
        CourseFileProvider(CourseFileService(), CloudinaryUploadService()),
    update: (_, auth, provider) => provider!
      ..syncWithAuth(isActiveUser: auth.isLoggedIn && auth.isAccountActive),
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
  /*
   * واجهة عمل المعلّم.
   *
   * الشرط "معلّم نشط" لا "مسجَّل دخول": الطالب والمشرف حسابان صالحان،
   * وتمرير معرّف أيٍّ منهما هنا يفتح استعلام courseOfferings حيث teacherId
   * يساويه — استعلام لا يعيد شيئًا في أحسن الأحوال، ومستمع لا مبرر له في
   * كل الأحوال. تمرير null يوقف كل شيء ويمسح الحالة.
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
  ChangeNotifierProxyProvider2<AuthProvider, StudentCoursesProvider, TaskProvider>(
    create: (_) => TaskProvider(TaskService()),
    update: (_, auth, studentCourses, taskProvider) {
      /*
       * المهام الشخصية ميزة طالب وحده.
       *
       * الشرط هنا "طالب نشط" لا "مسجَّل دخول": المعلّم والمشرف حسابان
       * صالحان بمعرّفات حقيقية، وبدون هذا القيد يفتح المزوّد استماعًا إلى
       * tasks لهما — وهو استماع ترفضه القواعد بحق وينتج PERMISSION_DENIED.
       */
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
];
