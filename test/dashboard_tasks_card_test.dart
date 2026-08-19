import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/dashboard/widgets/today_tasks_card.dart';
import 'package:academia/features/tasks/models/task_model.dart';
import 'package:academia/features/assignments/models/course_assignment_model.dart';
import 'package:academia/features/assignments/providers/course_assignment_provider.dart';
import 'package:academia/features/tasks/providers/task_provider.dart';

// --------------------------------------------------------------- fixtures

/// Fixed reference instant so nothing depends on the wall clock or on a run
/// crossing midnight. 14:00 local on 2026-08-13.
final DateTime _now = DateTime(2026, 8, 13, 14);

TaskModel _task({
  required String id,
  required String title,
  DateTime? dueAt,
  TaskStatus status = TaskStatus.pending,
  TaskPriority priority = TaskPriority.medium,
}) {
  return TaskModel(
    id: id,
    userId: 'student1',
    title: title,
    dueAt: dueAt,
    status: status,
    priority: priority,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );
}

// ------------------------------------------------------------------ fakes

class FakeTaskProvider extends ChangeNotifier implements TaskProvider {
  FakeTaskProvider({
    this.tasksValue = const [],
    this.isLoadingValue = false,
    this.errorValue,
  });

  final List<TaskModel> tasksValue;
  final bool isLoadingValue;
  final String? errorValue;

  @override
  List<TaskModel> get tasks => tasksValue;

  @override
  bool get isLoading => isLoadingValue;

  @override
  String? get errorMessage => errorValue;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RouteRecorder extends NavigatorObserver {
  final List<String?> pushed = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}

/*
 * Phase 8.4: the card now merges personal tasks with academic assignments.
 * Loaded and empty keeps these tests about the task half; assignment
 * behaviour is covered in student_work_item_test and tasks_screen tests.
 */
class FakeAssignmentProvider extends ChangeNotifier
    implements CourseAssignmentProvider {
  FakeAssignmentProvider({
    this.assignmentsValue = const <CourseAssignmentModel>[],
    this.error,
  });

  final List<CourseAssignmentModel> assignmentsValue;
  final String? error;

  @override
  List<CourseAssignmentModel> get assignments => assignmentsValue;

  @override
  List<CourseAssignmentModel> get activeAssignments =>
      assignmentsValue.where((a) => a.isActive).toList();

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => error;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(
  FakeTaskProvider provider, {
  RouteRecorder? recorder,
  FakeAssignmentProvider? assignments,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TaskProvider>.value(value: provider),
      ChangeNotifierProvider<CourseAssignmentProvider>.value(
        value: assignments ?? FakeAssignmentProvider(),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('ar'),
      navigatorObservers: [?recorder],
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => settings.name == Navigator.defaultRouteName
            ? Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: TodayTasksCard(now: _now),
                  ),
                ),
              )
            : const Scaffold(body: Center(child: Text('TASKS-SCREEN-STUB'))),
      ),
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
  // to be established explicitly — the card formats dates with DateFormat(…,
  // 'ar') exactly as TaskCard does.
  setUpAll(() async {
    await initializeDateFormatting('ar', null);
  });

  group('empty state', () {
    testWidgets('zero tasks gives an honest empty state, never "coming soon"', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(FakeTaskProvider()));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.dashboardTasksEmpty), findsOneWidget);
      expect(find.text(AppStrings.dashboardTasksEmptyHint), findsOneWidget);
      expect(find.text(AppStrings.dashboardComingSoonBadge), findsNothing);

      // The route out is still offered when there is nothing to show.
      expect(find.text(AppStrings.dashboardTasksViewAll), findsOneWidget);
    });
  });

  group('counting', () {
    testWidgets('one task due today is shown and counted as one', (
      tester,
    ) async {
      final provider = FakeTaskProvider(
        tasksValue: [
          _task(
            id: 't1',
            title: 'تسليم تقرير التحليل',
            dueAt: DateTime(2026, 8, 13, 18),
          ),
        ],
      );

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('تسليم تقرير التحليل'), findsOneWidget);
      expect(
        find.text(AppStrings.dashboardTasksTodaySummary(1)),
        findsOneWidget,
      );
      // No overdue chip when nothing is overdue.
      expect(
        find.text(AppStrings.dashboardTasksOverdueSummary(1)),
        findsNothing,
      );
    });

    testWidgets('a completed task counts as no work and is not previewed', (
      tester,
    ) async {
      final provider = FakeTaskProvider(
        tasksValue: [
          _task(
            id: 't1',
            title: 'مهمة منجزة',
            dueAt: DateTime(2026, 8, 13, 9),
            status: TaskStatus.completed,
          ),
          // Completed but with a past due date — must not read as overdue.
          _task(
            id: 't2',
            title: 'مهمة منجزة قديمة',
            dueAt: DateTime(2026, 8, 1, 9),
            status: TaskStatus.completed,
          ),
        ],
      );

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('مهمة منجزة'), findsNothing);
      expect(find.text('مهمة منجزة قديمة'), findsNothing);
      expect(find.text(AppStrings.dashboardTasksEmpty), findsOneWidget);
      expect(
        find.text(AppStrings.dashboardTasksOverdueSummary(1)),
        findsNothing,
      );
    });

    testWidgets('a task with no due date is neither today nor overdue', (
      tester,
    ) async {
      final provider = FakeTaskProvider(
        tasksValue: [_task(id: 't1', title: 'مهمة بلا موعد')],
      );

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      // It is pending, but it is not due work — the summary stays honest.
      expect(find.text(AppStrings.dashboardTasksEmpty), findsOneWidget);
      expect(find.text('مهمة بلا موعد'), findsNothing);
      expect(
        find.text(AppStrings.dashboardTasksOverdueSummary(1)),
        findsNothing,
      );
    });
  });

  group('ordering', () {
    testWidgets('overdue comes first, then today, then upcoming', (
      tester,
    ) async {
      final provider = FakeTaskProvider(
        tasksValue: [
          // Deliberately supplied out of order. Titles are chosen not to
          // collide with the card's own chip/summary wording.
          _task(
            id: 'up',
            title: 'قراءة الفصل السابع',
            dueAt: DateTime(2026, 8, 20, 10),
          ),
          _task(
            id: 'today',
            title: 'تسليم تقرير التحليل',
            dueAt: DateTime(2026, 8, 13, 20),
          ),
          _task(
            id: 'late',
            title: 'واجب قواعد البيانات',
            dueAt: DateTime(2026, 8, 10, 10),
          ),
        ],
      );

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      final lateY = tester.getTopLeft(find.text('واجب قواعد البيانات')).dy;
      final todayY = tester.getTopLeft(find.text('تسليم تقرير التحليل')).dy;
      final upcomingY = tester.getTopLeft(find.text('قراءة الفصل السابع')).dy;

      expect(lateY, lessThan(todayY));
      expect(todayY, lessThan(upcomingY));

      // The overdue indicator is visible, and only today's task is counted
      // as due today.
      expect(
        find.text(AppStrings.dashboardTasksOverdueSummary(1)),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.dashboardTasksTodaySummary(1)),
        findsOneWidget,
      );
    });

    testWidgets('the preview is capped, upcoming tasks yielding first', (
      tester,
    ) async {
      final provider = FakeTaskProvider(
        tasksValue: [
          _task(id: 'l1', title: 'متأخرة أولى', dueAt: DateTime(2026, 8, 9)),
          _task(id: 'l2', title: 'متأخرة ثانية', dueAt: DateTime(2026, 8, 10)),
          _task(
            id: 'today',
            title: 'اليوم واحدة',
            dueAt: DateTime(2026, 8, 13, 20),
          ),
          _task(id: 'up', title: 'قادمة بعيدة', dueAt: DateTime(2026, 8, 25)),
        ],
      );

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('متأخرة أولى'), findsOneWidget);
      expect(find.text('متأخرة ثانية'), findsOneWidget);
      expect(find.text('اليوم واحدة'), findsOneWidget);
      // Fourth item exceeds the cap, and upcoming is the lowest priority.
      expect(find.text('قادمة بعيدة'), findsNothing);
      expect(
        find.text(AppStrings.dashboardTasksOverdueSummary(2)),
        findsOneWidget,
      );
    });
  });

  group('provider states', () {
    testWidgets('while loading it shows no fabricated zero', (tester) async {
      await tester.pumpWidget(_wrap(FakeTaskProvider(isLoadingValue: true)));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(AppStrings.dashboardTasksEmpty), findsNothing);
      expect(
        find.text(AppStrings.dashboardTasksTodaySummary(0)),
        findsNothing,
      );
    });

    testWidgets('an error stays inside the card', (tester) async {
      const message = 'تعذر تحميل المهام الدراسية.';
      await tester.pumpWidget(
        _wrap(FakeTaskProvider(errorValue: message)),
      );
      await tester.pumpAndSettle();

      expect(find.text(message), findsOneWidget);

      // The card still renders its header and its way out.
      expect(find.text(AppStrings.dashboardTasksTitle), findsOneWidget);
      expect(find.text(AppStrings.dashboardTasksViewAll), findsOneWidget);

      // No counts are claimed when the data could not be read.
      expect(find.text(AppStrings.dashboardTasksEmpty), findsNothing);
    });
  });

  group('navigation', () {
    testWidgets('"عرض الكل" opens the existing tasks route', (tester) async {
      final recorder = RouteRecorder();
      await tester.pumpWidget(
        _wrap(FakeTaskProvider(), recorder: recorder),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.dashboardTasksViewAll));
      await tester.pumpAndSettle();

      expect(recorder.pushed.last, AppRoutes.tasks);
      expect(find.text('TASKS-SCREEN-STUB'), findsOneWidget);
    });

    testWidgets('tapping the card itself opens the same route', (tester) async {
      final recorder = RouteRecorder();
      await tester.pumpWidget(
        _wrap(
          FakeTaskProvider(
            tasksValue: [
              _task(
                id: 't1',
                title: 'مهمة اليوم',
                dueAt: DateTime(2026, 8, 13, 18),
              ),
            ],
          ),
          recorder: recorder,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('مهمة اليوم'));
      await tester.pumpAndSettle();

      expect(recorder.pushed.last, AppRoutes.tasks);
    });
  });

  group('layout', () {
    testWidgets('no overflow at 360px with a full preview', (tester) async {
      _useNarrowScreen(tester);

      final provider = FakeTaskProvider(
        tasksValue: [
          _task(
            id: 'l1',
            title: 'تسليم تقرير مشروع تحليل وتصميم النظم النهائي الطويل جدًا',
            dueAt: DateTime(2026, 8, 9),
            priority: TaskPriority.high,
          ),
          _task(
            id: 'today',
            title: 'مراجعة محاضرة قواعد البيانات المتقدمة',
            dueAt: DateTime(2026, 8, 13, 20),
          ),
          _task(
            id: 'up',
            title: 'قراءة الفصل السابع',
            dueAt: DateTime(2026, 8, 25),
          ),
        ],
      );

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
