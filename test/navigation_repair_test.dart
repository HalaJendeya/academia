import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/academics/providers/academic_structure_provider.dart';
import 'package:academia/features/admin/models/admin_student_model.dart';
import 'package:academia/features/admin/screens/admin_course_details_screen.dart';
import 'package:academia/features/admin/screens/admin_dashboard_screen.dart';
import 'package:academia/features/admin/widgets/admin_stat_card.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/courses/providers/course_provider.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/courses/screens/student_courses_screen.dart';
import 'package:academia/features/dashboard/screens/dashboard_screen.dart';
import 'package:academia/features/enrollments/providers/enrollment_provider.dart';
import 'package:academia/features/files/providers/course_file_provider.dart';
import 'package:academia/features/semesters/models/semester_model.dart';
import 'package:academia/features/academics/models/major_model.dart';
import 'package:academia/features/tasks/models/task_model.dart';
import 'package:academia/features/tasks/providers/task_provider.dart';

// --------------------------------------------------------------- fixtures

const _course = CourseModel(
  id: 'course_bmis3344',
  courseCode: 'BMIS3344',
  title: 'تحليل وتصميم النظم',
  description: '',
  creditHours: 3,
  departmentId: 'dept_it',
  status: 'active',
);

const _adminUser = AppUserModel(
  uid: 'admin1',
  fullName: 'Admin',
  email: 'admin@test.com',
  role: UserRole.admin,
  status: 'active',
  emailVerified: true,
  onboardingCompleted: true,
  onboardingStatus: 'completed',
);

const _studentUser = AppUserModel(
  uid: 'student1',
  fullName: 'حلا جندية',
  email: 's@test.com',
  role: UserRole.student,
  status: 'active',
  emailVerified: true,
  onboardingCompleted: true,
  onboardingStatus: 'completed',
  academicLevel: 4,
);

// ------------------------------------------------------------------ fakes

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  FakeAuthProvider({required this.user});

  final AppUserModel user;

  @override
  bool get isLoggedIn => true;

  @override
  bool get isAdmin => user.isAdmin;

  @override
  AppUserModel? get currentUserProfile => user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCourseProvider extends ChangeNotifier implements CourseProvider {
  int listenCallCount = 0;

  @override
  List<CourseModel> get courses => const [_course];

  @override
  void listenToCourses() => listenCallCount++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeEnrollmentProvider extends ChangeNotifier
    implements EnrollmentProvider {
  @override
  List<AdminStudentModel> get students => const [];

  @override
  void listenToStudents() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records that the dashboard asked for a real count instead of printing one.
class FakeCourseFileProvider extends ChangeNotifier
    implements CourseFileProvider {
  FakeCourseFileProvider({this.countValue});

  int? countValue;
  int loadCountCallCount = 0;

  @override
  int? get activeFileCount => countValue;

  @override
  bool get isLoadingActiveFileCount => false;

  @override
  Future<void> loadActiveFileCount() async {
    loadCountCallCount++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTaskProvider extends ChangeNotifier implements TaskProvider {
  @override
  List<TaskModel> get tasks => const [];

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAcademicStructureProvider extends ChangeNotifier
    implements AcademicStructureProvider {
  @override
  String departmentNameFor(String? departmentId) => 'تكنولوجيا المعلومات';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStudentCoursesProvider extends ChangeNotifier
    implements StudentCoursesProvider {
  @override
  bool get isLoading => false;

  @override
  bool get hasLoaded => true;

  @override
  String? get errorMessage => null;

  @override
  bool get hasMajor => true;

  @override
  bool get hasCurrentSemester => true;

  @override
  MajorModel? get major => const MajorModel(
    id: 'major_bmis',
    name: 'نظم المعلومات',
    code: 'BMIS',
    departmentId: 'dept_it',
    totalLevels: 8,
    status: MajorModel.statusActive,
  );

  @override
  String get majorName => 'نظم المعلومات';

  @override
  SemesterModel? get currentSemester => const SemesterModel(
    id: 'semester_2026_1',
    academicYear: '2026',
    semesterNumber: 1,
    semesterName: 'الفصل الأول 2026',
    status: SemesterModel.statusCurrent,
  );

  @override
  List<StudentCourseView> get currentCourses => const [];

  @override
  List<StudentAvailableCourseView> get availableNow => const [];

  @override
  List<StudentCourseView> get history => const [];

  @override
  List<StudentProgramEntryView> get recommendedForMyLevel => const [];

  @override
  List<int> get programLevels => const [];

  @override
  int get programTotalCreditHours => 134;

  @override
  int get recommendedCreditHours => 0;

  @override
  int? get academicLevel => 4;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ------------------------------------------------------------- navigation

/// Records every named push so a test can assert both the route and the
/// arguments it was given.
class RouteRecorder extends NavigatorObserver {
  final List<String?> pushedRoutes = <String?>[];
  final List<Object?> pushedArguments = <Object?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route.settings.name);
    pushedArguments.add(route.settings.arguments);
    super.didPush(route, previousRoute);
  }
}

/// A stand-in for every destination, so a push is observable without
/// building the real screen (which would need its own providers).
Widget _stubDestination(String label) =>
    Scaffold(body: Center(child: Text('STUB:$label')));

Widget _wrap({
  required Widget home,
  required List<SingleChildWidget> providers,
  required RouteRecorder recorder,
  Object? homeArguments,
}) {
  return MultiProvider(
    providers: providers,
    child: MaterialApp(
      locale: const Locale('ar'),
      navigatorObservers: [recorder],
      onGenerateRoute: (settings) {
        if (settings.name == Navigator.defaultRouteName) {
          return MaterialPageRoute(
            settings: RouteSettings(
              name: Navigator.defaultRouteName,
              arguments: homeArguments,
            ),
            builder: (_) =>
                Directionality(textDirection: TextDirection.rtl, child: home),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => _stubDestination(settings.name ?? ''),
        );
      },
    ),
  );
}

void main() {
  group('Admin course details → offerings', () {
    testWidgets('the offerings tile is enabled and opens the offerings route', (
      tester,
    ) async {
      final recorder = RouteRecorder();

      await tester.pumpWidget(
        _wrap(
          home: const AdminCourseDetailsScreen(),
          homeArguments: _course,
          recorder: recorder,
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => FakeAuthProvider(user: _adminUser),
            ),
            ChangeNotifierProvider<AcademicStructureProvider>(
              create: (_) => FakeAcademicStructureProvider(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.courseOfferingsTileTitle));
      await tester.pumpAndSettle();

      expect(recorder.pushedRoutes.last, AppRoutes.adminOfferings);

      // The offerings screen is semester-scoped, not course-scoped: it must
      // be opened plain so it starts from the current semester.
      expect(recorder.pushedArguments.last, isNull);
      expect(
        find.text('STUB:${AppRoutes.adminOfferings}'),
        findsOneWidget,
      );
    });

    testWidgets('the tile subtitle no longer promises a later phase', (
      tester,
    ) async {
      expect(AppStrings.courseOfferingsTileDesc, isNot(contains('لاحقة')));
    });
  });

  group('Admin dashboard', () {
    List<SingleChildWidget> adminProviders(
      FakeCourseFileProvider fileProvider,
    ) => [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => FakeAuthProvider(user: _adminUser),
      ),
      ChangeNotifierProvider<CourseProvider>(create: (_) => FakeCourseProvider()),
      ChangeNotifierProvider<EnrollmentProvider>(
        create: (_) => FakeEnrollmentProvider(),
      ),
      ChangeNotifierProvider<CourseFileProvider>.value(value: fileProvider),
    ];

    testWidgets(
      'the upload action opens the offerings screen, never the upload screen',
      (tester) async {
        final recorder = RouteRecorder();
        final fileProvider = FakeCourseFileProvider(countValue: 0);

        await tester.pumpWidget(
          _wrap(
            home: const AdminDashboardScreen(),
            recorder: recorder,
            providers: adminProviders(fileProvider),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text(AppStrings.uploadFileQuickAction));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.uploadFileQuickAction));
        await tester.pumpAndSettle();

        expect(recorder.pushedRoutes.last, AppRoutes.adminOfferings);

        // The old bug: going straight to an offering-scoped screen with no
        // offering, which rendered "offering not found".
        expect(
          recorder.pushedRoutes,
          isNot(contains(AppRoutes.adminUploadFile)),
        );
      },
    );

    testWidgets('the dashboard fabricates no offering or upload arguments', (
      tester,
    ) async {
      final recorder = RouteRecorder();
      final fileProvider = FakeCourseFileProvider(countValue: 0);

      await tester.pumpWidget(
        _wrap(
          home: const AdminDashboardScreen(),
          recorder: recorder,
          providers: adminProviders(fileProvider),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(AppStrings.uploadFileQuickAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.uploadFileQuickAction));
      await tester.pumpAndSettle();

      // Every argument the dashboard passes must be null — it knows no
      // offering, and inventing one would lie to the layer that derives the
      // course and semester from it.
      for (final arguments in recorder.pushedArguments) {
        expect(arguments, isNull);
      }
    });

    testWidgets('the files statistic comes from the provider, not a literal', (
      tester,
    ) async {
      final recorder = RouteRecorder();
      final fileProvider = FakeCourseFileProvider(countValue: 7);

      await tester.pumpWidget(
        _wrap(
          home: const AdminDashboardScreen(),
          recorder: recorder,
          providers: adminProviders(fileProvider),
        ),
      );
      await tester.pumpAndSettle();

      expect(fileProvider.loadCountCallCount, 1);

      final filesCard = tester.widget<AdminStatCard>(
        find.ancestor(
          of: find.text(AppStrings.filesManagementTitle),
          matching: find.byType(AdminStatCard),
        ),
      );
      expect(filesCard.value, '7');

      // A changed count reaches the card without any screen-local state.
      fileProvider.countValue = 12;
      fileProvider.notifyListeners();
      await tester.pumpAndSettle();

      final updated = tester.widget<AdminStatCard>(
        find.ancestor(
          of: find.text(AppStrings.filesManagementTitle),
          matching: find.byType(AdminStatCard),
        ),
      );
      expect(updated.value, '12');
    });

    testWidgets('an unknown count shows a dash, never a fabricated zero', (
      tester,
    ) async {
      final recorder = RouteRecorder();
      final fileProvider = FakeCourseFileProvider(countValue: null);

      await tester.pumpWidget(
        _wrap(
          home: const AdminDashboardScreen(),
          recorder: recorder,
          providers: adminProviders(fileProvider),
        ),
      );
      await tester.pumpAndSettle();

      final filesCard = tester.widget<AdminStatCard>(
        find.ancestor(
          of: find.text(AppStrings.filesManagementTitle),
          matching: find.byType(AdminStatCard),
        ),
      );
      expect(filesCard.value, '—');
      expect(filesCard.value, isNot('0'));
    });

    testWidgets('no overflow at 360px', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // ثلاثة أرقام في بطاقة الملفات: العدد الحقيقي قد يكبر، والبطاقة يجب
      // أن تحتمله على أضيق شاشة.
      final fileProvider = FakeCourseFileProvider(countValue: 128);

      await tester.pumpWidget(
        _wrap(
          home: const AdminDashboardScreen(),
          recorder: RouteRecorder(),
          providers: adminProviders(fileProvider),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Student app-bar profile action', () {
    List<SingleChildWidget> studentProviders() => [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => FakeAuthProvider(user: _studentUser),
      ),
      ChangeNotifierProvider<StudentCoursesProvider>(
        create: (_) => FakeStudentCoursesProvider(),
      ),
      // The dashboard's tasks summary reads this directly.
      ChangeNotifierProvider<TaskProvider>(create: (_) => FakeTaskProvider()),
    ];

    testWidgets('the dashboard avatar opens the profile route', (tester) async {
      final recorder = RouteRecorder();

      await tester.pumpWidget(
        _wrap(
          home: const DashboardScreen(),
          recorder: recorder,
          providers: studentProviders(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(AppStrings.profile));
      await tester.pumpAndSettle();

      expect(recorder.pushedRoutes.last, AppRoutes.profile);
    });

    testWidgets('the student courses avatar opens the profile route', (
      tester,
    ) async {
      final recorder = RouteRecorder();

      await tester.pumpWidget(
        _wrap(
          home: const StudentCoursesScreen(),
          recorder: recorder,
          providers: studentProviders(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(AppStrings.profile));
      await tester.pumpAndSettle();

      expect(recorder.pushedRoutes.last, AppRoutes.profile);
    });

    testWidgets('the notification bell remains without a destination', (
      tester,
    ) async {
      final recorder = RouteRecorder();

      await tester.pumpWidget(
        _wrap(
          home: const DashboardScreen(),
          recorder: recorder,
          providers: studentProviders(),
        ),
      );
      await tester.pumpAndSettle();

      final pushesBefore = recorder.pushedRoutes.length;

      await tester.tap(find.byTooltip(AppStrings.notifications));
      await tester.pumpAndSettle();

      // Deferred on purpose: there is no notifications screen to open, and
      // this test pins that so a future phase notices it must change here.
      expect(recorder.pushedRoutes.length, pushesBefore);
    });

    testWidgets('no overflow at 360px on the changed student screens', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrap(
          home: const DashboardScreen(),
          recorder: RouteRecorder(),
          providers: studentProviders(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _wrap(
          home: const StudentCoursesScreen(),
          recorder: RouteRecorder(),
          providers: studentProviders(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
