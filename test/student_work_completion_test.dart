import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/assignments/models/course_assignment_model.dart';
import 'package:academia/features/assignments/providers/assignment_progress_provider.dart';
import 'package:academia/features/assignments/providers/course_assignment_provider.dart';
import 'package:academia/features/assignments/screens/student_assignment_details_screen.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/tasks/models/student_work_item.dart';
import 'package:academia/features/tasks/models/task_model.dart';
import 'package:academia/features/tasks/providers/task_provider.dart';
import 'package:academia/features/tasks/screens/tasks_screen.dart';

// ------------------------------------------------------------------ fakes

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool get isLoggedIn => true;

  @override
  bool get isStudent => true;

  @override
  bool get isTeacher => false;

  @override
  bool get isAdmin => false;

  @override
  bool get isAccountActive => true;

  @override
  AppUserModel? get currentUserProfile => const AppUserModel(
    uid: 'student1',
    fullName: 'حلا',
    email: 's@test.com',
    role: UserRole.student,
    status: 'active',
    emailVerified: true,
    onboardingCompleted: true,
    onboardingStatus: 'completed',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStudentCoursesProvider extends ChangeNotifier
    implements StudentCoursesProvider {
  @override
  List<StudentCourseView> get currentCourses => const <StudentCourseView>[];

  @override
  List<StudentCourseView> get history => const <StudentCourseView>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTaskProvider extends ChangeNotifier implements TaskProvider {
  FakeTaskProvider({this.tasksValue = const <TaskModel>[]});

  final List<TaskModel> tasksValue;

  @override
  List<TaskModel> get tasks => tasksValue;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAssignmentProvider extends ChangeNotifier
    implements CourseAssignmentProvider {
  FakeAssignmentProvider({this.assignmentsValue = const <CourseAssignmentModel>[]});

  final List<CourseAssignmentModel> assignmentsValue;

  @override
  List<CourseAssignmentModel> get assignments => assignmentsValue;

  @override
  List<CourseAssignmentModel> get activeAssignments =>
      assignmentsValue.where((a) => a.isActive).toList();

  @override
  List<CourseAssignmentModel> get selectedAssignments => assignmentsValue;

  @override
  List<CourseAssignmentModel> get activeSelectedAssignments =>
      assignmentsValue.where((a) => a.isActive).toList();

  @override
  bool get isLoading => false;

  @override
  bool get isLoadingSelected => false;

  @override
  String? get errorMessage => null;

  @override
  String? get selectedErrorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProgressProvider extends ChangeNotifier
    implements AssignmentProgressProvider {
  FakeProgressProvider({
    Set<String>? completed,
    Map<String, DateTime?>? times,
  }) : completed = completed ?? <String>{},
       times = times ?? <String, DateTime?>{};

  final Set<String> completed;
  final Map<String, DateTime?> times;

  /// Simulates the live stream reacting to an undo written elsewhere —
  /// from the details screen, say — without going through Firestore.
  void undo(String assignmentId) {
    completed.remove(assignmentId);
    times.remove(assignmentId);
    notifyListeners();
  }

  @override
  Set<String> get completedAssignmentIds => completed;

  @override
  Map<String, DateTime?> get completionTimes => times;

  @override
  bool isCompleted(String assignmentId) => completed.contains(assignmentId);

  @override
  DateTime? completedAt(String assignmentId) => times[assignmentId];

  @override
  bool isSaving(String assignmentId) => false;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --------------------------------------------------------------- fixtures

final _now = DateTime.now();

CourseAssignmentModel _assignment({
  String id = 'a1',
  String title = 'واجب أكاديمي',
  DateTime? dueAt,
  String status = CourseAssignmentModel.statusActive,
  String priority = CourseAssignmentModel.priorityHigh,
}) {
  return CourseAssignmentModel(
    id: id,
    offeringId: 'off1',
    courseId: 'c1',
    semesterId: 'semester_2026_1',
    title: title,
    description: 'تعليمات',
    dueAt: dueAt ?? DateTime(2030, 9, 20, 23, 59),
    priority: priority,
    status: status,
    createdBy: 'teacher1',
  );
}

TaskModel _task({
  String id = 't1',
  String title = 'مهمة شخصية',
  TaskStatus status = TaskStatus.pending,
  DateTime? completedAt,
}) {
  return TaskModel(
    id: id,
    userId: 'student1',
    title: title,
    dueAt: DateTime(2030, 9, 20),
    status: status,
    createdAt: _now,
    updatedAt: _now,
    completedAt: completedAt,
  );
}

// ----------------------------------------------------------------- harness

Widget _wrapTasks({
  List<TaskModel> tasks = const <TaskModel>[],
  List<CourseAssignmentModel> assignments = const <CourseAssignmentModel>[],
  Set<String> completed = const <String>{},
  Map<String, DateTime?> times = const <String, DateTime?>{},
  FakeProgressProvider? progress,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
      ChangeNotifierProvider<StudentCoursesProvider>(
        create: (_) => FakeStudentCoursesProvider(),
      ),
      ChangeNotifierProvider<TaskProvider>.value(
        value: FakeTaskProvider(tasksValue: tasks),
      ),
      ChangeNotifierProvider<CourseAssignmentProvider>.value(
        value: FakeAssignmentProvider(assignmentsValue: assignments),
      ),
      ChangeNotifierProvider<AssignmentProgressProvider>.value(
        value:
            progress ??
            FakeProgressProvider(
              completed: {...completed},
              times: {...times},
            ),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar')],
      routes: {
        AppRoutes.assignmentDetails: (_) =>
            const StudentAssignmentDetailsScreen(),
        AppRoutes.taskDetail: (_) => const Scaffold(body: Text('task-detail')),
        AppRoutes.createEditTask: (_) =>
            const Scaffold(body: Text('create-task')),
      },
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: TasksScreen(),
      ),
    ),
  );
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
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
  setUpAll(() async {
    await initializeDateFormatting('ar', null);
  });

  // ------------------------------------------------------ the view model

  group('StudentWorkItem completion', () {
    test('an assignment is complete only when the mark says so', () {
      final assignment = _assignment();

      expect(StudentWorkItem.fromAssignment(assignment).isCompleted, isFalse);
      expect(
        StudentWorkItem.fromAssignment(assignment, isCompleted: true)
            .isCompleted,
        isTrue,
      );
    });

    /*
     * The whole point of the design. The SAME assignment object is shared
     * by both students; only the injected mark differs, because the mark
     * lives in a per-student document and never on the assignment.
     */
    test('one student completion does not affect another student', () {
      final shared = _assignment();

      final forStudentA = StudentWorkItem.merge(
        tasks: const <TaskModel>[],
        assignments: [shared],
        openOnly: false,
        completedAssignmentIds: const {'a1'},
      ).single;

      final forStudentB = StudentWorkItem.merge(
        tasks: const <TaskModel>[],
        assignments: [shared],
        openOnly: false,
        completedAssignmentIds: const <String>{},
      ).single;

      expect(forStudentA.isCompleted, isTrue);
      expect(forStudentB.isCompleted, isFalse);
      expect(forStudentA.isOpen, isFalse);
      expect(forStudentB.isOpen, isTrue);

      // Both read the very same underlying document.
      expect(identical(forStudentA.assignment, forStudentB.assignment), isTrue);
    });

    test('marking complete does not mutate the assignment document', () {
      final assignment = _assignment(dueAt: DateTime(2020, 1, 1));

      StudentWorkItem.merge(
        tasks: const <TaskModel>[],
        assignments: [assignment],
        openOnly: false,
        completedAssignmentIds: const {'a1'},
      );

      // The teacher-owned fields are exactly as they were.
      expect(assignment.status, CourseAssignmentModel.statusActive);
      expect(assignment.dueAt, DateTime(2020, 1, 1));
      expect(assignment.priority, CourseAssignmentModel.priorityHigh);
      expect(assignment.isActive, isTrue);
      // And the model's own notion of overdue is untouched: that describes
      // the deadline, not the student.
      expect(assignment.isOverdue(), isTrue);
    });

    test('a completed assignment stops counting as overdue work', () {
      final overdue = _assignment(dueAt: DateTime(2020, 1, 1));

      final open = StudentWorkItem.fromAssignment(overdue);
      final done = StudentWorkItem.fromAssignment(overdue, isCompleted: true);

      expect(open.isOverdue(), isTrue);
      expect(open.urgencyRank(), 0);

      expect(done.isOverdue(), isFalse);
      expect(done.isDueToday(), isFalse);
      expect(done.urgencyRank(), isNot(0));
      expect(done.isOpen, isFalse);
    });

    test('completed work is dropped from the open list and kept otherwise', () {
      final assignments = [
        _assignment(id: 'a1', title: 'واجب منجَز'),
        _assignment(id: 'a2', title: 'واجب قائم'),
      ];

      final open = StudentWorkItem.merge(
        tasks: const <TaskModel>[],
        assignments: assignments,
        completedAssignmentIds: const {'a1'},
      );
      expect(open.map((i) => i.title), ['واجب قائم']);

      final all = StudentWorkItem.merge(
        tasks: const <TaskModel>[],
        assignments: assignments,
        openOnly: false,
        completedAssignmentIds: const {'a1'},
      );
      expect(all, hasLength(2));
      expect(all.where((i) => i.isCompleted).map((i) => i.title), [
        'واجب منجَز',
      ]);
    });

    test('a completed personal task and assignment behave the same way', () {
      final doneTask = StudentWorkItem.fromTask(
        _task(status: TaskStatus.completed, completedAt: DateTime(2026, 8, 1)),
      );
      final doneAssignment = StudentWorkItem.fromAssignment(
        _assignment(),
        isCompleted: true,
        completedAt: DateTime(2026, 8, 2),
      );

      for (final item in [doneTask, doneAssignment]) {
        expect(item.isCompleted, isTrue);
        expect(item.isOpen, isFalse);
        expect(item.isOverdue(), isFalse);
        expect(item.completedAt, isNotNull);
      }
    });
  });

  // ----------------------------------------------------------- the screen

  group('tasks screen reflects completion', () {
    testWidgets('a completed assignment leaves the الكل tab', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapTasks(
          assignments: [
            _assignment(id: 'a1', title: 'واجب منجَز'),
            _assignment(id: 'a2', title: 'واجب قائم'),
          ],
          completed: const {'a1'},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('واجب قائم'), findsOneWidget);
      expect(find.text('واجب منجَز'), findsNothing);
    });

    /*
     * This tab is the student's academic record, not a to-do list: it
     * answers "what was set for me this term", and finishing something
     * does not change that answer. Only الكل drops completed work.
     */
    testWidgets('a completed assignment STAYS in the الواجبات tab', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapTasks(
          assignments: [
            _assignment(id: 'a1', title: 'واجب منجَز'),
            _assignment(id: 'a2', title: 'واجب قائم'),
          ],
          completed: const {'a1'},
        ),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabAssignments);

      expect(find.text('واجب قائم'), findsOneWidget);
      expect(find.text('واجب منجَز'), findsOneWidget);
    });

    testWidgets('it carries the مُنجَز state, not an overdue one', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapTasks(
          assignments: [
            _assignment(
              id: 'a1',
              title: 'واجب منجَز',
              dueAt: DateTime(2020, 1, 1),
            ),
          ],
          completed: const {'a1'},
        ),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabAssignments);

      expect(find.text(AppStrings.assignmentCompletedBadge), findsOneWidget);
      // Months overdue, but the student finished it.
      expect(find.text(AppStrings.assignmentOverdueLabel), findsNothing);

      // Everything a student reads about the assignment is still there.
      expect(find.text('واجب منجَز'), findsOneWidget);
      expect(find.text(AppStrings.assignmentPriorityHigh), findsOneWidget);
      expect(find.text(AppStrings.viewDetailsAction), findsOneWidget);
    });

    testWidgets('undoing the mark restores the normal assignment state', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      final progress = FakeProgressProvider(
        completed: {'a1'},
        times: {'a1': DateTime(2026, 8, 20)},
      );

      await tester.pumpWidget(
        _wrapTasks(
          assignments: [
            _assignment(
              id: 'a1',
              title: 'واجب منجَز',
              dueAt: DateTime(2020, 1, 1),
            ),
          ],
          progress: progress,
        ),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabAssignments);
      expect(find.text(AppStrings.assignmentCompletedBadge), findsOneWidget);

      // The undo lands from the details screen; the tab follows the stream.
      progress.undo('a1');
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.assignmentCompletedBadge), findsNothing);
      expect(find.text(AppStrings.assignmentOverdueLabel), findsOneWidget);
      expect(find.text('واجب منجَز'), findsOneWidget);

      // And it is open work again, so الكل takes it back.
      await _openTab(tester, AppStrings.workTabAll);
      expect(find.text('واجب منجَز'), findsOneWidget);
    });

    testWidgets('it appears in مكتملة instead, marked as done', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapTasks(
          assignments: [
            _assignment(
              id: 'a1',
              title: 'واجب منجَز',
              dueAt: DateTime(2020, 1, 1),
            ),
          ],
          completed: const {'a1'},
          times: {'a1': DateTime(2026, 8, 20)},
        ),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabCompleted);

      expect(find.text('واجب منجَز'), findsOneWidget);
      expect(find.text(AppStrings.assignmentCompletedBadge), findsOneWidget);
      /*
       * It is months past its deadline, but the student finished it. Still
       * calling it late would be asking for work already done.
       */
      expect(find.text(AppStrings.assignmentOverdueLabel), findsNothing);
    });

    testWidgets('مكتملة shows completed tasks and assignments together', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapTasks(
          tasks: [
            _task(
              id: 't1',
              title: 'مهمة منجَزة',
              status: TaskStatus.completed,
              completedAt: DateTime(2026, 8, 19),
            ),
            _task(id: 't2', title: 'مهمة قائمة'),
          ],
          assignments: [_assignment(id: 'a1', title: 'واجب منجَز')],
          completed: const {'a1'},
          times: {'a1': DateTime(2026, 8, 20)},
        ),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabCompleted);

      expect(find.text('مهمة منجَزة'), findsOneWidget);
      expect(find.text('واجب منجَز'), findsOneWidget);
      // Unfinished work stays out of this tab.
      expect(find.text('مهمة قائمة'), findsNothing);
    });

    testWidgets('an empty مكتملة says both sources will appear there', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapTasks(assignments: [_assignment()]),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabCompleted);

      expect(find.text(AppStrings.workEmptyCompletedTitle), findsOneWidget);
    });

    /*
     * The regression this guards: a student who finished everything used
     * to see "no assignments" in this tab, which reads as "none were ever
     * set". الكل goes quiet instead, which is the tab that should.
     */
    testWidgets('finishing everything leaves الواجبات full and الكل empty', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapTasks(
          assignments: [
            _assignment(id: 'a1', title: 'واجب أول'),
            _assignment(id: 'a2', title: 'واجب ثانٍ'),
          ],
          completed: const {'a1', 'a2'},
        ),
      );
      await tester.pumpAndSettle();

      // الكل: nothing left needing attention.
      expect(find.text(AppStrings.workEmptyAllTitle), findsOneWidget);

      await _openTab(tester, AppStrings.workTabAssignments);
      expect(find.text(AppStrings.workEmptyAssignmentsTitle), findsNothing);
      expect(find.text('واجب أول'), findsOneWidget);
      expect(find.text('واجب ثانٍ'), findsOneWidget);
      expect(
        find.text(AppStrings.assignmentCompletedBadge),
        findsNWidgets(2),
      );

      // And both are in مكتملة as well.
      await _openTab(tester, AppStrings.workTabCompleted);
      expect(find.text('واجب أول'), findsOneWidget);
      expect(find.text('واجب ثانٍ'), findsOneWidget);
    });

    testWidgets('an empty الواجبات now means none were ever set', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrapTasks());
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabAssignments);

      expect(find.text(AppStrings.workEmptyAssignmentsTitle), findsOneWidget);
    });

    /*
     * A student with no completion marks must see exactly what they saw
     * before the feature existed.
     */
    testWidgets('no marks means unchanged behaviour', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapTasks(
          assignments: [
            _assignment(id: 'a1', title: 'واجب أول'),
            _assignment(id: 'a2', title: 'واجب ثانٍ'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('واجب أول'), findsOneWidget);
      expect(find.text('واجب ثانٍ'), findsOneWidget);
      expect(find.text(AppStrings.assignmentCompletedBadge), findsNothing);
    });
  });
}
