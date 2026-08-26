import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/core/widgets/app_bottom_navigation.dart';
import 'package:academia/core/widgets/primary_button.dart';
import 'package:academia/features/assignments/models/course_assignment_model.dart';
import 'package:academia/features/assignments/providers/assignment_progress_provider.dart';
import 'package:academia/features/assignments/providers/course_assignment_provider.dart';
import 'package:academia/features/assignments/screens/student_assignment_details_screen.dart';
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

// ------------------------------------------------------------------ fakes

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  FakeAuthProvider({this.role = UserRole.student});

  final UserRole role;

  @override
  bool get isLoggedIn => true;

  @override
  bool get isStudent => role == UserRole.student;

  @override
  bool get isTeacher => role == UserRole.teacher;

  @override
  bool get isAdmin => role == UserRole.admin;

  @override
  bool get isAccountActive => true;

  @override
  AppUserModel? get currentUserProfile => AppUserModel(
    uid: 'student1',
    fullName: 'حلا',
    email: 's@test.com',
    role: role,
    status: 'active',
    emailVerified: true,
    onboardingCompleted: true,
    onboardingStatus: 'completed',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mirrors the real provider's contract, including its duplicate-write
/// guard, so the screen is tested against the behaviour it actually gets.
///
/// [gate] lets a test hold a write open and assert what the UI does while
/// it is in flight.
class FakeProgressProvider extends ChangeNotifier
    implements AssignmentProgressProvider {
  FakeProgressProvider({
    Set<String>? completed,
    Map<String, DateTime?>? times,
    this.shouldFail = false,
  }) : _completed = completed ?? <String>{},
       _times = times ?? <String, DateTime?>{};

  final Set<String> _completed;
  final Map<String, DateTime?> _times;
  final Set<String> _saving = <String>{};

  bool shouldFail;
  Completer<void>? gate;
  String? _error;

  /// Every accepted call, in order. A rejected duplicate never lands here.
  final List<({String id, bool completed})> calls = [];

  @override
  Set<String> get completedAssignmentIds => _completed;

  @override
  Map<String, DateTime?> get completionTimes => _times;

  @override
  bool isCompleted(String assignmentId) => _completed.contains(assignmentId);

  @override
  DateTime? completedAt(String assignmentId) => _times[assignmentId];

  @override
  bool isSaving(String assignmentId) => _saving.contains(assignmentId);

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => _error;

  @override
  Future<bool> setCompleted(String assignmentId, bool completed) async {
    // The real guard: a second write for the same assignment while one is
    // in flight is dropped, and reports no error because nothing failed.
    if (_saving.contains(assignmentId)) return false;

    calls.add((id: assignmentId, completed: completed));
    _saving.add(assignmentId);
    _error = null;
    notifyListeners();

    if (gate != null) await gate!.future;

    _saving.remove(assignmentId);

    if (shouldFail) {
      _error = AppStrings.assignmentProgressSaveError;
      notifyListeners();
      return false;
    }

    if (completed) {
      _completed.add(assignmentId);
      _times[assignmentId] = DateTime(2026, 8, 20, 10, 30);
    } else {
      _completed.remove(assignmentId);
      _times.remove(assignmentId);
    }
    notifyListeners();
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStudentCoursesProvider extends ChangeNotifier
    implements StudentCoursesProvider {
  FakeStudentCoursesProvider({
    this.currentValue = const <StudentCourseView>[],
    this.historyValue = const <StudentCourseView>[],
  });

  final List<StudentCourseView> currentValue;
  final List<StudentCourseView> historyValue;

  @override
  List<StudentCourseView> get currentCourses => currentValue;

  @override
  List<StudentCourseView> get history => historyValue;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAssignmentProvider extends ChangeNotifier
    implements CourseAssignmentProvider {
  FakeAssignmentProvider({
    this.assignmentsValue = const <CourseAssignmentModel>[],
    this.selectedValue = const <CourseAssignmentModel>[],
  });

  final List<CourseAssignmentModel> assignmentsValue;
  final List<CourseAssignmentModel> selectedValue;

  @override
  List<CourseAssignmentModel> get assignments => assignmentsValue;

  @override
  List<CourseAssignmentModel> get activeAssignments =>
      assignmentsValue.where((a) => a.isActive).toList();

  @override
  List<CourseAssignmentModel> get selectedAssignments => selectedValue;

  @override
  List<CourseAssignmentModel> get activeSelectedAssignments =>
      selectedValue.where((a) => a.isActive).toList();

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

class FakeTaskProvider extends ChangeNotifier implements TaskProvider {
  @override
  List<TaskModel> get tasks => const <TaskModel>[];

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --------------------------------------------------------------- fixtures

const _course = CourseModel(
  id: 'c1',
  courseCode: 'BMIS3344',
  title: 'تحليل وتصميم النظم',
  description: 'وصف المساق',
  creditHours: 3,
  departmentId: 'dep1',
  status: 'active',
);

const _offering = CourseOfferingModel(
  id: 'off1',
  courseId: 'c1',
  semesterId: 'semester_2026_1',
  teacherId: 't1',
  instructorName: 'د. سارة قاسم',
  section: '2',
  status: 'active',
);

StudentCourseView _attempt() => StudentCourseView(
  enrollment: const EnrollmentModel(
    id: 'student1_off1',
    userId: 'student1',
    offeringId: 'off1',
    courseId: 'c1',
    semesterId: 'semester_2026_1',
    status: 'active',
    assignedBy: 'admin1',
  ),
  offering: _offering,
  course: _course,
  semester: const SemesterModel(
    id: 'semester_2026_1',
    academicYear: '2026',
    semesterNumber: 1,
    semesterName: 'الفصل الدراسي الأول 2026',
    status: 'current',
  ),
);

CourseAssignmentModel _assignment({
  String id = 'a1',
  String title = 'واجب البرمجة الأول',
  String description = 'حل التمارين من 1 إلى 10',
  DateTime? dueAt,
  DateTime? createdAt,
  String priority = CourseAssignmentModel.priorityHigh,
  String status = CourseAssignmentModel.statusActive,
  String offeringId = 'off1',
}) {
  return CourseAssignmentModel(
    id: id,
    offeringId: offeringId,
    courseId: 'c1',
    semesterId: 'semester_2026_1',
    title: title,
    description: description,
    dueAt: dueAt ?? DateTime(2030, 9, 20, 23, 59),
    priority: priority,
    status: status,
    createdBy: 't1',
    createdAt: createdAt ?? DateTime(2026, 8, 1),
  );
}

// ----------------------------------------------------------------- harness

/// The details screen on its own route, with [assignment] as its argument.
///
/// `arguments: null` reproduces a route reached without them, which is the
/// only way the screen can fail to find an assignment.
Widget _wrapDetails({
  CourseAssignmentModel? assignment,
  FakeStudentCoursesProvider? courses,
  FakeAssignmentProvider? assignments,
  FakeProgressProvider? progress,
  FakeAuthProvider? auth,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth ?? FakeAuthProvider(),
      ),
      ChangeNotifierProvider<StudentCoursesProvider>.value(
        value:
            courses ??
            FakeStudentCoursesProvider(currentValue: [_attempt()]),
      ),
      ChangeNotifierProvider<CourseAssignmentProvider>.value(
        value: assignments ?? FakeAssignmentProvider(),
      ),
      ChangeNotifierProvider<AssignmentProgressProvider>.value(
        value: progress ?? FakeProgressProvider(),
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
      onGenerateRoute: (_) => MaterialPageRoute(
        settings: RouteSettings(
          name: AppRoutes.assignmentDetails,
          arguments: assignment == null
              ? null
              : StudentAssignmentDetailsArgs(assignment: assignment),
        ),
        builder: (_) => const Directionality(
          textDirection: TextDirection.rtl,
          child: StudentAssignmentDetailsScreen(),
        ),
      ),
    ),
  );
}

/// The real tasks screen with the real details route registered, so a tap
/// on «عرض التفاصيل» exercises the actual navigation wiring.
Widget _wrapTasksScreen({
  required List<CourseAssignmentModel> assignments,
  FakeProgressProvider? progress,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
      ChangeNotifierProvider<StudentCoursesProvider>(
        create: (_) =>
            FakeStudentCoursesProvider(currentValue: [_attempt()]),
      ),
      ChangeNotifierProvider<TaskProvider>(create: (_) => FakeTaskProvider()),
      ChangeNotifierProvider<CourseAssignmentProvider>.value(
        value: FakeAssignmentProvider(
          assignmentsValue: assignments,
          selectedValue: assignments,
        ),
      ),
      ChangeNotifierProvider<AssignmentProgressProvider>.value(
        value: progress ?? FakeProgressProvider(),
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
      },
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: TasksScreen(),
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
  setUpAll(() async {
    await initializeDateFormatting('ar', null);
  });

  group('rendering', () {
    testWidgets('renders the details screen for a passed assignment', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrapDetails(assignment: _assignment()));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.assignmentDetailsScreenTitle),
        findsOneWidget,
      );
      expect(find.text('واجب البرمجة الأول'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows every field the model actually carries', (tester) async {
      _useNarrowScreen(tester);
      final assignment = _assignment();
      await tester.pumpWidget(_wrapDetails(assignment: assignment));
      await tester.pumpAndSettle();

      // Title and instructions.
      expect(find.text('واجب البرمجة الأول'), findsOneWidget);
      expect(find.text('حل التمارين من 1 إلى 10'), findsOneWidget);
      expect(
        find.text(AppStrings.assignmentInstructionsSectionTitle),
        findsOneWidget,
      );

      // Deadline, formatted by the model itself.
      expect(find.text(assignment.dueDateLabel), findsOneWidget);

      // Status is a labelled line; priority is the badge the rest of the
      // app already uses. Neither value is repeated on the screen.
      expect(find.text(AppStrings.activeStatus), findsOneWidget);
      expect(find.text(AppStrings.assignmentPriorityHigh), findsOneWidget);

      // Course and instructor, resolved from the student's own enrolment.
      // The course sits in the subtitle, together with the section.
      expect(
        find.text(
          'BMIS3344 — تحليل وتصميم النظم · '
          '${AppStrings.offeringSectionLabel} 2',
        ),
        findsOneWidget,
      );
      expect(find.text('د. سارة قاسم'), findsOneWidget);

      // Creation date.
      expect(
        find.text(
          intl.DateFormat('yyyy/MM/dd', 'ar').format(DateTime(2026, 8, 1)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('an archived assignment reports itself as archived', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapDetails(
          assignment: _assignment(
            status: CourseAssignmentModel.statusArchived,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.archivedStatus), findsOneWidget);
      expect(find.text(AppStrings.activeStatus), findsNothing);
    });

    testWidgets('an overdue deadline is flagged', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapDetails(assignment: _assignment(dueAt: DateTime(2020, 1, 1))),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.assignmentOverdueLabel), findsOneWidget);
    });
  });

  group('read-only for students', () {
    testWidgets('no teacher or admin management controls are rendered', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrapDetails(assignment: _assignment()));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.editAssignmentTitle), findsNothing);
      expect(find.text(AppStrings.archiveAssignmentAction), findsNothing);
      expect(find.text(AppStrings.adminModerateArchiveAction), findsNothing);
      expect(find.text(AppStrings.addAssignmentTitle), findsNothing);
      expect(find.text(AppStrings.assignmentSaveNewAction), findsNothing);

      /*
       * The student now has exactly ONE action here — marking the
       * assignment done for themselves — so this asserts the absence of
       * everything that writes the shared assignment document, not the
       * absence of buttons in general.
       */
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text(AppStrings.assignmentMarkDoneAction), findsOneWidget);
    });

    testWidgets('the read-only reason is stated once', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrapDetails(assignment: _assignment()));
      await tester.pumpAndSettle();

      // The note now also explains that the completion mark is private,
      // so the two sentences render as one Text.
      expect(
        find.textContaining(AppStrings.assignmentStudentReadOnlyNote),
        findsOneWidget,
      );
      expect(
        find.textContaining(AppStrings.assignmentCompletionPrivateNote),
        findsOneWidget,
      );
    });
  });

  group('missing and optional fields', () {
    testWidgets('an empty description says so instead of rendering blank', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapDetails(assignment: _assignment(description: '   ')),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.assignmentNoInstructions), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    /*
     * An unresolvable offering is normal, not a bug: the assignment carries
     * ids, and the enrolment that names them may not be loaded yet. The
     * screen must drop those lines rather than print a raw id.
     */
    testWidgets('an unresolvable course hides the course and teacher lines', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapDetails(
          assignment: _assignment(),
          courses: FakeStudentCoursesProvider(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('BMIS3344'), findsNothing);
      expect(find.text('د. سارة قاسم'), findsNothing);
      expect(find.textContaining('off1'), findsNothing);

      // The assignment's own fields still render.
      expect(find.text('واجب البرمجة الأول'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a missing creation date simply omits that line', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapDetails(
          assignment: CourseAssignmentModel(
            id: 'a1',
            offeringId: 'off1',
            courseId: 'c1',
            semesterId: 'semester_2026_1',
            title: 'واجب بلا تاريخ إنشاء',
            dueAt: DateTime(2030, 9, 20, 23, 59),
            createdBy: 't1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('واجب بلا تاريخ إنشاء'), findsOneWidget);
      expect(
        find.textContaining(AppStrings.assignmentCreatedAtLabel),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a route reached without arguments explains itself', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrapDetails());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.assignmentUnavailableTitle), findsOneWidget);
      expect(find.text(AppStrings.assignmentUnavailableDesc), findsOneWidget);
      expect(find.text(AppStrings.backToAssignmentsAction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long Arabic title does not overflow at 360px', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapDetails(
          assignment: _assignment(
            title:
                'واجب بعنوان طويل جدًا يمتد على أكثر من سطر واحد بسهولة تامة '
                'ويحتوي تفاصيل كثيرة',
            dueAt: DateTime(2020, 1, 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('freshness without an extra read', () {
    /*
     * The card hands over the assignment it already holds, so opening the
     * screen costs no Firestore read. A live edit still wins, because the
     * provider is already streaming these documents for the tasks screen.
     */
    testWidgets('a live edit overrides the passed copy', (tester) async {
      _useNarrowScreen(tester);
      final stale = _assignment(title: 'العنوان القديم');
      final fresh = _assignment(title: 'العنوان المحدَّث');

      await tester.pumpWidget(
        _wrapDetails(
          assignment: stale,
          assignments: FakeAssignmentProvider(assignmentsValue: [fresh]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('العنوان المحدَّث'), findsOneWidget);
      expect(find.text('العنوان القديم'), findsNothing);
    });

    testWidgets('an assignment absent from the stream still renders', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapDetails(
          assignment: _assignment(),
          assignments: FakeAssignmentProvider(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('واجب البرمجة الأول'), findsOneWidget);
      expect(find.text(AppStrings.assignmentUnavailableTitle), findsNothing);
    });
  });

  group('navigation from the assignment card', () {
    testWidgets('tapping عرض التفاصيل opens the details screen', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapTasksScreen(assignments: [_assignment()]),
      );
      await tester.pumpAndSettle();

      // The card is on the الكل tab, which opens first.
      expect(find.text(AppStrings.viewDetailsAction), findsOneWidget);

      await tester.tap(find.text(AppStrings.viewDetailsAction));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.assignmentDetailsScreenTitle),
        findsOneWidget,
      );
      expect(
        find.textContaining(AppStrings.assignmentStudentReadOnlyNote),
        findsOneWidget,
      );
    });

    testWidgets('the الواجبات tab opens details too', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapTasksScreen(assignments: [_assignment()]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.workTabAssignments));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.viewDetailsAction));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.assignmentDetailsScreenTitle),
        findsOneWidget,
      );
    });

    testWidgets('back returns to the tasks screen with its bottom bar', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapTasksScreen(assignments: [_assignment()]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.viewDetailsAction));
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.assignmentDetailsScreenTitle),
        findsOneWidget,
      );

      // The details screen is pushed ON TOP, so it carries no bottom
      // navigation of its own and going back restores the one that was
      // already there.
      expect(find.byType(AcademiaBottomNavigation), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.tasksAndAssignmentsTitle), findsOneWidget);
      expect(
        find.text(AppStrings.assignmentDetailsScreenTitle),
        findsNothing,
      );
      expect(find.byType(AcademiaBottomNavigation), findsOneWidget);
    });
  });

  // ------------------------------------------- personal completion marking

  group('mark as done', () {
    testWidgets('an incomplete assignment offers تم الإنجاز', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrapDetails(assignment: _assignment()));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.assignmentMarkDoneAction), findsOneWidget);
      expect(find.text(AppStrings.assignmentCompletedTitle), findsNothing);
      expect(find.text(AppStrings.assignmentUndoDoneAction), findsNothing);
    });

    testWidgets('tapping it records the completion for this student', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      final progress = FakeProgressProvider();
      await tester.pumpWidget(
        _wrapDetails(assignment: _assignment(), progress: progress),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.assignmentMarkDoneAction));
      await tester.pumpAndSettle();

      expect(progress.calls, [(id: 'a1', completed: true)]);
      expect(progress.completedAssignmentIds, contains('a1'));
      expect(find.text(AppStrings.assignmentMarkedDoneSuccess), findsOneWidget);
    });

    testWidgets('the completed state renders with its timestamp', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapDetails(
          assignment: _assignment(),
          progress: FakeProgressProvider(
            completed: {'a1'},
            times: {'a1': DateTime(2026, 8, 20, 10, 30)},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.assignmentCompletedTitle), findsOneWidget);
      expect(find.text(AppStrings.assignmentCompletedBadge), findsOneWidget);
      expect(find.text(AppStrings.assignmentUndoDoneAction), findsOneWidget);
      expect(find.text(AppStrings.assignmentMarkDoneAction), findsNothing);
      expect(
        find.text(
          intl.DateFormat(
            'yyyy/MM/dd · hh:mm a',
            'ar',
          ).format(DateTime(2026, 8, 20, 10, 30)),
        ),
        findsOneWidget,
      );
    });

    /*
     * The server timestamp is null locally until the write syncs. The mark
     * itself is already true, so the state must render — only the date line
     * waits.
     */
    testWidgets('a completion with no timestamp yet still renders', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapDetails(
          assignment: _assignment(),
          progress: FakeProgressProvider(
            completed: {'a1'},
            times: {'a1': null},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.assignmentCompletedTitle), findsOneWidget);
      expect(
        find.textContaining(AppStrings.assignmentCompletedAtLabel),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the student can undo the completion', (tester) async {
      _useNarrowScreen(tester);
      final progress = FakeProgressProvider(
        completed: {'a1'},
        times: {'a1': DateTime(2026, 8, 20, 10, 30)},
      );
      await tester.pumpWidget(
        _wrapDetails(assignment: _assignment(), progress: progress),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.assignmentUndoDoneAction));
      await tester.pumpAndSettle();

      expect(progress.calls, [(id: 'a1', completed: false)]);
      expect(progress.completedAssignmentIds, isNot(contains('a1')));
      expect(find.text(AppStrings.assignmentUndoneSuccess), findsOneWidget);
      // And the screen is back to offering the action.
      expect(find.text(AppStrings.assignmentMarkDoneAction), findsOneWidget);
    });

    testWidgets('the state survives a rebuild', (tester) async {
      _useNarrowScreen(tester);
      final progress = FakeProgressProvider(completed: {'a1'});
      await tester.pumpWidget(
        _wrapDetails(assignment: _assignment(), progress: progress),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.assignmentCompletedTitle), findsOneWidget);

      // A provider notification rebuilds the subtree; the mark is read from
      // the provider, not held in widget state, so it must survive.
      progress.notifyListeners();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.assignmentCompletedTitle), findsOneWidget);
      expect(find.text(AppStrings.assignmentMarkDoneAction), findsNothing);
    });

    /*
     * Deadline state and personal completion are independent. An overdue
     * assignment can still be finished, and once it is, the screen must
     * stop calling it late.
     */
    testWidgets('an overdue assignment can still be marked complete', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      final overdue = _assignment(dueAt: DateTime(2020, 1, 1));
      final progress = FakeProgressProvider();

      await tester.pumpWidget(
        _wrapDetails(assignment: overdue, progress: progress),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.assignmentOverdueLabel), findsOneWidget);
      expect(find.text(AppStrings.assignmentMarkDoneAction), findsOneWidget);

      await tester.tap(find.text(AppStrings.assignmentMarkDoneAction));
      await tester.pumpAndSettle();

      expect(progress.completedAssignmentIds, contains('a1'));
      expect(find.text(AppStrings.assignmentCompletedBadge), findsOneWidget);
      // Completion takes precedence over the overdue badge.
      expect(find.text(AppStrings.assignmentOverdueLabel), findsNothing);

      // The teacher-owned fields are untouched by any of this.
      expect(overdue.dueAt, DateTime(2020, 1, 1));
      expect(overdue.status, CourseAssignmentModel.statusActive);
      expect(overdue.priority, CourseAssignmentModel.priorityHigh);
    });

    testWidgets('a failed write shows a friendly Arabic error', (tester) async {
      _useNarrowScreen(tester);
      final progress = FakeProgressProvider(shouldFail: true);
      await tester.pumpWidget(
        _wrapDetails(assignment: _assignment(), progress: progress),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.assignmentMarkDoneAction));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.assignmentProgressSaveError),
        findsOneWidget,
      );
      // No raw Firebase exception text reaches the student.
      expect(find.textContaining('FirebaseException'), findsNothing);
      expect(find.textContaining('permission-denied'), findsNothing);
      // And the screen stays on the correct (still incomplete) state.
      expect(find.text(AppStrings.assignmentMarkDoneAction), findsOneWidget);
      expect(find.text(AppStrings.assignmentCompletedTitle), findsNothing);
    });

    testWidgets('duplicate taps while saving produce one write', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      final progress = FakeProgressProvider();
      final gate = Completer<void>();
      progress.gate = gate;

      await tester.pumpWidget(
        _wrapDetails(assignment: _assignment(), progress: progress),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.assignmentMarkDoneAction));
      await tester.pump(); // start the write, do not let it finish

      // Button is disabled and showing progress while the write is open.
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Hammer it while it is in flight.
      await tester.tap(
        find.byType(AppPrimaryButton),
        warnIfMissed: false,
      );
      await tester.tap(
        find.byType(AppPrimaryButton),
        warnIfMissed: false,
      );
      await tester.pump();

      gate.complete();
      await tester.pumpAndSettle();

      expect(progress.calls, hasLength(1));
      expect(progress.calls.single, (id: 'a1', completed: true));
    });

    testWidgets('a teacher session gets no completion action at all', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapDetails(
          assignment: _assignment(),
          auth: FakeAuthProvider(role: UserRole.teacher),
          progress: FakeProgressProvider(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.assignmentMarkDoneAction), findsNothing);
      expect(find.text(AppStrings.assignmentUndoDoneAction), findsNothing);
      expect(find.text(AppStrings.assignmentCompletedTitle), findsNothing);
      // Still no management controls either — this screen never has them.
      expect(find.text(AppStrings.editAssignmentTitle), findsNothing);
      expect(find.text(AppStrings.archiveAssignmentAction), findsNothing);
    });

    testWidgets('an archived assignment offers no new completion', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapDetails(
          assignment: _assignment(
            status: CourseAssignmentModel.statusArchived,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.assignmentMarkDoneAction), findsNothing);
      expect(find.text(AppStrings.archivedStatus), findsOneWidget);
    });
  });
}
