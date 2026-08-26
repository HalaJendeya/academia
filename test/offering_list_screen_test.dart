import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/admin/screens/admin_offering_list_screen.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/models/course_offering_model.dart';
import 'package:academia/features/courses/providers/course_offering_provider.dart';
import 'package:academia/features/courses/providers/course_provider.dart';
import 'package:academia/features/semesters/models/semester_model.dart';
import 'package:academia/features/semesters/providers/semester_provider.dart';

const _current = SemesterModel(
  id: 'semester_2026_1',
  academicYear: '2026',
  semesterNumber: 1,
  semesterName: 'الفصل الأول 2026',
  status: SemesterModel.statusCurrent,
);

const _past = SemesterModel(
  id: 'semester_2025_2',
  academicYear: '2025',
  semesterNumber: 2,
  semesterName: 'الفصل الثاني 2025',
  status: SemesterModel.statusCompleted,
);

const _course = CourseModel(
  id: 'course_bmis3344',
  courseCode: 'BMIS3344',
  title: 'برمجة تطبيقات الهواتف الذكية',
  description: '',
  creditHours: 3,
  departmentId: 'dep1',
  status: CourseModel.statusActive,
);

const _offering = CourseOfferingModel(
  id: 'course_bmis3344_semester_2026_1_1',
  courseId: 'course_bmis3344',
  semesterId: 'semester_2026_1',
  instructorName: 'م. حمزة السويركي',
  section: '1',
  status: CourseOfferingModel.statusActive,
);

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
  List<SemesterModel> get semesters => const [_current, _past];

  @override
  Map<String, SemesterModel> get byId =>
      const {'semester_2026_1': _current, 'semester_2025_2': _past};

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
  FakeOfferingProvider({this.offeringsValue = const []});

  final List<CourseOfferingModel> offeringsValue;

  String? duplicatedFrom;
  String? duplicatedTo;

  @override
  List<CourseOfferingModel> get offerings => offeringsValue;

  @override
  bool get isLoading => false;

  @override
  bool get isSaving => false;

  @override
  String? get errorMessage => null;

  @override
  String? get semesterId => 'semester_2026_1';

  @override
  void listenToSemesterOfferings(String semesterId) {}

  @override
  Future<int?> duplicateSemesterOfferings({
    required String fromSemesterId,
    required String toSemesterId,
  }) async {
    duplicatedFrom = fromSemesterId;
    duplicatedTo = toSemesterId;
    return 3;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(FakeOfferingProvider offeringProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
      ChangeNotifierProvider<SemesterProvider>(
        create: (_) => FakeSemesterProvider(),
      ),
      ChangeNotifierProvider<CourseProvider>(
        create: (_) => FakeCourseProvider(),
      ),
      ChangeNotifierProvider<CourseOfferingProvider>.value(
        value: offeringProvider,
      ),
    ],
    child: const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: AdminOfferingListScreen(),
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
  testWidgets('a semester with no offerings gets an actionable empty state', (
    tester,
  ) async {
    _useNarrowScreen(tester);
    await tester.pumpWidget(_wrap(FakeOfferingProvider()));
    await tester.pumpAndSettle();

    // This is the live state for semester_2026_1 today.
    expect(find.text(AppStrings.noOfferingsForSemester), findsOneWidget);
    expect(find.text(AppStrings.addOfferingLabel), findsWidgets);
  });

  testWidgets('an offering shows its course, section and instructor', (
    tester,
  ) async {
    _useNarrowScreen(tester);
    await tester.pumpWidget(
      _wrap(FakeOfferingProvider(offeringsValue: const [_offering])),
    );
    await tester.pumpAndSettle();

    expect(find.text('برمجة تطبيقات الهواتف الذكية'), findsOneWidget);
    expect(find.text('BMIS3344'), findsOneWidget);
    // Instructor and section belong to the offering, never to the course.
    expect(find.text('م. حمزة السويركي'), findsOneWidget);
    expect(
      find.text('${AppStrings.offeringSectionLabel} 1'),
      findsOneWidget,
    );
    expect(find.text(AppStrings.viewRosterAction), findsOneWidget);
  });

  testWidgets('duplicating from a previous semester targets the shown one', (
    tester,
  ) async {
    _useNarrowScreen(tester);
    final provider = FakeOfferingProvider();
    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.copy_all_rounded));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.duplicateOfferingsTitle), findsOneWidget);
    // The source list must exclude the semester being viewed.
    expect(find.text('الفصل الثاني 2025'), findsOneWidget);

    await tester.tap(find.text(AppStrings.duplicateOfferingsConfirm));
    await tester.pumpAndSettle();

    expect(provider.duplicatedFrom, 'semester_2025_2');
    expect(provider.duplicatedTo, 'semester_2026_1');
    expect(
      find.textContaining(AppStrings.duplicateOfferingsSuccessPrefix),
      findsOneWidget,
    );
  });
}
