import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/core/widgets/app_bottom_navigation.dart';
import 'package:academia/features/analytics/screens/weekly_summary_screen.dart';
import 'package:academia/features/assignments/providers/assignment_progress_provider.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/profile/models/study_preferences.dart';
import 'package:academia/features/profile/providers/study_preferences_provider.dart';
import 'package:academia/features/profile/screens/study_preferences_screen.dart';
import 'package:academia/features/study/models/study_session_model.dart';
import 'package:academia/features/study/providers/study_session_provider.dart';
import 'package:academia/features/study/screens/active_session_screen.dart';
import 'package:academia/features/study/screens/create_study_session_screen.dart';
import 'package:academia/features/study/screens/session_complete_screen.dart';
import 'package:academia/features/study/screens/session_history_screen.dart';
import 'package:academia/features/study/screens/study_hub_screen.dart';
import 'package:academia/features/study/screens/study_plan_screen.dart';
import 'package:academia/features/study/services/study_session_service.dart';
import 'package:academia/features/tasks/models/task_model.dart';
import 'package:academia/features/tasks/providers/task_provider.dart';

/*
 * The whole مذاكرة navigation map, wired against the REAL destination
 * screens at the REAL route names from akademia_app.dart.
 *
 * Every study route registered in production is opened here at least once,
 * so a screen that cannot build is caught by a test rather than on a device.
 */

class FakeStudySessionService implements StudySessionService {
  final controllers = <StreamController<List<StudySessionModel>>>[];
  final startCalls = <Map<String, dynamic>>[];
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
  }) async {}

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

class FakePreferencesProvider extends ChangeNotifier
    implements StudyPreferencesProvider {
  @override
  final StudyPreferences? preferences = const StudyPreferences(
    studyDays: ['الأحد', 'الثلاثاء'],
    preferredSessionDuration: 45,
  );
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCoursesProvider extends ChangeNotifier
    implements StudentCoursesProvider {
  @override
  List<StudentCourseView> get currentCourses => const [];
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

class FakeProgressProvider extends ChangeNotifier
    implements AssignmentProgressProvider {
  @override
  Set<String> get completedAssignmentIds => const <String>{};
  @override
  Map<String, DateTime?> get completionTimes => const {};
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapRealRoutes(StudySessionProvider sessions) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<StudyPreferencesProvider>(
        create: (_) => FakePreferencesProvider(),
      ),
      ChangeNotifierProvider<StudentCoursesProvider>(
        create: (_) => FakeCoursesProvider(),
      ),
      ChangeNotifierProvider<TaskProvider>(create: (_) => FakeTaskProvider()),
      ChangeNotifierProvider<AssignmentProgressProvider>(
        create: (_) => FakeProgressProvider(),
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
      // The same widgets the production route table registers.
      routes: {
        AppRoutes.createStudySession: (_) => const CreateStudySessionScreen(),
        AppRoutes.activeStudySession: (_) => const ActiveSessionScreen(),
        AppRoutes.sessionComplete: (_) => const SessionCompleteScreen(),
        AppRoutes.sessionHistory: (_) => const SessionHistoryScreen(),
        AppRoutes.weeklySummary: (_) => const WeeklySummaryScreen(),
        AppRoutes.studyPlan: (_) => const StudyPlanScreen(),
        AppRoutes.studyPreferences: (_) => const StudyPreferencesScreen(),
      },
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: StudyHubScreen(),
      ),
    ),
  );
}

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<StudySessionProvider> _pumpHub(
  WidgetTester tester,
  FakeStudySessionService service,
) async {
  final sessions = StudySessionProvider(service)
    ..syncWithUser(studentId: 'student1');
  addTearDown(service.closeAll);
  addTearDown(sessions.dispose);

  await tester.pumpWidget(_wrapRealRoutes(sessions));
  service.controller.add(const []);
  await tester.pumpAndSettle();
  return sessions;
}

void main() {
  group('Study Hub navigation map', () {
    testWidgets('opens the create-session screen', (tester) async {
      _tall(tester);
      await _pumpHub(tester, FakeStudySessionService());

      await tester.tap(find.text(AppStrings.startStudySession));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CreateStudySessionScreen), findsOneWidget);
      // A sub-screen carries no second bottom navigation bar.
      expect(find.byType(AcademiaBottomNavigation), findsNothing);
    });

    testWidgets('opens session history', (tester) async {
      _tall(tester);
      await _pumpHub(tester, FakeStudySessionService());

      await tester.tap(find.text(AppStrings.sessionHistoryTile));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SessionHistoryScreen), findsOneWidget);
      expect(find.byType(AcademiaBottomNavigation), findsNothing);
    });

    testWidgets('«عرض الكل» also opens history', (tester) async {
      _tall(tester);
      await _pumpHub(tester, FakeStudySessionService());

      await tester.tap(find.text(AppStrings.viewAllAction));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SessionHistoryScreen), findsOneWidget);
    });

    testWidgets('opens the weekly report', (tester) async {
      _tall(tester);
      await _pumpHub(tester, FakeStudySessionService());

      await tester.tap(find.text(AppStrings.weeklyReportTile));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(WeeklySummaryScreen), findsOneWidget);
      expect(find.byType(AcademiaBottomNavigation), findsNothing);
    });

    testWidgets('opens the study-plan form', (tester) async {
      _tall(tester);
      await _pumpHub(tester, FakeStudySessionService());

      await tester.tap(find.text(AppStrings.studyPlanTile));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StudyPlanScreen), findsOneWidget);
    });

    testWidgets('opens the existing preferences screen', (tester) async {
      _tall(tester);
      await _pumpHub(tester, FakeStudySessionService());

      await tester.tap(find.text(AppStrings.studyPreferencesTile));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StudyPreferencesScreen), findsOneWidget);
    });

    testWidgets('back from every sub-screen returns to the hub with its nav',
        (tester) async {
      _tall(tester);
      await _pumpHub(tester, FakeStudySessionService());

      for (final tile in [
        AppStrings.sessionHistoryTile,
        AppStrings.weeklyReportTile,
        AppStrings.studyPlanTile,
      ]) {
        await tester.tap(find.text(tile));
        await tester.pumpAndSettle();
        expect(find.byType(StudyHubScreen), findsNothing);

        await tester.tap(find.byTooltip(AppStrings.back));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(StudyHubScreen), findsOneWidget);
        expect(find.byType(AcademiaBottomNavigation), findsOneWidget);
      }
    });
  });

  group('full session flow', () {
    testWidgets('create → timer → complete', (tester) async {
      _tall(tester);
      final service = FakeStudySessionService();
      final sessions = await _pumpHub(tester, service);

      // 1. hub → create
      await tester.tap(find.text(AppStrings.startStudySession));
      await tester.pumpAndSettle();
      expect(find.byType(CreateStudySessionScreen), findsOneWidget);

      // 2. create → timer
      await tester.tap(find.text(AppStrings.startNowAction));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ActiveSessionScreen), findsOneWidget);
      expect(service.startCalls, hasLength(1));
      expect(find.byType(AcademiaBottomNavigation), findsNothing);

      // 3. timer → complete, via the explicit end action
      await tester.tap(find.text(AppStrings.endSessionAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.finishSessionAction).last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SessionCompleteScreen), findsOneWidget);
      expect(sessions.hasActiveSession, isFalse);
    });

    testWidgets('the hub CTA returns to a running session instead of a new one',
        (tester) async {
      _tall(tester);
      final service = FakeStudySessionService();
      final sessions = await _pumpHub(tester, service);

      await sessions.startSession(plannedMinutes: 25);
      await tester.pumpAndSettle();

      // With a session running the CTA must lead back to it, not to a form
      // whose start would be refused.
      await tester.tap(find.text(AppStrings.resumeSessionAction));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ActiveSessionScreen), findsOneWidget);
      expect(service.startCalls, hasLength(1));

      await sessions.cancel();
      await tester.pump();
    });
  });
}
