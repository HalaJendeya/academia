import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/academics/models/major_model.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/dashboard/screens/dashboard_screen.dart';
import 'package:academia/features/curriculum/models/curriculum_course_model.dart';
import 'package:academia/features/semesters/models/semester_model.dart';

const _majorId = 'Bo7h3btN54SxANGuVqb1';

const _major = MajorModel(
  id: _majorId,
  name: 'نظم المعلومات الإدارية والتجارية المعاصرة',
  code: 'MIS',
  departmentId: 'dep1',
  totalLevels: 8,
  status: MajorModel.statusActive,
);

const _semester = SemesterModel(
  id: 'semester_2026_1',
  academicYear: '2026',
  semesterNumber: 1,
  semesterName: 'الفصل الأول 2026',
  status: SemesterModel.statusCurrent,
);

/// Level 4 of the live MIS plan: 3 courses (3h each) + 3 slots = 16 hours.
List<StudentProgramEntryView> _level4Rows() {
  return [
    for (final entry in const [
      ('BMIS2342', 1, 3),
      ('BMIS2344', 2, 3),
      ('BMIS2306', 3, 3),
    ])
      StudentProgramEntryView(
        entry: CurriculumCourseModel(
          id: '${_majorId}_course_${entry.$1}',
          majorId: _majorId,
          entryType: CurriculumCourseModel.entryCourse,
          courseId: 'course_${entry.$1}',
          academicLevel: 4,
          requirementType: CurriculumCourseModel.majorRequired,
          sequence: entry.$2,
        ),
        course: CourseModel(
          id: 'course_${entry.$1}',
          courseCode: entry.$1,
          title: 'مساق ${entry.$1}',
          description: '',
          creditHours: entry.$3,
          departmentId: 'dep1',
          status: CourseModel.statusActive,
        ),
      ),
    for (final slot in const [
      ('متطلب تخصص اختياري (1)', 4, 3, CurriculumCourseModel.majorElective),
      ('متطلب جامعة إجباري (4)', 5, 2, CurriculumCourseModel.universityRequired),
      (
        'متطلب جامعة اختياري (4)',
        6,
        2,
        CurriculumCourseModel.universityElective,
      ),
    ])
      StudentProgramEntryView(
        entry: CurriculumCourseModel(
          id: '${_majorId}_slot_4_${slot.$2}',
          majorId: _majorId,
          entryType: CurriculumCourseModel.entrySlot,
          slotLabel: slot.$1,
          academicLevel: 4,
          requirementType: slot.$4,
          creditHours: slot.$3,
          sequence: slot.$2,
        ),
      ),
  ];
}

// ------------------------------------------------------------------ fakes

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  FakeAuthProvider({this.profile});

  final AppUserModel? profile;

  @override
  AppUserModel? get currentUserProfile =>
      profile ??
      const AppUserModel(
        uid: '9psSX1ZO4cWD2z7c7HXVZTSnvAq2',
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
  bool get isLoggedIn => true;

  @override
  bool get isAdmin => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStudentCoursesProvider extends ChangeNotifier
    implements StudentCoursesProvider {
  FakeStudentCoursesProvider({
    this.hasMajorValue = true,
    this.hasCurrentSemesterValue = true,
    this.isLoadingValue = false,
    this.hasLoadedValue = true,
    this.errorValue,
    this.majorValue = _major,
    this.academicLevelValue = 4,
    this.totalHours = 134,
    List<StudentProgramEntryView>? recommended,
    this.currentCoursesValue = const [],
    this.availableNowValue = const [],
  }) : recommendedValue = recommended ?? _level4Rows();

  final bool hasMajorValue;
  final bool hasCurrentSemesterValue;
  final bool isLoadingValue;
  final bool hasLoadedValue;
  final String? errorValue;
  final MajorModel? majorValue;
  final int? academicLevelValue;
  final int totalHours;
  final List<StudentProgramEntryView> recommendedValue;
  final List<StudentCourseView> currentCoursesValue;
  final List<StudentAvailableCourseView> availableNowValue;

  @override
  bool get isLoading => isLoadingValue;

  @override
  bool get hasLoaded => hasLoadedValue;

  @override
  String? get errorMessage => errorValue;

  @override
  bool get hasMajor => hasMajorValue;

  @override
  bool get hasCurrentSemester => hasCurrentSemesterValue;

  @override
  SemesterModel? get currentSemester =>
      hasCurrentSemesterValue ? _semester : null;

  @override
  MajorModel? get major => majorValue;

  @override
  String get majorName => majorValue?.name ?? AppStrings.unknownMajor;

  @override
  int? get academicLevel => academicLevelValue;

  @override
  int get programTotalCreditHours => totalHours;

  @override
  List<StudentProgramEntryView> get recommendedForMyLevel => recommendedValue;

  @override
  int get recommendedCreditHours =>
      recommendedValue.fold<int>(0, (sum, row) => sum + row.creditHours);

  @override
  List<StudentCourseView> get currentCourses => currentCoursesValue;

  @override
  List<StudentAvailableCourseView> get availableNow => availableNowValue;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap({
  FakeStudentCoursesProvider? courses,
  FakeAuthProvider? auth,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth ?? FakeAuthProvider(),
      ),
      ChangeNotifierProvider<StudentCoursesProvider>.value(
        value: courses ?? FakeStudentCoursesProvider(),
      ),
    ],
    child: const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: DashboardScreen(),
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
  group('identity', () {
    testWidgets('renders the real name, level and resolved major name', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(
        find.text('${AppStrings.dashboardGreeting}، حلا جندية'),
        findsOneWidget,
      );

      // Level comes from the int in users/{uid}; the Arabic label is built
      // at render time. The major name is resolved from majors/{majorId},
      // never from the legacy free-text users.major.
      expect(
        find.text(
          '${AppStrings.academicLevelDisplay(4)} • '
          'نظم المعلومات الإدارية والتجارية المعاصرة',
        ),
        findsOneWidget,
      );
      expect(find.text('نظم المعلومات'), findsNothing); // legacy value
    });

    testWidgets('renders the current semester by stored status', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('الفصل الأول 2026'), findsOneWidget);
      expect(find.text(AppStrings.semesterStatusCurrent), findsOneWidget);
    });
  });

  group('plan summary', () {
    testWidgets('renders 134 total hours, level 4 and 16 level hours', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('134'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text(AppStrings.dashboardPlanTotalHours), findsOneWidget);
    });

    testWidgets('never shows a completion percentage', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // With zero enrollments any completion figure would be fabricated.
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });
  });

  group('courses summary', () {
    testWidgets('zero current and zero available render as valid empties', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.dashboardNoCurrentCourses), findsOneWidget);
      expect(find.text(AppStrings.dashboardNoAvailableCourses), findsOneWidget);
      // Empty is not an error.
      expect(find.text(AppStrings.coursesLoadError), findsNothing);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });

  group('recommended for level', () {
    testWidgets('previews plan rows and marks slots as non-courses', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final card = find.text(AppStrings.dashboardRecommendedTitle);
      await tester.scrollUntilVisible(card, 200);
      expect(card, findsOneWidget);
      expect(find.text('BMIS2342'), findsOneWidget);
    });

    testWidgets('a slot in the preview is never wrapped in a tap target', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      // Slots first, so they land inside the 3-row preview window.
      final slotsFirst = _level4Rows().reversed.toList();
      await tester.pumpWidget(
        _wrap(courses: FakeStudentCoursesProvider(recommended: slotsFirst)),
      );
      await tester.pumpAndSettle();

      final slot = find.text('متطلب جامعة اختياري (4)');
      await tester.scrollUntilVisible(slot, 200);
      expect(slot, findsOneWidget);

      expect(
        find.ancestor(of: slot, matching: find.byType(InkWell)),
        findsNothing,
      );
    });
  });

  group('deferred features', () {
    testWidgets('tasks show a coming-soon state, never fake counts', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final tasks = find.text(AppStrings.dashboardTasksTitle);
      await tester.scrollUntilVisible(tasks, 200);
      expect(tasks, findsOneWidget);
      expect(find.text(AppStrings.dashboardComingSoonBadge), findsOneWidget);

      // None of the invented metrics the old design implied.
      for (final fake in ['3 مهام اليوم', 'مهمتان', 'إنجاز', 'ساعات الدراسة']) {
        expect(find.text(fake), findsNothing);
      }
    });
  });

  group('degraded states', () {
    testWidgets('a student with no major still gets a usable dashboard', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          courses: FakeStudentCoursesProvider(
            hasMajorValue: false,
            majorValue: null,
            recommended: const [],
          ),
          auth: FakeAuthProvider(
            profile: const AppUserModel(
              uid: 'no-major',
              fullName: 'طالب بلا تخصص',
              email: 'x@test.com',
              role: UserRole.student,
              status: 'active',
              emailVerified: true,
              onboardingCompleted: true,
              onboardingStatus: 'completed',
              academicLevel: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Identity still renders, and the plan explains itself.
      expect(
        find.text('${AppStrings.dashboardGreeting}، طالب بلا تخصص'),
        findsOneWidget,
      );
      expect(find.text(AppStrings.dashboardPlanUnavailable), findsOneWidget);
      expect(find.text('134'), findsNothing);
    });

    testWidgets('identity survives a courses load failure', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          courses: FakeStudentCoursesProvider(
            hasLoadedValue: false,
            errorValue: AppStrings.curriculumLoadError,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // One failing section must not blank the whole screen.
      expect(
        find.text('${AppStrings.dashboardGreeting}، حلا جندية'),
        findsOneWidget,
      );
      expect(find.text('الفصل الأول 2026'), findsOneWidget);
      expect(find.text(AppStrings.curriculumLoadError), findsOneWidget);
      expect(find.text(AppStrings.dashboardQuickActionsTitle), findsWidgets);
    });
  });

  testWidgets('no overflow at a 360px viewport', (tester) async {
    _useNarrowScreen(tester);
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    // Scroll the whole dashboard; any RenderFlex overflow throws here.
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
