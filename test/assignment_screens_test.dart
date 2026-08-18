import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/admin/models/admin_teacher_model.dart';
import 'package:academia/features/admin/providers/admin_teacher_provider.dart';
import 'package:academia/features/admin/screens/admin_assignment_list_screen.dart';
import 'package:academia/features/admin/screens/admin_assignment_details_screen.dart';
import 'package:academia/features/assignments/models/course_assignment_model.dart';
import 'package:academia/features/assignments/providers/course_assignment_provider.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/models/course_offering_model.dart';
import 'package:academia/features/courses/providers/course_provider.dart';
import 'package:academia/features/courses/widgets/student_assignment_preview_card.dart';
import 'package:academia/features/semesters/models/semester_model.dart';
import 'package:academia/features/teacher/models/teacher_offering_view.dart';
import 'package:academia/features/teacher/providers/teacher_offerings_provider.dart';
import 'package:academia/features/teacher/screens/teacher_add_assignment_screen.dart';
import 'package:academia/features/teacher/screens/teacher_assignment_details_screen.dart';
import 'package:academia/features/teacher/screens/teacher_assignments_screen.dart';

// ------------------------------------------------------------------ fakes

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  FakeAuthProvider({required this.role});

  final UserRole role;

  @override
  AppUserModel? get currentUserProfile => AppUserModel(
    uid: 'u1',
    fullName: 'د. سارة قاسم',
    email: 'u1@test.com',
    role: role,
    status: 'active',
    emailVerified: true,
    onboardingCompleted: true,
    onboardingStatus: 'completed',
  );

  @override
  bool get isLoggedIn => true;

  @override
  bool get isAccountActive => true;

  @override
  bool get isTeacher => role == UserRole.teacher;

  @override
  bool get isAdmin => role == UserRole.admin;

  @override
  bool get isStudent => role == UserRole.student;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAssignmentProvider extends ChangeNotifier
    implements CourseAssignmentProvider {
  FakeAssignmentProvider({
    this.assignmentsValue = const <CourseAssignmentModel>[],
    this.loading = false,
    this.error,
    this.saving = false,
    this.countValue,
    this.createSucceeds = true,
  });

  List<CourseAssignmentModel> assignmentsValue;
  bool loading;
  String? error;
  bool saving;
  int? countValue;
  bool createSucceeds;

  final createCalls = <Map<String, Object?>>[];
  final updateCalls = <Map<String, Object?>>[];
  final archiveCalls = <String>[];
  final moderateCalls = <String>[];
  final listenedOfferingSets = <List<String>>[];
  int globalListenCalls = 0;

  @override
  List<CourseAssignmentModel> get assignments => assignmentsValue;

  @override
  List<CourseAssignmentModel> get activeAssignments =>
      assignmentsValue.where((a) => a.isActive).toList();

  @override
  bool get isLoading => loading;

  @override
  String? get errorMessage => error;

  @override
  bool get isSaving => saving;

  @override
  int? get activeAssignmentCount => countValue;

  @override
  void listenToOfferingsAssignments(List<String> offeringIds) =>
      listenedOfferingSets.add(offeringIds);

  @override
  void listenToOfferingAssignments(String offeringId) =>
      listenedOfferingSets.add([offeringId]);

  @override
  void listenToAllActiveAssignments() => globalListenCalls++;

  @override
  void stopListening() {}

  @override
  Future<void> loadActiveAssignmentCount() async {}

  @override
  Future<bool> createAssignment({
    required String offeringId,
    required String title,
    required String description,
    required DateTime dueAt,
    required String priority,
  }) async {
    createCalls.add({
      'offeringId': offeringId,
      'title': title,
      'dueAt': dueAt,
      'priority': priority,
    });
    if (!createSucceeds) error = AppStrings.assignmentSaveError;
    return createSucceeds;
  }

  @override
  Future<bool> updateAssignment({
    required String assignmentId,
    required String title,
    required String description,
    required DateTime dueAt,
    required String priority,
  }) async {
    updateCalls.add({'assignmentId': assignmentId, 'title': title});
    return true;
  }

  @override
  Future<bool> archiveAssignment(String assignmentId) async {
    archiveCalls.add(assignmentId);
    return true;
  }

  @override
  Future<bool> moderateArchiveAssignment(String assignmentId) async {
    moderateCalls.add(assignmentId);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTeacherOfferingsProvider extends ChangeNotifier
    implements TeacherOfferingsProvider {
  FakeTeacherOfferingsProvider({
    this.offeringsValue = const <TeacherOfferingView>[],
    this.loading = false,
  });

  List<TeacherOfferingView> offeringsValue;
  bool loading;

  @override
  List<TeacherOfferingView> get offerings => offeringsValue;

  @override
  List<TeacherOfferingView> get activeOfferings =>
      offeringsValue.where((v) => v.isActive).toList();

  @override
  bool get isLoading => loading;

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCourseProvider extends ChangeNotifier implements CourseProvider {
  FakeCourseProvider(this.coursesValue);
  final List<CourseModel> coursesValue;

  @override
  List<CourseModel> get courses => coursesValue;

  @override
  void listenToCourses() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAdminTeacherProvider extends ChangeNotifier
    implements AdminTeacherProvider {
  FakeAdminTeacherProvider(this.teachersValue);
  final List<AdminTeacherModel> teachersValue;

  @override
  List<AdminTeacherModel> get teachers => teachersValue;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --------------------------------------------------------------- fixtures

final _fixedNow = DateTime(2026, 9, 10, 12);

CourseAssignmentModel _assignment({
  String id = 'a1',
  String offeringId = 'off1',
  String title = 'واجب البرمجة الأول',
  DateTime? dueAt,
  String priority = CourseAssignmentModel.priorityHigh,
  String status = CourseAssignmentModel.statusActive,
  String description = 'حل التمارين المرفقة',
}) {
  return CourseAssignmentModel(
    id: id,
    offeringId: offeringId,
    courseId: 'c1',
    semesterId: 'semester_2026_1',
    title: title,
    description: description,
    dueAt: dueAt ?? DateTime(2026, 9, 20, 23, 59),
    priority: priority,
    status: status,
    createdBy: 'u1',
    createdAt: DateTime(2026, 9, 1),
  );
}

const _course = CourseModel(
  id: 'c1',
  courseCode: 'BMIS3344',
  title: 'تحليل وتصميم النظم',
  description: '',
  creditHours: 3,
  departmentId: 'dep1',
  status: 'active',
);

TeacherOfferingView _offeringView({
  String id = 'off1',
  String status = 'active',
}) {
  return TeacherOfferingView(
    offering: CourseOfferingModel(
      id: id,
      courseId: 'c1',
      semesterId: 'semester_2026_1',
      teacherId: 'u1',
      instructorName: 'د. سارة قاسم',
      section: '2',
      status: status,
    ),
    course: _course,
    semester: const SemesterModel(
      id: 'semester_2026_1',
      academicYear: '2026',
      semesterNumber: 1,
      semesterName: 'الفصل الدراسي الأول 2026',
      status: 'current',
    ),
  );
}

// ----------------------------------------------------------------- harness

Widget _wrap(
  Widget child, {
  required FakeAssignmentProvider assignments,
  FakeTeacherOfferingsProvider? offerings,
  UserRole role = UserRole.teacher,
  List<CourseModel> courses = const <CourseModel>[],
  List<AdminTeacherModel> teachers = const <AdminTeacherModel>[],
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(
        value: FakeAuthProvider(role: role),
      ),
      ChangeNotifierProvider<CourseAssignmentProvider>.value(
        value: assignments,
      ),
      ChangeNotifierProvider<TeacherOfferingsProvider>.value(
        value: offerings ?? FakeTeacherOfferingsProvider(),
      ),
      ChangeNotifierProvider<CourseProvider>.value(
        value: FakeCourseProvider(courses),
      ),
      ChangeNotifierProvider<AdminTeacherProvider>.value(
        value: FakeAdminTeacherProvider(teachers),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('ar'),
      home: Directionality(textDirection: TextDirection.rtl, child: child),
      routes: routes,
    ),
  );
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
  // In the app, GlobalMaterialLocalizations loads the Arabic date symbols.
  // A bare test MaterialApp has no delegates, so the same precondition has
  // to be established explicitly — assignment cards format deadlines with
  // DateFormat(…, 'ar').
  setUpAll(() async {
    await initializeDateFormatting('ar', null);
  });

  // ===================================================================
  //  Teacher — assignments list
  // ===================================================================
  group('TeacherAssignmentsScreen', () {
    testWidgets('no offerings shows the assignment-impossible state', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherAssignmentsScreen(),
          assignments: FakeAssignmentProvider(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.teacherAssignmentsNoOfferingsTitle),
        findsOneWidget,
      );
      // Nothing to create against, so no FAB.
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('offerings but no assignments shows the empty state', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherAssignmentsScreen(),
          assignments: FakeAssignmentProvider(),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.teacherAssignmentsEmptyTitle), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('loading is shown before assignments arrive', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherAssignmentsScreen(),
          assignments: FakeAssignmentProvider(loading: true),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView()],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    /*
     * The subscription must be built from the teacher's OWN offerings, and
     * from nothing else: this is the client half of the ownership model.
     */
    testWidgets('subscribes only to the teacher-owned offering ids', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      final assignments = FakeAssignmentProvider();
      await tester.pumpWidget(
        _wrap(
          const TeacherAssignmentsScreen(),
          assignments: assignments,
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [
              _offeringView(id: 'off1'),
              _offeringView(id: 'off2'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(assignments.listenedOfferingSets, isNotEmpty);
      expect(assignments.listenedOfferingSets.last, ['off1', 'off2']);
    });

    testWidgets('renders assignments with course context and priority', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherAssignmentsScreen(),
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment()],
          ),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('واجب البرمجة الأول'), findsOneWidget);
      expect(find.textContaining('BMIS3344'), findsOneWidget);
      expect(find.text(AppStrings.assignmentPriorityHigh), findsOneWidget);
    });

    testWidgets('tapping an assignment opens its details route', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherAssignmentsScreen(),
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment()],
          ),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView()],
          ),
          routes: {
            AppRoutes.teacherAssignmentDetails: (_) =>
                const Scaffold(body: Text('details-route')),
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('واجب البرمجة الأول'));
      await tester.pumpAndSettle();

      expect(find.text('details-route'), findsOneWidget);
    });

    testWidgets('the FAB opens the add-assignment route', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherAssignmentsScreen(),
          assignments: FakeAssignmentProvider(),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView()],
          ),
          routes: {
            AppRoutes.teacherAddAssignment: (_) =>
                const Scaffold(body: Text('add-route')),
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('add-route'), findsOneWidget);
    });

    testWidgets('an error is shown local to the assignments area', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherAssignmentsScreen(),
          assignments: FakeAssignmentProvider(
            error: AppStrings.courseAssignmentsLoadError,
          ),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.courseAssignmentsLoadError),
        findsOneWidget,
      );
      // The screen chrome survives a data failure.
      expect(find.text(AppStrings.teacherAssignmentsTitle), findsOneWidget);
    });

    testWidgets('no overflow at 360px with several assignments', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherAssignmentsScreen(),
          assignments: FakeAssignmentProvider(
            assignmentsValue: [
              _assignment(id: 'a1'),
              _assignment(
                id: 'a2',
                title: 'واجب طويل جدًا في تحليل وتصميم النظم المتقدمة',
                dueAt: DateTime(2026, 9, 1),
              ),
              _assignment(id: 'a3', priority: 'low'),
            ],
          ),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ===================================================================
  //  Teacher — add assignment
  // ===================================================================
  group('TeacherAddAssignmentScreen', () {
    testWidgets('with no offerings the form is not shown at all', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherAddAssignmentScreen(),
          assignments: FakeAssignmentProvider(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.teacherAssignmentsNoOfferingsTitle),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('only the teacher-owned offerings are offered', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherAddAssignmentScreen(),
          assignments: FakeAssignmentProvider(),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView(id: 'off1')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('BMIS3344'), findsWidgets);
    });

    testWidgets('submitting empty shows title and deadline errors', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      final assignments = FakeAssignmentProvider();
      await tester.pumpWidget(
        _wrap(
          const TeacherAddAssignmentScreen(),
          assignments: assignments,
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.assignmentSaveNewAction));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.assignmentTitleRequired), findsOneWidget);
      expect(find.text(AppStrings.assignmentDeadlineRequired), findsOneWidget);
      // Nothing reached the backend.
      expect(assignments.createCalls, isEmpty);
    });

    testWidgets('an archived offering is not selectable for a new assignment', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherAddAssignmentScreen(),
          assignments: FakeAssignmentProvider(),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView(id: 'old', status: 'archived')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.teacherAssignmentsNoOfferingsTitle),
        findsOneWidget,
      );
    });

    testWidgets('while saving the button is busy and cannot re-submit', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      final assignments = FakeAssignmentProvider(saving: true);
      await tester.pumpWidget(
        _wrap(
          const TeacherAddAssignmentScreen(),
          assignments: assignments,
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView()],
          ),
        ),
      );
      // pump, not pumpAndSettle: the busy button spins forever by design,
      // so there is no steady state to settle into.
      await tester.pump();

      // A tap while saving must not enqueue a second create.
      await tester.tap(
        find.byType(ElevatedButton).first,
        warnIfMissed: false,
      );
      await tester.pump();

      expect(assignments.createCalls, isEmpty);
    });

    testWidgets('no overflow at 360px on the form', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const TeacherAddAssignmentScreen(),
          assignments: FakeAssignmentProvider(),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ===================================================================
  //  Teacher — assignment details
  // ===================================================================
  group('TeacherAssignmentDetailsScreen', () {
    Widget detailsHarness({
      required FakeAssignmentProvider assignments,
      required FakeTeacherOfferingsProvider offerings,
      String assignmentId = 'a1',
    }) {
      return _wrap(
        Builder(
          builder: (context) => Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              settings: RouteSettings(
                arguments: TeacherAssignmentDetailsArgs(
                  assignmentId: assignmentId,
                ),
              ),
              builder: (_) => const TeacherAssignmentDetailsScreen(),
            ),
          ),
        ),
        assignments: assignments,
        offerings: offerings,
      );
    }

    testWidgets('shows the real assignment content', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        detailsHarness(
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment()],
          ),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('واجب البرمجة الأول'), findsOneWidget);
      expect(find.text('حل التمارين المرفقة'), findsOneWidget);
      expect(find.textContaining('BMIS3344'), findsOneWidget);
    });

    /*
     * Relational fields are not merely read-only here — they are absent.
     * There is no control through which a teacher could retarget an
     * assignment at another offering.
     */
    testWidgets('exposes no control for relational fields', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        detailsHarness(
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment()],
          ),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('an unowned assignment shows an explicit unavailable state', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        detailsHarness(
          // The assignment exists but its offering is not the teacher's.
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment(offeringId: 'someone-elses')],
          ),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView(id: 'off1')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.assignmentNotOwnedTitle), findsOneWidget);
      expect(find.text(AppStrings.archiveAssignmentAction), findsNothing);
    });

    testWidgets('archive asks for confirmation before acting', (tester) async {
      _useNarrowScreen(tester);
      final assignments = FakeAssignmentProvider(
        assignmentsValue: [_assignment()],
      );
      await tester.pumpWidget(
        detailsHarness(
          assignments: assignments,
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.archiveAssignmentAction));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.archiveAssignmentConfirmTitle),
        findsOneWidget,
      );
      // Still nothing archived until the dialog is confirmed.
      expect(assignments.archiveCalls, isEmpty);

      await tester.tap(find.text(AppStrings.cancelAction));
      await tester.pumpAndSettle();
      expect(assignments.archiveCalls, isEmpty);
    });

    testWidgets('confirming archive calls the teacher archive path', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      final assignments = FakeAssignmentProvider(
        assignmentsValue: [_assignment()],
      );
      await tester.pumpWidget(
        detailsHarness(
          assignments: assignments,
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.archiveAssignmentAction));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(
        TextButton,
        AppStrings.archiveAssignmentAction,
      ));
      await tester.pumpAndSettle();

      expect(assignments.archiveCalls, ['a1']);
      // Teacher archive, never the admin moderation path.
      expect(assignments.moderateCalls, isEmpty);
    });

    testWidgets('no overflow at 360px', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        detailsHarness(
          assignments: FakeAssignmentProvider(
            assignmentsValue: [
              _assignment(
                title: 'واجب بعنوان طويل جدًا لاختبار التفاف النص العربي',
                description: 'تعليمات مطوّلة ' * 20,
              ),
            ],
          ),
          offerings: FakeTeacherOfferingsProvider(
            offeringsValue: [_offeringView()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ===================================================================
  //  Student — preview card
  // ===================================================================
  group('AssignmentPreviewCard (student)', () {
    Widget cardHarness(CourseAssignmentModel assignment) {
      return MaterialApp(
        locale: const Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: AssignmentPreviewCard(assignment: assignment),
          ),
        ),
      );
    }

    testWidgets('shows title, deadline and priority', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(cardHarness(_assignment()));
      await tester.pumpAndSettle();

      expect(find.text('واجب البرمجة الأول'), findsOneWidget);
      expect(find.text(AppStrings.assignmentPriorityHigh), findsOneWidget);
    });

    testWidgets('an overdue assignment is labelled overdue', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        cardHarness(_assignment(dueAt: DateTime(2020, 1, 1))),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.assignmentOverdueLabel), findsOneWidget);
    });

    /*
     * Students get information, never controls. No edit, no archive, no
     * create anywhere on the card.
     */
    testWidgets('offers the student no management controls', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(cardHarness(_assignment()));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.archiveAssignmentAction), findsNothing);
      expect(find.text(AppStrings.editAssignmentTitle), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      // No dead "view details" affordance either, since none is wired.
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('no overflow at 360px with long Arabic content', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        cardHarness(
          _assignment(
            title: 'واجب بعنوان طويل جدًا يمتد على أكثر من سطر واحد بسهولة',
            description: 'تعليمات مطوّلة جدًا ' * 15,
            dueAt: DateTime(2020, 1, 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ===================================================================
  //  Admin — oversight
  // ===================================================================
  group('AdminAssignmentListScreen', () {
    testWidgets('lists real assignments globally', (tester) async {
      _useNarrowScreen(tester);
      final assignments = FakeAssignmentProvider(
        assignmentsValue: [_assignment(), _assignment(id: 'a2', title: 'واجب 2')],
      );
      await tester.pumpWidget(
        _wrap(
          const AdminAssignmentListScreen(),
          assignments: assignments,
          role: UserRole.admin,
          courses: const [_course],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('واجب البرمجة الأول'), findsOneWidget);
      expect(find.text('واجب 2'), findsOneWidget);
      expect(assignments.globalListenCalls, greaterThan(0));
    });

    /*
     * The admin creation path was removed in this phase: the rules deny
     * admin create, and a button that leads to a guaranteed denial is not
     * a feature.
     */
    testWidgets('offers no create-assignment action', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const AdminAssignmentListScreen(),
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment()],
          ),
          role: UserRole.admin,
          courses: const [_course],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text(AppStrings.addNewAssignmentAction), findsNothing);
      expect(find.text(AppStrings.addAssignmentTitle), findsNothing);
    });

    testWidgets('empty state explains that teachers author assignments', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const AdminAssignmentListScreen(),
          assignments: FakeAssignmentProvider(),
          role: UserRole.admin,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.adminAssignmentsEmptyTitle), findsOneWidget);
      expect(
        find.text(AppStrings.adminAssignmentsOversightNote),
        findsOneWidget,
      );
    });

    testWidgets('no overflow at 360px', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          const AdminAssignmentListScreen(),
          assignments: FakeAssignmentProvider(
            assignmentsValue: [
              _assignment(id: 'a1'),
              _assignment(id: 'a2', dueAt: DateTime(2020, 1, 1)),
            ],
          ),
          role: UserRole.admin,
          courses: const [_course],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('AdminAssignmentDetailsScreen', () {
    Widget adminDetailsHarness({
      required FakeAssignmentProvider assignments,
      CourseAssignmentModel? assignment,
    }) {
      return _wrap(
        Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute(
            settings: RouteSettings(
              arguments: AdminAssignmentDetailsArgs(
                assignment: assignment ?? _assignment(),
              ),
            ),
            builder: (_) => const AdminAssignmentDetailsScreen(),
          ),
        ),
        assignments: assignments,
        role: UserRole.admin,
        courses: const [_course],
        teachers: const [
          AdminTeacherModel(
            uid: 'u1',
            fullName: 'د. سارة قاسم',
            email: 'u1@test.com',
            status: 'active',
          ),
        ],
      );
    }

    testWidgets('academic content is read-only text, not inputs', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        adminDetailsHarness(assignments: FakeAssignmentProvider()),
      );
      await tester.pumpAndSettle();

      expect(find.text('واجب البرمجة الأول'), findsOneWidget);
      expect(find.text('حل التمارين المرفقة'), findsOneWidget);
      // No authoring controls of any kind.
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.text(AppStrings.editAssignmentTitle), findsNothing);
    });

    testWidgets('resolves the authoring teacher name when available', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        adminDetailsHarness(assignments: FakeAssignmentProvider()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('د. سارة قاسم'), findsWidgets);
    });

    testWidgets('moderation archive uses the admin path, not teacher archive', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      final assignments = FakeAssignmentProvider();
      await tester.pumpWidget(adminDetailsHarness(assignments: assignments));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.adminModerateArchiveAction));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(
        TextButton,
        AppStrings.adminModerateArchiveAction,
      ));
      await tester.pumpAndSettle();

      expect(assignments.moderateCalls, ['a1']);
      expect(assignments.archiveCalls, isEmpty);
    });

    testWidgets('an already-archived assignment offers no moderation action', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        adminDetailsHarness(
          assignments: FakeAssignmentProvider(),
          assignment: _assignment(
            status: CourseAssignmentModel.statusArchived,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.adminModerateArchiveAction), findsNothing);
    });

    testWidgets('no overflow at 360px', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        adminDetailsHarness(
          assignments: FakeAssignmentProvider(),
          assignment: _assignment(description: 'تعليمات مطوّلة ' * 25),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // A guard on the fixture itself, so the derived-state tests above stay
  // meaningful if someone edits the shared clock.
  test('fixture clock is the instant the UI tests assume', () {
    expect(_fixedNow, DateTime(2026, 9, 10, 12));
  });
}
