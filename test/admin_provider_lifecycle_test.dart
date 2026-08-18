import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:academia/features/academics/models/department_model.dart';
import 'package:academia/features/academics/models/major_model.dart';
import 'package:academia/features/academics/providers/academic_structure_provider.dart';
import 'package:academia/features/academics/services/department_service.dart';
import 'package:academia/features/academics/services/major_service.dart';
import 'package:academia/features/admin/models/admin_student_model.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/providers/course_provider.dart';
import 'package:academia/features/courses/services/course_service.dart';
import 'package:academia/features/enrollments/providers/enrollment_provider.dart';
import 'package:academia/features/enrollments/services/enrollment_service.dart';

// ------------------------------------------------------------------ fakes
//
// Each fake hands out a broadcast-free StreamController so the test can assert
// on `hasListener` — the property that actually answers "is a Firestore
// listener still attached?".

class FakeCourseService implements CourseService {
  final controller = StreamController<List<CourseModel>>();

  @override
  Stream<List<CourseModel>> watchCourses() => controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeEnrollmentService implements EnrollmentService {
  final students = StreamController<List<AdminStudentModel>>();

  @override
  Stream<List<AdminStudentModel>> watchStudents() => students.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDepartmentService implements DepartmentService {
  final controller = StreamController<List<DepartmentModel>>();

  @override
  Stream<List<DepartmentModel>> watchDepartments() => controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMajorService implements MajorService {
  final controller = StreamController<List<MajorModel>>();

  @override
  Stream<List<MajorModel>> watchMajors() => controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _course = CourseModel(
  id: 'course_1',
  courseCode: 'BMIS3344',
  title: 'تحليل وتصميم النظم',
  description: '',
  creditHours: 3,
  departmentId: 'dept_it',
  status: 'active',
);

const _student = AdminStudentModel(
  uid: 'student1',
  fullName: 'حلا جندية',
  email: 's@test.com',
  studentId: '2320220914',
  major: '',
  status: 'active',
  onboardingCompleted: true,
);

void main() {
  group('CourseProvider — courses listener', () {
    test('an admin session may listen', () async {
      final service = FakeCourseService();
      final provider = CourseProvider(service);
      addTearDown(service.controller.close);

      provider.syncWithAuth(isActiveAdmin: true);
      provider.listenToCourses();
      service.controller.add([_course]);
      await Future<void>.delayed(Duration.zero);

      expect(service.controller.hasListener, isTrue);
      expect(provider.courses, hasLength(1));
    });

    test('logout cancels the listener and clears admin state', () async {
      final service = FakeCourseService();
      final provider = CourseProvider(service);
      addTearDown(service.controller.close);

      provider.syncWithAuth(isActiveAdmin: true);
      provider.listenToCourses();
      service.controller.add([_course]);
      await Future<void>.delayed(Duration.zero);
      expect(service.controller.hasListener, isTrue);

      // Sign-out.
      provider.syncWithAuth(isActiveAdmin: false);
      await Future<void>.delayed(Duration.zero);

      // This is the bug that produced PERMISSION_DENIED after logout.
      expect(service.controller.hasListener, isFalse);
      expect(provider.courses, isEmpty);
      expect(provider.errorMessage, isNull);
    });

    test('switching admin → student leaves no listener alive', () async {
      final service = FakeCourseService();
      final provider = CourseProvider(service);
      addTearDown(service.controller.close);

      provider.syncWithAuth(isActiveAdmin: true);
      provider.listenToCourses();
      await Future<void>.delayed(Duration.zero);

      // A student is an authenticated user, but not an active admin.
      provider.syncWithAuth(isActiveAdmin: false);
      await Future<void>.delayed(Duration.zero);

      expect(service.controller.hasListener, isFalse);
      expect(provider.courses, isEmpty);
    });

    test('repeated non-admin syncs are cheap and do not notify forever', () async {
      final service = FakeCourseService();
      final provider = CourseProvider(service);
      // No teardown close here: this controller is deliberately never
      // listened to, and closing an unlistened single-subscription
      // controller never completes.

      var notifications = 0;
      provider.addListener(() => notifications++);

      // Never was an admin: nothing to stop, nothing to announce.
      provider.syncWithAuth(isActiveAdmin: false);
      provider.syncWithAuth(isActiveAdmin: false);
      await Future<void>.delayed(Duration.zero);

      expect(notifications, 0);
    });
  });

  group('EnrollmentProvider — users where role == student', () {
    test('logout cancels the admin-only students listener', () async {
      final service = FakeEnrollmentService();
      final provider = EnrollmentProvider(service);
      addTearDown(service.students.close);

      provider.syncWithAuth(isActiveAdmin: true);
      provider.listenToStudents();
      service.students.add([_student]);
      await Future<void>.delayed(Duration.zero);

      expect(service.students.hasListener, isTrue);
      expect(provider.students, hasLength(1));

      provider.syncWithAuth(isActiveAdmin: false);
      await Future<void>.delayed(Duration.zero);

      // `users where role == 'student'` is admin-only; a surviving listener
      // is denied for a signed-out user AND for a signed-in student.
      expect(service.students.hasListener, isFalse);
      expect(provider.students, isEmpty);
      expect(provider.selectedStudent, isNull);
    });
  });

  group('AcademicStructureProvider — departments listener', () {
    test('logout cancels departments and majors listeners', () async {
      final departments = FakeDepartmentService();
      final majors = FakeMajorService();
      final provider = AcademicStructureProvider(departments, majors);
      addTearDown(departments.controller.close);
      addTearDown(majors.controller.close);

      provider.syncWithAuth(isActiveAdmin: true);
      provider.listenToStructure();
      await Future<void>.delayed(Duration.zero);

      expect(departments.controller.hasListener, isTrue);
      expect(majors.controller.hasListener, isTrue);

      provider.syncWithAuth(isActiveAdmin: false);
      await Future<void>.delayed(Duration.zero);

      expect(departments.controller.hasListener, isFalse);
      expect(majors.controller.hasListener, isFalse);
      expect(provider.departments, isEmpty);
      expect(provider.majors, isEmpty);
    });
  });
}
