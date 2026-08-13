import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/core/widgets/app_card.dart';
import 'package:academia/features/academics/models/department_model.dart';
import 'package:academia/features/academics/models/major_model.dart';
import 'package:academia/features/academics/providers/academic_structure_provider.dart';
import 'package:academia/features/admin/screens/admin_curriculum_screen.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/providers/course_provider.dart';
import 'package:academia/features/curriculum/models/curriculum_course_model.dart';
import 'package:academia/features/curriculum/providers/curriculum_provider.dart';

/*
 * The official MIS plan as migrated in Phase 7C: 31 course rows + 18 slot
 * rows = 49, hours 16/16/16/16/17/16/18/19 = 134.
 *
 * (academicLevel, sequence, courseCode, creditHours, requirementType)
 */
const _courseRows = <(int, int, String, int, String)>[
  (1, 1, 'BUSA1341', 3, 'college_required'),
  (1, 2, 'ACCT1341', 3, 'college_required'),
  (1, 3, 'ECON1301', 3, 'college_required'),
  (1, 4, 'BMIS1341', 3, 'college_required'), // CSW-001
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

/// (academicLevel, sequence, slotLabel, creditHours, requirementType)
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

const _majorId = 'maj1';
const _departmentId = 'dep1';

String _courseIdOf(String code) => 'course_$code';

final _major = MajorModel(
  id: _majorId,
  name: 'نظم المعلومات الإدارية والتجارية المعاصرة',
  code: 'MIS',
  departmentId: _departmentId,
  totalLevels: 8,
  status: MajorModel.statusActive,
);

/// 31 curriculum courses + MIS202 (outside the plan) = the live catalog of 32.
List<CourseModel> _buildCourses() {
  final courses = <CourseModel>[
    for (final row in _courseRows)
      CourseModel(
        id: _courseIdOf(row.$3),
        courseCode: row.$3,
        title: 'مساق ${row.$3}',
        description: '',
        creditHours: row.$4,
        departmentId: _departmentId,
        status: CourseModel.statusActive,
      ),
    const CourseModel(
      id: 'XiaHEH1GBYuw4znLQlSe',
      courseCode: 'MIS202',
      title: 'قواعد بيانات متقدمة',
      description: '',
      creditHours: 3,
      departmentId: _departmentId,
      status: CourseModel.statusArchived,
    ),
  ];
  return courses;
}

List<CurriculumCourseModel> _buildCurriculum() {
  final entries = <CurriculumCourseModel>[
    for (final row in _courseRows)
      CurriculumCourseModel(
        id: CurriculumCourseModel.buildId(_majorId, _courseIdOf(row.$3)),
        majorId: _majorId,
        entryType: CurriculumCourseModel.entryCourse,
        courseId: _courseIdOf(row.$3),
        academicLevel: row.$1,
        requirementType: row.$5,
        sequence: row.$2,
      ),
    for (final row in _slotRows)
      CurriculumCourseModel(
        id: CurriculumCourseModel.buildSlotId(_majorId, row.$1, row.$2),
        majorId: _majorId,
        entryType: CurriculumCourseModel.entrySlot,
        slotLabel: row.$3,
        academicLevel: row.$1,
        requirementType: row.$5,
        creditHours: row.$4,
        sequence: row.$2,
      ),
  ];

  entries.sort((a, b) {
    final byLevel = a.academicLevel.compareTo(b.academicLevel);
    if (byLevel != 0) return byLevel;
    return a.sequence.compareTo(b.sequence);
  });
  return entries;
}

// ------------------------------------------------------------------- fakes

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool get isLoggedIn => true;

  @override
  bool get isAdmin => true;

  @override
  bool get isLoading => false;

  @override
  AppUserModel? get currentUserProfile => const AppUserModel(
    uid: 'admin1',
    fullName: 'Admin',
    email: 'admin@test.com',
    role: UserRole.admin,
    status: 'active',
    emailVerified: true,
    onboardingCompleted: true,
    onboardingStatus: 'completed',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStructureProvider extends ChangeNotifier
    implements AcademicStructureProvider {
  @override
  List<MajorModel> get majors => [_major];

  @override
  Map<String, MajorModel> get majorsById => {_majorId: _major};

  @override
  List<DepartmentModel> get departments => const [];

  @override
  void listenToStructure() {}

  @override
  void listenToDepartments() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCourseProvider extends ChangeNotifier implements CourseProvider {
  @override
  List<CourseModel> get courses => _buildCourses();

  @override
  void listenToCourses() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCurriculumProvider extends ChangeNotifier
    implements CurriculumProvider {
  final List<CurriculumCourseModel> _entries = _buildCurriculum();

  @override
  List<CurriculumCourseModel> get entries => _entries;

  @override
  bool get isLoading => false;

  @override
  bool get isSaving => false;

  @override
  String? get errorMessage => null;

  @override
  List<int> get levels {
    final set = _entries.map((e) => e.academicLevel).toSet().toList()..sort();
    return set;
  }

  @override
  List<CurriculumCourseModel> entriesForLevel(int level) =>
      _entries.where((e) => e.academicLevel == level).toList();

  @override
  void listenToCurriculum(String majorId) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
      ChangeNotifierProvider<AcademicStructureProvider>(
        create: (_) => FakeStructureProvider(),
      ),
      ChangeNotifierProvider<CourseProvider>(
        create: (_) => FakeCourseProvider(),
      ),
      ChangeNotifierProvider<CurriculumProvider>(
        create: (_) => FakeCurriculumProvider(),
      ),
    ],
    child: MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            settings: RouteSettings(arguments: _major),
            builder: (_) => const AdminCurriculumScreen(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('AdminCurriculumScreen — live MIS plan', () {
    testWidgets('renders 49 rows across levels 1..8 with 134 hours', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Summary card: 49 rows / 134 hours.
      expect(find.text('49'), findsOneWidget);
      expect(find.text('134'), findsOneWidget);

      // Every level header is present, and each level's hour total matches
      // the official plan. Scrolling is required — the plan is long.
      const expectedLevelHours = <int, int>{
        1: 16, 2: 16, 3: 16, 4: 16, 5: 17, 6: 16, 7: 18, 8: 19,
      };

      for (final entry in expectedLevelHours.entries) {
        final header = find.text(AppStrings.academicLevelDisplay(entry.key));
        await tester.scrollUntilVisible(header, 300);
        expect(header, findsOneWidget);
        expect(
          find.text('${entry.value} ${AppStrings.creditHoursShort}'),
          findsWidgets,
          reason: 'level ${entry.key} should total ${entry.value} hours',
        );
      }
    });

    testWidgets('slot rows are labelled and never open course details', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // The list builds lazily, so the level-1 slot must be scrolled into view.
      final slotLabel = find.text('متطلب جامعة إجباري (1)');
      await tester.scrollUntilVisible(slotLabel, 200);
      expect(slotLabel, findsOneWidget);

      // A slot is not a course: its card carries the explanatory note and
      // never exposes the "view course" action.
      final slotCard = find
          .ancestor(of: slotLabel, matching: find.byType(AppCard))
          .first;
      expect(
        find.descendant(of: slotCard, matching: find.text(AppStrings.viewAction)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: slotCard,
          matching: find.text(AppStrings.slotNotSelectableNote),
        ),
        findsOneWidget,
      );

      // A course row in the same plan does expose it.
      final courseTitle = find.text('مساق BUSA1341');
      await tester.scrollUntilVisible(courseTitle, -200);
      final courseCard = find
          .ancestor(of: courseTitle, matching: find.byType(AppCard))
          .first;
      expect(
        find.descendant(
          of: courseCard,
          matching: find.text(AppStrings.viewAction),
        ),
        findsOneWidget,
      );
    });

    testWidgets('requirement types render in Arabic, never as raw enums', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // CSW-001: BMIS1341 stays a college requirement, shown in Arabic.
      expect(find.text(AppStrings.requirementCollegeRequired), findsWidgets);

      final universityRequired = find.text(
        AppStrings.requirementUniversityRequired,
      );
      await tester.scrollUntilVisible(universityRequired, 200);
      expect(universityRequired, findsWidgets);

      // Raw enum values must never reach the screen, at any scroll position.
      for (final raw in CurriculumCourseModel.allowedRequirementTypes) {
        expect(
          find.text(raw),
          findsNothing,
          reason: 'raw enum "$raw" must never be shown to the admin',
        );
      }
    });
  });
}
