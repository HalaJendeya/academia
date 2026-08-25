import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/analytics/models/analytics_summary.dart';
import 'package:academia/features/analytics/models/study_duration_format.dart';
import 'package:academia/features/analytics/screens/analytics_screen.dart';
import 'package:academia/features/assignments/models/course_assignment_model.dart';
import 'package:academia/features/assignments/providers/assignment_progress_provider.dart';
import 'package:academia/features/assignments/providers/course_assignment_provider.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/models/course_offering_model.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/enrollments/models/enrollment_model.dart';
import 'package:academia/features/study/models/study_session_model.dart';
import 'package:academia/features/study/providers/study_session_provider.dart';
import 'package:academia/features/tasks/models/task_model.dart';
import 'package:academia/features/tasks/providers/task_provider.dart';

/*
 * The analytics screen used to display three constants written into the
 * source — 12 completed tasks, 24 study hours, an 85% "commitment rate" —
 * plus a fabricated weekly trend, an invented 30-hour goal, and a mock
 * course name. Several tests below assert those numbers can no longer
 * appear for data that does not produce them.
 */

// ------------------------------------------------------------------ fixtures

TaskModel _task({required bool done, String id = 't'}) => TaskModel(
  id: id,
  userId: 'student1',
  title: 'مهمة',
  status: done ? TaskStatus.completed : TaskStatus.pending,
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 1),
);

CourseAssignmentModel _assignment({
  required String id,
  String courseId = 'c1',
  String status = CourseAssignmentModel.statusActive,
}) => CourseAssignmentModel(
  id: id,
  offeringId: 'off1',
  courseId: courseId,
  semesterId: 'sem1',
  title: 'واجب',
  dueAt: DateTime(2026, 9, 1),
  status: status,
  createdBy: 'teacher1',
);

StudySessionModel _session({
  required StudySessionStatus status,
  required int actualMinutes,
  String id = 's',
  String? courseId,
}) => StudySessionModel(
  id: id,
  userId: 'student1',
  courseId: courseId,
  offeringId: courseId == null ? null : 'off1',
  plannedMinutes: 60,
  actualMinutes: actualMinutes,
  status: status,
  startedAt: DateTime(2026, 8, 20),
);

StudentCourseView _courseView({String courseId = 'c1', String title = 'قواعد البيانات'}) =>
    StudentCourseView(
      enrollment: EnrollmentModel(
        id: 'student1_off1',
        userId: 'student1',
        offeringId: 'off1',
        courseId: courseId,
        semesterId: 'sem1',
        attemptNumber: 1,
        status: 'active',
        assignedBy: 'admin1',
      ),
      offering: CourseOfferingModel(
        id: 'off1',
        courseId: courseId,
        semesterId: 'sem1',
        section: '1',
        status: 'active',
        instructorName: 'د. مثال',
        createdBy: 'admin1',
      ),
      course: CourseModel(
        id: courseId,
        courseCode: 'BMIS3344',
        title: title,
        description: '',
        creditHours: 3,
        departmentId: 'dep1',
        status: 'active',
      ),
    );

// --------------------------------------------------------------------- fakes

class FakeTaskProvider extends ChangeNotifier implements TaskProvider {
  FakeTaskProvider({this.tasksValue = const [], this.loading = false});
  final List<TaskModel> tasksValue;
  final bool loading;
  @override
  List<TaskModel> get tasks => tasksValue;
  @override
  bool get isLoading => loading;
  @override
  String? get errorMessage => null;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakeAssignmentsProvider extends ChangeNotifier
    implements CourseAssignmentProvider {
  FakeAssignmentsProvider({this.activeValue = const [], this.loading = false});
  final List<CourseAssignmentModel> activeValue;
  final bool loading;
  @override
  List<CourseAssignmentModel> get activeAssignments => activeValue;
  @override
  List<CourseAssignmentModel> get assignments => activeValue;
  @override
  bool get isLoading => loading;
  @override
  String? get errorMessage => null;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakeProgressProvider extends ChangeNotifier
    implements AssignmentProgressProvider {
  FakeProgressProvider({this.completed = const <String>{}});
  final Set<String> completed;
  @override
  Set<String> get completedAssignmentIds => completed;
  @override
  bool isCompleted(String id) => completed.contains(id);
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakeSessionsProvider extends ChangeNotifier
    implements StudySessionProvider {
  FakeSessionsProvider({this.sessionsValue = const [], this.loading = false});
  final List<StudySessionModel> sessionsValue;
  final bool loading;
  @override
  List<StudySessionModel> get sessions => sessionsValue;
  @override
  bool get isLoading => loading;
  @override
  String? get errorMessage => null;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakeCoursesProvider extends ChangeNotifier
    implements StudentCoursesProvider {
  FakeCoursesProvider({this.coursesValue = const []});
  final List<StudentCourseView> coursesValue;
  @override
  List<StudentCourseView> get currentCourses => coursesValue;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget _wrap({
  List<TaskModel> tasks = const [],
  List<CourseAssignmentModel> assignments = const [],
  Set<String> completedAssignments = const <String>{},
  List<StudySessionModel> sessions = const [],
  List<StudentCourseView> courses = const [],
  bool loading = false,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TaskProvider>(
        create: (_) => FakeTaskProvider(tasksValue: tasks, loading: loading),
      ),
      ChangeNotifierProvider<CourseAssignmentProvider>(
        create: (_) =>
            FakeAssignmentsProvider(activeValue: assignments, loading: loading),
      ),
      ChangeNotifierProvider<AssignmentProgressProvider>(
        create: (_) => FakeProgressProvider(completed: completedAssignments),
      ),
      ChangeNotifierProvider<StudySessionProvider>(
        create: (_) =>
            FakeSessionsProvider(sessionsValue: sessions, loading: loading),
      ),
      ChangeNotifierProvider<StudentCoursesProvider>(
        create: (_) => FakeCoursesProvider(coursesValue: courses),
      ),
    ],
    child: const MaterialApp(
      locale: Locale('ar'),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('ar')],
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: AnalyticsScreen(),
      ),
    ),
  );
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  // =============================================================== formulas
  group('AnalyticsSummary', () {
    test('a student with no data gets honest zeros, not an error', () {
      const summary = AnalyticsSummary();

      expect(summary.completedWork, 0);
      expect(summary.studiedMinutes, 0);
      expect(summary.isEmpty, isTrue);
      // No denominator means no percentage at all — not 0%, not 85%.
      expect(summary.completionRate, isNull);
      expect(summary.hasCompletionRate, isFalse);
    });

    test('counts completed personal tasks only', () {
      final summary = AnalyticsSummary.from(
        tasks: [
          _task(done: true, id: 't1'),
          _task(done: true, id: 't2'),
          _task(done: false, id: 't3'),
        ],
        assignments: const [],
        completedAssignmentIds: const <String>{},
        sessions: const [],
      );

      expect(summary.completedTasks, 2);
      expect(summary.totalTasks, 3);
    });

    test('counts completed assignments from the student progress set', () {
      final summary = AnalyticsSummary.from(
        tasks: const [],
        assignments: [_assignment(id: 'a1'), _assignment(id: 'a2')],
        completedAssignmentIds: const {'a1'},
        sessions: const [],
      );

      expect(summary.completedAssignments, 1);
      expect(summary.totalAssignments, 2);
    });

    test('combines both kinds of work into one honest total', () {
      final summary = AnalyticsSummary.from(
        tasks: [_task(done: true, id: 't1'), _task(done: false, id: 't2')],
        assignments: [_assignment(id: 'a1'), _assignment(id: 'a2')],
        completedAssignmentIds: const {'a1', 'a2'},
        sessions: const [],
      );

      expect(summary.completedWork, 3); // 1 task + 2 assignments
      expect(summary.totalWork, 4); // 2 tasks + 2 assignments
    });

    test('a progress mark for a non-active assignment cannot inflate the '
        'numerator above the denominator', () {
      // The student completed an assignment that has since been archived,
      // so it is no longer part of what is required of them.
      final summary = AnalyticsSummary.from(
        tasks: const [],
        assignments: [_assignment(id: 'a1')],
        completedAssignmentIds: const {'a1', 'ghost-archived'},
        sessions: const [],
      );

      expect(summary.completedAssignments, 1);
      expect(summary.completionRate, 1.0);
      expect(summary.completionRate! <= 1.0, isTrue);
    });

    test('study time sums actual minutes of completed sessions only', () {
      final summary = AnalyticsSummary.from(
        tasks: const [],
        assignments: const [],
        completedAssignmentIds: const <String>{},
        sessions: [
          _session(
            id: 's1',
            status: StudySessionStatus.completed,
            actualMinutes: 45,
          ),
          _session(
            id: 's2',
            status: StudySessionStatus.completed,
            actualMinutes: 30,
          ),
        ],
      );

      expect(summary.studiedMinutes, 75);
    });

    test('cancelled sessions contribute nothing', () {
      final summary = AnalyticsSummary.from(
        tasks: const [],
        assignments: const [],
        completedAssignmentIds: const <String>{},
        sessions: [
          _session(
            id: 's1',
            status: StudySessionStatus.completed,
            actualMinutes: 20,
          ),
          _session(
            id: 's2',
            status: StudySessionStatus.cancelled,
            actualMinutes: 999,
          ),
        ],
      );

      expect(summary.studiedMinutes, 20);
    });

    test('an in-progress session does not count until it completes', () {
      final summary = AnalyticsSummary.from(
        tasks: const [],
        assignments: const [],
        completedAssignmentIds: const <String>{},
        sessions: [
          _session(
            id: 's1',
            status: StudySessionStatus.active,
            actualMinutes: 0,
          ),
        ],
      );

      expect(summary.studiedMinutes, 0);
      expect(summary.hasStudyTime, isFalse);
    });

    test('completion rate is mathematically correct', () {
      final summary = AnalyticsSummary.from(
        tasks: [
          _task(done: true, id: 't1'),
          _task(done: false, id: 't2'),
          _task(done: false, id: 't3'),
        ],
        assignments: [_assignment(id: 'a1')],
        completedAssignmentIds: const {'a1'},
        sessions: const [],
      );

      // 2 completed of 4 required.
      expect(summary.completedWork, 2);
      expect(summary.totalWork, 4);
      expect(summary.completionRate, 0.5);
    });

    test('most-studied course is the real maximum by actual minutes', () {
      final summary = AnalyticsSummary.from(
        tasks: const [],
        assignments: const [],
        completedAssignmentIds: const <String>{},
        sessions: [
          _session(
            id: 's1',
            status: StudySessionStatus.completed,
            actualMinutes: 20,
            courseId: 'c1',
          ),
          _session(
            id: 's2',
            status: StudySessionStatus.completed,
            actualMinutes: 50,
            courseId: 'c2',
          ),
          _session(
            id: 's3',
            status: StudySessionStatus.completed,
            actualMinutes: 15,
            courseId: 'c2',
          ),
          // A general session belongs to no course and must not win.
          _session(
            id: 's4',
            status: StudySessionStatus.completed,
            actualMinutes: 300,
          ),
        ],
      );

      expect(summary.mostStudiedCourseId, 'c2');
      expect(summary.mostStudiedCourseMinutes, 65);
      expect(summary.studiedMinutes, 385);
    });

    test('no course-linked session means no most-studied course', () {
      final summary = AnalyticsSummary.from(
        tasks: const [],
        assignments: const [],
        completedAssignmentIds: const <String>{},
        sessions: [
          _session(
            id: 's1',
            status: StudySessionStatus.completed,
            actualMinutes: 40,
          ),
        ],
      );

      expect(summary.hasMostStudiedCourse, isFalse);
    });
  });

  // ============================================================= formatting
  group('StudyDurationFormat', () {
    test('formats Arabic durations naturally', () {
      expect(StudyDurationFormat.format(0), '0 دقيقة');
      expect(StudyDurationFormat.format(45), '45 دقيقة');
      expect(StudyDurationFormat.format(60), 'ساعة');
      expect(StudyDurationFormat.format(90), 'ساعة و30 دقيقة');
      expect(StudyDurationFormat.format(120), 'ساعتان');
      expect(StudyDurationFormat.format(150), 'ساعتان و30 دقيقة');
      expect(StudyDurationFormat.format(180), '3 ساعات');
      expect(StudyDurationFormat.format(195), '3 ساعات و15 دقيقة');
      expect(StudyDurationFormat.format(660), '11 ساعة');
    });

    test('a negative value degrades to zero rather than throwing', () {
      expect(StudyDurationFormat.format(-5), '0 دقيقة');
    });
  });

  // ================================================================= screen
  group('AnalyticsScreen', () {
    testWidgets('a student with no history sees zeros, not the old constants',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The three hardcoded values are gone.
      expect(find.text('12'), findsNothing);
      expect(find.text('24 ساعة'), findsNothing);
      expect(find.text('85%'), findsNothing);
      // And the fabricated badges with them.
      expect(find.textContaining('+3 هذا الأسبوع'), findsNothing);
      expect(find.textContaining('الهدف: 30'), findsNothing);
      expect(find.text('هندسة البرمجيات'), findsNothing);

      expect(find.text('0'), findsOneWidget);
      expect(find.text('0 دقيقة'), findsOneWidget);
      expect(find.text(AppStrings.analyticsNoCompletionRate), findsOneWidget);
    });

    testWidgets('renders real counts from the providers', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _wrap(
          tasks: [
            _task(done: true, id: 't1'),
            _task(done: true, id: 't2'),
            _task(done: false, id: 't3'),
          ],
          assignments: [_assignment(id: 'a1'), _assignment(id: 'a2')],
          completedAssignments: const {'a1'},
          sessions: [
            _session(
              id: 's1',
              status: StudySessionStatus.completed,
              actualMinutes: 90,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // 2 tasks + 1 assignment = 3 completed of 5 required = 60%.
      expect(find.text('3'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('3 ${AppStrings.completionRateOf} 5'), findsOneWidget);
      expect(find.text('ساعة و30 دقيقة'), findsOneWidget);
    });

    testWidgets('cancelled and active sessions are excluded on screen',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _wrap(
          sessions: [
            _session(
              id: 's1',
              status: StudySessionStatus.completed,
              actualMinutes: 60,
            ),
            _session(
              id: 's2',
              status: StudySessionStatus.cancelled,
              actualMinutes: 120,
            ),
            _session(
              id: 's3',
              status: StudySessionStatus.active,
              actualMinutes: 0,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ساعة'), findsOneWidget);
      expect(find.text('3 ساعات'), findsNothing);
    });

    testWidgets('the most-studied course shows its real name and time',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _wrap(
          sessions: [
            _session(
              id: 's1',
              status: StudySessionStatus.completed,
              actualMinutes: 120,
              courseId: 'c1',
            ),
          ],
          courses: [_courseView(title: 'قواعد البيانات')],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('قواعد البيانات'), findsOneWidget);
      expect(find.text(AppStrings.mostStudiedCourseTitle), findsOneWidget);
    });

    testWidgets('the course card is hidden when no session is course-linked',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _wrap(
          sessions: [
            _session(
              id: 's1',
              status: StudySessionStatus.completed,
              actualMinutes: 30,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // No invented course name to fill the space.
      expect(find.text(AppStrings.mostStudiedCourseTitle), findsNothing);
    });

    testWidgets('shows a loading state only while there is nothing to show',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(_wrap(loading: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('zero data is not treated as a loading or error state',
        (tester) async {
      _phone(tester);
      // Providers finished loading and the student genuinely has nothing.
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(AppStrings.analyticsDashboardTitle), findsWidgets);
    });

    testWidgets('no overflow at a 360px viewport with full data',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _wrap(
          tasks: [_task(done: true, id: 't1')],
          assignments: [_assignment(id: 'a1')],
          completedAssignments: const {'a1'},
          sessions: [
            _session(
              id: 's1',
              status: StudySessionStatus.completed,
              actualMinutes: 195,
              courseId: 'c1',
            ),
          ],
          courses: [_courseView(title: 'تحليل وتصميم النظم المتقدمة')],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('no chart with invented data is rendered', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // The only progress bar allowed is the completion rate, and it is
      // absent entirely when there is no denominator.
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });
}
