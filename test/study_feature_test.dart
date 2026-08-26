import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/analytics/screens/weekly_summary_screen.dart';
import 'package:academia/features/assignments/providers/assignment_progress_provider.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/models/course_offering_model.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/enrollments/models/enrollment_model.dart';
import 'package:academia/features/profile/models/study_preferences.dart';
import 'package:academia/features/profile/providers/study_preferences_provider.dart';
import 'package:academia/features/study/models/study_history_summary.dart';
import 'package:academia/features/study/models/study_session_model.dart';
import 'package:academia/features/study/models/study_week.dart';
import 'package:academia/features/study/models/weekly_study_summary.dart';
import 'package:academia/features/study/providers/study_session_provider.dart';
import 'package:academia/features/study/screens/create_study_session_screen.dart';
import 'package:academia/features/study/screens/session_complete_screen.dart';
import 'package:academia/features/study/screens/session_history_screen.dart';
import 'package:academia/features/study/screens/study_plan_screen.dart';
import 'package:academia/features/study/services/study_session_service.dart';
import 'package:academia/features/study/widgets/study_session_card.dart';
import 'package:academia/features/tasks/models/task_model.dart';
import 'package:academia/features/tasks/providers/task_provider.dart';

// ------------------------------------------------------------------ fakes

class FakeService implements StudySessionService {
  final controllers = <StreamController<List<StudySessionModel>>>[];
  final startCalls = <Map<String, dynamic>>[];
  final closeCalls = <Map<String, dynamic>>[];
  final reflectionCalls = <Map<String, String>>[];

  StreamController<List<StudySessionModel>> get controller => controllers.last;

  @override
  Stream<List<StudySessionModel>> watchUserSessions(String userId) {
    final c = StreamController<List<StudySessionModel>>();
    controllers.add(c);
    return c.stream;
  }

  @override
  Future<String> startSession({
    required String userId,
    required int plannedMinutes,
    String? offeringId,
    String? courseId,
    String? sessionName,
    String? goal,
  }) async {
    startCalls.add({
      'plannedMinutes': plannedMinutes,
      'offeringId': offeringId,
      'courseId': courseId,
      'sessionName': sessionName,
      'goal': goal,
    });
    return 'session1';
  }

  @override
  Future<void> closeSession({
    required String sessionId,
    required StudySessionStatus status,
    required int actualMinutes,
  }) async {
    closeCalls.add({'status': status, 'actualMinutes': actualMinutes});
  }

  @override
  Future<void> saveReflection({
    required String sessionId,
    required String reflection,
  }) async {
    reflectionCalls.add({'sessionId': sessionId, 'reflection': reflection});
  }

  Future<void> closeAll() async {
    for (final c in controllers) {
      if (c.hasListener) await c.close();
    }
  }
}

class FakePrefs extends ChangeNotifier implements StudyPreferencesProvider {
  FakePrefs({this.minutes = 45});
  final int minutes;
  @override
  StudyPreferences? get preferences =>
      StudyPreferences(studyDays: const ['الأحد'], preferredSessionDuration: minutes);
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  bool get isSaving => false;
  @override
  bool get hasUnsavedChanges => false;
  @override
  Future<void> loadPreferences({bool forceRefresh = false}) async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakeCourses extends ChangeNotifier implements StudentCoursesProvider {
  FakeCourses({this.list = const []});
  final List<StudentCourseView> list;
  @override
  List<StudentCourseView> get currentCourses => list;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakeTasks extends ChangeNotifier implements TaskProvider {
  FakeTasks({this.list = const []});
  final List<TaskModel> list;
  @override
  List<TaskModel> get tasks => list;
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakeProgress extends ChangeNotifier
    implements AssignmentProgressProvider {
  FakeProgress({this.times = const {}});
  final Map<String, DateTime?> times;
  @override
  Map<String, DateTime?> get completionTimes => times;
  @override
  Set<String> get completedAssignmentIds => times.keys.toSet();
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// --------------------------------------------------------------- fixtures

StudySessionModel _session({
  String id = 's1',
  StudySessionStatus status = StudySessionStatus.completed,
  int actual = 45,
  int planned = 45,
  String? courseId,
  DateTime? at,
  String? name,
  String? goal,
}) => StudySessionModel(
  id: id,
  userId: 'student1',
  courseId: courseId,
  offeringId: courseId == null ? null : 'off1',
  sessionName: name,
  goal: goal,
  plannedMinutes: planned,
  actualMinutes: actual,
  status: status,
  startedAt: at ?? DateTime(2026, 8, 20, 10),
);

StudentCourseView _course({String id = 'c1', String title = 'قواعد البيانات'}) =>
    StudentCourseView(
      enrollment: EnrollmentModel(
        id: 'student1_off1',
        userId: 'student1',
        offeringId: 'off1',
        courseId: id,
        semesterId: 'sem1',
        attemptNumber: 1,
        status: 'active',
        assignedBy: 'admin1',
      ),
      offering: CourseOfferingModel(
        id: 'off1',
        courseId: id,
        semesterId: 'sem1',
        section: '1',
        status: 'active',
        instructorName: 'د. مثال',
        createdBy: 'admin1',
      ),
      course: CourseModel(
        id: id,
        courseCode: 'BMIS3344',
        title: title,
        description: '',
        creditHours: 3,
        departmentId: 'dep1',
        status: 'active',
      ),
    );

TaskModel _task({required bool done, DateTime? completedAt, DateTime? due}) =>
    TaskModel(
      id: 't${completedAt?.day ?? due?.day ?? 0}',
      userId: 'student1',
      title: 'مهمة',
      dueAt: due,
      status: done ? TaskStatus.completed : TaskStatus.pending,
      completedAt: completedAt,
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );

Widget _wrap(Widget child, {
  required StudySessionProvider sessions,
  List<StudentCourseView> courses = const [],
  List<TaskModel> tasks = const [],
  Map<String, DateTime?> progress = const {},
  int prefMinutes = 45,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<StudyPreferencesProvider>(
        create: (_) => FakePrefs(minutes: prefMinutes),
      ),
      ChangeNotifierProvider<StudentCoursesProvider>(
        create: (_) => FakeCourses(list: courses),
      ),
      ChangeNotifierProvider<TaskProvider>(create: (_) => FakeTasks(list: tasks)),
      ChangeNotifierProvider<AssignmentProgressProvider>(
        create: (_) => FakeProgress(times: progress),
      ),
      ChangeNotifierProvider<StudySessionProvider>.value(value: sessions),
    ],
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar')],
      // Stub destinations: these tests assert what each screen writes and
      // renders, not what the next screen looks like.
      routes: {
        AppRoutes.activeStudySession: (_) =>
            const Scaffold(body: Text('timer-route')),
        AppRoutes.createStudySession: (_) =>
            const Scaffold(body: Text('create-route')),
        AppRoutes.sessionComplete: (_) =>
            const Scaffold(body: Text('complete-route')),
      },
      home: Directionality(textDirection: TextDirection.rtl, child: child),
    ),
  );
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(402, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _reference(WidgetTester tester) {
  // 402x874 — the Figma artboard size.
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  // ============================================================ week maths
  group('StudyWeek', () {
    test('the week runs Saturday to Friday, matching study-day order', () {
      // Tuesday 2026-08-25.
      final week = StudyWeek.containing(DateTime(2026, 8, 25, 13));
      expect(week.start, DateTime(2026, 8, 22)); // Saturday
      expect(week.lastDay, DateTime(2026, 8, 28)); // Friday
      expect(week.contains(DateTime(2026, 8, 22)), isTrue);
      expect(week.contains(DateTime(2026, 8, 28, 23, 59)), isTrue);
      expect(week.contains(DateTime(2026, 8, 29)), isFalse);
      expect(week.contains(DateTime(2026, 8, 21, 23, 59)), isFalse);
    });

    test('a Saturday belongs to the week it opens', () {
      final week = StudyWeek.containing(DateTime(2026, 8, 22, 8));
      expect(week.start, DateTime(2026, 8, 22));
    });

    test('the previous week is the seven days before', () {
      final week = StudyWeek.containing(DateTime(2026, 8, 25));
      expect(week.previous.start, DateTime(2026, 8, 15));
      expect(week.previous.end, DateTime(2026, 8, 22));
    });
  });

  // ======================================================= weekly summary
  group('WeeklyStudySummary', () {
    final now = DateTime(2026, 8, 25, 12); // Tuesday
    final inWeek = DateTime(2026, 8, 24, 9); // Monday
    final lastWeek = DateTime(2026, 8, 17, 9);

    test('counts only completed sessions started inside the week', () {
      final s = WeeklyStudySummary.from(
        now: now,
        tasks: const [],
        assignmentCompletionTimes: const {},
        sessions: [
          _session(id: 'a', actual: 60, at: inWeek),
          _session(id: 'b', actual: 30, at: lastWeek),
          _session(
            id: 'c',
            actual: 90,
            at: inWeek,
            status: StudySessionStatus.cancelled,
          ),
        ],
      );

      expect(s.studiedMinutes, 60);
      expect(s.completedSessions, 1);
      expect(s.previousWeekMinutes, 30);
    });

    test('the trend is real, computed against the previous week', () {
      final s = WeeklyStudySummary.from(
        now: now,
        tasks: const [],
        assignmentCompletionTimes: const {},
        sessions: [
          _session(id: 'a', actual: 120, at: inWeek),
          _session(id: 'b', actual: 100, at: lastWeek),
        ],
      );
      expect(s.trendRatio, closeTo(0.2, 0.0001));
    });

    test('no previous-week data means no trend at all, not +100%', () {
      final s = WeeklyStudySummary.from(
        now: now,
        tasks: const [],
        assignmentCompletionTimes: const {},
        sessions: [_session(id: 'a', actual: 60, at: inWeek)],
      );
      expect(s.previousWeekMinutes, 0);
      expect(s.trendRatio, isNull);
      expect(s.hasTrend, isFalse);
    });

    test('best day is the weekday with the most minutes', () {
      final s = WeeklyStudySummary.from(
        now: now,
        tasks: const [],
        assignmentCompletionTimes: const {},
        sessions: [
          _session(id: 'a', actual: 30, at: DateTime(2026, 8, 23, 9)), // Sun
          _session(id: 'b', actual: 50, at: DateTime(2026, 8, 24, 9)), // Mon
          _session(id: 'c', actual: 20, at: DateTime(2026, 8, 24, 14)), // Mon
        ],
      );
      expect(s.bestWeekday, DateTime.monday);
      expect(s.bestWeekdayMinutes, 70);
      expect(ArabicWeekday.name(s.bestWeekday), AppStrings.monday);
    });

    test('tasks count for the week by completedAt, never by isCompleted alone',
        () {
      final s = WeeklyStudySummary.from(
        now: now,
        sessions: const [],
        assignmentCompletionTimes: const {},
        tasks: [
          _task(done: true, completedAt: inWeek),
          _task(done: true, completedAt: lastWeek), // finished, but not now
          // Completed with no timestamp: cannot be claimed for this week.
          _task(done: true, completedAt: null),
          _task(done: false, due: DateTime(2026, 8, 1)), // overdue
          _task(done: false, due: DateTime(2026, 12, 1)), // pending
        ],
      );

      expect(s.completedTasks, 1);
      expect(s.overdueTasks, 1);
      expect(s.pendingTasks, 2);
    });

    test('assignment completions count by their stored timestamp', () {
      final s = WeeklyStudySummary.from(
        now: now,
        sessions: const [],
        tasks: const [],
        assignmentCompletionTimes: {
          'a1': inWeek,
          'a2': lastWeek,
          'a3': null,
        },
      );
      expect(s.completedAssignments, 1);
      expect(s.totalCompletedWork, 1);
    });

    test('a week with nothing in it is empty, not an error', () {
      final s = WeeklyStudySummary.from(
        now: now,
        sessions: const [],
        tasks: const [],
        assignmentCompletionTimes: const {},
      );
      expect(s.isEmpty, isTrue);
      expect(s.studiedMinutes, 0);
      expect(s.trendRatio, isNull);
    });
  });

  // ======================================================= history summary
  group('StudyHistorySummary', () {
    final now = DateTime(2026, 8, 25, 12);

    test('excludes still-running sessions from the record', () {
      final s = StudyHistorySummary.from(
        now: now,
        sessions: [
          _session(id: 'a', at: now),
          _session(id: 'b', at: now, status: StudySessionStatus.active),
        ],
      );
      expect(s.sessions, hasLength(1));
    });

    test('the week filter keeps only this week', () {
      final s = StudyHistorySummary.from(
        now: now,
        range: StudyHistoryRange.week,
        sessions: [
          _session(id: 'a', actual: 40, at: DateTime(2026, 8, 24)),
          _session(id: 'b', actual: 50, at: DateTime(2026, 8, 10)),
        ],
      );
      expect(s.sessions, hasLength(1));
      expect(s.totalMinutes, 40);
    });

    test('the month filter keeps only this calendar month', () {
      final s = StudyHistorySummary.from(
        now: now,
        range: StudyHistoryRange.month,
        sessions: [
          _session(id: 'a', actual: 40, at: DateTime(2026, 8, 2)),
          _session(id: 'b', actual: 50, at: DateTime(2026, 7, 30)),
        ],
      );
      expect(s.sessions, hasLength(1));
      expect(s.totalMinutes, 40);
    });

    test('the course filter keeps only that course', () {
      final s = StudyHistorySummary.from(
        now: now,
        courseId: 'c1',
        sessions: [
          _session(id: 'a', actual: 40, courseId: 'c1', at: now),
          _session(id: 'b', actual: 50, courseId: 'c2', at: now),
          _session(id: 'c', actual: 20, at: now), // general
        ],
      );
      expect(s.sessions, hasLength(1));
      expect(s.totalMinutes, 40);
    });

    test('cancelled sessions are listed but never counted', () {
      final s = StudyHistorySummary.from(
        now: now,
        sessions: [
          _session(id: 'a', actual: 40, at: now),
          _session(
            id: 'b',
            actual: 0,
            at: now,
            status: StudySessionStatus.cancelled,
          ),
        ],
      );
      expect(s.sessions, hasLength(2));
      expect(s.completedSessions, 1);
      expect(s.cancelledSessions, 1);
      expect(s.totalMinutes, 40);
    });

    test('sessions come back newest first', () {
      final s = StudyHistorySummary.from(
        now: now,
        sessions: [
          _session(id: 'old', at: DateTime(2026, 8, 1)),
          _session(id: 'new', at: DateTime(2026, 8, 24)),
        ],
      );
      expect(s.sessions.first.id, 'new');
    });

    test('average is null with nothing completed', () {
      final s = StudyHistorySummary.from(now: now, sessions: const []);
      expect(s.averageMinutes, isNull);
      expect(s.isEmpty, isTrue);
    });

    test('course filter options come from sessions, not enrolments', () {
      final ids = StudyHistorySummary.courseIdsIn([
        _session(id: 'a', courseId: 'c1'),
        _session(id: 'b', courseId: 'c1'),
        _session(id: 'c', courseId: 'c2'),
        _session(id: 'd'),
        _session(id: 'e', courseId: 'c9', status: StudySessionStatus.active),
      ]);
      expect(ids, ['c1', 'c2']);
    });
  });

  // ================================================= schema pass-through
  group('optional session fields', () {
    test('name and goal reach the service and the running session', () async {
      final service = FakeService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await provider.startSession(
        plannedMinutes: 30,
        sessionName: 'مراجعة نهائية',
        goal: 'إنهاء الفصل الرابع',
      );

      expect(service.startCalls.single['sessionName'], 'مراجعة نهائية');
      expect(service.startCalls.single['goal'], 'إنهاء الفصل الرابع');
      expect(provider.activeSessionName, 'مراجعة نهائية');
      expect(provider.activeGoal, 'إنهاء الفصل الرابع');

      await provider.cancel();
    });

    test('a reflection is written only when the student wrote one', () async {
      final service = FakeService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await provider.startSession(plannedMinutes: 30);
      await provider.finishEarly();

      // Blank input succeeds but costs no write.
      expect(await provider.saveReflection('   '), isTrue);
      expect(service.reflectionCalls, isEmpty);

      expect(await provider.saveReflection('راجعت الفصل'), isTrue);
      expect(service.reflectionCalls, hasLength(1));
      expect(service.reflectionCalls.single['reflection'], 'راجعت الفصل');
    });

    test('the finished session is available right after closing', () async {
      final service = FakeService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await provider.startSession(
        plannedMinutes: 30,
        sessionName: 'مراجعة',
        courseId: 'c1',
        offeringId: 'off1',
      );
      await provider.finishEarly();

      // The stream has not echoed the write yet; the snapshot carries the
      // real values in the meantime.
      final finished = provider.lastFinishedSession;
      expect(finished, isNotNull);
      expect(finished!.plannedMinutes, 30);
      expect(finished.sessionName, 'مراجعة');
      expect(finished.isCompleted, isTrue);
    });

    test('a session model reads documents that predate the new fields', () {
      final legacy = StudySessionModel.fromFirestore({
        'userId': 'student1',
        'plannedMinutes': 45,
        'actualMinutes': 45,
        'status': 'completed',
      }, 'legacy1');

      expect(legacy.sessionName, isNull);
      expect(legacy.goal, isNull);
      expect(legacy.reflection, isNull);
      expect(legacy.hasSessionName, isFalse);
      expect(legacy.completionRatio, 1.0);
    });
  });

  // ================================================== create session screen
  group('CreateStudySessionScreen', () {
    testWidgets('offers only the student enrolled courses', (tester) async {
      _phone(tester);
      final service = FakeService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrap(
        const CreateStudySessionScreen(),
        sessions: provider,
        courses: [_course(title: 'قواعد البيانات')],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();

      expect(find.text('قواعد البيانات'), findsWidgets);
      expect(find.text('مساق غير مسجَّل'), findsNothing);
    });

    testWidgets('defaults the duration to the stored preference',
        (tester) async {
      _tall(tester);
      final service = FakeService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrap(
        const CreateStudySessionScreen(),
        sessions: provider,
        prefMinutes: 60,
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(AppStrings.startNowAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.startNowAction));
      await tester.pumpAndSettle();

      expect(service.startCalls.single['plannedMinutes'], 60);
 
      // Stop the ticker in-body: the binding checks for pending timers
      // before tearDown runs.
      await provider.cancel();
      await tester.pump();
    });

    testWidgets('sends the typed name and goal', (tester) async {
      _tall(tester);
      final service = FakeService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrap(
        const CreateStudySessionScreen(),
        sessions: provider,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, AppStrings.sessionNameHint),
        'مراجعة نهائية',
      );
      await tester.enterText(
        find.widgetWithText(TextField, AppStrings.sessionGoalHint),
        'حل التمارين',
      );
      await tester.ensureVisible(find.text(AppStrings.startNowAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.startNowAction));
      await tester.pumpAndSettle();

      expect(service.startCalls.single['sessionName'], 'مراجعة نهائية');
      expect(service.startCalls.single['goal'], 'حل التمارين');
 
      // Stop the ticker in-body: the binding checks for pending timers
      // before tearDown runs.
      await provider.cancel();
      await tester.pump();
    });

    testWidgets('refuses to start a second session', (tester) async {
      _tall(tester);
      final service = FakeService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await provider.startSession(plannedMinutes: 25);
      expect(service.startCalls, hasLength(1));

      await tester.pumpWidget(_wrap(
        const CreateStudySessionScreen(),
        sessions: provider,
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(AppStrings.startNowAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.startNowAction));
      await tester.pumpAndSettle();

      // No second write.
      expect(service.startCalls, hasLength(1));
      expect(find.text(AppStrings.studySessionAlreadyRunning), findsOneWidget);

      await provider.cancel();
      await tester.pump();
    });

    testWidgets('picking a duration chip changes what is sent',
        (tester) async {
      _tall(tester);
      final service = FakeService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrap(
        const CreateStudySessionScreen(),
        sessions: provider,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('25 ${AppStrings.minutesUnit}'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(AppStrings.startNowAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.startNowAction));
      await tester.pumpAndSettle();

      expect(service.startCalls.single['plannedMinutes'], 25);
 
      // Stop the ticker in-body: the binding checks for pending timers
      // before tearDown runs.
      await provider.cancel();
      await tester.pump();
    });

    testWidgets('no overflow at 360 or at the Figma width', (tester) async {
      for (final size in [const Size(360, 780), const Size(402, 874)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        final service = FakeService();
        final provider = StudySessionProvider(service)
          ..syncWithUser(studentId: 'student1');

        await tester.pumpWidget(_wrap(
          const CreateStudySessionScreen(),
          sessions: provider,
          courses: [_course(title: 'تحليل وتصميم النظم المتقدمة جدًا')],
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'at $size');

        provider.dispose();
        await service.closeAll();
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  // ================================================ session complete screen
  group('SessionCompleteScreen', () {
    Future<StudySessionProvider> finished(
      WidgetTester tester,
      FakeService service, {
      int planned = 45,
      int actual = 45,
      bool cancel = false,
    }) async {
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      await provider.startSession(
        plannedMinutes: planned,
        courseId: 'c1',
        offeringId: 'off1',
      );
      if (cancel) {
        await provider.cancel();
      } else {
        // Drive the clock so elapsed minutes are real.
        provider.debugSetClock(
          () => DateTime.now().add(Duration(minutes: actual)),
        );
        await provider.finishEarly();
      }
      return provider;
    }

    testWidgets('shows the real duration, course and achieved ratio',
        (tester) async {
      _phone(tester);
      final service = FakeService();
      final provider = await finished(tester, service, planned: 45, actual: 45);
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrap(
        const SessionCompleteScreen(),
        sessions: provider,
        courses: [_course(title: 'قواعد البيانات')],
      ));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.sessionCompleteHeadline), findsOneWidget);
      expect(find.text('قواعد البيانات'), findsOneWidget);
      expect(find.text('45/45 ${AppStrings.minutesUnit}'), findsOneWidget);
    });

    testWidgets('saves the reflection the student typed', (tester) async {
      _tall(tester);
      final service = FakeService();
      final provider = await finished(tester, service);
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrap(
        const SessionCompleteScreen(),
        sessions: provider,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, AppStrings.reflectionHint),
        'أنهيت الفصل الرابع',
      );
      await tester.ensureVisible(find.text(AppStrings.saveSessionAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.saveSessionAction));
      await tester.pumpAndSettle();

      expect(service.reflectionCalls, hasLength(1));
      expect(
        service.reflectionCalls.single['reflection'],
        'أنهيت الفصل الرابع',
      );
    });

    testWidgets('saving without writing anything costs no write',
        (tester) async {
      _tall(tester);
      final service = FakeService();
      final provider = await finished(tester, service);
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrap(
        const SessionCompleteScreen(),
        sessions: provider,
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(AppStrings.saveSessionAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.saveSessionAction));
      await tester.pumpAndSettle();

      expect(service.reflectionCalls, isEmpty);
    });

    testWidgets('a cancelled session offers no reflection field',
        (tester) async {
      _phone(tester);
      final service = FakeService();
      final provider = await finished(tester, service, cancel: true);
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrap(
        const SessionCompleteScreen(),
        sessions: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.sessionCancelledHeadline), findsOneWidget);
      // Nothing was accomplished to describe, and the rules reject it.
      expect(find.text(AppStrings.reflectionQuestion), findsNothing);
    });
  });

  // ======================================================= history screen
  group('SessionHistoryScreen', () {
    testWidgets('lists real sessions and filters by range', (tester) async {
      _tall(tester);
      final service = FakeService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrap(
        const SessionHistoryScreen(),
        sessions: provider,
        courses: [_course()],
      ));
      service.controller.add([
        _session(id: 'a', actual: 45, at: DateTime.now()),
        _session(id: 'b', actual: 30, at: DateTime(2020, 1, 1)),
      ]);
      await tester.pumpAndSettle();

      expect(find.byType(StudySessionCard), findsNWidgets(2));

      await tester.tap(find.text(AppStrings.filterWeek));
      await tester.pumpAndSettle();

      // The old session drops out; the summary follows the filter.
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.historyEmptyForFilter), findsNothing);
    });

    testWidgets('an empty history states it plainly', (tester) async {
      _phone(tester);
      final service = FakeService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrap(
        const SessionHistoryScreen(),
        sessions: provider,
      ));
      service.controller.add(const []);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noStudySessionsTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a filter that matches nothing says so, not "no sessions"',
        (tester) async {
      _tall(tester);
      final service = FakeService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrap(
        const SessionHistoryScreen(),
        sessions: provider,
      ));
      service.controller.add([
        _session(id: 'old', actual: 30, at: DateTime(2020, 1, 1)),
      ]);
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.filterWeek));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.historyEmptyForFilter), findsOneWidget);
    });

    testWidgets('completed and cancelled are distinguished', (tester) async {
      _reference(tester);
      final service = FakeService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrap(
        const SessionHistoryScreen(),
        sessions: provider,
      ));
      service.controller.add([
        _session(id: 'a', actual: 45, at: DateTime.now()),
        _session(
          id: 'b',
          actual: 0,
          at: DateTime.now(),
          status: StudySessionStatus.cancelled,
        ),
      ]);
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.sessionStatusCompletedShort),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.sessionStatusCancelledShort),
        findsOneWidget,
      );
    });
  });

  // ================================================== weekly report screen
  group('WeeklySummaryScreen', () {
    testWidgets('reports this week only, with no invented trend',
        (tester) async {
      _reference(tester);
      final service = FakeService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrap(
        const WeeklySummaryScreen(),
        sessions: provider,
      ));
      service.controller.add([
        _session(id: 'a', actual: 60, at: DateTime.now()),
      ]);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.weeklySummaryTitle), findsWidgets);
      // Only one week of data exists, so no comparison may be shown.
      expect(find.textContaining(AppStrings.weeklyVsLastWeek), findsNothing);
    });

    testWidgets('a week with no data shows an honest empty state',
        (tester) async {
      _phone(tester);
      final service = FakeService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrap(
        const WeeklySummaryScreen(),
        sessions: provider,
      ));
      service.controller.add(const []);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.weeklyEmptyTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no goal-based congratulation is rendered', (tester) async {
      _reference(tester);
      final service = FakeService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrap(
        const WeeklySummaryScreen(),
        sessions: provider,
      ));
      service.controller.add([
        _session(id: 'a', actual: 60, at: DateTime.now()),
      ]);
      await tester.pumpAndSettle();

      // The Figma hero claims the student beat a weekly goal; no such goal
      // exists in the data model, so the claim must not appear.
      expect(find.textContaining('هدفك الأسبوعي'), findsNothing);
      expect(find.textContaining('تجاوزت'), findsNothing);
    });
  });

  // ===================================================== study plan screen
  group('StudyPlanScreen', () {
    testWidgets('the form works but generating says it is unavailable',
        (tester) async {
      _tall(tester);
      final service = FakeService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrap(
        const StudyPlanScreen(),
        sessions: provider,
        courses: [_course(title: 'قواعد البيانات')],
      ));
      await tester.pumpAndSettle();

      // Real controls over real courses.
      await tester.tap(find.text(AppStrings.planPeriodMonth));
      await tester.pumpAndSettle();
      await tester.tap(find.text('قواعد البيانات'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(AppStrings.planGenerateAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.planGenerateAction));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.planUnavailableTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('claims nothing was analysed or suggested', (tester) async {
      _reference(tester);
      final service = FakeService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrap(
        const StudyPlanScreen(),
        sessions: provider,
      ));
      await tester.pumpAndSettle();

      // No AI language anywhere on the screen.
      expect(find.textContaining('الذكاء'), findsNothing);
      expect(find.textContaining('حلّل'), findsNothing);
      expect(find.textContaining('أقترح'), findsNothing);
    });
  });
}
