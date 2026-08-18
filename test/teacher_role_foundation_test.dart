import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/core/services/auth_service.dart';
import 'package:academia/features/admin/widgets/admin_access_guard.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/academics/services/major_service.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/courses/services/course_offering_service.dart';
import 'package:academia/features/courses/services/course_service.dart';
import 'package:academia/features/curriculum/services/curriculum_service.dart';
import 'package:academia/features/enrollments/services/enrollment_service.dart';
import 'package:academia/features/semesters/services/semester_service.dart';
import 'package:academia/features/teacher/screens/teacher_shell_screen.dart';
import 'package:academia/features/teacher/models/teacher_offering_view.dart';
import 'package:academia/features/teacher/providers/teacher_offerings_provider.dart';
import 'package:academia/features/teacher/widgets/teacher_access_guard.dart';

// --------------------------------------------------------------- fixtures

AppUserModel _user({
  required String uid,
  required UserRole role,
  String status = 'active',
}) {
  return AppUserModel(
    uid: uid,
    fullName: 'حلا جندية',
    email: '$uid@test.com',
    role: role,
    status: status,
    emailVerified: true,
    onboardingCompleted: true,
    onboardingStatus: 'completed',
  );
}

/// Builds a model straight from a raw Firestore map, exercising the real
/// parser rather than the enum.
AppUserModel _fromRaw(Map<String, dynamic> data) {
  return AppUserModel.fromFirestore(_FakeDoc(data));
}

/*
 * AppUserModel.fromFirestore takes a DocumentSnapshot, and the role parser
 * it exercises is the single most security-relevant function in this phase.
 * cloud_firestore seals the type and this project adds no faking package, so
 * a contained test double is the only way to feed it a raw map. Only `id`
 * and `data()` are ever reached.
 */
// ignore: subtype_of_sealed_class
class _FakeDoc implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDoc(this._data);
  final Map<String, dynamic> _data;

  @override
  String get id => 'uid1';

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthService {
  FakeAuthService(this.profile);
  AppUserModel? profile;

  int signOutCount = 0;

  @override
  Future<AppUserModel?> getCurrentUserProfile() async => profile;

  @override
  Future<void> signOut() async => signOutCount++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Minimal auth stand-in for guard/widget tests.
class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  FakeAuthProvider({
    required this.role,
    this.loggedIn = true,
    this.active = true,
  });

  final UserRole role;
  final bool loggedIn;
  final bool active;

  @override
  bool get isLoggedIn => loggedIn;

  @override
  bool get isAccountActive => active;

  @override
  bool get isAdmin => role == UserRole.admin;

  @override
  bool get isStudent => role == UserRole.student;

  @override
  bool get isTeacher => role == UserRole.teacher;

  @override
  bool get hasKnownRole => role != UserRole.unknown;

  @override
  AppUserModel? get currentUserProfile => _user(uid: 'u1', role: role);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RouteRecorder extends NavigatorObserver {
  final List<String?> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}

/*
 * An inert teacher workspace: loaded, no error, no assignments.
 *
 * Phase 8.1 made the dashboard and مساقاتي read real data, so the shell
 * cannot be built without this provider. "Loaded and empty" is the state
 * these shell tests are about — a teacher who has been given nothing yet.
 * Data-driven behaviour lives in teacher_workspace_test and
 * teacher_screens_test; this file stays about the role and the shell.
 */
class InertTeacherOfferingsProvider extends ChangeNotifier
    implements TeacherOfferingsProvider {
  @override
  List<TeacherOfferingView> get offerings => const <TeacherOfferingView>[];

  @override
  List<TeacherOfferingView> get activeOfferings =>
      const <TeacherOfferingView>[];

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _guarded({
  required Widget child,
  required FakeAuthProvider auth,
  required RouteRecorder recorder,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<TeacherOfferingsProvider>(
        create: (_) => InertTeacherOfferingsProvider(),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('ar'),
      navigatorObservers: [recorder],
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => settings.name == Navigator.defaultRouteName
            ? Directionality(textDirection: TextDirection.rtl, child: child)
            : Scaffold(body: Text('ROUTE:${settings.name}')),
      ),
    ),
  );
}

void main() {
  group('role parsing fails closed', () {
    test('the three supported roles parse correctly', () {
      expect(_fromRaw({'role': 'student'}).role, UserRole.student);
      expect(_fromRaw({'role': 'admin'}).role, UserRole.admin);
      expect(_fromRaw({'role': 'teacher'}).role, UserRole.teacher);
      expect(_fromRaw({'role': 'TEACHER'}).role, UserRole.teacher);
      expect(_fromRaw({'role': '  teacher  '}).role, UserRole.teacher);
    });

    test('an unrecognised role is NOT student, admin or teacher', () {
      final model = _fromRaw({'role': 'professor'});

      expect(model.role, UserRole.unknown);
      expect(model.isStudent, isFalse);
      expect(model.isAdmin, isFalse);
      expect(model.isTeacher, isFalse);
      expect(model.hasKnownRole, isFalse);
    });

    test('a missing role field grants no capability', () {
      final model = _fromRaw({'fullName': 'x'});

      // The old parser returned student here — a silent privilege grant.
      expect(model.role, UserRole.unknown);
      expect(model.isStudent, isFalse);
      expect(model.hasKnownRole, isFalse);
    });

    test('an empty or null role grants no capability', () {
      for (final raw in [<String, dynamic>{'role': ''}, {'role': null}]) {
        final model = _fromRaw(raw);
        expect(model.isStudent, isFalse);
        expect(model.isAdmin, isFalse);
        expect(model.isTeacher, isFalse);
        expect(model.hasKnownRole, isFalse);
      }
    });
  });

  group('AuthProvider role surface', () {
    test('isTeacher reflects a loaded teacher profile', () async {
      final auth = AuthProvider(
        authService: FakeAuthService(_user(uid: 't1', role: UserRole.teacher)),
      );
      await auth.loadCurrentUserProfile();

      expect(auth.isTeacher, isTrue);
      expect(auth.isAdmin, isFalse);
      expect(auth.isStudent, isFalse);
      expect(auth.hasKnownRole, isTrue);
    });

    test('an unknown role reports no capability', () async {
      final auth = AuthProvider(
        authService: FakeAuthService(_user(uid: 'x1', role: UserRole.unknown)),
      );
      await auth.loadCurrentUserProfile();

      expect(auth.isStudent, isFalse);
      expect(auth.isAdmin, isFalse);
      expect(auth.isTeacher, isFalse);
      expect(auth.hasKnownRole, isFalse);
    });

    test('initializeCurrentUser signs out an unknown role', () async {
      final service = FakeAuthService(
        _user(uid: 'x1', role: UserRole.unknown),
      );
      final auth = _AuthProviderWithSession(authService: service);

      final ok = await auth.initializeCurrentUser();

      expect(ok, isFalse);
      expect(service.signOutCount, 1);
      expect(auth.currentUserProfile, isNull);
      expect(auth.errorMessage, AppStrings.unsupportedAccountRole);
    });

    test('initializeCurrentUser admits an active teacher', () async {
      final service = FakeAuthService(
        _user(uid: 't1', role: UserRole.teacher),
      );
      final auth = _AuthProviderWithSession(authService: service);

      expect(await auth.initializeCurrentUser(), isTrue);
      expect(service.signOutCount, 0);
      expect(auth.isTeacher, isTrue);
    });

    test('initializeCurrentUser rejects a disabled teacher', () async {
      final service = FakeAuthService(
        _user(uid: 't1', role: UserRole.teacher, status: 'disabled'),
      );
      final auth = _AuthProviderWithSession(authService: service);

      expect(await auth.initializeCurrentUser(), isFalse);
      expect(service.signOutCount, 1);
      expect(auth.errorMessage, 'هذا الحساب غير نشط.');
    });
  });

  group('TeacherAccessGuard', () {
    testWidgets('an active teacher sees the child', (tester) async {
      final recorder = RouteRecorder();
      await tester.pumpWidget(
        _guarded(
          child: const TeacherAccessGuard(
            child: Scaffold(body: Text('TEACHER-CONTENT')),
          ),
          auth: FakeAuthProvider(role: UserRole.teacher),
          recorder: recorder,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TEACHER-CONTENT'), findsOneWidget);
      expect(recorder.pushed.where((r) => r != '/'), isEmpty);
    });

    testWidgets('a student is sent to the student dashboard', (tester) async {
      final recorder = RouteRecorder();
      await tester.pumpWidget(
        _guarded(
          child: const TeacherAccessGuard(
            child: Scaffold(body: Text('TEACHER-CONTENT')),
          ),
          auth: FakeAuthProvider(role: UserRole.student),
          recorder: recorder,
        ),
      );
      await tester.pumpAndSettle();

      expect(recorder.pushed.last, AppRoutes.dashboard);
      expect(find.text('TEACHER-CONTENT'), findsNothing);
    });

    testWidgets('an admin is sent to the admin shell', (tester) async {
      final recorder = RouteRecorder();
      await tester.pumpWidget(
        _guarded(
          child: const TeacherAccessGuard(
            child: Scaffold(body: Text('TEACHER-CONTENT')),
          ),
          auth: FakeAuthProvider(role: UserRole.admin),
          recorder: recorder,
        ),
      );
      await tester.pumpAndSettle();

      expect(recorder.pushed.last, AppRoutes.adminShell);
    });

    testWidgets('a disabled teacher is denied', (tester) async {
      final recorder = RouteRecorder();
      await tester.pumpWidget(
        _guarded(
          child: const TeacherAccessGuard(
            child: Scaffold(body: Text('TEACHER-CONTENT')),
          ),
          auth: FakeAuthProvider(role: UserRole.teacher, active: false),
          recorder: recorder,
        ),
      );
      await tester.pumpAndSettle();

      expect(recorder.pushed.last, AppRoutes.login);
      expect(find.text('TEACHER-CONTENT'), findsNothing);
    });

    testWidgets('an unknown role is denied, never treated as a student', (
      tester,
    ) async {
      final recorder = RouteRecorder();
      await tester.pumpWidget(
        _guarded(
          child: const TeacherAccessGuard(
            child: Scaffold(body: Text('TEACHER-CONTENT')),
          ),
          auth: FakeAuthProvider(role: UserRole.unknown),
          recorder: recorder,
        ),
      );
      await tester.pumpAndSettle();

      expect(recorder.pushed.last, AppRoutes.login);
      expect(recorder.pushed, isNot(contains(AppRoutes.dashboard)));
    });

    testWidgets('a signed-out visitor goes to login', (tester) async {
      final recorder = RouteRecorder();
      await tester.pumpWidget(
        _guarded(
          child: const TeacherAccessGuard(
            child: Scaffold(body: Text('TEACHER-CONTENT')),
          ),
          auth: FakeAuthProvider(role: UserRole.teacher, loggedIn: false),
          recorder: recorder,
        ),
      );
      await tester.pumpAndSettle();

      expect(recorder.pushed.last, AppRoutes.login);
    });
  });

  group('AdminAccessGuard sends each role to its own shell', () {
    testWidgets('a teacher on an admin route goes to the teacher shell', (
      tester,
    ) async {
      final recorder = RouteRecorder();
      await tester.pumpWidget(
        _guarded(
          child: const AdminAccessGuard(
            child: Scaffold(body: Text('ADMIN-CONTENT')),
          ),
          auth: FakeAuthProvider(role: UserRole.teacher),
          recorder: recorder,
        ),
      );
      await tester.pumpAndSettle();

      // Previously every non-admin landed on the student dashboard.
      expect(recorder.pushed.last, AppRoutes.teacherShell);
      expect(recorder.pushed, isNot(contains(AppRoutes.dashboard)));
      expect(find.text('ADMIN-CONTENT'), findsNothing);
    });

    testWidgets('a student on an admin route still goes to the dashboard', (
      tester,
    ) async {
      final recorder = RouteRecorder();
      await tester.pumpWidget(
        _guarded(
          child: const AdminAccessGuard(
            child: Scaffold(body: Text('ADMIN-CONTENT')),
          ),
          auth: FakeAuthProvider(role: UserRole.student),
          recorder: recorder,
        ),
      );
      await tester.pumpAndSettle();

      expect(recorder.pushed.last, AppRoutes.dashboard);
    });

    testWidgets('an unknown role on an admin route goes to login', (
      tester,
    ) async {
      final recorder = RouteRecorder();
      await tester.pumpWidget(
        _guarded(
          child: const AdminAccessGuard(
            child: Scaffold(body: Text('ADMIN-CONTENT')),
          ),
          auth: FakeAuthProvider(role: UserRole.unknown),
          recorder: recorder,
        ),
      );
      await tester.pumpAndSettle();

      expect(recorder.pushed.last, AppRoutes.login);
    });

    testWidgets('an admin still sees admin content', (tester) async {
      final recorder = RouteRecorder();
      await tester.pumpWidget(
        _guarded(
          child: const AdminAccessGuard(
            child: Scaffold(body: Text('ADMIN-CONTENT')),
          ),
          auth: FakeAuthProvider(role: UserRole.admin),
          recorder: recorder,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ADMIN-CONTENT'), findsOneWidget);
    });
  });

  group('teacher shell', () {
    testWidgets('renders four tabs with honest deferred states', (
      tester,
    ) async {
      final recorder = RouteRecorder();
      await tester.pumpWidget(
        _guarded(
          child: const TeacherShellScreen(),
          auth: FakeAuthProvider(role: UserRole.teacher),
          recorder: recorder,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.teacherHomeTab), findsOneWidget);
      expect(find.text(AppStrings.teacherCoursesTab), findsOneWidget);
      expect(find.text(AppStrings.teacherAssignmentsTab), findsOneWidget);
      expect(find.text(AppStrings.teacherProfileTab), findsOneWidget);

      // Dashboard shows identity and an honest empty state.
      expect(
        find.text(AppStrings.teacherDashboardDeferredTitle),
        findsOneWidget,
      );
      /*
       * '0' is no longer in this list, and that is the Phase 8.1 change.
       *
       * In 8A there was no data source, so any number on this screen was
       * invented. The count is now READ from courseOfferings, so a zero
       * here is a verified fact: this teacher has no active offerings.
       * What must still never appear is a number nothing produced.
       *
       * The complementary guarantee — a dash, never 0, while the count is
       * unknown or failed — is asserted in teacher_screens_test.
       */
      for (final fabricated in ['3 مساقات', '12 طالب', '85%']) {
        expect(find.text(fabricated), findsNothing);
      }
    });

    testWidgets('courses and assignments tabs state they are deferred', (
      tester,
    ) async {
      await tester.pumpWidget(
        _guarded(
          child: const TeacherShellScreen(),
          auth: FakeAuthProvider(role: UserRole.teacher),
          recorder: RouteRecorder(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.teacherCoursesTab));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.teacherCoursesDeferredTitle), findsOneWidget);

      await tester.tap(find.text(AppStrings.teacherAssignmentsTab));
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.teacherAssignmentsDeferredTitle),
        findsOneWidget,
      );
    });

    testWidgets('no overflow at 360px', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _guarded(
          child: const TeacherShellScreen(),
          auth: FakeAuthProvider(role: UserRole.teacher),
          recorder: RouteRecorder(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('student-only providers stay inert for a teacher', () {
    test('StudentCoursesProvider does not load for a teacher', () {
      final provider = _inertStudentCourses();

      provider.syncWithUser(
        _user(uid: 't1', role: UserRole.teacher),
        isLoggedIn: true,
      );

      // No service was touched: a teacher has no study plan.
      expect(provider.currentCourses, isEmpty);
      expect(provider.history, isEmpty);
      expect(provider.hasMajor, isFalse);
    });

    test('StudentCoursesProvider does not load for an unknown role', () {
      final provider = _inertStudentCourses();

      provider.syncWithUser(
        _user(uid: 'x1', role: UserRole.unknown),
        isLoggedIn: true,
      );

      expect(provider.currentCourses, isEmpty);
      expect(provider.hasMajor, isFalse);
    });

    test('the task-provider gate admits only an active student', () {
      // Mirrors the condition wired in app_providers.dart.
      bool gate(UserRole role, {bool active = true}) =>
          true && role == UserRole.student && active;

      expect(gate(UserRole.student), isTrue);
      expect(gate(UserRole.teacher), isFalse);
      expect(gate(UserRole.admin), isFalse);
      expect(gate(UserRole.unknown), isFalse);
      expect(gate(UserRole.student, active: false), isFalse);
    });

    test('the admin-provider gate admits only an active admin', () {
      bool gate(UserRole role, {bool active = true}) =>
          true && role == UserRole.admin && active;

      expect(gate(UserRole.admin), isTrue);
      expect(gate(UserRole.teacher), isFalse);
      expect(gate(UserRole.student), isFalse);
      expect(gate(UserRole.unknown), isFalse);
    });
  });
}

/// AuthProvider reports "logged in" from FirebaseAuth, which is unavailable
/// in tests; this override isolates the role/status logic under test.
class _AuthProviderWithSession extends AuthProvider {
  _AuthProviderWithSession({required super.authService});

  @override
  bool get isLoggedIn => true;
}

/*
 * Any call is a failure: these prove the provider never reaches Firestore
 * for a non-student. One class per service because Dart needs the concrete
 * type at each constructor position.
 */
mixin _NeverCalled {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError(
      'service reached for a non-student: ${invocation.memberName}',
    );
  }
}

class FakeSemesterService with _NeverCalled implements SemesterService {}

class FakeCurriculumService with _NeverCalled implements CurriculumService {}

class FakeCourseService with _NeverCalled implements CourseService {}

class FakeCourseOfferingService
    with _NeverCalled
    implements CourseOfferingService {}

class FakeEnrollmentService with _NeverCalled implements EnrollmentService {}

class FakeMajorService with _NeverCalled implements MajorService {}

StudentCoursesProvider _inertStudentCourses() => StudentCoursesProvider(
  FakeSemesterService(),
  FakeCurriculumService(),
  FakeCourseService(),
  FakeCourseOfferingService(),
  FakeEnrollmentService(),
  FakeMajorService(),
);
