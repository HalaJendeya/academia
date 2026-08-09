import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/academics/models/major_model.dart';
import 'package:academia/features/admin/models/admin_student_model.dart';
import 'package:academia/features/admin/screens/admin_student_details_screen.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/models/course_offering_model.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/enrollments/models/enrollment_model.dart';
import 'package:academia/features/enrollments/providers/admin_student_record_provider.dart';
import 'package:academia/features/semesters/models/semester_model.dart';

const _majorId = 'Bo7h3btN54SxANGuVqb1';

const _student = AdminStudentModel(
  uid: '9psSX1ZO4cWD2z7c7HXVZTSnvAq2',
  fullName: 'حلا جندية',
  email: 'hala@test.com',
  studentId: '2320220914',
  major: 'نظم المعلومات',
  majorId: _majorId,
  academicLevel: 4,
  status: 'active',
  onboardingCompleted: true,
);

const _majorName = 'نظم المعلومات الإدارية والتجارية المعاصرة';

StudentCourseView _view({
  required String code,
  required String semesterId,
  required String semesterName,
  required int attemptNumber,
  String status = EnrollmentModel.statusActive,
  String? completionStatus,
  String? grade,
}) {
  final courseId = 'course_$code';
  final offeringId = '${courseId}_${semesterId}_1';
  return StudentCourseView(
    enrollment: EnrollmentModel(
      id: EnrollmentModel.buildId(_student.uid, offeringId),
      userId: _student.uid,
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
    course: CourseModel(
      id: courseId,
      courseCode: code,
      title: 'مساق $code',
      description: '',
      creditHours: 3,
      departmentId: 'dep1',
      status: CourseModel.statusActive,
    ),
    semester: SemesterModel(
      id: semesterId,
      academicYear: '2026',
      semesterNumber: 1,
      semesterName: semesterName,
      status: SemesterModel.statusCurrent,
    ),
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

class FakeRecordProvider extends ChangeNotifier
    implements AdminStudentRecordProvider {
  FakeRecordProvider({
    this.isLoadingValue = false,
    this.hasLoadedValue = true,
    this.errorValue,
    this.majorNameValue = _majorName,
    this.currentValue = const [],
    this.historyValue = const [],
  });

  final bool isLoadingValue;
  final bool hasLoadedValue;
  final String? errorValue;
  final String? majorNameValue;
  final List<StudentCourseView> currentValue;
  final List<StudentCourseView> historyValue;

  @override
  bool get isLoading => isLoadingValue;

  @override
  bool get hasLoaded => hasLoadedValue;

  @override
  String? get errorMessage => errorValue;

  @override
  String? get majorName => majorNameValue;

  @override
  String? get studentUid => _student.uid;

  @override
  MajorModel? get major => null;

  @override
  List<StudentCourseView> get currentAttempts => currentValue;

  @override
  List<StudentCourseView> get history => historyValue;

  @override
  Future<void> loadForStudent({required String uid, String? majorId}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RouteRecorder extends NavigatorObserver {
  _RouteRecorder(this.pushed);

  final List<Route<dynamic>> pushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
}

Widget _wrap(FakeRecordProvider record, {List<Route<dynamic>>? pushed}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
      ChangeNotifierProvider<AdminStudentRecordProvider>.value(value: record),
    ],
    child: MaterialApp(
      navigatorObservers: [if (pushed != null) _RouteRecorder(pushed)],
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => settings.name == '/'
            ? const Directionality(
                textDirection: TextDirection.rtl,
                child: AdminStudentDetailsScreen(student: _student),
              )
            : const Scaffold(body: Text('assign-screen')),
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

/// The profile block must be present regardless of enrollment state.
void _expectProfileRendered() {
  expect(find.text('حلا جندية'), findsWidgets);
  expect(find.text('2320220914'), findsOneWidget);
  expect(find.text('hala@test.com'), findsOneWidget);
  expect(find.text(AppStrings.academicLevelDisplay(4)), findsOneWidget);
}

void main() {
  group('profile renders independently of enrollment state', () {
    testWidgets('with zero enrollments', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap(FakeRecordProvider()));
      await tester.pumpAndSettle();

      _expectProfileRendered();
      // The live state today: profile present, academic record empty.
      expect(
        find.text(AppStrings.noCurrentEnrollmentsForStudent),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.noEnrollmentHistoryForStudent),
        findsOneWidget,
      );
    });

    testWidgets('while enrollments are still loading', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(FakeRecordProvider(isLoadingValue: true, hasLoadedValue: false)),
      );
      await tester.pump();

      _expectProfileRendered();
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('when enrollment loading fails', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(FakeRecordProvider(errorValue: AppStrings.courseLoadError)),
      );
      await tester.pumpAndSettle();

      // The old screen let one failure blank the page; the profile survives.
      _expectProfileRendered();
      expect(find.text(AppStrings.courseLoadError), findsWidgets);
    });
  });

  group('academic program', () {
    testWidgets('shows the resolved major name, not the legacy text', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap(FakeRecordProvider()));
      await tester.pumpAndSettle();

      expect(find.text(_majorName), findsOneWidget);
      expect(find.text('نظم المعلومات'), findsNothing);
    });

    testWidgets('falls back to legacy text when the major cannot resolve', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrap(FakeRecordProvider(majorNameValue: null)));
      await tester.pumpAndSettle();

      expect(find.text('نظم المعلومات'), findsOneWidget);
      expect(find.text(AppStrings.legacyMajorTextNote), findsOneWidget);
    });
  });

  group('academic record', () {
    testWidgets('an active enrollment renders with its offering data', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          FakeRecordProvider(
            currentValue: [
              _view(
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

      expect(find.text('مساق BMIS2344'), findsOneWidget);
      expect(find.text('BMIS2344'), findsOneWidget);
      // Instructor, section and semester resolve through the offering chain —
      // exactly what the old screen could not do.
      expect(find.text('م. حمزة السويركي'), findsOneWidget);
      expect(find.text('الفصل الأول 2026'), findsOneWidget);
      expect(find.text('${AppStrings.sectionLabel} 1'), findsOneWidget);
      expect(
        find.text(AppStrings.noCurrentEnrollmentsForStudent),
        findsNothing,
      );
    });

    testWidgets('a completed attempt renders its result and grade', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          FakeRecordProvider(
            historyValue: [
              _view(
                code: 'BMIS2344',
                semesterId: 'semester_2025_2',
                semesterName: 'الفصل الثاني 2025',
                attemptNumber: 1,
                status: EnrollmentModel.statusCompleted,
                completionStatus: EnrollmentModel.completionPassed,
                grade: 'ممتاز',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.completionPassedLabel), findsOneWidget);
      expect(find.text('${AppStrings.gradeLabel}: ممتاز'), findsOneWidget);
    });

    testWidgets('two retake attempts render as separate cards', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrap(
          FakeRecordProvider(
            historyValue: [
              _view(
                code: 'BMIS2344',
                semesterId: 'semester_2024_2',
                semesterName: 'الفصل الثاني 2024',
                attemptNumber: 1,
                status: EnrollmentModel.statusCompleted,
                completionStatus: EnrollmentModel.completionFailed,
              ),
              _view(
                code: 'BMIS2344',
                semesterId: 'semester_2025_2',
                semesterName: 'الفصل الثاني 2025',
                attemptNumber: 2,
                status: EnrollmentModel.statusCompleted,
                completionStatus: EnrollmentModel.completionPassed,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // One course, two attempts, never merged into a single row.
      expect(find.text('${AppStrings.attemptLabel} 1'), findsOneWidget);
      expect(find.text('${AppStrings.attemptLabel} 2'), findsOneWidget);
      expect(find.text('مساق BMIS2344'), findsNWidgets(2));
      expect(find.text(AppStrings.completionFailedLabel), findsOneWidget);
      expect(find.text(AppStrings.completionPassedLabel), findsOneWidget);
    });
  });

  testWidgets('the assign action navigates to the assignment flow', (
    tester,
  ) async {
    _useNarrowScreen(tester);
    final pushed = <Route<dynamic>>[];
    await tester.pumpWidget(_wrap(FakeRecordProvider(), pushed: pushed));
    await tester.pumpAndSettle();
    pushed.clear();

    await tester.tap(find.text(AppStrings.assignCourseLabel));
    await tester.pumpAndSettle();

    expect(pushed, hasLength(1));
    expect(pushed.single.settings.name, '/admin/students/assign-courses');
    expect(pushed.single.settings.arguments, isA<AdminStudentModel>());
  });

  testWidgets('no overflow at 360px with a full record', (tester) async {
    _useNarrowScreen(tester);
    await tester.pumpWidget(
      _wrap(
        FakeRecordProvider(
          currentValue: [
            _view(
              code: 'BMIS2344',
              semesterId: 'semester_2026_1',
              semesterName: 'الفصل الأول 2026',
              attemptNumber: 2,
            ),
          ],
          historyValue: [
            _view(
              code: 'BMIS2344',
              semesterId: 'semester_2025_2',
              semesterName: 'الفصل الثاني 2025',
              attemptNumber: 1,
              status: EnrollmentModel.statusCompleted,
              completionStatus: EnrollmentModel.completionFailed,
              grade: 'راسب',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
