import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/assignments/models/course_assignment_model.dart';
import 'package:academia/features/assignments/providers/course_assignment_provider.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/models/course_offering_model.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/courses/screens/student_course_detail_screen.dart';
import 'package:academia/features/curriculum/models/curriculum_course_model.dart';
import 'package:academia/features/enrollments/models/enrollment_model.dart';
import 'package:academia/features/files/models/course_file_model.dart';
import 'package:academia/features/files/providers/course_file_provider.dart';
import 'package:academia/features/semesters/models/semester_model.dart';

// ------------------------------------------------------------------ fakes

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

  final listenedOfferingIds = <String>[];

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
  void listenToOfferingAssignments(String offeringId) =>
      listenedOfferingIds.add(offeringId);

  @override
  void stopListening() {}

  /*
   * Phase 8.4: leaving the tab hands the provider back to the student's
   * app-wide subscription rather than cancelling it outright.
   */
  int restoreCalls = 0;

  @override
  void restoreStudentOfferings() => restoreCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFileProvider extends ChangeNotifier implements CourseFileProvider {
  @override
  List<CourseFileModel> get files => const <CourseFileModel>[];

  @override
  List<CourseFileModel> get activeFiles => const <CourseFileModel>[];

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  void listenToOfferingFiles(String offeringId) {}

  @override
  void stopListening() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStudentCoursesProvider extends ChangeNotifier
    implements StudentCoursesProvider {
  FakeStudentCoursesProvider({this.attempt});

  final StudentCourseView? attempt;

  @override
  CourseModel? courseById(String? courseId) =>
      courseId == 'c1' ? _course : null;

  @override
  CourseOfferingModel? offeringById(String? offeringId) => offeringId == 'off1'
      ? const CourseOfferingModel(
          id: 'off1',
          courseId: 'c1',
          semesterId: 'semester_2026_1',
          teacherId: 't1',
          instructorName: 'د. سارة قاسم',
          section: '2',
          status: 'active',
        )
      : null;

  @override
  CurriculumCourseModel? curriculumEntryForCourse(String? courseId) => null;

  @override
  List<StudentCourseView> get currentCourses =>
      attempt == null ? const [] : [attempt!];

  @override
  List<StudentCourseView> get history => const [];

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

StudentCourseView _attempt() => StudentCourseView(
  enrollment: const EnrollmentModel(
    id: 'u1_off1',
    userId: 'u1',
    offeringId: 'off1',
    courseId: 'c1',
    semesterId: 'semester_2026_1',
    status: 'active',
    assignedBy: 'admin1',
  ),
  offering: const CourseOfferingModel(
    id: 'off1',
    courseId: 'c1',
    semesterId: 'semester_2026_1',
    teacherId: 't1',
    instructorName: 'د. سارة قاسم',
    section: '2',
    status: 'active',
  ),
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
  DateTime? dueAt,
  String priority = CourseAssignmentModel.priorityHigh,
  String status = CourseAssignmentModel.statusActive,
}) {
  return CourseAssignmentModel(
    id: id,
    offeringId: 'off1',
    courseId: 'c1',
    semesterId: 'semester_2026_1',
    title: title,
    description: 'حل التمارين',
    dueAt: dueAt ?? DateTime(2030, 9, 20, 23, 59),
    priority: priority,
    status: status,
    createdBy: 't1',
  );
}

// ----------------------------------------------------------------- harness

Widget _wrap({
  required FakeAssignmentProvider assignments,
  String? offeringId = 'off1',
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<StudentCoursesProvider>.value(
        value: FakeStudentCoursesProvider(attempt: _attempt()),
      ),
      ChangeNotifierProvider<CourseAssignmentProvider>.value(
        value: assignments,
      ),
      ChangeNotifierProvider<CourseFileProvider>.value(value: FakeFileProvider()),
    ],
    child: MaterialApp(
      locale: const Locale('ar'),
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: RouteSettings(
          name: AppRoutes.courseDetail,
          arguments: StudentCourseDetailArgs(
            courseId: 'c1',
            offeringId: offeringId,
          ),
        ),
        builder: (_) => const Directionality(
          textDirection: TextDirection.rtl,
          child: StudentCourseDetailScreen(),
        ),
      ),
    ),
  );
}

Future<void> _openAssignmentsTab(WidgetTester tester) async {
  await tester.tap(find.text(AppStrings.courseAssignmentsTab));
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

  group('Assignments tab', () {
    testWidgets('subscribes to exactly the enrolled offering', (tester) async {
      _useNarrowScreen(tester);
      final assignments = FakeAssignmentProvider();
      await tester.pumpWidget(_wrap(assignments: assignments));
      await tester.pumpAndSettle();
      await _openAssignmentsTab(tester);

      expect(assignments.listenedOfferingIds, contains('off1'));
    });

    testWidgets('shows an active assignment', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment()],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openAssignmentsTab(tester);

      expect(find.text('واجب البرمجة الأول'), findsOneWidget);
      expect(find.text(AppStrings.assignmentPriorityHigh), findsOneWidget);
    });

    testWidgets('shows multiple assignments', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          assignments: FakeAssignmentProvider(
            assignmentsValue: [
              _assignment(id: 'a1', title: 'واجب أول'),
              _assignment(id: 'a2', title: 'واجب ثانٍ'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openAssignmentsTab(tester);

      expect(find.text('واجب أول'), findsOneWidget);
      expect(find.text('واجب ثانٍ'), findsOneWidget);
    });

    /*
     * Archived assignments never reach the student in production because
     * the query filters on status. This asserts the second line of
     * defence: even if one arrived, the tab renders only active ones.
     */
    testWidgets('an archived assignment is not rendered', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          assignments: FakeAssignmentProvider(
            assignmentsValue: [
              _assignment(id: 'a1', title: 'واجب نشط'),
              _assignment(
                id: 'a2',
                title: 'واجب مؤرشف',
                status: CourseAssignmentModel.statusArchived,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openAssignmentsTab(tester);

      expect(find.text('واجب نشط'), findsOneWidget);
      expect(find.text('واجب مؤرشف'), findsNothing);
    });

    testWidgets('an overdue assignment is labelled overdue', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment(dueAt: DateTime(2020, 1, 1))],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openAssignmentsTab(tester);

      expect(find.text(AppStrings.assignmentOverdueLabel), findsOneWidget);
    });

    testWidgets('an assignment due later today is labelled due today', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      final now = DateTime.now();
      final laterToday = DateTime(now.year, now.month, now.day, 23, 59);

      await tester.pumpWidget(
        _wrap(
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment(dueAt: laterToday)],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openAssignmentsTab(tester);

      // 23:59 today is either "due today" or, if the suite runs in that
      // last minute, "overdue" — both are correct, neither is "soon".
      final dueToday = find.text(AppStrings.assignmentDueTodayLabel);
      final overdue = find.text(AppStrings.assignmentOverdueLabel);
      expect(
        dueToday.evaluate().isNotEmpty || overdue.evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('a deadline within 24h is labelled due soon', (tester) async {
      _useNarrowScreen(tester);
      // Tomorrow at this time: inside the window but a different day.
      final soon = DateTime.now().add(const Duration(hours: 20));

      await tester.pumpWidget(
        _wrap(
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment(dueAt: soon)],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openAssignmentsTab(tester);

      final soonLabel = find.text(AppStrings.assignmentDueSoonLabel);
      final dueToday = find.text(AppStrings.assignmentDueTodayLabel);
      expect(
        soonLabel.evaluate().isNotEmpty || dueToday.evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('the student gets no management controls', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment()],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openAssignmentsTab(tester);

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text(AppStrings.archiveAssignmentAction), findsNothing);
      expect(find.text(AppStrings.editAssignmentTitle), findsNothing);
      expect(find.text(AppStrings.addAssignmentTitle), findsNothing);
    });

    testWidgets('empty assignments give an honest empty state', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap(assignments: FakeAssignmentProvider()));
      await tester.pumpAndSettle();
      await _openAssignmentsTab(tester);

      expect(find.text(AppStrings.noAssignmentsTitle), findsOneWidget);
      expect(find.text(AppStrings.courseAssignmentsEmptyDesc), findsOneWidget);
    });

    testWidgets('loading is shown before data arrives', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(assignments: FakeAssignmentProvider(loading: true)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.courseAssignmentsTab));
      /*
       * Advance past the tab transition without settling: the loading
       * spinner animates forever, so pumpAndSettle would never return.
       */
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    /*
     * A study-plan course the student never enrolled in has no offering,
     * and therefore no assignments it could legitimately show.
     */
    testWidgets('a course with no offering says so instead of showing data', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      final assignments = FakeAssignmentProvider(
        assignmentsValue: [_assignment()],
      );
      await tester.pumpWidget(
        _wrap(assignments: assignments, offeringId: null),
      );
      await tester.pumpAndSettle();
      await _openAssignmentsTab(tester);

      expect(
        find.text(AppStrings.courseAssignmentsNoOfferingTitle),
        findsOneWidget,
      );
      expect(find.text('واجب البرمجة الأول'), findsNothing);
      // And nothing was subscribed to.
      expect(assignments.listenedOfferingIds, isEmpty);
    });

    testWidgets('an error stays local to the tab', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          assignments: FakeAssignmentProvider(
            error: AppStrings.courseAssignmentsLoadError,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openAssignmentsTab(tester);

      expect(find.text(AppStrings.courseAssignmentsLoadError), findsOneWidget);
      // The rest of the course detail screen is untouched.
      expect(find.text(AppStrings.courseOverviewTab), findsOneWidget);
      expect(find.text(AppStrings.courseFilesTab), findsOneWidget);
    });

    testWidgets('other course-detail tabs still work', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          assignments: FakeAssignmentProvider(
            assignmentsValue: [_assignment()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Overview renders the real course before we ever open assignments.
      expect(find.textContaining('تحليل وتصميم النظم'), findsWidgets);

      await _openAssignmentsTab(tester);
      expect(find.text('واجب البرمجة الأول'), findsOneWidget);
    });

    testWidgets('no overflow at 360px with long Arabic assignments', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          assignments: FakeAssignmentProvider(
            assignmentsValue: [
              _assignment(
                id: 'a1',
                title: 'واجب بعنوان طويل جدًا يمتد على أكثر من سطر بسهولة تامة',
                dueAt: DateTime(2020, 1, 1),
              ),
              _assignment(id: 'a2', priority: 'low'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _openAssignmentsTab(tester);

      expect(tester.takeException(), isNull);
    });
  });
}
