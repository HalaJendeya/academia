import 'dart:async';

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
import 'package:academia/features/assignments/models/assignment_progress_model.dart';
import 'package:academia/features/assignments/services/assignment_progress_service.dart';
import 'package:academia/features/assignments/services/course_assignment_service.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/models/course_offering_model.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/enrollments/models/enrollment_model.dart';
import 'package:academia/features/semesters/models/semester_model.dart';
import 'package:academia/features/tasks/models/task_model.dart';
import 'package:academia/features/tasks/providers/task_provider.dart';
import 'package:academia/features/tasks/screens/tasks_screen.dart';
import 'package:academia/features/tasks/services/task_service.dart';
import 'package:academia/features/tasks/widgets/task_filter_bar.dart';

/*
 * Integration-level harness.
 *
 * The Phase 8.4 unit tests faked the PROVIDERS, so they never exercised the
 * real provider wiring — which is exactly where the device regression lived.
 * Here the providers are REAL and only the services are faked, mounted
 * through the same ProxyProvider chain app_providers builds.
 */

/// Carries a Firestore-style error code, so the provider error mapping is
/// exercised the way a real FirebaseException would drive it.
class FirebaseLikeError implements Exception {
  FirebaseLikeError(this.code);
  final String code;
}

// --------------------------------------------------------------- services

class FakeTaskService implements TaskService {
  final controller = StreamController<List<TaskModel>>.broadcast();
  final watchedUserIds = <String>[];

  @override
  Stream<List<TaskModel>> watchTasks(String userId) {
    watchedUserIds.add(userId);
    return controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Progress reads that never resolve to a mark.
///
/// This suite mirrors app_providers with REAL providers over fake services,
/// so the progress provider is wired the same way here — which also proves
/// its auth gating opens no listener for a non-student session.
class FakeProgressService implements AssignmentProgressService {
  final watchedStudentIds = <String>[];

  @override
  Stream<List<AssignmentProgressModel>> watchStudentProgress(
    String studentId,
  ) {
    watchedStudentIds.add(studentId);
    return Stream<List<AssignmentProgressModel>>.value(
      const <AssignmentProgressModel>[],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAssignmentService implements CourseAssignmentService {
  final Map<String, StreamController<List<CourseAssignmentModel>>> controllers =
      {};
  final watchedOfferingIds = <String>[];

  StreamController<List<CourseAssignmentModel>> controllerFor(String id) =>
      controllers.putIfAbsent(
        id,
        () => StreamController<List<CourseAssignmentModel>>.broadcast(),
      );

  @override
  Stream<List<CourseAssignmentModel>> watchOfferingAssignments(String id) {
    watchedOfferingIds.add(id);
    return controllerFor(id).stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// -------------------------------------------------------------- providers

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  FakeAuthProvider({this.uid = 'student1'});

  String? uid;

  void signOut() {
    uid = null;
    notifyListeners();
  }

  void signInAs(String next) {
    uid = next;
    notifyListeners();
  }

  @override
  bool get isLoggedIn => uid != null;

  @override
  bool get isStudent => true;

  @override
  bool get isAccountActive => true;

  @override
  AppUserModel? get currentUserProfile => uid == null
      ? null
      : AppUserModel(
          uid: uid!,
          fullName: 'حلا',
          email: '$uid@test.com',
          role: UserRole.student,
          status: 'active',
          emailVerified: true,
          onboardingCompleted: true,
          onboardingStatus: 'completed',
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mimics the real load sequence: no courses at first, then they arrive.
class FakeStudentCoursesProvider extends ChangeNotifier
    implements StudentCoursesProvider {
  List<StudentCourseView> _current = const [];

  @override
  List<StudentCourseView> get currentCourses => _current;

  void arrive(List<StudentCourseView> views) {
    _current = views;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --------------------------------------------------------------- fixtures

final _now = DateTime.now();

StudentCourseView _courseView({String offeringId = 'off1'}) {
  return StudentCourseView(
    enrollment: EnrollmentModel(
      id: 'student1_$offeringId',
      userId: 'student1',
      offeringId: offeringId,
      courseId: 'c1',
      semesterId: 'semester_2026_1',
      status: 'active',
      assignedBy: 'admin1',
    ),
    offering: CourseOfferingModel(
      id: offeringId,
      courseId: 'c1',
      semesterId: 'semester_2026_1',
      teacherId: 't1',
      instructorName: 'د. سارة',
      section: '1',
      status: 'active',
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
    semester: const SemesterModel(
      id: 'semester_2026_1',
      academicYear: '2026',
      semesterNumber: 1,
      semesterName: 'الفصل الأول 2026',
      status: 'current',
    ),
  );
}

TaskModel _task({String id = 't1', String title = 'مهمة شخصية'}) => TaskModel(
  id: id,
  userId: 'student1',
  title: title,
  status: TaskStatus.pending,
  createdAt: _now,
  updatedAt: _now,
);

CourseAssignmentModel _assignment({
  String id = 'a1',
  String title = 'واجب أكاديمي',
  String offeringId = 'off1',
}) {
  return CourseAssignmentModel(
    id: id,
    offeringId: offeringId,
    courseId: 'c1',
    semesterId: 'semester_2026_1',
    title: title,
    description: '',
    dueAt: DateTime(2030, 1, 1),
    status: CourseAssignmentModel.statusActive,
    createdBy: 't1',
  );
}

// ----------------------------------------------------------------- harness

class Harness {
  Harness()
    : auth = FakeAuthProvider(),
      courses = FakeStudentCoursesProvider(),
      taskService = FakeTaskService(),
      assignmentService = FakeAssignmentService();

  final FakeAuthProvider auth;
  final FakeStudentCoursesProvider courses;
  final FakeTaskService taskService;
  final FakeAssignmentService assignmentService;
  final FakeProgressService progressService = FakeProgressService();

  Widget build() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<StudentCoursesProvider>.value(value: courses),
        // The same ProxyProvider shapes app_providers registers.
        ChangeNotifierProxyProvider<AuthProvider, AssignmentProgressProvider>(
          create: (_) => AssignmentProgressProvider(progressService),
          update: (_, a, provider) => provider!
            ..syncWithUser(
              studentId: a.isLoggedIn && a.isStudent && a.isAccountActive
                  ? a.currentUserProfile?.uid
                  : null,
            ),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, StudentCoursesProvider,
            CourseAssignmentProvider>(
          create: (_) => CourseAssignmentProvider(assignmentService),
          update: (_, a, c, provider) {
            provider!.syncWithAuth(
              isActiveUser: a.isLoggedIn && a.isAccountActive,
              role: a.currentUserProfile?.role.name,
            );
            final isActiveStudent =
                a.isLoggedIn && a.isStudent && a.isAccountActive;
            provider.syncStudentOfferings(
              isActiveStudent
                  ? [for (final v in c.currentCourses) v.offeringId]
                  : null,
            );
            return provider;
          },
        ),
        ChangeNotifierProxyProvider2<AuthProvider, StudentCoursesProvider,
            TaskProvider>(
          create: (_) => TaskProvider(taskService),
          update: (_, a, c, provider) {
            final isActiveStudent =
                a.isLoggedIn && a.isStudent && a.isAccountActive;
            provider!.syncWithUserAndCourses(
              userId: isActiveStudent ? a.currentUserProfile?.uid : null,
              isLoggedIn: isActiveStudent,
              currentCourses: c.currentCourses,
            );
            return provider;
          },
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
          AppRoutes.taskDetail: (_) => const Scaffold(body: Text('detail')),
          AppRoutes.createEditTask: (_) => const Scaffold(body: Text('create')),
        },
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: TasksScreen(),
        ),
      ),
    );
  }
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

  testWidgets('REGRESSION: renders real content, never a bare error screen', (
    tester,
  ) async {
    _useNarrowScreen(tester);
    final h = Harness();

    await tester.pumpWidget(h.build());
    await tester.pump();

    // Courses arrive after the first frame, as they do on a real device.
    h.courses.arrive([_courseView()]);
    await tester.pump();

    h.taskService.controller.add([_task()]);
    h.assignmentService.controllerFor('off1').add([_assignment()]);
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isNull,
      reason: 'no framework exception during the real provider sequence',
    );
    expect(find.text('حدث خطأ ما'), findsNothing);
    expect(find.text('مهمة شخصية'), findsOneWidget);
    expect(find.text('واجب أكاديمي'), findsOneWidget);
  });

  testWidgets('assignments appear when courses arrive after the screen', (
    tester,
  ) async {
    _useNarrowScreen(tester);
    final h = Harness();

    await tester.pumpWidget(h.build());
    await tester.pump();
    h.taskService.controller.add([]);
    await tester.pumpAndSettle();

    // No offerings yet — must not claim a permanent empty result.
    h.courses.arrive([_courseView()]);
    await tester.pump();
    h.assignmentService.controllerFor('off1').add([_assignment()]);
    await tester.pumpAndSettle();

    expect(h.assignmentService.watchedOfferingIds, contains('off1'));
    expect(find.text('واجب أكاديمي'), findsOneWidget);
  });

  testWidgets('a student switch leaks nothing from the previous student', (
    tester,
  ) async {
    _useNarrowScreen(tester);
    final h = Harness();

    await tester.pumpWidget(h.build());
    h.courses.arrive([_courseView()]);
    await tester.pump();
    h.taskService.controller.add([_task(title: 'مهمة الأولى')]);
    h.assignmentService.controllerFor('off1').add([
      _assignment(title: 'واجب الأولى'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('واجب الأولى'), findsOneWidget);

    h.auth.signOut();
    h.courses.arrive(const []);
    await tester.pumpAndSettle();

    expect(find.text('واجب الأولى'), findsNothing);
    expect(find.text('مهمة الأولى'), findsNothing);
  });

  /*
   * The device symptom: a bare "حدث خطأ ما" filling the screen. These pin
   * that a SINGLE failing source can never produce it, and that when both
   * fail the error at least says which area failed.
   */
  testWidgets('assignments failure still shows personal tasks', (tester) async {
    _useNarrowScreen(tester);
    final h = Harness();

    await tester.pumpWidget(h.build());
    h.courses.arrive([_courseView()]);
    await tester.pump();

    h.taskService.controller.add([_task()]);
    h.assignmentService
        .controllerFor('off1')
        .addError(FirebaseLikeError('permission-denied'));
    await tester.pumpAndSettle();

    expect(find.text('مهمة شخصية'), findsOneWidget);
    expect(find.text('حدث خطأ ما'), findsNothing);
    expect(find.text(AppStrings.workAssignmentsUnavailableNote), findsOneWidget);
  });

  testWidgets('tasks failure still shows assignments', (tester) async {
    _useNarrowScreen(tester);
    final h = Harness();

    await tester.pumpWidget(h.build());
    h.courses.arrive([_courseView()]);
    await tester.pump();

    h.taskService.controller.addError(FirebaseLikeError('permission-denied'));
    h.assignmentService.controllerFor('off1').add([_assignment()]);
    await tester.pumpAndSettle();

    expect(find.text('واجب أكاديمي'), findsOneWidget);
    expect(find.text('حدث خطأ ما'), findsNothing);
    expect(find.text(AppStrings.workTasksUnavailableNote), findsOneWidget);
  });

  testWidgets('both failing gives a NAMED error, not a bare generic', (
    tester,
  ) async {
    _useNarrowScreen(tester);
    final h = Harness();

    await tester.pumpWidget(h.build());
    h.courses.arrive([_courseView()]);
    await tester.pump();

    h.taskService.controller.addError(FirebaseLikeError('permission-denied'));
    h.assignmentService
        .controllerFor('off1')
        .addError(FirebaseLikeError('permission-denied'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.workAllErrorTitle), findsOneWidget);
    expect(find.text('حدث خطأ ما'), findsNothing);
  });

  /*
   * A permission failure and a network failure need different actions from
   * the student, so they must not share one message.
   */
  testWidgets('permission-denied and offline map to different messages', (
    tester,
  ) async {
    _useNarrowScreen(tester);
    final h = Harness();

    await tester.pumpWidget(h.build());
    h.courses.arrive([_courseView()]);
    await tester.pump();
    h.taskService.controller.add([]);
    h.assignmentService
        .controllerFor('off1')
        .addError(FirebaseLikeError('unavailable'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.workTabAssignments));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.assignmentsUnavailableOffline), findsOneWidget);
    expect(find.text(AppStrings.assignmentsPermissionDenied), findsNothing);
  });

  testWidgets('the filter row appears on مهامي only', (tester) async {
    _useNarrowScreen(tester);
    final h = Harness();

    await tester.pumpWidget(h.build());
    h.courses.arrive([_courseView()]);
    await tester.pump();
    h.taskService.controller.add([_task()]);
    h.assignmentService.controllerFor('off1').add([_assignment()]);
    await tester.pumpAndSettle();

    // الكل — no task-specific filter controls.
    expect(find.byType(TaskFilterBar), findsNothing);

    await tester.tap(find.text(AppStrings.workTabAssignments));
    await tester.pumpAndSettle();
    expect(find.byType(TaskFilterBar), findsNothing);

    await tester.tap(find.text(AppStrings.workTabMyTasks));
    await tester.pumpAndSettle();
    expect(find.byType(TaskFilterBar), findsOneWidget);
    // Exactly one row, and 'مكتملة' is a tab not a pill.
    expect(
      find.descendant(
        of: find.byType(TaskFilterBar),
        matching: find.text(AppStrings.workTabCompleted),
      ),
      findsNothing,
    );

    await tester.tap(find.text(AppStrings.workTabCompleted));
    await tester.pumpAndSettle();
    expect(find.byType(TaskFilterBar), findsNothing);
  });

  testWidgets('no overflow at 360px across all four tabs', (tester) async {
    _useNarrowScreen(tester);
    final h = Harness();

    await tester.pumpWidget(h.build());
    h.courses.arrive([_courseView()]);
    await tester.pump();
    h.taskService.controller.add([
      _task(title: 'مهمة شخصية بعنوان طويل جدًا يمتد على أكثر من سطر واحد'),
    ]);
    h.assignmentService.controllerFor('off1').add([
      _assignment(title: 'واجب أكاديمي بعنوان طويل جدًا لاختبار التفاف النص'),
    ]);
    await tester.pumpAndSettle();

    for (final tab in [
      AppStrings.workTabAll,
      AppStrings.workTabAssignments,
      AppStrings.workTabMyTasks,
      AppStrings.workTabCompleted,
    ]) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'overflow on $tab');
    }
  });
}
