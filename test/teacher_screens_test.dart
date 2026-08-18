import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/admin/models/admin_student_model.dart';
import 'package:academia/features/admin/models/admin_teacher_model.dart';
import 'package:academia/features/admin/providers/admin_teacher_provider.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/models/course_offering_model.dart';
import 'package:academia/features/enrollments/models/enrollment_model.dart';
import 'package:academia/features/semesters/models/semester_model.dart';
import 'package:academia/features/teacher/models/teacher_offering_view.dart';
import 'package:academia/features/teacher/providers/teacher_offerings_provider.dart';
import 'package:academia/features/teacher/screens/teacher_courses_screen.dart';
import 'package:academia/features/teacher/screens/teacher_dashboard_screen.dart';
import 'package:academia/features/teacher/screens/teacher_offering_detail_screen.dart';

// ------------------------------------------------------------------ fakes

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  FakeAuthProvider({this.profile});

  final AppUserModel? profile;

  @override
  AppUserModel? get currentUserProfile => profile;

  @override
  bool get isLoggedIn => profile != null;

  @override
  bool get isTeacher => profile?.isTeacher ?? false;

  @override
  bool get isAdmin => profile?.isAdmin ?? false;

  @override
  bool get isStudent => profile?.isStudent ?? false;

  @override
  bool get isAccountActive => profile?.isActive ?? false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTeacherOfferingsProvider extends ChangeNotifier
    implements TeacherOfferingsProvider {
  FakeTeacherOfferingsProvider({
    this.offeringsValue = const <TeacherOfferingView>[],
    this.rosterValue = const <TeacherRosterEntry>[],
    this.selected,
    this.loading = false,
    this.error,
    this.rosterError,
    this.loadingRoster = false,
  });

  final List<TeacherOfferingView> offeringsValue;
  final List<TeacherRosterEntry> rosterValue;
  final TeacherOfferingView? selected;
  final bool loading;
  final String? error;
  final String? rosterError;
  final bool loadingRoster;

  final rosterRequests = <String>[];

  @override
  List<TeacherOfferingView> get offerings => offeringsValue;

  @override
  List<TeacherOfferingView> get activeOfferings =>
      offeringsValue.where((view) => view.isActive).toList();

  @override
  List<TeacherRosterEntry> get roster => rosterValue;

  @override
  TeacherOfferingView? get selectedOffering => selected;

  @override
  bool get isLoading => loading;

  @override
  String? get errorMessage => error;

  @override
  bool get isLoadingRoster => loadingRoster;

  @override
  String? get rosterErrorMessage => rosterError;

  @override
  void listenToOfferingRoster(String offeringId) =>
      rosterRequests.add(offeringId);

  @override
  void stopListeningToRoster() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --------------------------------------------------------------- fixtures

const _teacher = AppUserModel(
  uid: 'teacher1',
  fullName: 'د. سارة قاسم',
  email: 'sara@test.com',
  role: UserRole.teacher,
  status: 'active',
  emailVerified: true,
  onboardingCompleted: true,
  onboardingStatus: 'completed',
);

TeacherOfferingView _view({
  String id = 'c1_semester_2026_1_1',
  String status = 'active',
  String title = 'تحليل وتصميم النظم المتقدمة والمتكاملة',
}) {
  return TeacherOfferingView(
    offering: CourseOfferingModel(
      id: id,
      courseId: 'c1',
      semesterId: 'semester_2026_1',
      teacherId: 'teacher1',
      instructorName: 'د. سارة قاسم',
      section: '1',
      status: status,
    ),
    course: CourseModel(
      id: 'c1',
      courseCode: 'BMIS3344',
      title: title,
      description: '',
      creditHours: 3,
      departmentId: 'dep1',
      status: 'active',
    ),
    semester: const SemesterModel(
      id: 'semester_2026_1',
      academicYear: '2026',
      semesterNumber: 1,
      semesterName: 'الفصل الدراسي الأول 2026',
      status: 'current',
    ),
  );
}

TeacherRosterEntry _rosterEntry({
  String userId = 'student1',
  String? name = 'حلا هيثم جندية',
  int attempt = 1,
}) {
  return TeacherRosterEntry(
    enrollment: EnrollmentModel(
      id: '${userId}_c1_semester_2026_1_1',
      userId: userId,
      offeringId: 'c1_semester_2026_1_1',
      courseId: 'c1',
      semesterId: 'semester_2026_1',
      attemptNumber: attempt,
      status: 'active',
      assignedBy: 'admin1',
    ),
    student: name == null
        ? null
        : AdminStudentModel(
            uid: userId,
            fullName: name,
            email: '$userId@test.com',
            studentId: '2320220914',
            major: '',
            status: 'active',
            onboardingCompleted: true,
          ),
  );
}

// ----------------------------------------------------------------- harness

Widget _wrap(Widget child, {FakeTeacherOfferingsProvider? offerings}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(
        value: FakeAuthProvider(profile: _teacher),
      ),
      ChangeNotifierProvider<TeacherOfferingsProvider>.value(
        value: offerings ?? FakeTeacherOfferingsProvider(),
      ),
      ChangeNotifierProvider<AdminTeacherProvider>.value(
        value: _InertAdminTeacherProvider(),
      ),
    ],
    child: MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: child),
      // The destination exists so a tap can be asserted end to end; the
      // screen under test is the one that decides to navigate.
      routes: {
        AppRoutes.teacherOfferingDetail: (_) =>
            const Scaffold(body: Text('offering-detail')),
      },
    ),
  );
}

class _InertAdminTeacherProvider extends ChangeNotifier
    implements AdminTeacherProvider {
  @override
  List<AdminTeacherModel> get teachers => const <AdminTeacherModel>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void _useNarrowScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  // ===================================================================
  //  Teacher courses
  // ===================================================================
  group('TeacherCoursesScreen', () {
    testWidgets('shows an honest empty state with no assignments', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap(const TeacherCoursesScreen()));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.teacherCoursesDeferredTitle),
        findsOneWidget,
      );
    });

    testWidgets('lists assigned offerings with real course metadata', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherCoursesScreen(),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_view()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('BMIS3344'),
        findsOneWidget,
        reason: 'the course code must come from the resolved course document',
      );
      expect(find.text('الفصل الدراسي الأول 2026'), findsOneWidget);
      expect(find.text(AppStrings.teacherCoursesDeferredTitle), findsNothing);
    });

    testWidgets('tapping an offering opens its roster', (tester) async {
      _useNarrowScreen(tester);
      final provider = FakeTeacherOfferingsProvider(
        offeringsValue: [_view()],
      );
      await tester.pumpWidget(
        _wrap(const TeacherCoursesScreen(), offerings: provider),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('BMIS3344'));
      await tester.pumpAndSettle();

      expect(provider.rosterRequests, ['c1_semester_2026_1_1']);
    });

    testWidgets('no overflow at 360px with several offerings', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherCoursesScreen(),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [
              _view(),
              _view(id: 'b', status: 'archived'),
              _view(id: 'c'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ===================================================================
  //  Teacher dashboard
  // ===================================================================
  group('TeacherDashboardScreen', () {
    /*
     * The no-fake-data rule, asserted directly: while the count is unknown
     * the card must show a dash, never 0. Zero is a claim that the teacher
     * has no active offerings.
     */
    testWidgets('shows a dash, not zero, while offerings are loading', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherDashboardScreen(),
          offerings: FakeTeacherOfferingsProvider(loading: true),
        ),
      );
      await tester.pump();

      expect(find.text('—'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows a dash when loading failed', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherDashboardScreen(),
          offerings: FakeTeacherOfferingsProvider(
            error: AppStrings.teacherOfferingsLoadError,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('counts only ACTIVE offerings once loaded', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherDashboardScreen(),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [
              _view(),
              _view(id: 'b'),
              _view(id: 'c', status: 'archived'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('—'), findsNothing);
    });

    testWidgets('shows the real teacher name from AuthProvider', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap(const TeacherDashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('د. سارة قاسم'), findsOneWidget);
    });

    testWidgets('no overflow at 360px with offerings listed', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherDashboardScreen(),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_view(), _view(id: 'b')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ===================================================================
  //  Teacher offering detail + roster
  // ===================================================================
  group('TeacherOfferingDetailScreen', () {
    testWidgets('renders the roster with resolved student names', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherOfferingDetailScreen(),
          offerings: FakeTeacherOfferingsProvider(
            selected: _view(),
            rosterValue: [_rosterEntry(), _rosterEntry(userId: 'student2')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('حلا هيثم جندية'), findsNWidgets(2));
      expect(
        find.textContaining('${AppStrings.offeringRosterCountLabel}: 2'),
        findsOneWidget,
      );
    });

    testWidgets('an unresolvable name is stated, not replaced by a uid', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherOfferingDetailScreen(),
          offerings: FakeTeacherOfferingsProvider(
            selected: _view(),
            rosterValue: [_rosterEntry(userId: 'ghost', name: null)],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.teacherUnknownStudentName), findsOneWidget);
      expect(find.text('ghost'), findsNothing);
    });

    /*
     * The roster count must not appear as 0 mid-load, for the same reason
     * the dashboard count must not.
     */
    testWidgets('hides the roster count while it is still loading', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherOfferingDetailScreen(),
          offerings: FakeTeacherOfferingsProvider(
            selected: _view(),
            loadingRoster: true,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.textContaining(AppStrings.offeringRosterCountLabel),
        findsNothing,
      );
    });

    testWidgets('empties out when the assignment is withdrawn', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherOfferingDetailScreen(),
          // selected == null: the offering is no longer the teacher's.
          offerings: FakeTeacherOfferingsProvider(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.teacherCoursesDeferredTitle),
        findsOneWidget,
      );
    });

    testWidgets('surfaces a roster read failure', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherOfferingDetailScreen(),
          offerings: FakeTeacherOfferingsProvider(
            selected: _view(),
            rosterError: AppStrings.teacherRosterLoadError,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.teacherRosterLoadError), findsOneWidget);
    });

    testWidgets('no overflow at 360px with a full roster', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherOfferingDetailScreen(),
          offerings: FakeTeacherOfferingsProvider(
            selected: _view(),
            rosterValue: [
              _rosterEntry(),
              _rosterEntry(userId: 'student2', attempt: 3),
              _rosterEntry(userId: 'student3', name: null),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
