import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/academics/models/major_model.dart';
import 'package:academia/features/academics/services/major_service.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/models/course_offering_model.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/courses/services/course_offering_service.dart';
import 'package:academia/features/courses/services/course_service.dart';
import 'package:academia/features/curriculum/models/curriculum_course_model.dart';
import 'package:academia/features/curriculum/services/curriculum_service.dart';
import 'package:academia/features/enrollments/models/enrollment_model.dart';
import 'package:academia/features/enrollments/services/enrollment_service.dart';
import 'package:academia/features/semesters/models/semester_model.dart';
import 'package:academia/features/semesters/services/semester_service.dart';

// --------------------------------------------------------------- fixtures
// Mirrors the Phase 7 schema and the live MIS shape: a permanent catalog,
// a curriculum of course rows + slot rows, per-semester offerings, and
// enrollments that point at an offering.

const _majorId = 'Bo7h3btN54SxANGuVqb1';
const _studentUid = '9psSX1ZO4cWD2z7c7HXVZTSnvAq2';

const _semCurrent = 'semester_2026_1';
const _semPast = 'semester_2025_2';
const _semOlder = 'semester_2024_2';

const _courseA = 'course_bmis2344'; // level 4, in curriculum
const _courseB = 'course_bmis3345'; // level 5, in curriculum
const _courseOutside = 'XiaHEH1GBYuw4znLQlSe'; // MIS202 — NOT in curriculum

final _semesters = <SemesterModel>[
  const SemesterModel(
    id: _semOlder,
    academicYear: '2024',
    semesterNumber: 2,
    semesterName: 'الفصل الثاني 2024',
    status: SemesterModel.statusCompleted,
  ),
  const SemesterModel(
    id: _semPast,
    academicYear: '2025',
    semesterNumber: 2,
    semesterName: 'الفصل الثاني 2025',
    status: SemesterModel.statusCompleted,
  ),
  const SemesterModel(
    id: _semCurrent,
    academicYear: '2026',
    semesterNumber: 1,
    semesterName: 'الفصل الأول 2026',
    status: SemesterModel.statusCurrent,
  ),
];

final _catalog = <String, CourseModel>{
  _courseA: const CourseModel(
    id: _courseA,
    courseCode: 'BMIS2344',
    title: 'تحليل وتصميم نظم المعلومات الإدارية',
    description: '',
    creditHours: 3,
    departmentId: 'dep1',
    status: CourseModel.statusActive,
  ),
  _courseB: const CourseModel(
    id: _courseB,
    courseCode: 'BMIS3345',
    title: 'نظم إدارة قواعد البيانات',
    description: '',
    creditHours: 3,
    departmentId: 'dep1',
    status: CourseModel.statusActive,
  ),
  _courseOutside: const CourseModel(
    id: _courseOutside,
    courseCode: 'MIS202',
    title: 'قواعد بيانات متقدمة',
    description: '',
    creditHours: 3,
    departmentId: 'dep1',
    status: CourseModel.statusArchived,
  ),
};

final _curriculum = <CurriculumCourseModel>[
  CurriculumCourseModel(
    id: CurriculumCourseModel.buildId(_majorId, _courseA),
    majorId: _majorId,
    entryType: CurriculumCourseModel.entryCourse,
    courseId: _courseA,
    academicLevel: 4,
    requirementType: CurriculumCourseModel.majorRequired,
    sequence: 2,
  ),
  CurriculumCourseModel(
    id: CurriculumCourseModel.buildSlotId(_majorId, 4, 4),
    majorId: _majorId,
    entryType: CurriculumCourseModel.entrySlot,
    slotLabel: 'متطلب تخصص اختياري (1)',
    academicLevel: 4,
    requirementType: CurriculumCourseModel.majorElective,
    creditHours: 3,
    sequence: 4,
  ),
  CurriculumCourseModel(
    id: CurriculumCourseModel.buildId(_majorId, _courseB),
    majorId: _majorId,
    entryType: CurriculumCourseModel.entryCourse,
    courseId: _courseB,
    academicLevel: 5,
    requirementType: CurriculumCourseModel.majorRequired,
    sequence: 3,
  ),
];

/// Offerings across three semesters. Only the current-semester ones are
/// returned by getOfferingsBySemester; the past ones must be reachable only
/// by explicit id lookup, which is what history resolution has to do.
final _allOfferings = <String, CourseOfferingModel>{
  '${_courseA}_${_semCurrent}_1': const CourseOfferingModel(
    id: '${_courseA}_${_semCurrent}_1',
    courseId: _courseA,
    semesterId: _semCurrent,
    instructorName: 'م. حمزة السويركي',
    section: '1',
    status: CourseOfferingModel.statusActive,
  ),
  '${_courseB}_${_semCurrent}_1': const CourseOfferingModel(
    id: '${_courseB}_${_semCurrent}_1',
    courseId: _courseB,
    semesterId: _semCurrent,
    instructorName: 'م. أنس الحرازين',
    section: '1',
    status: CourseOfferingModel.statusActive,
  ),
  '${_courseA}_${_semPast}_1': const CourseOfferingModel(
    id: '${_courseA}_${_semPast}_1',
    courseId: _courseA,
    semesterId: _semPast,
    instructorName: 'د. سابق',
    section: '2',
    status: CourseOfferingModel.statusArchived,
  ),
  '${_courseOutside}_${_semOlder}_1': const CourseOfferingModel(
    id: '${_courseOutside}_${_semOlder}_1',
    courseId: _courseOutside,
    semesterId: _semOlder,
    instructorName: 'م. أنس الحرازين',
    section: '1',
    status: CourseOfferingModel.statusArchived,
  ),
};

EnrollmentModel _enrollment({
  required String offeringId,
  required String courseId,
  required String semesterId,
  int attemptNumber = 1,
  String status = EnrollmentModel.statusActive,
  String? completionStatus,
  String? grade,
}) {
  return EnrollmentModel(
    id: EnrollmentModel.buildId(_studentUid, offeringId),
    userId: _studentUid,
    offeringId: offeringId,
    courseId: courseId,
    semesterId: semesterId,
    attemptNumber: attemptNumber,
    status: status,
    completionStatus: completionStatus,
    grade: grade,
    assignedBy: 'admin1',
    assignedAt: DateTime(2026, 1, 1),
  );
}

AppUserModel _student({String? majorId = _majorId, int? academicLevel = 4}) {
  return AppUserModel(
    uid: _studentUid,
    fullName: 'حلا جندية',
    email: 'student@test.com',
    role: UserRole.student,
    status: 'active',
    emailVerified: true,
    onboardingCompleted: true,
    onboardingStatus: 'completed',
    majorId: majorId,
    academicLevel: academicLevel,
  );
}

// ----------------------------------------------------------------- fakes

class FakeSemesterService implements SemesterService {
  bool shouldFail = false;

  @override
  Future<List<SemesterModel>> getSemesters() async {
    if (shouldFail) throw const SemesterException('boom');
    return _semesters;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCurriculumService implements CurriculumService {
  @override
  Future<List<CurriculumCourseModel>> getCurriculum(String majorId) async {
    if (majorId != _majorId) return <CurriculumCourseModel>[];
    return _curriculum;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCourseService implements CourseService {
  final List<List<String>> requestedIdBatches = [];

  @override
  Future<List<CourseModel>> getCoursesByIds(List<String> courseIds) async {
    requestedIdBatches.add(List.of(courseIds));
    return [
      for (final id in courseIds)
        if (_catalog.containsKey(id)) _catalog[id]!,
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeOfferingService implements CourseOfferingService {
  final List<List<String>> requestedIdBatches = [];

  @override
  Future<List<CourseOfferingModel>> getOfferingsBySemester(
    String semesterId,
  ) async {
    return _allOfferings.values
        .where((offering) => offering.semesterId == semesterId)
        .toList();
  }

  @override
  Future<List<CourseOfferingModel>> getOfferingsByIds(
    List<String> offeringIds,
  ) async {
    requestedIdBatches.add(List.of(offeringIds));
    return [
      for (final id in offeringIds)
        if (_allOfferings.containsKey(id)) _allOfferings[id]!,
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMajorService implements MajorService {
  @override
  Future<MajorModel?> getMajorById(String id) async {
    if (id != _majorId) return null;
    return const MajorModel(
      id: _majorId,
      name: 'نظم المعلومات الإدارية والتجارية المعاصرة',
      code: 'MIS',
      departmentId: 'dep1',
      totalLevels: 8,
      status: MajorModel.statusActive,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeEnrollmentService implements EnrollmentService {
  final StreamController<List<EnrollmentModel>> controller =
      StreamController<List<EnrollmentModel>>.broadcast();
  int watchCallCount = 0;

  @override
  Stream<List<EnrollmentModel>> watchMyEnrollments() {
    watchCallCount++;
    return controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mirrors AuthProvider's surface closely enough to drive the proxy wiring.
class ControllableAuthProvider extends ChangeNotifier implements AuthProvider {
  AppUserModel? _profile;

  void signIn(AppUserModel user) {
    _profile = user;
    notifyListeners();
  }

  void signOut() {
    _profile = null;
    notifyListeners();
  }

  @override
  AppUserModel? get currentUserProfile => _profile;

  @override
  bool get isLoggedIn => _profile != null;

  @override
  bool get isAdmin => _profile?.isAdmin ?? false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ------------------------------------------------------------------ setup

late FakeSemesterService semesterService;
late FakeCurriculumService curriculumService;
late FakeCourseService courseService;
late FakeOfferingService offeringService;
late FakeEnrollmentService enrollmentService;
late FakeMajorService majorService;
late StudentCoursesProvider provider;

StudentCoursesProvider _build() {
  semesterService = FakeSemesterService();
  curriculumService = FakeCurriculumService();
  courseService = FakeCourseService();
  offeringService = FakeOfferingService();
  enrollmentService = FakeEnrollmentService();
  majorService = FakeMajorService();
  return StudentCoursesProvider(
    semesterService,
    curriculumService,
    courseService,
    offeringService,
    enrollmentService,
    majorService,
  );
}

/// Pushes enrollments through the live stream and lets the provider resolve
/// any offerings/courses they reference.
Future<void> _emit(List<EnrollmentModel> enrollments) async {
  enrollmentService.controller.add(enrollments);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  setUp(() {
    provider = _build();
  });

  tearDown(() {
    enrollmentService.controller.close();
  });

  group('program', () {
    test('a valid major with ZERO enrollments still produces the program', () async {
      await provider.load(user: _student());

      expect(provider.hasMajor, isTrue);
      expect(provider.enrollments, isEmpty);
      expect(provider.currentCourses, isEmpty);
      expect(provider.historyByCourse, isEmpty);

      // The plan is present regardless of enrollment.
      expect(provider.programLevels, [4, 5]);
      expect(provider.programTotalCreditHours, 9); // 3 + 3 (slot) + 3

      // The real major name is resolved from majors/{majorId}, not from the
      // legacy free-text users.major.
      expect(provider.majorName, 'نظم المعلومات الإدارية والتجارية المعاصرة');
    });

    test('groups levels correctly and keeps slot rows', () async {
      await provider.load(user: _student());

      final level4 = provider.programForLevel(4);
      expect(level4, hasLength(2));
      expect(level4.first.sequence, 2);
      expect(level4.first.isSlot, isFalse);
      expect(level4.first.courseCode, 'BMIS2344');
      expect(level4.last.isSlot, isTrue);
      expect(level4.last.title, 'متطلب تخصص اختياري (1)');
      expect(level4.last.creditHours, 3);

      expect(provider.programForLevel(5), hasLength(1));
      expect(provider.programForLevel(7), isEmpty);
    });

    test('a student with no major gets an empty program, not an error', () async {
      await provider.load(user: _student(majorId: null));

      expect(provider.hasMajor, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.programByLevel, isEmpty);
    });
  });

  group('recommendedForMyLevel', () {
    test("uses the signed-in student's own academicLevel", () async {
      await provider.load(user: _student(academicLevel: 4));

      expect(provider.academicLevel, 4);
      expect(provider.recommendedForMyLevel, hasLength(2));
      expect(provider.recommendedCreditHours, 6);

      // A different student level selects a different slice of the plan.
      final other = _build();
      addTearDown(() => enrollmentService.controller.close());
      await other.load(user: _student(academicLevel: 5));
      expect(other.recommendedForMyLevel, hasLength(1));
      expect(other.recommendedForMyLevel.single.courseCode, 'BMIS3345');
    });

    test('an unknown academicLevel yields no recommendation', () async {
      await provider.load(user: _student(academicLevel: null));
      expect(provider.recommendedForMyLevel, isEmpty);
    });
  });

  group('current, history and retakes', () {
    test('an active current-semester enrollment appears in currentCourses', () async {
      await provider.load(user: _student());
      await _emit([
        _enrollment(
          offeringId: '${_courseA}_${_semCurrent}_1',
          courseId: _courseA,
          semesterId: _semCurrent,
        ),
      ]);

      expect(provider.currentCourses, hasLength(1));
      final row = provider.currentCourses.single;
      expect(row.courseCode, 'BMIS2344');
      expect(row.instructorName, 'م. حمزة السويركي'); // from the offering
      expect(row.semesterName, 'الفصل الأول 2026');
      expect(row.requirementType, CurriculumCourseModel.majorRequired);

      // It must NOT also appear in history.
      expect(provider.historyByCourse, isEmpty);
    });

    test('a past enrollment appears in history and not in currentCourses', () async {
      await provider.load(user: _student());
      await _emit([
        _enrollment(
          offeringId: '${_courseA}_${_semPast}_1',
          courseId: _courseA,
          semesterId: _semPast,
          status: EnrollmentModel.statusCompleted,
          completionStatus: EnrollmentModel.completionFailed,
          grade: 'راسب',
        ),
      ]);

      expect(provider.currentCourses, isEmpty);
      expect(provider.historyByCourse.keys, [_courseA]);

      final attempt = provider.historyByCourse[_courseA]!.single;
      expect(attempt.completionStatus, EnrollmentModel.completionFailed);
      expect(attempt.grade, 'راسب');
      expect(attempt.semesterId, _semPast);
      expect(attempt.offeringId, '${_courseA}_${_semPast}_1');
    });

    test('retaking a course keeps the attempts separate', () async {
      await provider.load(user: _student());
      await _emit([
        _enrollment(
          offeringId: '${_courseA}_${_semPast}_1',
          courseId: _courseA,
          semesterId: _semPast,
          attemptNumber: 1,
          status: EnrollmentModel.statusCompleted,
          completionStatus: EnrollmentModel.completionFailed,
        ),
        _enrollment(
          offeringId: '${_courseA}_${_semCurrent}_1',
          courseId: _courseA,
          semesterId: _semCurrent,
          attemptNumber: 2,
        ),
      ]);

      // Attempt 2 is the current course; attempt 1 is history. One course,
      // two attempts, never merged and never double-counted.
      expect(provider.currentCourses.single.attemptNumber, 2);
      expect(provider.currentCourses.single.isRetake, isTrue);

      final past = provider.historyByCourse[_courseA]!;
      expect(past, hasLength(1));
      expect(past.single.attemptNumber, 1);
    });

    test('a removed enrollment is hidden from the student entirely', () async {
      await provider.load(user: _student());
      await _emit([
        _enrollment(
          offeringId: '${_courseA}_${_semCurrent}_1',
          courseId: _courseA,
          semesterId: _semCurrent,
          status: EnrollmentModel.statusRemoved,
        ),
      ]);

      expect(provider.currentCourses, isEmpty);
      expect(provider.historyByCourse, isEmpty);
    });
  });

  group('availableNow', () {
    test('is the curriculum intersected with active current offerings', () async {
      await provider.load(user: _student());

      expect(provider.availableNow, hasLength(2));
      expect(
        provider.availableNow.map((v) => v.courseCode),
        ['BMIS2344', 'BMIS3345'],
      );
      expect(provider.availableNow.first.instructorName, 'م. حمزة السويركي');
    });

    test('excludes an offering the student is already actively enrolled in', () async {
      await provider.load(user: _student());
      await _emit([
        _enrollment(
          offeringId: '${_courseA}_${_semCurrent}_1',
          courseId: _courseA,
          semesterId: _semCurrent,
        ),
      ]);

      expect(provider.availableNow, hasLength(1));
      expect(provider.availableNow.single.courseCode, 'BMIS3345');
    });

    test('still offers a course the student previously passed (retakes allowed)', () async {
      await provider.load(user: _student());
      await _emit([
        _enrollment(
          offeringId: '${_courseA}_${_semPast}_1',
          courseId: _courseA,
          semesterId: _semPast,
          status: EnrollmentModel.statusCompleted,
          completionStatus: EnrollmentModel.completionPassed,
        ),
      ]);

      // Passing must NOT silently hide the course: retaking is supported and
      // no approved rule forbids it.
      expect(
        provider.availableNow.map((v) => v.courseCode),
        contains('BMIS2344'),
      );
    });
  });

  group('reference resolution', () {
    test('resolves a historical offering by id, not by loading everything', () async {
      await provider.load(user: _student());
      await _emit([
        _enrollment(
          offeringId: '${_courseA}_${_semPast}_1',
          courseId: _courseA,
          semesterId: _semPast,
          status: EnrollmentModel.statusCompleted,
        ),
      ]);

      final attempt = provider.historyByCourse[_courseA]!.single;
      expect(attempt.instructorName, 'د. سابق');
      expect(attempt.section, '2');
      expect(attempt.semesterName, 'الفصل الثاني 2025');

      // Targeted lookup only — the past offering was fetched by id.
      expect(offeringService.requestedIdBatches, hasLength(1));
      expect(
        offeringService.requestedIdBatches.single,
        ['${_courseA}_${_semPast}_1'],
      );
    });

    test('an enrollment outside the curriculum still resolves its course', () async {
      await provider.load(user: _student());
      await _emit([
        _enrollment(
          offeringId: '${_courseOutside}_${_semOlder}_1',
          courseId: _courseOutside,
          semesterId: _semOlder,
          status: EnrollmentModel.statusCompleted,
          completionStatus: EnrollmentModel.completionPassed,
        ),
      ]);

      final attempt = provider.historyByCourse[_courseOutside]!.single;
      // MIS202 is deliberately absent from the MIS plan; it must still show
      // its real title rather than becoming an unknown course.
      expect(attempt.hasCourse, isTrue);
      expect(attempt.courseCode, 'MIS202');
      expect(attempt.title, 'قواعد بيانات متقدمة');
      expect(attempt.instructorName, 'م. أنس الحرازين');
      // Outside the plan, so it has no requirement type.
      expect(attempt.requirementType, isNull);
    });
  });

  group('lifecycle', () {
    test('a failed prerequisite load does not start enrollment listening', () async {
      semesterService.shouldFail = true;

      await provider.load(user: _student());

      expect(provider.errorMessage, isNotNull);
      expect(provider.failedStage, StudentCoursesStage.semester);
      expect(enrollmentService.watchCallCount, 0);
      expect(provider.hasLoaded, isFalse);
    });

    test('clear() removes the previous student state and stops listening', () async {
      await provider.load(user: _student());
      await _emit([
        _enrollment(
          offeringId: '${_courseA}_${_semCurrent}_1',
          courseId: _courseA,
          semesterId: _semCurrent,
        ),
      ]);
      expect(provider.currentCourses, hasLength(1));

      provider.clear();

      expect(provider.userId, isNull);
      expect(provider.majorId, isNull);
      expect(provider.academicLevel, isNull);
      expect(provider.enrollments, isEmpty);
      expect(provider.programByLevel, isEmpty);
      expect(provider.currentCourses, isEmpty);
      expect(provider.historyByCourse, isEmpty);

      // A late event from the previous student's stream must be ignored.
      await _emit([
        _enrollment(
          offeringId: '${_courseA}_${_semCurrent}_1',
          courseId: _courseA,
          semesterId: _semCurrent,
        ),
      ]);
      expect(provider.enrollments, isEmpty);
    });

    test('signing out via syncWithUser clears cached academic data', () async {
      await provider.load(user: _student());
      await _emit([
        _enrollment(
          offeringId: '${_courseA}_${_semCurrent}_1',
          courseId: _courseA,
          semesterId: _semCurrent,
        ),
      ]);
      expect(provider.enrollments, hasLength(1));

      provider.syncWithUser(null, isLoggedIn: false);
      await Future<void>.delayed(Duration.zero);

      expect(provider.userId, isNull);
      expect(provider.enrollments, isEmpty);
      expect(provider.programByLevel, isEmpty);
    });

    testWidgets(
      'the AuthProvider proxy wiring drives load/clear without notifying '
      'during build',
      (tester) async {
        final auth = ControllableAuthProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              // Identical to the wiring registered in app_providers.dart.
              ChangeNotifierProxyProvider<AuthProvider, StudentCoursesProvider>(
                create: (_) => provider,
                update: (_, a, studentCourses) {
                  studentCourses!.syncWithUser(
                    a.currentUserProfile,
                    isLoggedIn: a.isLoggedIn,
                  );
                  return studentCourses;
                },
              ),
            ],
            child: MaterialApp(
              home: Consumer<StudentCoursesProvider>(
                builder: (_, p, _) => Text(
                  'levels:${p.programLevels.length}',
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Signed out: nothing loaded, and no build-phase notify exception.
        expect(tester.takeException(), isNull);
        expect(provider.userId, isNull);
        expect(find.text('levels:0'), findsOneWidget);

        auth.signIn(_student());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(provider.userId, _studentUid);
        expect(provider.majorId, _majorId);
        expect(provider.academicLevel, 4);
        expect(find.text('levels:2'), findsOneWidget);

        auth.signOut();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(provider.userId, isNull);
        expect(find.text('levels:0'), findsOneWidget);
      },
    );

    test('switching students drops the previous student data', () async {
      await provider.load(user: _student());
      await _emit([
        _enrollment(
          offeringId: '${_courseA}_${_semCurrent}_1',
          courseId: _courseA,
          semesterId: _semCurrent,
        ),
      ]);
      expect(provider.currentCourses, hasLength(1));

      final otherStudent = AppUserModel(
        uid: 'another-student',
        fullName: 'طالب آخر',
        email: 'other@test.com',
        role: UserRole.student,
        status: 'active',
        emailVerified: true,
        onboardingCompleted: true,
        onboardingStatus: 'completed',
        majorId: null,
        academicLevel: 1,
      );

      await provider.load(user: otherStudent);

      expect(provider.userId, 'another-student');
      expect(provider.majorId, isNull);
      expect(provider.academicLevel, 1);
      // No leakage of the first student's enrollments or plan.
      expect(provider.enrollments, isEmpty);
      expect(provider.programByLevel, isEmpty);
      expect(provider.currentCourses, isEmpty);
    });
  });
}
