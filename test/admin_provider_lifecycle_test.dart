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
import 'package:academia/features/admin/providers/admin_support_provider.dart';
import 'package:academia/features/enrollments/providers/enrollment_provider.dart';
import 'package:academia/features/enrollments/services/enrollment_service.dart';
import 'package:academia/features/profile/models/support_request.dart';
import 'package:academia/features/profile/services/support_service.dart';

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

/// Unlike the fakes above, this one hands out a **fresh** controller per call,
/// because that is what `snapshots()` does: every `watchSupportRequests()`
/// builds a new query stream. Keeping all of them lets a test prove that a
/// second `listenToRequests()` leaves exactly one subscription alive rather
/// than merely that *a* listener exists.
class FakeSupportService implements SupportService {
  final List<StreamController<List<SupportRequest>>> controllers = [];

  /// The most recent stream handed out — the one currently in use.
  StreamController<List<SupportRequest>> get controller => controllers.last;

  int get liveListenerCount =>
      controllers.where((c) => c.hasListener).length;

  @override
  Stream<List<SupportRequest>> watchSupportRequests() {
    final controller = StreamController<List<SupportRequest>>();
    controllers.add(controller);
    return controller.stream;
  }

  /// Closes only what was actually listened to: closing an unlistened
  /// single-subscription controller never completes.
  Future<void> closeAll() async {
    for (final c in controllers) {
      if (c.hasListener) await c.close();
    }
  }

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

const _supportRequest = SupportRequest(
  id: 'req1',
  uid: 'student1',
  fullName: 'حلا جندية',
  email: 's@test.com',
  subject: 'مشكلة في تسجيل المساقات',
  message: 'لا أستطيع رؤية مساقات الفصل الحالي.',
  status: SupportRequest.statusOpen,
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

  group('AdminSupportProvider — supportRequests listener', () {
    test('an active admin may start the listener', () async {
      final service = FakeSupportService();
      final provider = AdminSupportProvider(service);
      addTearDown(service.closeAll);

      provider.syncWithAuth(isActiveAdmin: true);
      provider.listenToRequests();
      service.controller.add([_supportRequest]);
      await Future<void>.delayed(Duration.zero);

      expect(service.controller.hasListener, isTrue);
      expect(provider.requests, hasLength(1));
      expect(provider.openRequests, hasLength(1));
      expect(provider.isLoading, isFalse);
    });

    test('logout cancels the listener and clears admin state', () async {
      final service = FakeSupportService();
      final provider = AdminSupportProvider(service);
      addTearDown(service.closeAll);

      provider.syncWithAuth(isActiveAdmin: true);
      provider.listenToRequests();
      service.controller.add([_supportRequest]);
      await Future<void>.delayed(Duration.zero);
      expect(service.controller.hasListener, isTrue);

      // Sign-out.
      provider.syncWithAuth(isActiveAdmin: false);
      await Future<void>.delayed(Duration.zero);

      // supportRequests is an admin-only read; a surviving listener is
      // exactly what produces PERMISSION_DENIED after logout.
      expect(service.controller.hasListener, isFalse);
      expect(provider.requests, isEmpty);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('switching admin → student leaves no listener alive', () async {
      final service = FakeSupportService();
      final provider = AdminSupportProvider(service);
      addTearDown(service.closeAll);

      provider.syncWithAuth(isActiveAdmin: true);
      provider.listenToRequests();
      await Future<void>.delayed(Duration.zero);

      // A student is an authenticated, active user — but not an admin.
      provider.syncWithAuth(isActiveAdmin: false);
      await Future<void>.delayed(Duration.zero);

      expect(service.controller.hasListener, isFalse);
      expect(provider.requests, isEmpty);
    });

    test('a disabled admin account keeps no listener', () async {
      final service = FakeSupportService();
      final provider = AdminSupportProvider(service);
      addTearDown(service.closeAll);

      provider.syncWithAuth(isActiveAdmin: true);
      provider.listenToRequests();
      await Future<void>.delayed(Duration.zero);

      // _isActiveAdmin folds "account disabled" into the same false, so the
      // provider must tear down for it exactly as it does for a sign-out.
      provider.syncWithAuth(isActiveAdmin: false);
      await Future<void>.delayed(Duration.zero);

      expect(service.controller.hasListener, isFalse);
      expect(provider.requests, isEmpty);
    });

    test('repeated admin syncs do not stack duplicate listeners', () async {
      final service = FakeSupportService();
      final provider = AdminSupportProvider(service);
      addTearDown(service.closeAll);

      // ProxyProvider.update runs on every rebuild; syncing must stay a
      // no-op that never opens a second subscription.
      provider.syncWithAuth(isActiveAdmin: true);
      provider.listenToRequests();
      provider.syncWithAuth(isActiveAdmin: true);
      provider.syncWithAuth(isActiveAdmin: true);
      await Future<void>.delayed(Duration.zero);

      // One query stream requested, one subscription alive.
      expect(service.controllers, hasLength(1));
      expect(service.liveListenerCount, 1);

      provider.syncWithAuth(isActiveAdmin: false);
      await Future<void>.delayed(Duration.zero);
      expect(service.liveListenerCount, 0);
    });

    test('calling listenToRequests twice leaves exactly one subscription',
        () async {
      final service = FakeSupportService();
      final provider = AdminSupportProvider(service);
      addTearDown(service.closeAll);

      provider.syncWithAuth(isActiveAdmin: true);
      provider.listenToRequests();
      // The retry button calls this again. Cancelling before re-listening is
      // what keeps the first subscription from being orphaned and left live.
      provider.listenToRequests();
      service.controller.add([_supportRequest]);
      await Future<void>.delayed(Duration.zero);

      expect(service.controllers, hasLength(2));
      expect(service.liveListenerCount, 1);
      expect(provider.requests, hasLength(1));

      provider.stopListening();
      expect(service.liveListenerCount, 0);
    });

    test('repeated non-admin syncs are cheap and do not notify', () async {
      final service = FakeSupportService();
      final provider = AdminSupportProvider(service);
      // Deliberately never listened to; closing an unlistened
      // single-subscription controller never completes.

      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.syncWithAuth(isActiveAdmin: false);
      provider.syncWithAuth(isActiveAdmin: false);
      await Future<void>.delayed(Duration.zero);

      expect(notifications, 0);
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
