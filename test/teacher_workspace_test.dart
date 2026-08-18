import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:academia/features/admin/models/admin_student_model.dart';
import 'package:academia/features/admin/models/admin_teacher_model.dart';
import 'package:academia/features/admin/providers/admin_teacher_provider.dart';
import 'package:academia/features/admin/services/admin_teacher_service.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/models/course_offering_model.dart';
import 'package:academia/features/courses/services/course_offering_service.dart';
import 'package:academia/features/courses/services/course_service.dart';
import 'package:academia/features/enrollments/models/enrollment_model.dart';
import 'package:academia/features/enrollments/services/enrollment_service.dart';
import 'package:academia/features/semesters/models/semester_model.dart';
import 'package:academia/features/semesters/services/semester_service.dart';
import 'package:academia/features/teacher/models/teacher_offering_view.dart';
import 'package:academia/features/teacher/providers/teacher_offerings_provider.dart';

// ------------------------------------------------------------------ fakes
//
// `hasListener` is the property that actually answers "is a Firestore
// listener still attached?", so every fake exposes its controller.
//
// Broadcast controllers, deliberately: a Firestore snapshots() call returns
// a FRESH stream each time, so cancel-then-resubscribe is normal and must
// keep working. A single-subscription controller would throw on the second
// listen and fail a switch-accounts test for a reason the product does not
// have.

class FakeOfferingService implements CourseOfferingService {
  final byTeacher = StreamController<List<CourseOfferingModel>>.broadcast();
  final requestedTeacherIds = <String>[];

  @override
  Stream<List<CourseOfferingModel>> watchOfferingsByTeacher(String teacherId) {
    requestedTeacherIds.add(teacherId);
    return byTeacher.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCourseService implements CourseService {
  List<CourseModel> courses = const <CourseModel>[];
  final requestedIds = <List<String>>[];

  @override
  Future<List<CourseModel>> getCoursesByIds(List<String> courseIds) async {
    requestedIds.add(courseIds);
    return courses;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSemesterService implements SemesterService {
  final semesters = StreamController<List<SemesterModel>>.broadcast();

  @override
  Stream<List<SemesterModel>> watchSemesters() => semesters.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeEnrollmentService implements EnrollmentService {
  final roster = StreamController<List<EnrollmentModel>>.broadcast();
  List<AdminStudentModel> students = const <AdminStudentModel>[];
  final lookedUpIds = <List<String>>[];

  @override
  Stream<List<EnrollmentModel>> watchOfferingRoster(String offeringId) =>
      roster.stream;

  @override
  Future<List<AdminStudentModel>> getStudentsByIds(
    List<String> userIds,
  ) async {
    lookedUpIds.add(userIds);
    return students;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAdminTeacherService implements AdminTeacherService {
  final teachers = StreamController<List<AdminTeacherModel>>.broadcast();

  @override
  Stream<List<AdminTeacherModel>> watchTeachers() => teachers.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/*
 * Any call is a failure. Used to prove a provider never reaches Firestore
 * for a session that must not open listeners.
 */
mixin _NeverCalled {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('service reached: ${invocation.memberName}');
  }
}

class NeverCalledOfferingService
    with _NeverCalled
    implements CourseOfferingService {}

class NeverCalledCourseService with _NeverCalled implements CourseService {}

class NeverCalledSemesterService
    with _NeverCalled
    implements SemesterService {}

class NeverCalledEnrollmentService
    with _NeverCalled
    implements EnrollmentService {}

class NeverCalledAdminTeacherService
    with _NeverCalled
    implements AdminTeacherService {}

// --------------------------------------------------------------- fixtures

const _offering = CourseOfferingModel(
  id: 'c1_semester_2026_1_1',
  courseId: 'c1',
  semesterId: 'semester_2026_1',
  teacherId: 'teacher1',
  instructorName: 'د. سارة قاسم',
  section: '1',
  status: 'active',
);

const _course = CourseModel(
  id: 'c1',
  courseCode: 'BMIS3344',
  title: 'تحليل وتصميم النظم',
  description: '',
  creditHours: 3,
  departmentId: 'dep1',
  status: 'active',
);

EnrollmentModel _enrollment(String userId) => EnrollmentModel(
  id: '${userId}_c1_semester_2026_1_1',
  userId: userId,
  offeringId: 'c1_semester_2026_1_1',
  courseId: 'c1',
  semesterId: 'semester_2026_1',
  status: 'active',
  assignedBy: 'admin1',
);

void main() {
  // ===================================================================
  //  CourseOfferingModel.teacherId
  // ===================================================================
  group('CourseOfferingModel teacherId', () {
    test('parses a stored teacherId', () {
      final offering = CourseOfferingModel.fromFirestore({
        'courseId': 'c1',
        'semesterId': 'semester_2026_1',
        'teacherId': 'teacher1',
        'instructorName': 'د. سارة',
        'section': '1',
        'status': 'active',
      }, 'c1_semester_2026_1_1');

      expect(offering.teacherId, 'teacher1');
      expect(offering.hasTeacher, isTrue);
    });

    /*
     * A pre-8.1 offering has no teacherId at all. It must read as unowned,
     * never as owned-by-empty-string: '' would still be compared against a
     * uid in the rules, and an offering nobody owns must stay that way.
     */
    test('a legacy offering with no teacherId is unowned', () {
      final offering = CourseOfferingModel.fromFirestore({
        'courseId': 'c1',
        'semesterId': 'semester_2026_1',
        'instructorName': 'م. حمزة السويركي',
        'section': '1',
        'status': 'active',
      }, 'c1_semester_2026_1_1');

      expect(offering.teacherId, isNull);
      expect(offering.hasTeacher, isFalse);
      expect(offering.instructorName, 'م. حمزة السويركي');
    });

    test('an empty or blank stored teacherId reads as unowned', () {
      for (final blank in ['', '   ']) {
        final offering = CourseOfferingModel.fromFirestore({
          'courseId': 'c1',
          'semesterId': 'semester_2026_1',
          'teacherId': blank,
          'instructorName': 'م. حمزة',
          'section': '1',
          'status': 'active',
        }, 'c1_semester_2026_1_1');

        expect(offering.hasTeacher, isFalse, reason: 'blank: "$blank"');
        expect(offering.teacherId, isNull);
      }
    });

    /*
     * The rules reject any teacherId that is not a real teacher account, so
     * writing '' would fail the WHOLE document write. Omitting the key is
     * what keeps an unassigned offering saveable.
     */
    test('toMap omits teacherId entirely when unassigned', () {
      const unassigned = CourseOfferingModel(
        id: 'c1_semester_2026_1_1',
        courseId: 'c1',
        semesterId: 'semester_2026_1',
        instructorName: 'م. حمزة',
        section: '1',
        status: 'active',
      );

      expect(unassigned.toMap().containsKey('teacherId'), isFalse);
      expect(_offering.toMap()['teacherId'], 'teacher1');
    });

    test('copyWith carries the teacher forward by default', () {
      expect(_offering.copyWith(status: 'archived').teacherId, 'teacher1');
    });

    test('copyWith clears the teacher only when asked explicitly', () {
      final cleared = _offering.copyWith(clearTeacher: true);
      expect(cleared.teacherId, isNull);
      expect(cleared.hasTeacher, isFalse);
      // The display name survives unassignment; it is a separate field.
      expect(cleared.instructorName, 'د. سارة قاسم');
    });
  });

  // ===================================================================
  //  TeacherOfferingsProvider — lifecycle
  // ===================================================================
  group('TeacherOfferingsProvider lifecycle', () {
    test('a non-teacher session never reaches any service', () {
      final provider = TeacherOfferingsProvider(
        NeverCalledOfferingService(),
        NeverCalledCourseService(),
        NeverCalledSemesterService(),
        NeverCalledEnrollmentService(),
      );

      // Signed out, then a student session, then an admin session: each
      // arrives as a null uid and none may open a listener.
      expect(() => provider.syncWithAuth(teacherUid: null), returnsNormally);
      expect(() => provider.syncWithAuth(teacherUid: null), returnsNormally);
      expect(provider.offerings, isEmpty);
    });

    test('an active teacher session queries by their own uid', () {
      final offerings = FakeOfferingService();
      final provider = TeacherOfferingsProvider(
        offerings,
        FakeCourseService(),
        FakeSemesterService(),
        FakeEnrollmentService(),
      );

      provider.syncWithAuth(teacherUid: 'teacher1');

      expect(offerings.requestedTeacherIds, ['teacher1']);
      expect(offerings.byTeacher.hasListener, isTrue);
    });

    test('logout cancels the offerings listener and clears state', () async {
      final offerings = FakeOfferingService();
      final semesters = FakeSemesterService();
      final provider = TeacherOfferingsProvider(
        offerings,
        FakeCourseService(),
        semesters,
        FakeEnrollmentService(),
      );

      provider.syncWithAuth(teacherUid: 'teacher1');
      offerings.byTeacher.add([_offering]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.offerings, hasLength(1));

      provider.syncWithAuth(teacherUid: null);

      expect(offerings.byTeacher.hasListener, isFalse);
      expect(semesters.semesters.hasListener, isFalse);
      expect(provider.offerings, isEmpty);
    });

    test('switching teachers inherits nothing from the previous one', () async {
      final offerings = FakeOfferingService();
      final provider = TeacherOfferingsProvider(
        offerings,
        FakeCourseService(),
        FakeSemesterService(),
        FakeEnrollmentService(),
      );

      provider.syncWithAuth(teacherUid: 'teacher1');
      offerings.byTeacher.add([_offering]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.offerings, hasLength(1));

      provider.syncWithAuth(teacherUid: 'teacher2');

      expect(provider.offerings, isEmpty);
      expect(offerings.requestedTeacherIds, ['teacher1', 'teacher2']);
    });

    test('a repeated sync for the same teacher does not re-subscribe', () {
      final offerings = FakeOfferingService();
      final provider = TeacherOfferingsProvider(
        offerings,
        FakeCourseService(),
        FakeSemesterService(),
        FakeEnrollmentService(),
      );

      provider.syncWithAuth(teacherUid: 'teacher1');
      provider.syncWithAuth(teacherUid: 'teacher1');
      provider.syncWithAuth(teacherUid: 'teacher1');

      expect(offerings.requestedTeacherIds, ['teacher1']);
    });
  });

  // ===================================================================
  //  TeacherOfferingsProvider — data
  // ===================================================================
  group('TeacherOfferingsProvider data', () {
    test('activeOfferings excludes archived and cancelled', () async {
      final offerings = FakeOfferingService();
      final provider = TeacherOfferingsProvider(
        offerings,
        FakeCourseService(),
        FakeSemesterService(),
        FakeEnrollmentService(),
      );

      provider.syncWithAuth(teacherUid: 'teacher1');
      offerings.byTeacher.add([
        _offering,
        _offering.copyWith(id: 'a', status: 'archived'),
        _offering.copyWith(id: 'c', status: 'cancelled'),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.offerings, hasLength(3));
      expect(provider.activeOfferings, hasLength(1));
      expect(provider.activeOfferings.single.offeringId, _offering.id);
    });

    test('course metadata is resolved into the view', () async {
      final offerings = FakeOfferingService();
      final courses = FakeCourseService()..courses = [_course];
      final provider = TeacherOfferingsProvider(
        offerings,
        courses,
        FakeSemesterService(),
        FakeEnrollmentService(),
      );

      provider.syncWithAuth(teacherUid: 'teacher1');
      offerings.byTeacher.add([_offering]);
      await Future<void>.delayed(Duration.zero);

      expect(courses.requestedIds, [
        ['c1'],
      ]);
      expect(provider.offerings.single.courseCode, 'BMIS3344');
      expect(provider.offerings.single.creditHours, 3);
    });

    /*
     * Withdrawing an assignment while the detail screen is open must empty
     * it, not leave a teacher looking at an offering that is no longer
     * theirs.
     */
    test('selectedOffering follows the live list, not a snapshot', () async {
      final offerings = FakeOfferingService();
      final enrollments = FakeEnrollmentService();
      final provider = TeacherOfferingsProvider(
        offerings,
        FakeCourseService(),
        FakeSemesterService(),
        enrollments,
      );

      provider.syncWithAuth(teacherUid: 'teacher1');
      offerings.byTeacher.add([_offering]);
      await Future<void>.delayed(Duration.zero);

      provider.listenToOfferingRoster(_offering.id);
      expect(provider.selectedOffering, isNotNull);

      // The admin reassigns the offering to somebody else.
      offerings.byTeacher.add([]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.selectedOffering, isNull);
    });

    test('roster resolves student names by individual lookup', () async {
      final offerings = FakeOfferingService();
      final enrollments = FakeEnrollmentService()
        ..students = [
          const AdminStudentModel(
            uid: 'student1',
            fullName: 'حلا جندية',
            email: 'student1@test.com',
            studentId: '220123',
            major: '',
            status: 'active',
            onboardingCompleted: true,
          ),
        ];

      final provider = TeacherOfferingsProvider(
        offerings,
        FakeCourseService(),
        FakeSemesterService(),
        enrollments,
      );

      provider.syncWithAuth(teacherUid: 'teacher1');
      provider.listenToOfferingRoster(_offering.id);
      enrollments.roster.add([_enrollment('student1')]);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(enrollments.lookedUpIds, [
        ['student1'],
      ]);
      expect(provider.roster.single.fullName, 'حلا جندية');
      expect(provider.roster.single.studentId, '220123');
    });

    /*
     * An unreadable user document must not break the roster: the enrollment
     * is the truth about who is in the class, the name is decoration.
     */
    test('a roster entry survives an unresolvable student name', () async {
      final offerings = FakeOfferingService();
      final enrollments = FakeEnrollmentService()..students = [];

      final provider = TeacherOfferingsProvider(
        offerings,
        FakeCourseService(),
        FakeSemesterService(),
        enrollments,
      );

      provider.syncWithAuth(teacherUid: 'teacher1');
      provider.listenToOfferingRoster(_offering.id);
      enrollments.roster.add([_enrollment('ghost')]);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(provider.roster, hasLength(1));
      expect(provider.roster.single.fullName, isNull);
    });

    test('stopListeningToRoster cancels and clears', () async {
      final offerings = FakeOfferingService();
      final enrollments = FakeEnrollmentService();
      final provider = TeacherOfferingsProvider(
        offerings,
        FakeCourseService(),
        FakeSemesterService(),
        enrollments,
      );

      provider.syncWithAuth(teacherUid: 'teacher1');
      provider.listenToOfferingRoster(_offering.id);
      expect(enrollments.roster.hasListener, isTrue);

      provider.stopListeningToRoster();

      expect(enrollments.roster.hasListener, isFalse);
      expect(provider.roster, isEmpty);
      expect(provider.selectedOfferingId, isNull);
    });
  });

  // ===================================================================
  //  View models
  // ===================================================================
  group('TeacherOfferingView', () {
    test('displayTitle prefers code and title together', () {
      const view = TeacherOfferingView(offering: _offering, course: _course);
      expect(view.displayTitle, 'BMIS3344 — تحليل وتصميم النظم');
    });

    test('displayTitle falls back to the course id, never to blank', () {
      const view = TeacherOfferingView(offering: _offering);
      expect(view.displayTitle, 'c1');
    });
  });

  group('TeacherRosterEntry', () {
    test('reports a missing name as null rather than an empty string', () {
      final entry = TeacherRosterEntry(enrollment: _enrollment('student1'));
      expect(entry.fullName, isNull);
      expect(entry.studentId, isEmpty);
      expect(entry.userId, 'student1');
    });
  });

  // ===================================================================
  //  AdminTeacherProvider — lifecycle
  // ===================================================================
  group('AdminTeacherProvider lifecycle', () {
    test('a non-admin session never reaches the service', () {
      final provider = AdminTeacherProvider(
        NeverCalledAdminTeacherService(),
        NeverCalledOfferingService(),
      );

      expect(
        () => provider.syncWithAuth(isActiveAdmin: false),
        returnsNormally,
      );
      expect(provider.teachers, isEmpty);
    });

    test('logout cancels the teachers listener', () async {
      final service = FakeAdminTeacherService();
      final provider = AdminTeacherProvider(service, FakeOfferingService());

      provider.syncWithAuth(isActiveAdmin: true);
      provider.listenToTeachers();
      expect(service.teachers.hasListener, isTrue);

      provider.syncWithAuth(isActiveAdmin: false);

      expect(service.teachers.hasListener, isFalse);
      expect(provider.teachers, isEmpty);
    });

    test('activeTeachers excludes disabled accounts', () async {
      final service = FakeAdminTeacherService();
      final provider = AdminTeacherProvider(service, FakeOfferingService());

      provider.syncWithAuth(isActiveAdmin: true);
      provider.listenToTeachers();
      service.teachers.add(const [
        AdminTeacherModel(
          uid: 't1',
          fullName: 'سارة',
          email: 's@test.com',
          status: 'active',
        ),
        AdminTeacherModel(
          uid: 't2',
          fullName: 'حمزة',
          email: 'h@test.com',
          status: 'disabled',
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.teachers, hasLength(2));
      expect(provider.activeTeachers.single.uid, 't1');
    });

  });

  group('AdminTeacherModel', () {
    test('displayName falls back to email when the name is blank', () {
      const teacher = AdminTeacherModel(
        uid: 't1',
        fullName: '   ',
        email: 'sara@test.com',
        status: 'active',
      );
      expect(teacher.displayName, 'sara@test.com');
    });

    test('a missing status field reads as active', () {
      final teacher = AdminTeacherModel.fromFirestore({
        'fullName': 'سارة',
        'email': 'sara@test.com',
      }, 't1');
      expect(teacher.isActive, isTrue);
    });
  });
}
