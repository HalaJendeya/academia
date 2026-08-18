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
import 'package:academia/features/assignments/providers/course_assignment_provider.dart';
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
/// Mirrors FakeCourseFileProvider for the assignment statistic.
class FakeCourseAssignmentProvider extends ChangeNotifier
    implements CourseAssignmentProvider {
  FakeCourseAssignmentProvider({this.countValue});

  int? countValue;
  int loadCountCallCount = 0;

  @override
  int? get activeAssignmentCount => countValue;

  @override
  bool get isLoadingActiveAssignmentCount => false;

  @override
  Future<void> loadActiveAssignmentCount() async {
    loadCountCallCount++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
      FakeCourseFileProvider fileProvider, [
      FakeCourseAssignmentProvider? assignmentProvider,
    ]) => [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => FakeAuthProvider(user: _adminUser),
      ),
      ChangeNotifierProvider<CourseProvider>(create: (_) => FakeCourseProvider()),
      ChangeNotifierProvider<EnrollmentProvider>(
        create: (_) => FakeEnrollmentProvider(),
      ),
      ChangeNotifierProvider<CourseFileProvider>.value(value: fileProvider),
      /*
       * Phase 8.3: the dashboard's assignment card now reads a real count
       * from this provider instead of the hardcoded '0' it used to show.
       */
      ChangeNotifierProvider<CourseAssignmentProvider>.value(
        value: assignmentProvider ?? FakeCourseAssignmentProvider(),
      ),
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

    // ---- Phase 8.3: the assignment statistic ----

    AdminStatCard assignmentCard(WidgetTester tester) =>
        tester.widget<AdminStatCard>(
          find.ancestor(
            of: find.text(AppStrings.assignmentsManagementTitle),
            matching: find.byType(AdminStatCard),
          ),
        );

    Future<void> pumpDashboard(
      WidgetTester tester,
      FakeCourseAssignmentProvider assignments,
    ) async {
      await tester.pumpWidget(
        _wrap(
          home: const AdminDashboardScreen(),
          recorder: RouteRecorder(),
          providers: adminProviders(
            FakeCourseFileProvider(countValue: 0),
            assignments,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /*
     * Until the count is read, the card must say "unknown", not "none".
     * The old dashboard hardcoded '0', which asserted there were no
     * assignments in a system that had never been asked.
     */
    testWidgets('an unread assignment count shows a dash, never 0', (
      tester,
    ) async {
      final assignments = FakeCourseAssignmentProvider();
      await pumpDashboard(tester, assignments);

      expect(assignmentCard(tester).value, '—');
      expect(assignments.loadCountCallCount, 1);
    });

    testWidgets('a real zero shows as 0', (tester) async {
      await pumpDashboard(tester, FakeCourseAssignmentProvider(countValue: 0));
      expect(assignmentCard(tester).value, '0');
    });

    testWidgets('a real count shows the number', (tester) async {
      await pumpDashboard(tester, FakeCourseAssignmentProvider(countValue: 9));
      expect(assignmentCard(tester).value, '9');
    });

    testWidgets('a provider update reaches the card', (tester) async {
      final assignments = FakeCourseAssignmentProvider(countValue: 3);
      await pumpDashboard(tester, assignments);
      expect(assignmentCard(tester).value, '3');

      assignments.countValue = 5;
      assignments.notifyListeners();
      await tester.pumpAndSettle();

      expect(assignmentCard(tester).value, '5');
    });

    /*
     * A failed count read leaves the value null. The dashboard must keep
     * rendering everything else rather than fabricating a zero.
     */
    testWidgets('a failed count does not fabricate 0 or break the dashboard', (
      tester,
    ) async {
      final assignments = FakeCourseAssignmentProvider(countValue: 4);
      await pumpDashboard(tester, assignments);

      assignments.countValue = null; // read failed
      assignments.notifyListeners();
      await tester.pumpAndSettle();

      expect(assignmentCard(tester).value, '—');
      // Neighbouring statistics and the page itself are unaffected.
      expect(find.text(AppStrings.filesManagementTitle), findsOneWidget);
      expect(find.text(AppStrings.adminStudentsTitle), findsOneWidget);
    });

    /*
     * The admin authoring path was removed in Phase 8.3: teachers author
     * assignments, and the rules deny admin create.
     */
    testWidgets('the dashboard offers oversight, not assignment creation', (
      tester,
    ) async {
      await pumpDashboard(tester, FakeCourseAssignmentProvider(countValue: 0));

      expect(find.text(AppStrings.addAssignmentQuickAction), findsNothing);
      expect(
        find.text(AppStrings.adminAssignmentsOversightTitle),
        findsOneWidget,
      );
    });

    testWidgets('the oversight action opens the assignments list', (
      tester,
    ) async {
      final recorder = RouteRecorder();
      await tester.pumpWidget(
        _wrap(
          home: const AdminDashboardScreen(),
          recorder: recorder,
          providers: adminProviders(
            FakeCourseFileProvider(countValue: 0),
            FakeCourseAssignmentProvider(countValue: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.text(AppStrings.adminAssignmentsOversightTitle),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.adminAssignmentsOversightTitle));
      await tester.pumpAndSettle();

      expect(recorder.pushedRoutes.last, AppRoutes.adminAssignments);
    });

    testWidgets('no overflow at 360px with the assignment card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpDashboard(tester, FakeCourseAssignmentProvider(countValue: 42));

      expect(tester.takeException(), isNull);
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
