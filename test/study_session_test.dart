import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/models/course_offering_model.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/enrollments/models/enrollment_model.dart';
import 'package:academia/features/profile/models/study_preferences.dart';
import 'package:academia/features/profile/providers/study_preferences_provider.dart';
import 'package:academia/features/study/models/study_session_model.dart';
import 'package:academia/features/study/providers/study_session_provider.dart';
import 'package:academia/features/study/screens/study_hub_screen.dart';
import 'package:academia/features/study/services/study_session_service.dart';
import 'package:academia/features/study/widgets/study_timer.dart';

// ------------------------------------------------------------------- fakes

/// Records every call so a test can prove how *many* Firestore writes a
/// session costs, not merely that it eventually persisted.
class FakeStudySessionService implements StudySessionService {
  FakeStudySessionService({this.failStart = false, this.failClose = false});

  final bool failStart;
  final bool failClose;

  final controllers = <StreamController<List<StudySessionModel>>>[];
  final startCalls = <Map<String, dynamic>>[];
  final closeCalls = <Map<String, dynamic>>[];
  int nextId = 1;

  StreamController<List<StudySessionModel>> get controller => controllers.last;
  int get liveListenerCount => controllers.where((c) => c.hasListener).length;

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
      'userId': userId,
      'plannedMinutes': plannedMinutes,
      'offeringId': offeringId,
      'courseId': courseId,
    });
    if (failStart) {
      throw const StudySessionException(AppStrings.studySessionStartError);
    }
    return 'session${nextId++}';
  }

  @override
  Future<void> closeSession({
    required String sessionId,
    required StudySessionStatus status,
    required int actualMinutes,
  }) async {
    closeCalls.add({
      'sessionId': sessionId,
      'status': status,
      'actualMinutes': actualMinutes,
    });
    if (failClose) {
      throw const StudySessionException(AppStrings.studySessionCloseError);
    }
  }

  final reflectionCalls = <Map<String, String>>[];

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

class FakeStudyPreferencesProvider extends ChangeNotifier
    implements StudyPreferencesProvider {
  FakeStudyPreferencesProvider({
    this.preferences,
    this.loading = false,
    this.error,
  });

  @override
  final StudyPreferences? preferences;
  final bool loading;
  final String? error;

  @override
  bool get isLoading => loading;
  @override
  String? get errorMessage => error;
  @override
  bool get isSaving => false;
  @override
  bool get hasUnsavedChanges => false;

  @override
  Future<void> loadPreferences({bool forceRefresh = false}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStudentCoursesProvider extends ChangeNotifier
    implements StudentCoursesProvider {
  FakeStudentCoursesProvider({this.courses = const []});

  final List<StudentCourseView> courses;

  @override
  List<StudentCourseView> get currentCourses => courses;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ------------------------------------------------------------------ fixtures

const _prefs = StudyPreferences(
  studyDays: ['الأحد', 'الثلاثاء'],
  preferredSessionDuration: 45,
);

StudentCourseView _course() => StudentCourseView(
  enrollment: EnrollmentModel(
    id: 'student1_off1',
    userId: 'student1',
    offeringId: 'off1',
    courseId: 'c1',
    semesterId: 'sem1',
    attemptNumber: 1,
    status: 'active',
    assignedBy: 'admin1',
  ),
  offering: CourseOfferingModel(
    id: 'off1',
    courseId: 'c1',
    semesterId: 'sem1',
    section: '1',
    status: 'active',
    instructorName: 'د. مثال',
    createdBy: 'admin1',
  ),
  course: const CourseModel(
    id: 'c1',
    courseCode: 'BMIS3344',
    title: 'تحليل وتصميم النظم',
    description: '',
    creditHours: 3,
    departmentId: 'dep1',
    status: 'active',
  ),
);

StudySessionModel _session({
  String id = 's1',
  StudySessionStatus status = StudySessionStatus.completed,
  int actualMinutes = 40,
  DateTime? startedAt,
}) => StudySessionModel(
  id: id,
  userId: 'student1',
  plannedMinutes: 45,
  actualMinutes: actualMinutes,
  status: status,
  startedAt: startedAt ?? DateTime(2026, 8, 20, 10),
);

Widget _wrapHub({
  required StudySessionProvider sessions,
  StudyPreferences? prefs = _prefs,
  bool prefsLoading = false,
  List<StudentCourseView> courses = const [],
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<StudyPreferencesProvider>.value(
        value: FakeStudyPreferencesProvider(
          preferences: prefs,
          loading: prefsLoading,
        ),
      ),
      ChangeNotifierProvider<StudentCoursesProvider>.value(
        value: FakeStudentCoursesProvider(courses: courses),
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
      // Stub destinations: these tests assert that the hub *routes* there,
      // not what those screens render.
      routes: {
        AppRoutes.activeStudySession: (_) =>
            const Scaffold(body: Text('active-session-route')),
        AppRoutes.studyPreferences: (_) =>
            const Scaffold(body: Text('study-preferences-route')),
        AppRoutes.createStudySession: (_) =>
            const Scaffold(body: Text('create-session-route')),
        AppRoutes.sessionHistory: (_) =>
            const Scaffold(body: Text('history-route')),
        AppRoutes.weeklySummary: (_) =>
            const Scaffold(body: Text('weekly-route')),
        AppRoutes.studyPlan: (_) => const Scaffold(body: Text('plan-route')),
      },
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: StudyHubScreen(),
      ),
    ),
  );
}

/// The hub is a ListView; sections below the fold are never built. Widget
/// tests here use a tall viewport so history is laid out and assertable.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  // ================================================================ timer
  group('StudySessionProvider — timer', () {
    late FakeStudySessionService service;
    late StudySessionProvider provider;
    late DateTime now;

    setUp(() {
      service = FakeStudySessionService();
      provider = StudySessionProvider(service);
      now = DateTime(2026, 8, 21, 9);
      provider.debugSetClock(() => now);
      provider.syncWithUser(studentId: 'student1');
    });

    tearDown(() async {
      provider.dispose();
      await service.closeAll();
    });

    test('starting a session writes once and begins the countdown', () async {
      final ok = await provider.startSession(plannedMinutes: 25);

      expect(ok, isTrue);
      expect(provider.hasActiveSession, isTrue);
      expect(provider.isRunning, isTrue);
      expect(provider.remaining, const Duration(minutes: 25));
      // Exactly one write to start a session — the countdown itself is local.
      expect(service.startCalls, hasLength(1));
      expect(service.closeCalls, isEmpty);
    });

    test('a second start is refused while one is running', () async {
      await provider.startSession(plannedMinutes: 25);
      final second = await provider.startSession(plannedMinutes: 45);

      expect(second, isFalse);
      // The refusal happens before the service is touched.
      expect(service.startCalls, hasLength(1));
      expect(provider.plannedMinutes, 25);
    });

    test('an invalid duration never reaches the service', () async {
      final ok = await provider.startSession(plannedMinutes: 999);

      expect(ok, isFalse);
      expect(service.startCalls, isEmpty);
      expect(provider.errorMessage, AppStrings.studySessionInvalidDuration);
    });

    test('remaining is derived from the clock, not a ticking counter', () async {
      await provider.startSession(plannedMinutes: 30);

      // Simulate the app being away for ten minutes without any tick firing.
      now = now.add(const Duration(minutes: 10));

      // A decrementing integer would still read 30:00 here.
      expect(provider.remaining, const Duration(minutes: 20));
      expect(provider.elapsedMinutes, 10);
    });

    test('pause freezes the remaining time even as the clock advances',
        () async {
      await provider.startSession(plannedMinutes: 30);
      now = now.add(const Duration(minutes: 5));

      provider.pause();
      expect(provider.isPaused, isTrue);
      expect(provider.remaining, const Duration(minutes: 25));

      now = now.add(const Duration(minutes: 10));
      // Paused time must not be counted against the student.
      expect(provider.remaining, const Duration(minutes: 25));
    });

    test('resume continues from where it paused', () async {
      await provider.startSession(plannedMinutes: 30);
      now = now.add(const Duration(minutes: 5));
      provider.pause();
      now = now.add(const Duration(minutes: 10));

      provider.resume();
      expect(provider.isRunning, isTrue);
      expect(provider.remaining, const Duration(minutes: 25));

      now = now.add(const Duration(minutes: 5));
      expect(provider.remaining, const Duration(minutes: 20));
    });

    test('reaching zero marks the session finished but writes nothing yet',
        () async {
      await provider.startSession(plannedMinutes: 10);
      now = now.add(const Duration(minutes: 10));

      expect(provider.remaining, Duration.zero);
      expect(provider.hasReachedZero, isTrue);
      // Closing stays an explicit decision; no background write happened.
      expect(service.closeCalls, isEmpty);
    });

    test('complete stores the full planned duration', () async {
      await provider.startSession(plannedMinutes: 10);
      now = now.add(const Duration(minutes: 10));

      final ok = await provider.complete();

      expect(ok, isTrue);
      expect(service.closeCalls, hasLength(1));
      expect(service.closeCalls.single['status'], StudySessionStatus.completed);
      expect(service.closeCalls.single['actualMinutes'], 10);
      expect(provider.hasActiveSession, isFalse);
    });

    test('finishing early stores only what was actually studied', () async {
      await provider.startSession(plannedMinutes: 60);
      now = now.add(const Duration(minutes: 22));

      final ok = await provider.finishEarly();

      expect(ok, isTrue);
      expect(service.closeCalls.single['status'], StudySessionStatus.completed);
      expect(service.closeCalls.single['actualMinutes'], 22);
      expect(provider.hasActiveSession, isFalse);
    });

    test('cancelling records zero studied minutes', () async {
      await provider.startSession(plannedMinutes: 60);
      now = now.add(const Duration(minutes: 22));

      final ok = await provider.cancel();

      expect(ok, isTrue);
      expect(service.closeCalls.single['status'], StudySessionStatus.cancelled);
      expect(service.closeCalls.single['actualMinutes'], 0);
    });

    test('a whole session costs exactly two writes', () async {
      await provider.startSession(plannedMinutes: 25);
      now = now.add(const Duration(minutes: 25));
      await provider.complete();

      expect(service.startCalls.length + service.closeCalls.length, 2);
    });

    test('a failed close keeps the session open rather than losing it',
        () async {
      final failing = FakeStudySessionService(failClose: true);
      final p = StudySessionProvider(failing)
        ..debugSetClock(() => now)
        ..syncWithUser(studentId: 'student1');
      addTearDown(failing.closeAll);
      addTearDown(p.dispose);

      await p.startSession(plannedMinutes: 25);
      final ok = await p.finishEarly();

      expect(ok, isFalse);
      expect(p.hasActiveSession, isTrue);
      expect(p.errorMessage, AppStrings.studySessionCloseError);
    });
  });

  // ======================================================= course linkage
  group('StudySessionProvider — course linkage', () {
    test('an offering is passed through with its course id', () async {
      final service = FakeStudySessionService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await provider.startSession(
        plannedMinutes: 30,
        offeringId: 'off1',
        courseId: 'c1',
      );

      expect(service.startCalls.single['offeringId'], 'off1');
      expect(service.startCalls.single['courseId'], 'c1');
    });

  });

  // =================================================== provider lifecycle
  group('StudySessionProvider — lifecycle', () {
    test('an active student gets a listener', () async {
      final service = FakeStudySessionService();
      final provider = StudySessionProvider(service);
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      provider.syncWithUser(studentId: 'student1');
      service.controller.add([_session()]);
      await Future<void>.delayed(Duration.zero);

      expect(service.liveListenerCount, 1);
      expect(provider.sessions, hasLength(1));
    });

    test('logout cancels the listener and clears the history', () async {
      final service = FakeStudySessionService();
      final provider = StudySessionProvider(service);
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      provider.syncWithUser(studentId: 'student1');
      service.controller.add([_session()]);
      await Future<void>.delayed(Duration.zero);
      expect(service.liveListenerCount, 1);

      provider.syncWithUser(studentId: null);
      await Future<void>.delayed(Duration.zero);

      // studySessions is owner-only; a surviving listener is denied.
      expect(service.liveListenerCount, 0);
      expect(provider.sessions, isEmpty);
    });

    test('a non-student never opens a listener', () async {
      final service = FakeStudySessionService();
      final provider = StudySessionProvider(service);
      addTearDown(provider.dispose);

      // Teacher / admin resolve to a null studentId at registration.
      provider.syncWithUser(studentId: null);
      await Future<void>.delayed(Duration.zero);

      expect(service.controllers, isEmpty);
      expect(provider.sessions, isEmpty);
    });

    test('switching account drops the previous history and timer', () async {
      final service = FakeStudySessionService();
      final provider = StudySessionProvider(service);
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      provider.syncWithUser(studentId: 'student1');
      await provider.startSession(plannedMinutes: 25);
      service.controller.add([_session()]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.hasActiveSession, isTrue);

      provider.syncWithUser(studentId: 'student2');
      await Future<void>.delayed(Duration.zero);

      // No account may inherit another account's running session.
      expect(provider.hasActiveSession, isFalse);
      expect(provider.sessions, isEmpty);
      expect(service.liveListenerCount, 1);
    });

    test('repeated syncs with the same student do not stack listeners',
        () async {
      final service = FakeStudySessionService();
      final provider = StudySessionProvider(service);
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      provider.syncWithUser(studentId: 'student1');
      provider.syncWithUser(studentId: 'student1');
      provider.syncWithUser(studentId: 'student1');
      await Future<void>.delayed(Duration.zero);

      expect(service.controllers, hasLength(1));
      expect(service.liveListenerCount, 1);
    });
  });

  // ============================================================= study hub
  group('StudyHubScreen', () {
    testWidgets('renders real session counters', (tester) async {
      _useTallViewport(tester);
      final service = FakeStudySessionService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrapHub(sessions: provider));
      service.controller.add(const []);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.studySessionsTitle), findsWidgets);
      // Counters come from the session stream, not from constants.
      expect(find.text(AppStrings.completedSessionsLabel), findsOneWidget);
      expect(find.text(AppStrings.weeklyStudyMinutesLabel), findsOneWidget);
    });

    testWidgets('shows an honest empty state before any session',
        (tester) async {
      _useTallViewport(tester);
      final service = FakeStudySessionService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrapHub(sessions: provider));
      service.controller.add(const []);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noStudySessionsTitle), findsOneWidget);
    });

    testWidgets('renders real recent sessions', (tester) async {
      _useTallViewport(tester);
      final service = FakeStudySessionService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrapHub(sessions: provider));
      service.controller.add([
        _session(id: 's1', actualMinutes: 40),
        _session(
          id: 's2',
          status: StudySessionStatus.cancelled,
          actualMinutes: 0,
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noStudySessionsTitle), findsNothing);
      expect(find.text(AppStrings.sessionStatusCompleted), findsOneWidget);
      expect(find.text(AppStrings.sessionStatusCancelled), findsOneWidget);
      expect(find.textContaining('40'), findsWidgets);
    });

    testWidgets('an active session is still listed as none-finished',
        (tester) async {
      _useTallViewport(tester);
      final service = FakeStudySessionService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrapHub(sessions: provider));
      service.controller.add([
        _session(id: 's1', status: StudySessionStatus.active),
      ]);
      await tester.pumpAndSettle();

      // A running session is not history yet.
      expect(find.text(AppStrings.noStudySessionsTitle), findsOneWidget);
    });

    testWidgets('the start CTA opens the create-session screen',
        (tester) async {
      _useTallViewport(tester);
      final service = FakeStudySessionService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrapHub(sessions: provider));
      service.controller.add(const []);
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.startStudySession));
      await tester.pumpAndSettle();

      // The hub no longer starts a session itself — it opens the form.
      // Nothing may be written before the student confirms.
      expect(service.startCalls, isEmpty);
      expect(provider.hasActiveSession, isFalse);
      expect(find.text('create-session-route'), findsOneWidget);
    });

    testWidgets('the tools menu links to the existing preferences screen',
        (tester) async {
      _useTallViewport(tester);
      final service = FakeStudySessionService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_wrapHub(sessions: provider));
      service.controller.add(const []);
      await tester.pumpAndSettle();

      // No duplicated preference form on this screen — just a way out to it.
      await tester.tap(find.text(AppStrings.studyPreferencesTile));
      await tester.pumpAndSettle();
      expect(find.text('study-preferences-route'), findsOneWidget);
    });

    testWidgets('no overflow at a 360px viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = FakeStudySessionService();
      final provider = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(
        _wrapHub(sessions: provider, courses: [_course()]),
      );
      service.controller.add([_session()]);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ================================================================ model
  group('StudySessionModel', () {
    test('an unknown status is not read as active', () {
      // A corrupt document must not masquerade as a running session and
      // block the student from starting a new one.
      expect(
        StudySessionModel.statusFromString('something-new'),
        StudySessionStatus.cancelled,
      );
      expect(
        StudySessionModel.statusFromString(null),
        StudySessionStatus.cancelled,
      );
    });

    test('duration bounds match the preference bounds', () {
      expect(StudySessionModel.isValidDuration(4), isFalse);
      expect(StudySessionModel.isValidDuration(5), isTrue);
      expect(StudySessionModel.isValidDuration(180), isTrue);
      expect(StudySessionModel.isValidDuration(181), isFalse);
    });

    test('a half course link is not treated as linked', () {
      final partial = StudySessionModel(
        id: 's1',
        userId: 'student1',
        offeringId: 'off1',
        plannedMinutes: 30,
        startedAt: DateTime(2026, 8, 21),
      );
      expect(partial.hasCourse, isFalse);
    });

    test('the timer formats mm:ss', () {
      expect(StudyTimer.format(const Duration(minutes: 25)), '25:00');
      expect(StudyTimer.format(const Duration(seconds: 65)), '01:05');
      expect(StudyTimer.format(const Duration(seconds: -5)), '00:00');
    });
  });
}
