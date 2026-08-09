import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/admin/models/admin_student_model.dart';
import 'package:academia/features/admin/screens/admin_assign_courses_screen.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/models/course_offering_model.dart';
import 'package:academia/features/courses/providers/course_offering_provider.dart';
import 'package:academia/features/courses/providers/course_provider.dart';
import 'package:academia/features/enrollments/models/enrollment_model.dart';
import 'package:academia/features/enrollments/providers/enrollment_provider.dart';
import 'package:academia/features/semesters/models/semester_model.dart';
import 'package:academia/features/semesters/providers/semester_provider.dart';

const _courseId = 'course_bmis3344';
const _currentOfferingId = '${_courseId}_semester_2026_1_1';

const _current = SemesterModel(
  id: 'semester_2026_1',
  academicYear: '2026',
  semesterNumber: 1,
  semesterName: 'الفصل الأول 2026',
  status: SemesterModel.statusCurrent,
);

const _course = CourseModel(
  id: _courseId,
  courseCode: 'BMIS3344',
  title: 'برمجة تطبيقات الهواتف الذكية',
  description: '',
  creditHours: 3,
  departmentId: 'dep1',
  status: CourseModel.statusActive,
);

const _currentOffering = CourseOfferingModel(
  id: _currentOfferingId,
  courseId: _courseId,
  semesterId: 'semester_2026_1',
  instructorName: 'م. حمزة السويركي',
  section: '1',
  status: CourseOfferingModel.statusActive,
);

const _student = AdminStudentModel(
  uid: 'student1',
  fullName: 'حلا جندية',
  email: 's1@test.com',
  studentId: '2320220914',
  major: 'نظم المعلومات',
  academicLevel: 4,
  status: 'active',
  onboardingCompleted: true,
);

EnrollmentModel _attempt({
  required String offeringId,
  required String semesterId,
  required int attemptNumber,
  String status = EnrollmentModel.statusCompleted,
  String? completionStatus,
}) {
  return EnrollmentModel(
    id: EnrollmentModel.buildId('student1', offeringId),
    userId: 'student1',
    offeringId: offeringId,
    courseId: _courseId,
    semesterId: semesterId,
    attemptNumber: attemptNumber,
    status: status,
    completionStatus: completionStatus,
    assignedBy: 'admin1',
  );
}

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool get isLoggedIn => true;

  @override
  bool get isAdmin => true;

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

class FakeSemesterProvider extends ChangeNotifier implements SemesterProvider {
  @override
  List<SemesterModel> get semesters => const [_current];

  @override
  SemesterModel? get currentSemester => _current;

  @override
  void listenToSemesters() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCourseProvider extends ChangeNotifier implements CourseProvider {
  @override
  List<CourseModel> get courses => const [_course];

  @override
  void listenToCourses() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeOfferingProvider extends ChangeNotifier
    implements CourseOfferingProvider {
  @override
  String? get semesterId => 'semester_2026_1';

  @override
  CourseOfferingModel? activeOfferingForCourse(String courseId) =>
      courseId == _courseId ? _currentOffering : null;

  @override
  void listenToSemesterOfferings(String semesterId) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Uses the real attempt-grouping logic rather than stubbing it, so the test
/// exercises what production actually computes.
class FakeEnrollmentProvider extends ChangeNotifier
    implements EnrollmentProvider {
  FakeEnrollmentProvider({this.enrollments = const []});

  final List<EnrollmentModel> enrollments;

  @override
  AdminStudentModel? get selectedStudent => _student;

  @override
  List<EnrollmentModel> get selectedStudentEnrollments => enrollments;

  @override
  bool get isLoadingEnrollments => false;

  @override
  bool get isSaving => false;

  @override
  String? get errorMessage => null;

  @override
  List<EnrollmentModel> attemptsForCourse(String courseId) {
    final attempts = enrollments
        .where((enrollment) => enrollment.courseId == courseId)
        .toList();
    attempts.sort((a, b) => a.attemptNumber.compareTo(b.attemptNumber));
    return attempts;
  }

  @override
  EnrollmentModel? enrollmentForOffering(String offeringId) {
    for (final enrollment in enrollments) {
      if (enrollment.offeringId == offeringId) return enrollment;
    }
    return null;
  }

  @override
  void selectStudent(AdminStudentModel student) {}

  @override
  void loadStudentEnrollments(String userId) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(FakeEnrollmentProvider enrollmentProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
      ChangeNotifierProvider<SemesterProvider>(
        create: (_) => FakeSemesterProvider(),
      ),
      ChangeNotifierProvider<CourseProvider>(
        create: (_) => FakeCourseProvider(),
      ),
      ChangeNotifierProvider<CourseOfferingProvider>(
        create: (_) => FakeOfferingProvider(),
      ),
      ChangeNotifierProvider<EnrollmentProvider>.value(
        value: enrollmentProvider,
      ),
    ],
    child: const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: AdminAssignCoursesScreen(),
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
  testWidgets('a first-time assignment shows no retake context', (
    tester,
  ) async {
    _useNarrowScreen(tester);
    await tester.pumpWidget(_wrap(FakeEnrollmentProvider()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.assignCourseLabel), findsOneWidget);
    expect(find.text(AppStrings.retakeBadgeLabel), findsNothing);
    expect(
      find.textContaining(AppStrings.willBeAttemptPrefix),
      findsNothing,
    );
  });

  testWidgets('previous attempts are surfaced with their results', (
    tester,
  ) async {
    _useNarrowScreen(tester);
    await tester.pumpWidget(
      _wrap(
        FakeEnrollmentProvider(
          enrollments: [
            _attempt(
              offeringId: '${_courseId}_semester_2024_2_1',
              semesterId: 'semester_2024_2',
              attemptNumber: 1,
              completionStatus: EnrollmentModel.completionFailed,
            ),
            _attempt(
              offeringId: '${_courseId}_semester_2025_2_1',
              semesterId: 'semester_2025_2',
              attemptNumber: 2,
              completionStatus: EnrollmentModel.completionFailed,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.retakeBadgeLabel), findsOneWidget);
    expect(
      find.text(
        '${AppStrings.attemptLabel} 1: ${AppStrings.completionFailedLabel}',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        '${AppStrings.attemptLabel} 2: ${AppStrings.completionFailedLabel}',
      ),
      findsOneWidget,
    );

    // The admin must see that assigning now creates attempt 3, not a first try.
    expect(
      find.text('${AppStrings.willBeAttemptPrefix} 3'),
      findsOneWidget,
    );
    // A previously failed course is still assignable: retakes are supported.
    expect(find.text(AppStrings.assignCourseLabel), findsOneWidget);
  });

  testWidgets('an active retake enrolment displays its attempt number', (
    tester,
  ) async {
    _useNarrowScreen(tester);
    await tester.pumpWidget(
      _wrap(
        FakeEnrollmentProvider(
          enrollments: [
            _attempt(
              offeringId: '${_courseId}_semester_2025_2_1',
              semesterId: 'semester_2025_2',
              attemptNumber: 1,
              completionStatus: EnrollmentModel.completionFailed,
            ),
            _attempt(
              offeringId: _currentOfferingId,
              semesterId: 'semester_2026_1',
              attemptNumber: 2,
              status: EnrollmentModel.statusActive,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('${AppStrings.attemptLabel} 2'), findsOneWidget);
    // Already enrolled in this offering, so the action is removal, not assign.
    expect(find.text(AppStrings.assignCourseLabel), findsNothing);
    expect(find.text('إلغاء التسجيل'), findsOneWidget);
  });
}
