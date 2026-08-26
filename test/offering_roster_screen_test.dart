import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/admin/models/admin_student_model.dart';
import 'package:academia/features/admin/screens/admin_offering_roster_screen.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/course_offering_model.dart';
import 'package:academia/features/enrollments/models/enrollment_model.dart';
import 'package:academia/features/enrollments/providers/enrollment_provider.dart';

const _offeringId = 'course_bmis3344_semester_2026_1_1';

const _offering = CourseOfferingModel(
  id: _offeringId,
  courseId: 'course_bmis3344',
  semesterId: 'semester_2026_1',
  instructorName: 'م. حمزة السويركي',
  section: '1',
  status: CourseOfferingModel.statusActive,
);

EnrollmentModel _enrollment({
  required String userId,
  int attemptNumber = 1,
  String? completionStatus,
  String? grade,
}) {
  return EnrollmentModel(
    id: EnrollmentModel.buildId(userId, _offeringId),
    userId: userId,
    offeringId: _offeringId,
    courseId: 'course_bmis3344',
    semesterId: 'semester_2026_1',
    attemptNumber: attemptNumber,
    status: EnrollmentModel.statusActive,
    completionStatus: completionStatus,
    grade: grade,
    assignedBy: 'admin1',
  );
}

const _students = <AdminStudentModel>[
  AdminStudentModel(
    uid: 'student1',
    fullName: 'حلا جندية',
    email: 's1@test.com',
    studentId: '2320220914',
    major: 'نظم المعلومات',
    academicLevel: 4,
    status: 'active',
    onboardingCompleted: true,
  ),
  AdminStudentModel(
    uid: 'student2',
    fullName: 'طالب ثانٍ',
    email: 's2@test.com',
    studentId: '2320220915',
    major: 'نظم المعلومات',
    academicLevel: 5,
    status: 'active',
    onboardingCompleted: true,
  ),
];

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

class FakeEnrollmentProvider extends ChangeNotifier
    implements EnrollmentProvider {
  FakeEnrollmentProvider({this.rosterValue = const []});

  final List<EnrollmentModel> rosterValue;

  String? recordedUserId;
  String? recordedCompletionStatus;
  String? recordedGrade;

  @override
  List<EnrollmentModel> get roster => rosterValue;

  @override
  bool get isLoadingRoster => false;

  @override
  bool get isSaving => false;

  @override
  String? get errorMessage => null;

  @override
  List<AdminStudentModel> get students => _students;

  @override
  void listenToStudents() {}

  @override
  void listenToOfferingRoster(String offeringId) {}

  @override
  void stopListeningToRoster() {}

  @override
  Future<bool> setCompletionStatusFor({
    required String userId,
    required String offeringId,
    required String completionStatus,
    String? grade,
  }) async {
    recordedUserId = userId;
    recordedCompletionStatus = completionStatus;
    recordedGrade = grade;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(FakeEnrollmentProvider provider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
      ChangeNotifierProvider<EnrollmentProvider>.value(value: provider),
    ],
    child: MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            settings: const RouteSettings(
              arguments: OfferingRosterArgs(
                offering: _offering,
                courseTitle: 'برمجة تطبيقات الهواتف الذكية',
              ),
            ),
            builder: (_) => const AdminOfferingRosterScreen(),
          ),
        ),
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
  testWidgets('empty roster is a valid state, not an error', (tester) async {
    _useNarrowScreen(tester);
    await tester.pumpWidget(_wrap(FakeEnrollmentProvider()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.offeringRosterEmpty), findsOneWidget);
    expect(find.text('${AppStrings.offeringRosterCountLabel}: 0'), findsOneWidget);
  });

  testWidgets('roster joins student names and shows attempt numbers', (
    tester,
  ) async {
    _useNarrowScreen(tester);
    await tester.pumpWidget(
      _wrap(
        FakeEnrollmentProvider(
          rosterValue: [
            _enrollment(userId: 'student1'),
            _enrollment(userId: 'student2', attemptNumber: 3),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The enrollment stores only a uid; the name comes from the students list.
    expect(find.text('حلا جندية'), findsOneWidget);
    expect(find.text('طالب ثانٍ'), findsOneWidget);
    expect(find.text('2320220914'), findsOneWidget);

    expect(find.text('${AppStrings.attemptLabel} 1'), findsOneWidget);
    expect(find.text('${AppStrings.attemptLabel} 3'), findsOneWidget);
    expect(find.text('${AppStrings.offeringRosterCountLabel}: 2'), findsOneWidget);
  });

  testWidgets('an already-recorded result is displayed with its grade', (
    tester,
  ) async {
    _useNarrowScreen(tester);
    await tester.pumpWidget(
      _wrap(
        FakeEnrollmentProvider(
          rosterValue: [
            _enrollment(
              userId: 'student1',
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

  testWidgets('recording a result requires a choice and writes it through', (
    tester,
  ) async {
    _useNarrowScreen(tester);
    final provider = FakeEnrollmentProvider(
      rosterValue: [_enrollment(userId: 'student1')],
    );
    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.recordResultAction));
    await tester.pumpAndSettle();
    expect(find.byType(RadioListTile<String>), findsNWidgets(3));

    // Confirming without picking a result must not write anything.
    await tester.tap(find.text(AppStrings.confirmAction));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.completionStatusRequired), findsOneWidget);
    expect(provider.recordedCompletionStatus, isNull);

    await tester.tap(find.text(AppStrings.completionFailedLabel));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'راسب');
    await tester.tap(find.text(AppStrings.confirmAction));
    await tester.pumpAndSettle();

    expect(provider.recordedUserId, 'student1');
    expect(
      provider.recordedCompletionStatus,
      EnrollmentModel.completionFailed,
    );
    expect(provider.recordedGrade, 'راسب');
    expect(find.text(AppStrings.resultRecordedSuccess), findsOneWidget);
  });

  testWidgets('cancelling the result dialog writes nothing', (tester) async {
    _useNarrowScreen(tester);
    final provider = FakeEnrollmentProvider(
      rosterValue: [_enrollment(userId: 'student1')],
    );
    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.recordResultAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.cancelAction));
    await tester.pumpAndSettle();

    expect(provider.recordedCompletionStatus, isNull);
  });
}
