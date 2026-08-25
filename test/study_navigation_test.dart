import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/core/widgets/app_bottom_navigation.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/profile/models/study_preferences.dart';
import 'package:academia/features/profile/providers/study_preferences_provider.dart';
import 'package:academia/features/profile/screens/study_preferences_screen.dart';
import 'package:academia/features/study/models/study_session_model.dart';
import 'package:academia/features/study/providers/study_session_provider.dart';
import 'package:academia/features/study/screens/active_session_screen.dart';
import 'package:academia/features/study/screens/study_hub_screen.dart';
import 'package:academia/features/study/services/study_session_service.dart';

/*
 * Navigation out of the Study Hub, wired against the REAL destination
 * screens at the REAL route names.
 *
 * study_session_test.dart deliberately stubs those destinations so it can
 * assert routing intent in isolation. That left a gap: nothing proved the
 * real StudyPreferencesScreen could actually build when pushed from the hub.
 * These tests close it by registering the same widgets akademia_app.dart
 * registers.
 */

class FakeStudySessionService implements StudySessionService {
  final controllers = <StreamController<List<StudySessionModel>>>[];
  final startCalls = <Map<String, dynamic>>[];

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
  }) async {
    startCalls.add({'plannedMinutes': plannedMinutes});
    return 'session1';
  }

  @override
  Future<void> closeSession({
    required String sessionId,
    required StudySessionStatus status,
    required int actualMinutes,
  }) async {}

  Future<void> closeAll() async {
    for (final c in controllers) {
      if (c.hasListener) await c.close();
    }
  }
}

class FakePreferencesProvider extends ChangeNotifier
    implements StudyPreferencesProvider {
  FakePreferencesProvider({
    this.preferences = const StudyPreferences(
      studyDays: ['الأحد', 'الثلاثاء'],
      preferredSessionDuration: 45,
    ),
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
  @override
  List<StudentCourseView> get currentCourses => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapRealRoutes({
  required StudySessionProvider sessions,
  StudyPreferencesProvider? prefs,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<StudyPreferencesProvider>.value(
        value: prefs ?? FakePreferencesProvider(),
      ),
      ChangeNotifierProvider<StudentCoursesProvider>(
        create: (_) => FakeStudentCoursesProvider(),
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
      // Same widgets, same route names as the production route table.
      routes: {
        AppRoutes.studyPreferences: (_) => const StudyPreferencesScreen(),
        AppRoutes.activeStudySession: (_) => const ActiveSessionScreen(),
      },
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: StudyHubScreen(),
      ),
    ),
  );
}

void _phoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _tallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('Study Hub → Study Preferences', () {
    testWidgets('opens the real preferences screen without an error screen',
        (tester) async {
      _tallViewport(tester);
      final service = FakeStudySessionService();
      final sessions = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(sessions.dispose);

      await tester.pumpWidget(_wrapRealRoutes(sessions: sessions));
      service.controller.add(const []);
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.editStudyPreferencesAction));
      await tester.pumpAndSettle();

      // The real screen is on screen, and nothing threw on the way there.
      expect(tester.takeException(), isNull);
      expect(find.byType(StudyPreferencesScreen), findsOneWidget);
      expect(find.text(AppStrings.studyPreferencesTitle), findsWidgets);
    });

    testWidgets('also survives a real phone width', (tester) async {
      _phoneViewport(tester);
      final service = FakeStudySessionService();
      final sessions = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(sessions.dispose);

      await tester.pumpWidget(_wrapRealRoutes(sessions: sessions));
      service.controller.add(const []);
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.editStudyPreferencesAction));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StudyPreferencesScreen), findsOneWidget);
    });

    testWidgets('back returns to the Study Hub', (tester) async {
      _tallViewport(tester);
      final service = FakeStudySessionService();
      final sessions = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);
      addTearDown(sessions.dispose);

      await tester.pumpWidget(_wrapRealRoutes(sessions: sessions));
      service.controller.add(const []);
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.editStudyPreferencesAction));
      await tester.pumpAndSettle();
      expect(find.byType(StudyHubScreen), findsNothing);

      // pushNamed, not pushReplacement: the hub must still be underneath.
      await tester.tap(find.byTooltip(AppStrings.back));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StudyHubScreen), findsOneWidget);
      expect(find.byType(StudyPreferencesScreen), findsNothing);
    });
  });

  group('Study Hub → Active session', () {
    testWidgets('start opens the real active-session screen', (tester) async {
      _tallViewport(tester);
      final service = FakeStudySessionService();
      final sessions = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);

      await tester.pumpWidget(_wrapRealRoutes(sessions: sessions));
      service.controller.add(const []);
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.startStudySession));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ActiveSessionScreen), findsOneWidget);
      expect(service.startCalls, hasLength(1));

      // A sub-screen carries no second bottom navigation bar.
      expect(find.byType(AcademiaBottomNavigation), findsNothing);

      await sessions.cancel();
      await tester.pump();
      sessions.dispose();
    });

    testWidgets('back from the session returns to the hub with its bottom nav',
        (tester) async {
      _tallViewport(tester);
      final service = FakeStudySessionService();
      final sessions = StudySessionProvider(service)
        ..syncWithUser(studentId: 'student1');
      addTearDown(service.closeAll);

      await tester.pumpWidget(_wrapRealRoutes(sessions: sessions));
      service.controller.add(const []);
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.startStudySession));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(AppStrings.back));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StudyHubScreen), findsOneWidget);
      // The hub's own bottom navigation is intact after coming back.
      expect(find.byType(AcademiaBottomNavigation), findsOneWidget);

      await sessions.cancel();
      await tester.pump();
      sessions.dispose();
    });
  });
}
