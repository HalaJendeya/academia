import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/admin/screens/admin_course_files_screen.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/course_offering_model.dart';
import 'package:academia/features/files/models/course_file_model.dart';
import 'package:academia/features/files/providers/course_file_provider.dart';
import 'package:academia/features/teacher/models/teacher_offering_view.dart';
import 'package:academia/features/teacher/providers/teacher_offerings_provider.dart';
import 'package:academia/features/teacher/screens/teacher_course_files_screen.dart';

void _useNarrowScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

const _offering = CourseOfferingModel(
  id: 'course_bmis3344_semester_2026_1_1',
  courseId: 'course_bmis3344',
  semesterId: 'semester_2026_1',
  instructorName: 'م. حمزة السويركي',
  section: '1',
  status: CourseOfferingModel.statusActive,
);

const _courseTitle = 'برمجة تطبيقات الهواتف الذكية';

CourseFileModel _file({
  String id = 'file1',
  String title = 'المحاضرة الأولى',
  String status = CourseFileModel.statusActive,
}) {
  return CourseFileModel(
    id: id,
    offeringId: _offering.id,
    courseId: _offering.courseId,
    semesterId: _offering.semesterId,
    title: title,
    description: 'مقدمة المساق',
    category: CourseFileModel.categoryLecture,
    fileName: 'lecture1.pdf',
    fileExtension: 'pdf',
    mimeType: 'application/pdf',
    fileSize: 2048,
    cloudinaryUrl: 'https://res.cloudinary.com/xmrgiypo/image/upload/v1/a.pdf',
    cloudinaryPublicId: 'academia/course_files/off/a',
    cloudinaryResourceType: 'image',
    uploadedBy: 'teacher1',
    status: status,
    createdAt: DateTime(2026, 8, 9),
  );
}

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  FakeAuthProvider({this.isTeacherValue = true});

  final bool isTeacherValue;

  @override
  bool get isLoggedIn => true;

  @override
  bool get isAdmin => false;

  @override
  bool get isStudent => false;

  @override
  bool get isTeacher => isTeacherValue;

  @override
  bool get isAccountActive => true;

  @override
  AppUserModel? get currentUserProfile => AppUserModel(
        uid: 'teacher1',
        fullName: 'Teacher 1',
        email: 'teacher1@test.com',
        role: isTeacherValue ? UserRole.teacher : UserRole.student,
        status: 'active',
        emailVerified: true,
        onboardingCompleted: true,
        onboardingStatus: 'completed',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTeacherOfferingsProvider extends ChangeNotifier
    implements TeacherOfferingsProvider {
  FakeTeacherOfferingsProvider({
    this.isLoadingValue = false,
    this.offeringsValue = const [],
  });

  bool isLoadingValue;
  List<TeacherOfferingView> offeringsValue;

  @override
  bool get isLoading => isLoadingValue;

  @override
  List<TeacherOfferingView> get offerings => offeringsValue;

  @override
  void listenToOfferingRoster(String offeringId) {}

  @override
  void stopListeningToRoster() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCourseFileProvider extends ChangeNotifier implements CourseFileProvider {
  FakeCourseFileProvider({
    this.filesValue = const [],
    this.isLoadingValue = false,
    this.errorValue,
  });

  List<CourseFileModel> filesValue;
  final bool isLoadingValue;
  String? errorValue;

  String? listenedOfferingId;
  CourseFileModel? updatedFile;
  String? archivedFileId;

  @override
  List<CourseFileModel> get files => filesValue;

  @override
  bool get isLoading => isLoadingValue;

  @override
  String? get errorMessage => errorValue;

  @override
  void listenToOfferingFiles(String offeringId) {
    listenedOfferingId = offeringId;
  }

  @override
  void clearFiles() {}

  @override
  Future<bool> updateFileMetadata(CourseFileModel file) async {
    updatedFile = file;
    return true;
  }

  @override
  Future<bool> archiveFile(String fileId) async {
    archivedFileId = fileId;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildTestableWidget({
    required AuthProvider auth,
    required TeacherOfferingsProvider teacherOfferings,
    required CourseFileProvider courseFile,
    required OfferingFilesArgs args,
  }) {
    return MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar')],
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<TeacherOfferingsProvider>.value(value: teacherOfferings),
          ChangeNotifierProvider<CourseFileProvider>.value(value: courseFile),
        ],
        child: Navigator(
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              settings: RouteSettings(arguments: args),
              builder: (context) => const TeacherCourseFilesScreen(),
            );
          },
        ),
      ),
    );
  }

  group('TeacherCourseFilesScreen - Permissions & Access', () {
    testWidgets('allows access when teacher owns the offering', (tester) async {
      final auth = FakeAuthProvider();
      final teacherOfferings = FakeTeacherOfferingsProvider(
        offeringsValue: [
          const TeacherOfferingView(offering: _offering),
        ],
      );
      final courseFile = FakeCourseFileProvider();

      await tester.pumpWidget(
        buildTestableWidget(
          auth: auth,
          teacherOfferings: teacherOfferings,
          courseFile: courseFile,
          args: const OfferingFilesArgs(offering: _offering, courseTitle: _courseTitle),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(AppStrings.offeringFilesTitle), findsOneWidget);
      expect(find.text(_courseTitle), findsOneWidget);
      expect(find.text(AppStrings.unauthorizedAccess), findsNothing);
    });

    testWidgets('blocks access and displays unauthorized when teacher does not own the offering', (tester) async {
      final auth = FakeAuthProvider();
      final teacherOfferings = FakeTeacherOfferingsProvider(
        offeringsValue: [], // No owned offerings
      );
      final courseFile = FakeCourseFileProvider();

      await tester.pumpWidget(
        buildTestableWidget(
          auth: auth,
          teacherOfferings: teacherOfferings,
          courseFile: courseFile,
          args: const OfferingFilesArgs(offering: _offering, courseTitle: _courseTitle),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(AppStrings.unauthorizedAccess), findsOneWidget);
      expect(find.text(_courseTitle), findsNothing);
    });

    testWidgets('displays loading state honestly and does not block when offerings are still loading', (tester) async {
      final auth = FakeAuthProvider();
      final teacherOfferings = FakeTeacherOfferingsProvider(
        isLoadingValue: true, // Offerings loading
        offeringsValue: [],
      );
      final courseFile = FakeCourseFileProvider();

      await tester.pumpWidget(
        buildTestableWidget(
          auth: auth,
          teacherOfferings: teacherOfferings,
          courseFile: courseFile,
          args: const OfferingFilesArgs(offering: _offering, courseTitle: _courseTitle),
        ),
      );

      // Offerings are loading, we should see loading indicator and NOT unauthorized access yet
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(AppStrings.unauthorizedAccess), findsNothing);
    });
  });

  group('TeacherCourseFilesScreen - States & Layout', () {
    testWidgets('renders loading state when provider is loading', (tester) async {
      final auth = FakeAuthProvider();
      final teacherOfferings = FakeTeacherOfferingsProvider(
        offeringsValue: [const TeacherOfferingView(offering: _offering)],
      );
      final courseFile = FakeCourseFileProvider(isLoadingValue: true);

      await tester.pumpWidget(
        buildTestableWidget(
          auth: auth,
          teacherOfferings: teacherOfferings,
          courseFile: courseFile,
          args: const OfferingFilesArgs(offering: _offering, courseTitle: _courseTitle),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders empty state when list is empty', (tester) async {
      final auth = FakeAuthProvider();
      final teacherOfferings = FakeTeacherOfferingsProvider(
        offeringsValue: [const TeacherOfferingView(offering: _offering)],
      );
      final courseFile = FakeCourseFileProvider(filesValue: []);

      await tester.pumpWidget(
        buildTestableWidget(
          auth: auth,
          teacherOfferings: teacherOfferings,
          courseFile: courseFile,
          args: const OfferingFilesArgs(offering: _offering, courseTitle: _courseTitle),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noOfferingFilesTitle), findsOneWidget);
      expect(find.text(AppStrings.uploadFileTitle), findsNWidgets(2));
    });

    testWidgets('renders files list and acts appropriately', (tester) async {
      _useNarrowScreen(tester);
      final auth = FakeAuthProvider();
      final teacherOfferings = FakeTeacherOfferingsProvider(
        offeringsValue: [const TeacherOfferingView(offering: _offering)],
      );
      final courseFile = FakeCourseFileProvider(filesValue: [
        _file(id: 'file1', title: 'ملف 1'),
      ]);

      await tester.pumpWidget(
        buildTestableWidget(
          auth: auth,
          teacherOfferings: teacherOfferings,
          courseFile: courseFile,
          args: const OfferingFilesArgs(offering: _offering, courseTitle: _courseTitle),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ملف 1'), findsOneWidget);
      expect(find.text('lecture1.pdf'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
