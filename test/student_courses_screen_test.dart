import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/models/course_offering_model.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/courses/screens/student_courses_screen.dart';
import 'package:academia/features/courses/widgets/student_program_entry_card.dart';
import 'package:academia/features/curriculum/models/curriculum_course_model.dart';
import 'package:academia/features/enrollments/models/enrollment_model.dart';
import 'package:academia/features/semesters/models/semester_model.dart';

// The live MIS plan: 31 course rows + 18 slot rows = 49, 134 hours.
const _courseRows = <(int, int, String, int, String)>[
  (1, 1, 'BUSA1341', 3, 'college_required'),
  (1, 2, 'ACCT1341', 3, 'college_required'),
  (1, 3, 'ECON1301', 3, 'college_required'),
  (1, 4, 'BMIS1341', 3, 'college_required'),
  (2, 1, 'BUSA1342', 3, 'college_required'),
  (2, 2, 'ACCT1342', 3, 'college_required'),
  (2, 3, 'ECON1303', 3, 'college_required'),
  (2, 4, 'BMIS1342', 3, 'major_required'),
  (3, 1, 'BMIS2341', 3, 'major_required'),
  (3, 2, 'BMIS2301', 3, 'major_required'),
  (3, 3, 'BMIS2347', 3, 'major_required'),
  (3, 4, 'BMIS2345', 3, 'major_required'),
  (4, 1, 'BMIS2342', 3, 'major_required'),
  (4, 2, 'BMIS2344', 3, 'major_required'),
  (4, 3, 'BMIS2306', 3, 'major_required'),
  (5, 1, 'BMIS3341', 3, 'major_required'),
  (5, 2, 'BMIS3343', 3, 'major_required'),
  (5, 3, 'BMIS3345', 3, 'major_required'),
  (5, 4, 'BMIS3313', 3, 'major_required'),
  (6, 1, 'BMIS3342', 3, 'major_required'),
  (6, 2, 'BMIS3344', 3, 'major_required'),
  (6, 3, 'BMIS3347', 3, 'major_required'),
  (6, 4, 'BMIS3314', 3, 'major_required'),
  (7, 1, 'BMIS4341', 3, 'major_required'),
  (7, 2, 'BMIS4315', 3, 'major_required'),
  (7, 3, 'BMIS4343', 3, 'major_required'),
  (7, 4, 'BMIS4316', 3, 'major_required'),
  (8, 1, 'BMIS4302', 3, 'major_required'),
  (8, 2, 'BMIS4346', 3, 'major_required'),
  (8, 3, 'BMIS4347', 3, 'major_required'),
  (8, 4, 'BMIS4200', 2, 'major_required'),
];

const _slotRows = <(int, int, String, int, String)>[
  (1, 5, 'متطلب جامعة إجباري (1)', 2, 'university_required'),
  (1, 6, 'متطلب جامعة اختياري (1)', 2, 'university_elective'),
  (2, 5, 'متطلب جامعة إجباري (2)', 2, 'university_required'),
  (2, 6, 'متطلب جامعة اختياري (2)', 2, 'university_elective'),
  (3, 5, 'متطلب جامعة إجباري (3)', 2, 'university_required'),
  (3, 6, 'متطلب جامعة اختياري (3)', 2, 'university_elective'),
  (4, 4, 'متطلب تخصص اختياري (1)', 3, 'major_elective'),
  (4, 5, 'متطلب جامعة إجباري (4)', 2, 'university_required'),
  (4, 6, 'متطلب جامعة اختياري (4)', 2, 'university_elective'),
  (5, 5, 'متطلب تخصص اختياري (2)', 3, 'major_elective'),
  (5, 6, 'متطلب جامعة اختياري (5)', 2, 'university_elective'),
  (6, 5, 'متطلب جامعة إجباري (5)', 2, 'university_required'),
  (6, 6, 'متطلب جامعة اختياري (6)', 2, 'university_elective'),
  (7, 5, 'متطلب تخصص اختياري (3)', 3, 'major_elective'),
  (7, 6, 'مساق حر 1', 3, 'free_elective'),
  (8, 5, 'متطلب تخصص اختياري (4)', 3, 'major_elective'),
  (8, 6, 'مساق حر 2', 3, 'free_elective'),
  (8, 7, 'متطلب جامعة إجباري (6)', 2, 'university_required'),
];

const _majorId = 'Bo7h3btN54SxANGuVqb1';
String _courseId(String code) => 'course_$code';

CourseModel _course(String code, int hours) => CourseModel(
  id: _courseId(code),
  courseCode: code,
  title: 'مساق $code',
  description: '',
  creditHours: hours,
  departmentId: 'dep1',
  status: CourseModel.statusActive,
);

Map<int, List<StudentProgramEntryView>> _buildProgram() {
  final grouped = <int, List<StudentProgramEntryView>>{};

  for (final row in _courseRows) {
    grouped
        .putIfAbsent(row.$1, () => [])
        .add(
          StudentProgramEntryView(
            entry: CurriculumCourseModel(
              id: CurriculumCourseModel.buildId(_majorId, _courseId(row.$3)),
              majorId: _majorId,
              entryType: CurriculumCourseModel.entryCourse,
              courseId: _courseId(row.$3),
              academicLevel: row.$1,
              requirementType: row.$5,
              sequence: row.$2,
            ),
            course: _course(row.$3, row.$4),
          ),
        );
  }

  for (final row in _slotRows) {
    grouped
        .putIfAbsent(row.$1, () => [])
        .add(
          StudentProgramEntryView(
            entry: CurriculumCourseModel(
              id: CurriculumCourseModel.buildSlotId(_majorId, row.$1, row.$2),
              majorId: _majorId,
              entryType: CurriculumCourseModel.entrySlot,
              slotLabel: row.$3,
              academicLevel: row.$1,
              requirementType: row.$5,
              creditHours: row.$4,
              sequence: row.$2,
            ),
          ),
        );
  }

  for (final rows in grouped.values) {
    rows.sort((a, b) => a.sequence.compareTo(b.sequence));
  }
  return grouped;
}

const _semester = SemesterModel(
  id: 'semester_2026_1',
  academicYear: '2026',
  semesterNumber: 1,
  semesterName: 'الفصل الأول 2026',
  status: SemesterModel.statusCurrent,
);

StudentCourseView _attempt({
  required String code,
  required String semesterId,
  required String semesterName,
  required int attemptNumber,
  String status = EnrollmentModel.statusActive,
  String? completionStatus,
  String? grade,
}) {
  final courseId = _courseId(code);
  final offeringId = '${courseId}_${semesterId}_1';
  return StudentCourseView(
    enrollment: EnrollmentModel(
      id: 'student1_$offeringId',
      userId: 'student1',
      offeringId: offeringId,
      courseId: courseId,
      semesterId: semesterId,
      attemptNumber: attemptNumber,
      status: status,
      completionStatus: completionStatus,
      grade: grade,
      assignedBy: 'admin1',
    ),
    offering: CourseOfferingModel(
      id: offeringId,
      courseId: courseId,
      semesterId: semesterId,
      instructorName: 'م. حمزة السويركي',
      section: '1',
      status: CourseOfferingModel.statusActive,
    ),
    course: _course(code, 3),
    semester: SemesterModel(
      id: semesterId,
      academicYear: '2025',
      semesterNumber: 2,
      semesterName: semesterName,
      status: SemesterModel.statusCompleted,
    ),
  );
}

// ------------------------------------------------------------------ fakes

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool get isLoggedIn => true;

  @override
  bool get isAdmin => false;

  @override
  AppUserModel? get currentUserProfile => const AppUserModel(
    uid: 'student1',
    fullName: 'حلا جندية',
    email: 's@test.com',
    role: UserRole.student,
    status: 'active',
    emailVerified: true,
    onboardingCompleted: true,
    onboardingStatus: 'completed',
    majorId: _majorId,
    academicLevel: 4,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStudentCoursesProvider extends ChangeNotifier
    implements StudentCoursesProvider {
  FakeStudentCoursesProvider({
    this.hasMajorValue = true,
    this.hasCurrentSemesterValue = true,
    Map<int, List<StudentProgramEntryView>>? program,
    this.availableNowValue = const [],
    this.currentCoursesValue = const [],
    this.historyValue = const {},
  }) : programValue = program ?? _buildProgram();

  final bool hasMajorValue;
  final bool hasCurrentSemesterValue;
  final Map<int, List<StudentProgramEntryView>> programValue;
  final List<StudentAvailableCourseView> availableNowValue;
  final List<StudentCourseView> currentCoursesValue;
  final Map<String, List<StudentCourseView>> historyValue;

  @override
  bool get isLoading => false;

  @override
  bool get hasLoaded => true;

  @override
  String? get errorMessage => null;

  @override
  bool get hasMajor => hasMajorValue;

  @override
  bool get hasCurrentSemester => hasCurrentSemesterValue;

  @override
  SemesterModel? get currentSemester => _semester;

  @override
  Map<int, List<StudentProgramEntryView>> get programByLevel => programValue;

  @override
  List<int> get programLevels => programValue.keys.toList()..sort();

  @override
  List<StudentProgramEntryView> programForLevel(int level) =>
      programValue[level] ?? const [];

  @override
  int get programTotalCreditHours => programValue.values
      .expand((rows) => rows)
      .fold<int>(0, (sum, row) => sum + row.creditHours);

  @override
  List<StudentAvailableCourseView> get availableNow => availableNowValue;

  @override
  List<StudentCourseView> get currentCourses => currentCoursesValue;

  @override
  Map<String, List<StudentCourseView>> get historyByCourse => historyValue;

  @override
  List<StudentCourseView> get history =>
      historyValue.values.expand((v) => v).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(FakeStudentCoursesProvider provider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
      ChangeNotifierProvider<StudentCoursesProvider>.value(value: provider),
    ],
    child: const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: StudentCoursesScreen(),
      ),
    ),
  );
}

/// Narrow Android viewport — the target device class.
void _useNarrowScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// The tab strip scrolls horizontally on a narrow screen, so a tab may start
/// off-screen and must be brought into view before it can be tapped.
/// The screen has two scrollables (the horizontal tab strip and the content
/// list), so scrolling has to name the one it means.
Finder get _contentList => find.descendant(
  of: find.byType(ListView),
  matching: find.byType(Scrollable),
);

Future<void> _openTab(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('برنامجي', () {
    testWidgets('renders the 49-row / 134-hour summary and all 8 levels', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap(FakeStudentCoursesProvider()));
      await tester.pumpAndSettle();

      expect(find.text('49'), findsOneWidget);
      expect(find.text('134'), findsOneWidget);

      for (var level = 1; level <= 8; level++) {
        final header = find.text(AppStrings.academicLevelDisplay(level));
        await tester.scrollUntilVisible(header, 300, scrollable: _contentList);
        expect(header, findsOneWidget);
      }
    });

    testWidgets('slot rows render but are not tappable as courses', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap(FakeStudentCoursesProvider()));
      await tester.pumpAndSettle();

      final slot = find.text('متطلب جامعة إجباري (1)');
      await tester.scrollUntilVisible(slot, 200, scrollable: _contentList);
      expect(slot, findsOneWidget);

      final slotCard = find
          .ancestor(of: slot, matching: find.byType(StudentProgramEntryCard))
          .first;
      final widget = tester.widget<StudentProgramEntryCard>(slotCard);
      expect(widget.entry.isSlot, isTrue);

      // Tapping a slot must not navigate anywhere.
      await tester.tap(slot);
      await tester.pumpAndSettle();
      expect(find.byType(StudentCoursesScreen), findsOneWidget);
      expect(
        find.descendant(of: slotCard, matching: find.text(AppStrings.slotNotACourseNote)),
        findsOneWidget,
      );
    });

    testWidgets('course rows expose a course code and are tappable', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap(FakeStudentCoursesProvider()));
      await tester.pumpAndSettle();

      expect(find.text('BUSA1341'), findsOneWidget);

      final courseCard = find
          .ancestor(
            of: find.text('مساق BUSA1341'),
            matching: find.byType(StudentProgramEntryCard),
          )
          .first;
      expect(
        tester.widget<StudentProgramEntryCard>(courseCard).onTap,
        isNotNull,
      );
    });

    testWidgets('a student with no major sees the no-major state', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(FakeStudentCoursesProvider(hasMajorValue: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noMajorTitle), findsOneWidget);
      expect(find.text('134'), findsNothing);
    });
  });

  group('empty states are distinct and valid', () {
    testWidgets('available-now empty state is not an error', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap(FakeStudentCoursesProvider()));
      await tester.pumpAndSettle();

      await _openTab(tester, AppStrings.studentTabAvailableNow);

      expect(find.text(AppStrings.availableNowEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.coursesLoadError), findsNothing);
    });

    testWidgets('current-courses empty state is its own message', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap(FakeStudentCoursesProvider()));
      await tester.pumpAndSettle();

      await _openTab(tester, AppStrings.studentTabCurrent);

      expect(find.text(AppStrings.currentCoursesEmptyTitle), findsOneWidget);
      // Must not be collapsed into the available-now wording.
      expect(find.text(AppStrings.availableNowEmptyTitle), findsNothing);
    });

    testWidgets('history empty state is its own message', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap(FakeStudentCoursesProvider()));
      await tester.pumpAndSettle();

      await _openTab(tester, AppStrings.studentTabHistory);

      expect(find.text(AppStrings.historyEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.currentCoursesEmptyTitle), findsNothing);
    });

    testWidgets('no current semester is distinguished from an empty list', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(FakeStudentCoursesProvider(hasCurrentSemesterValue: false)),
      );
      await tester.pumpAndSettle();

      await _openTab(tester, AppStrings.studentTabAvailableNow);
      expect(find.text(AppStrings.noCurrentSemesterTitle), findsOneWidget);
    });
  });

  group('enrolled data', () {
    testWidgets('one current course renders from StudentCourseView', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          FakeStudentCoursesProvider(
            currentCoursesValue: [
              _attempt(
                code: 'BMIS2344',
                semesterId: 'semester_2026_1',
                semesterName: 'الفصل الأول 2026',
                attemptNumber: 1,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _openTab(tester, AppStrings.studentTabCurrent);

      expect(find.text('مساق BMIS2344'), findsOneWidget);
      expect(find.text('BMIS2344'), findsOneWidget);
      expect(find.text('م. حمزة السويركي'), findsOneWidget); // from the offering
      expect(find.text('الفصل الأول 2026'), findsOneWidget);
      expect(find.text(AppStrings.currentCoursesEmptyTitle), findsNothing);
    });

    testWidgets('two attempts of one course render as separate attempts', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          FakeStudentCoursesProvider(
            historyValue: {
              _courseId('BMIS2344'): [
                _attempt(
                  code: 'BMIS2344',
                  semesterId: 'semester_2024_2',
                  semesterName: 'الفصل الثاني 2024',
                  attemptNumber: 1,
                  status: EnrollmentModel.statusCompleted,
                  completionStatus: EnrollmentModel.completionFailed,
                ),
                _attempt(
                  code: 'BMIS2344',
                  semesterId: 'semester_2025_2',
                  semesterName: 'الفصل الثاني 2025',
                  attemptNumber: 2,
                  status: EnrollmentModel.statusCompleted,
                  completionStatus: EnrollmentModel.completionPassed,
                  grade: 'جيد جدًا',
                ),
              ],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _openTab(tester, AppStrings.studentTabHistory);

      expect(find.text('${AppStrings.attemptsCountLabel}: 2'), findsOneWidget);
      expect(find.text('${AppStrings.attemptLabel} 1'), findsOneWidget);
      expect(find.text('${AppStrings.attemptLabel} 2'), findsOneWidget);
      expect(find.text(AppStrings.completionFailedLabel), findsOneWidget);
      expect(find.text(AppStrings.completionPassedLabel), findsOneWidget);
      expect(find.text('${AppStrings.gradeLabel}: جيد جدًا'), findsOneWidget);
      expect(find.text('الفصل الثاني 2024 '), findsNothing);
    });
  });

  testWidgets('no fabricated progress, rating or mock values appear', (
    tester,
  ) async {
    _useNarrowScreen(tester);
    await tester.pumpWidget(
      _wrap(
        FakeStudentCoursesProvider(
          currentCoursesValue: [
            _attempt(
              code: 'BMIS2344',
              semesterId: 'semester_2026_1',
              semesterName: 'الفصل الأول 2026',
              attemptNumber: 1,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _openTab(tester, AppStrings.studentTabCurrent);

    // The teammate's mock UI showed a progress bar, a percentage, a star
    // rating and "متابعة المساق". None of them have backing data.
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.textContaining('%'), findsNothing);

    // And none of the teammate's hardcoded fixtures leaked in.
    for (final mock in [
      'مقدمة في علوم الحاسب',
      'د. محمد العتيبي',
      'رياضيات منفصلة',
      '4 مهام قادمة',
      'اختبار غدًا',
    ]) {
      expect(find.text(mock), findsNothing, reason: 'mock value "$mock" leaked');
    }
  });
}
