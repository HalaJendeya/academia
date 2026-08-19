import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/assignments/models/course_assignment_model.dart';
import 'package:academia/features/assignments/providers/course_assignment_provider.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
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
  List<StudentCourseView> get currentCourses => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTaskProvider extends ChangeNotifier implements TaskProvider {
  FakeTaskProvider({
    this.tasksValue = const <TaskModel>[],
    this.loading = false,
    this.error,
  });

  final List<TaskModel> tasksValue;
  final bool loading;
  final String? error;

  @override
  List<TaskModel> get tasks => tasksValue;

  @override
  bool get isLoading => loading;

  @override
  String? get errorMessage => error;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAssignmentProvider extends ChangeNotifier
    implements CourseAssignmentProvider {
  FakeAssignmentProvider({
    this.assignmentsValue = const <CourseAssignmentModel>[],
    this.loading = false,
    this.error,
  });

  final List<CourseAssignmentModel> assignmentsValue;
  final bool loading;
  final String? error;

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --------------------------------------------------------------- fixtures

final _now = DateTime.now();

TaskModel _task({
  String id = 't1',
  String title = 'مهمة شخصية',
  DateTime? dueAt,
  TaskStatus status = TaskStatus.pending,
}) {
  return TaskModel(
    id: id,
    userId: 'student1',
    title: title,
    dueAt: dueAt,
    status: status,
    createdAt: _now,
    updatedAt: _now,
  );
}

CourseAssignmentModel _assignment({
  String id = 'a1',
  String title = 'واجب أكاديمي',
  DateTime? dueAt,
  String status = CourseAssignmentModel.statusActive,
}) {
  return CourseAssignmentModel(
    id: id,
    offeringId: 'off1',
    courseId: 'c1',
    semesterId: 'semester_2026_1',
    title: title,
    description: 'تعليمات',
    dueAt: dueAt ?? DateTime(2030, 9, 20),
    status: status,
    createdBy: 'teacher1',
  );
}

// ----------------------------------------------------------------- harness

Widget _wrap({
  FakeTaskProvider? tasks,
  FakeAssignmentProvider? assignments,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
      ChangeNotifierProvider<StudentCoursesProvider>(
        create: (_) => FakeStudentCoursesProvider(),
      ),
      ChangeNotifierProvider<TaskProvider>.value(
        value: tasks ?? FakeTaskProvider(),
      ),
      ChangeNotifierProvider<CourseAssignmentProvider>.value(
        value: assignments ?? FakeAssignmentProvider(),
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

  group('unified screen structure', () {
    testWidgets('shows the four source tabs', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.tasksAndAssignmentsTitle), findsOneWidget);
      expect(find.text(AppStrings.workTabAll), findsOneWidget);
      expect(find.text(AppStrings.workTabAssignments), findsWidgets);
      expect(find.text(AppStrings.workTabMyTasks), findsOneWidget);
      expect(find.text(AppStrings.workTabCompleted), findsOneWidget);
    });
  });

  // ===================================================================
  //  الكل
  // ===================================================================
  group('الكل tab', () {
    testWidgets('shows both a personal task and an academic assignment', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          tasks: FakeTaskProvider(tasksValue: [_task()]),
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مهمة شخصية'), findsOneWidget);
      expect(find.text('واجب أكاديمي'), findsOneWidget);
    });

    testWidgets('excludes completed tasks and archived assignments', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          tasks: FakeTaskProvider(
            tasksValue: [
              _task(id: 'open', title: 'مهمة مفتوحة'),
              _task(
                id: 'done',
                title: 'مهمة منتهية',
                status: TaskStatus.completed,
              ),
            ],
          ),
          assignments: FakeAssignmentProvider(
            assignmentsValue: [
              _assignment(id: 'live', title: 'واجب نشط'),
              _assignment(
                id: 'arch',
                title: 'واجب مؤرشف',
                status: CourseAssignmentModel.statusArchived,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مهمة مفتوحة'), findsOneWidget);
      expect(find.text('واجب نشط'), findsOneWidget);
      expect(find.text('مهمة منتهية'), findsNothing);
      expect(find.text('واجب مؤرشف'), findsNothing);
    });

    /*
     * Claiming "nothing due" while assignments are still arriving would be
     * a false statement, not merely a slow one.
     */
    testWidgets('waits for BOTH sources before claiming emptiness', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          tasks: FakeTaskProvider(),
          assignments: FakeAssignmentProvider(loading: true),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text(AppStrings.workEmptyAllTitle), findsNothing);
    });

    testWidgets('empty state when both sources are loaded and empty', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.workEmptyAllTitle), findsOneWidget);
    });

    testWidgets('an assignment failure still shows personal tasks', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          tasks: FakeTaskProvider(tasksValue: [_task()]),
          assignments: FakeAssignmentProvider(
            error: AppStrings.courseAssignmentsLoadError,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مهمة شخصية'), findsOneWidget);
      expect(
        find.text(AppStrings.workAssignmentsUnavailableNote),
        findsOneWidget,
      );
    });

    testWidgets('a task failure still shows assignments', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          tasks: FakeTaskProvider(error: 'تعذر تحميل المهام'),
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('واجب أكاديمي'), findsOneWidget);
      expect(find.text(AppStrings.workTasksUnavailableNote), findsOneWidget);
    });

    testWidgets('orders overdue work before upcoming work', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          tasks: FakeTaskProvider(
            tasksValue: [
              _task(
                id: 'later',
                title: 'مهمة قادمة',
                dueAt: DateTime(2030, 1, 1),
              ),
            ],
          ),
          assignments: FakeAssignmentProvider(
            assignmentsValue: [
              _assignment(
                id: 'late',
                title: 'واجب متأخر',
                dueAt: DateTime(2020, 1, 1),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overdueY = tester.getTopLeft(find.text('واجب متأخر')).dy;
      final upcomingY = tester.getTopLeft(find.text('مهمة قادمة')).dy;
      expect(overdueY, lessThan(upcomingY));
    });

    testWidgets('no overflow at 360px with mixed long Arabic content', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          tasks: FakeTaskProvider(
            tasksValue: [
              _task(
                title: 'مهمة شخصية بعنوان طويل جدًا يمتد على أكثر من سطر',
                dueAt: DateTime(2020, 1, 1),
              ),
            ],
          ),
          assignments: FakeAssignmentProvider(
            assignmentsValue: [
              _assignment(
                title: 'واجب أكاديمي بعنوان طويل جدًا لاختبار التفاف النص',
                dueAt: DateTime(2020, 1, 1),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ===================================================================
  //  الواجبات
  // ===================================================================
  group('الواجبات tab', () {
    testWidgets('shows assignments only, never personal tasks', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          tasks: FakeTaskProvider(tasksValue: [_task()]),
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment()],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabAssignments);

      expect(find.text('واجب أكاديمي'), findsOneWidget);
      expect(find.text('مهمة شخصية'), findsNothing);
    });

    testWidgets('empty state is assignment-specific', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabAssignments);

      expect(
        find.text(AppStrings.workEmptyAssignmentsTitle),
        findsOneWidget,
      );
    });

    testWidgets('surfaces a load failure', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          assignments: FakeAssignmentProvider(
            error: AppStrings.courseAssignmentsLoadError,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabAssignments);

      expect(
        find.text(AppStrings.courseAssignmentsLoadError),
        findsOneWidget,
      );
    });

    /*
     * Assignments are teacher-authored; the student may read them and
     * nothing else. No create affordance is offered on this tab.
     */
    testWidgets('offers no create action on the assignments tab', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment()],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabAssignments);

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('exposes no edit, archive or completion controls', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment()],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabAssignments);

      expect(find.text(AppStrings.archiveAssignmentAction), findsNothing);
      expect(find.text(AppStrings.editAssignmentTitle), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });
  });

  // ===================================================================
  //  مهامي
  // ===================================================================
  group('مهامي tab', () {
    testWidgets('shows pending personal tasks only', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          tasks: FakeTaskProvider(
            tasksValue: [
              _task(id: 'p', title: 'مهمة معلّقة'),
              _task(
                id: 'd',
                title: 'مهمة مكتملة',
                status: TaskStatus.completed,
              ),
            ],
          ),
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment()],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabMyTasks);

      expect(find.text('مهمة معلّقة'), findsOneWidget);
      expect(find.text('مهمة مكتملة'), findsNothing);
      expect(find.text('واجب أكاديمي'), findsNothing);
    });

    testWidgets('keeps the create-task action available', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(tasks: FakeTaskProvider(tasksValue: [_task()])),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabMyTasks);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('create-task'), findsOneWidget);
    });

    testWidgets('task detail navigation still works', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(tasks: FakeTaskProvider(tasksValue: [_task()])),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabMyTasks);

      await tester.tap(find.text('مهمة شخصية'));
      await tester.pumpAndSettle();

      expect(find.text('task-detail'), findsOneWidget);
    });
  });

  // ===================================================================
  //  مكتملة
  // ===================================================================
  group('مكتملة tab', () {
    testWidgets('shows completed personal tasks', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          tasks: FakeTaskProvider(
            tasksValue: [
              _task(
                id: 'd',
                title: 'مهمة منجزة',
                status: TaskStatus.completed,
              ),
              _task(id: 'p', title: 'مهمة معلّقة'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabCompleted);

      expect(find.text('مهمة منجزة'), findsOneWidget);
      expect(find.text('مهمة معلّقة'), findsNothing);
    });

    /*
     * The product constraint, asserted so it cannot drift: there is no
     * per-student assignment completion state anywhere in the system, so
     * no assignment may ever appear here — and the screen says why.
     */
    testWidgets('never shows academic assignments, and explains why', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          tasks: FakeTaskProvider(
            tasksValue: [
              _task(id: 'd', title: 'مهمة منجزة', status: TaskStatus.completed),
            ],
          ),
          assignments: FakeAssignmentProvider(
            assignmentsValue: [
              _assignment(),
              _assignment(
                id: 'arch',
                title: 'واجب مؤرشف',
                status: CourseAssignmentModel.statusArchived,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabCompleted);

      expect(find.text('واجب أكاديمي'), findsNothing);
      expect(find.text('واجب مؤرشف'), findsNothing);
      expect(
        find.text(AppStrings.workCompletedTasksOnlyNote),
        findsOneWidget,
      );
    });

    testWidgets('empty state is completion-specific', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabCompleted);

      expect(find.text(AppStrings.workEmptyCompletedTitle), findsOneWidget);
    });

    testWidgets('no overflow at 360px', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          tasks: FakeTaskProvider(
            tasksValue: [
              _task(
                id: 'd',
                title: 'مهمة منجزة بعنوان طويل جدًا يمتد على أكثر من سطر واحد',
                status: TaskStatus.completed,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, AppStrings.workTabCompleted);

      expect(tester.takeException(), isNull);
    });
  });
}
