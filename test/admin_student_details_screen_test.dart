import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/courses/providers/course_provider.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/enrollments/providers/enrollment_provider.dart';
import 'package:academia/features/enrollments/models/enrollment_model.dart';
import 'package:academia/features/admin/screens/admin_student_details_screen.dart';
import 'package:academia/features/admin/models/admin_student_model.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool get isLoggedIn => true;

  @override
  bool get isAdmin => true;

  @override
  bool get isLoading => false;

  @override
  AppUserModel? get currentUserProfile => const AppUserModel(
    uid: 'admin123',
    fullName: 'Admin User',
    email: 'admin@university.edu.sa',
    role: UserRole.admin,
    status: 'active',
    emailVerified: true,
    onboardingCompleted: true,
    onboardingStatus: 'completed',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCourseProvider extends ChangeNotifier implements CourseProvider {
  @override
  List<CourseModel> get courses => [
    const CourseModel(
      id: 'course1',
      courseCode: 'CS101',
      title: 'Introduction to CS',
      description: 'Basic CS concepts',
      instructorName: 'Dr. Ahmad',
      department: 'CS',
      semester: 1,
      academicYear: '2026',
      creditHours: 3,
      status: 'active',
      createdBy: 'admin123',
    ),
  ];

  @override
  void listenToCourses() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeEnrollmentProvider extends ChangeNotifier
    implements EnrollmentProvider {
  @override
  bool get isLoadingEnrollments => false;

  @override
  String? get errorMessage => null;

  @override
  List<EnrollmentModel> get selectedStudentEnrollments => [
    EnrollmentModel(
      id: 'student1_course1',
      userId: 'student1',
      courseId: 'course1',
      status: 'active',
      assignedBy: 'admin123',
      assignedAt: DateTime.now(),
    ),
  ];

  @override
  AdminStudentModel? get selectedStudent => const AdminStudentModel(
    uid: 'student1',
    fullName: 'Hala Jendeya',
    email: 'hala@university.edu.sa',
    studentId: '123456789',
    major: 'Computer Science',
    semester: 2,
    status: 'active',
    onboardingCompleted: true,
  );

  @override
  void selectStudent(AdminStudentModel student) {}

  @override
  void loadStudentEnrollments(String userId) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('AdminStudentDetailsScreen rendering test on small screen', (
    WidgetTester tester,
  ) async {
    final student = const AdminStudentModel(
      uid: 'student1',
      fullName: 'Hala Jendeya',
      email: 'hala@university.edu.sa',
      studentId: '123456789',
      major: 'Computer Science',
      semester: 2,
      status: 'active',
      onboardingCompleted: true,
    );

    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => FakeAuthProvider(),
          ),
          ChangeNotifierProvider<CourseProvider>(
            create: (_) => FakeCourseProvider(),
          ),
          ChangeNotifierProvider<EnrollmentProvider>(
            create: (_) => FakeEnrollmentProvider(),
          ),
        ],
        child: MaterialApp(home: AdminStudentDetailsScreen(student: student)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hala Jendeya'), findsWidgets);
    expect(find.text('Computer Science'), findsOneWidget);
  });
}
