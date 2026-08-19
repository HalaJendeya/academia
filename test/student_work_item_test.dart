import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:academia/features/assignments/models/course_assignment_model.dart';
import 'package:academia/features/assignments/providers/course_assignment_provider.dart';
import 'package:academia/features/assignments/services/course_assignment_service.dart';
import 'package:academia/features/tasks/models/student_work_item.dart';
import 'package:academia/features/tasks/models/task_model.dart';

// --------------------------------------------------------------- fixtures

final _now = DateTime(2026, 9, 10, 12);

TaskModel _task({
  String id = 't1',
  String title = 'مهمة',
  DateTime? dueAt,
  TaskStatus status = TaskStatus.pending,
}) {
  return TaskModel(
    id: id,
    userId: 'student1',
    title: title,
    dueAt: dueAt,
    status: status,
    createdAt: _now,
    updatedAt: _now,
  );
}

CourseAssignmentModel _assignment({
  String id = 'a1',
  String title = 'واجب',
  String offeringId = 'off1',
  DateTime? dueAt,
  String status = CourseAssignmentModel.statusActive,
}) {
  return CourseAssignmentModel(
    id: id,
    offeringId: offeringId,
    courseId: 'c1',
    semesterId: 'semester_2026_1',
    title: title,
    description: '',
    dueAt: dueAt ?? DateTime(2026, 9, 20),
    status: status,
    createdBy: 'teacher1',
  );
}

// ------------------------------------------------------------------ fakes

class FakeAssignmentService implements CourseAssignmentService {
  final Map<String, StreamController<List<CourseAssignmentModel>>> perOffering =
      {};
  final requestedOfferingIds = <String>[];

  StreamController<List<CourseAssignmentModel>> controllerFor(String id) =>
      perOffering.putIfAbsent(
        id,
        () => StreamController<List<CourseAssignmentModel>>.broadcast(),
      );

  @override
  Stream<List<CourseAssignmentModel>> watchOfferingAssignments(
    String offeringId,
  ) {
    requestedOfferingIds.add(offeringId);
    return controllerFor(offeringId).stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // ===================================================================
  //  Merge and sort
  // ===================================================================
  group('StudentWorkItem merge', () {
    test('a task and an assignment both appear in the merged list', () {
      final items = StudentWorkItem.merge(
        tasks: [_task(dueAt: DateTime(2026, 9, 12))],
        assignments: [_assignment(dueAt: DateTime(2026, 9, 13))],
        relativeTo: _now,
      );

      expect(items, hasLength(2));
      expect(
        items.map((i) => i.kind),
        containsAll([
          StudentWorkKind.personalTask,
          StudentWorkKind.academicAssignment,
        ]),
      );
    });

    test('a completed personal task is excluded from open work', () {
      final items = StudentWorkItem.merge(
        tasks: [
          _task(id: 'open', title: 'مفتوحة'),
          _task(id: 'done', title: 'منتهية', status: TaskStatus.completed),
        ],
        assignments: const [],
        relativeTo: _now,
      );

      expect(items, hasLength(1));
      expect(items.single.title, 'مفتوحة');
    });

    test('an archived assignment is excluded from open work', () {
      final items = StudentWorkItem.merge(
        tasks: const [],
        assignments: [
          _assignment(id: 'live', title: 'نشط'),
          _assignment(
            id: 'gone',
            title: 'مؤرشف',
            status: CourseAssignmentModel.statusArchived,
          ),
        ],
        relativeTo: _now,
      );

      expect(items, hasLength(1));
      expect(items.single.title, 'نشط');
    });

    /*
     * The documented order: overdue, then due today, then upcoming by
     * nearest deadline, then anything with no deadline at all.
     */
    test('sorts overdue, then today, then upcoming, then no-due', () {
      final items = StudentWorkItem.merge(
        tasks: [
          _task(id: 'noDue', title: 'بلا موعد'),
          _task(id: 'upcoming', title: 'قادم', dueAt: DateTime(2026, 9, 20)),
        ],
        assignments: [
          _assignment(
            id: 'today',
            title: 'اليوم',
            dueAt: DateTime(2026, 9, 10, 18),
          ),
          _assignment(
            id: 'late',
            title: 'متأخر',
            dueAt: DateTime(2026, 9, 1),
          ),
        ],
        relativeTo: _now,
      );

      expect(
        items.map((i) => i.title).toList(),
        ['متأخر', 'اليوم', 'قادم', 'بلا موعد'],
      );
    });

    test('within the same urgency the nearest deadline comes first', () {
      final items = StudentWorkItem.merge(
        tasks: const [],
        assignments: [
          _assignment(id: 'far', title: 'بعيد', dueAt: DateTime(2026, 9, 30)),
          _assignment(id: 'near', title: 'قريب', dueAt: DateTime(2026, 9, 15)),
        ],
        relativeTo: _now,
      );

      expect(items.map((i) => i.title).toList(), ['قريب', 'بعيد']);
    });

    test('ties break deterministically by id', () {
      final same = DateTime(2026, 9, 15);
      final first = StudentWorkItem.merge(
        tasks: [_task(id: 'zzz', dueAt: same), _task(id: 'aaa', dueAt: same)],
        assignments: const [],
        relativeTo: _now,
      );
      final second = StudentWorkItem.merge(
        tasks: [_task(id: 'aaa', dueAt: same), _task(id: 'zzz', dueAt: same)],
        assignments: const [],
        relativeTo: _now,
      );

      expect(
        first.map((i) => i.id).toList(),
        second.map((i) => i.id).toList(),
      );
    });

    /*
     * The two domains keep their own notion of "late", and that asymmetry
     * is deliberate: a personal task is day-granular, an assignment has a
     * submission time.
     */
    test('each source keeps its own overdue semantics', () {
      final earlierToday = DateTime(2026, 9, 10, 9);

      final taskItem = StudentWorkItem.fromTask(_task(dueAt: earlierToday));
      final assignmentItem = StudentWorkItem.fromAssignment(
        _assignment(dueAt: earlierToday),
      );

      // 09:00 today, observed at 12:00.
      expect(taskItem.isOverdue(relativeTo: _now), isFalse);
      expect(assignmentItem.isOverdue(relativeTo: _now), isTrue);
      // Both agree it belongs to today.
      expect(taskItem.isDueToday(relativeTo: _now), isTrue);
      expect(assignmentItem.isDueToday(relativeTo: _now), isTrue);
    });

    test('ids are namespaced so the two collections cannot collide', () {
      final task = StudentWorkItem.fromTask(_task(id: 'x'));
      final assignment = StudentWorkItem.fromAssignment(_assignment(id: 'x'));

      expect(task.id, isNot(assignment.id));
    });

    /*
     * The adapter is presentation state. It exposes no serializer, so it
     * cannot be written to Firestore even by accident.
     */
    test('exposes no serialization surface', () {
      final item = StudentWorkItem.fromTask(_task());
      expect(item, isNot(isA<Map<String, dynamic>>()));
      // The wrapped domain models remain the only source of truth.
      expect(item.task, isNotNull);
      expect(item.assignment, isNull);
    });

    test('no assignment completion state is fabricated', () {
      final item = StudentWorkItem.fromAssignment(_assignment());

      // Open-ness for an assignment means "not archived" — never "the
      // student finished it", which nothing in the system records.
      expect(item.isOpen, isTrue);
      expect(item.task, isNull);
    });

    test('openOnly:false keeps completed and archived items', () {
      final items = StudentWorkItem.merge(
        tasks: [_task(id: 'done', status: TaskStatus.completed)],
        assignments: [
          _assignment(id: 'arch', status: CourseAssignmentModel.statusArchived),
        ],
        relativeTo: _now,
        openOnly: false,
      );

      expect(items, hasLength(2));
    });
  });

  // ===================================================================
  //  Enrollment scoping of the student's assignment subscription
  // ===================================================================
  group('student assignment scoping', () {
    test('subscribes to exactly the offerings it is given', () {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.syncWithAuth(isActiveUser: true, role: 'student');
      provider.syncStudentOfferings(['off1', 'off2']);

      expect(service.requestedOfferingIds, containsAll(['off1', 'off2']));
      expect(service.requestedOfferingIds, hasLength(2));
    });

    /*
     * A removed enrolment never reaches this provider: StudentCoursesProvider
     * excludes it from currentCourses, so its offering id is simply absent
     * from the list handed over.
     */
    test('an offering absent from the list is never subscribed', () {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.syncWithAuth(isActiveUser: true, role: 'student');
      provider.syncStudentOfferings(['off1']);

      expect(service.requestedOfferingIds, ['off1']);
      expect(service.requestedOfferingIds, isNot(contains('removedOffering')));
    });

    test('the subscription follows a changed enrolment set', () {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.syncWithAuth(isActiveUser: true, role: 'student');
      provider.syncStudentOfferings(['off1']);
      provider.syncStudentOfferings(['off1', 'off2']);

      expect(service.requestedOfferingIds, ['off1', 'off1', 'off2']);
      expect(service.perOffering['off2']!.hasListener, isTrue);
    });

    test('an unchanged set does not resubscribe', () {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.syncWithAuth(isActiveUser: true, role: 'student');
      provider.syncStudentOfferings(['off1', 'off2']);
      provider.syncStudentOfferings(['off2', 'off1']);

      expect(service.requestedOfferingIds, hasLength(2));
    });

    test('logout clears assignments and cancels subscriptions', () async {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.syncWithAuth(isActiveUser: true, role: 'student');
      provider.syncStudentOfferings(['off1']);
      service.controllerFor('off1').add([_assignment()]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.assignments, hasLength(1));

      provider.syncWithAuth(isActiveUser: false);
      await Future<void>.delayed(Duration.zero);

      expect(service.perOffering['off1']!.hasListener, isFalse);
      expect(provider.assignments, isEmpty);
    });

    /*
     * Switching students on one device must not leave the previous
     * student's academic work on screen.
     */
    test('a student switch clears the previous student assignments', () async {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.syncWithAuth(isActiveUser: true, role: 'student');
      provider.syncStudentOfferings(['off1']);
      service.controllerFor('off1').add([_assignment(title: 'واجب الأولى')]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.assignments, hasLength(1));

      // Sign out, then in as a different student with different offerings.
      provider.syncWithAuth(isActiveUser: false);
      await Future<void>.delayed(Duration.zero);
      provider.syncWithAuth(isActiveUser: true, role: 'student');
      provider.syncStudentOfferings(['off9']);

      expect(provider.assignments, isEmpty);
      expect(service.perOffering['off1']!.hasListener, isFalse);
      expect(service.perOffering['off9']!.hasListener, isTrue);
    });

    test('a role switch clears the student subscription', () async {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.syncWithAuth(isActiveUser: true, role: 'student');
      provider.syncStudentOfferings(['off1']);
      service.controllerFor('off1').add([_assignment()]);
      await Future<void>.delayed(Duration.zero);

      provider.syncWithAuth(isActiveUser: true, role: 'teacher');

      expect(service.perOffering['off1']!.hasListener, isFalse);
      expect(provider.assignments, isEmpty);
    });

    /*
     * A non-student session must not disturb a teacher's or admin's own
     * subscriptions, which their screens drive directly.
     */
    test('a null offering list is inert when no student session existed', () {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.syncWithAuth(isActiveUser: true, role: 'teacher');
      provider.listenToOfferingsAssignments(['teacherOffering']);
      provider.syncStudentOfferings(null);

      expect(service.perOffering['teacherOffering']!.hasListener, isTrue);
    });

    /*
     * Course Detail takes the provider over for one offering; leaving it
     * must hand the student's own subscription back rather than cancel it.
     */
    test('restoreStudentOfferings re-subscribes after a screen took over', () {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.syncWithAuth(isActiveUser: true, role: 'student');
      provider.syncStudentOfferings(['off1', 'off2']);

      // Course Detail narrows to a single, possibly historical, offering.
      provider.listenToOfferingAssignments('historical');
      expect(service.perOffering['off1']!.hasListener, isFalse);

      provider.restoreStudentOfferings();

      expect(service.perOffering['off1']!.hasListener, isTrue);
      expect(service.perOffering['off2']!.hasListener, isTrue);
      expect(service.perOffering['historical']!.hasListener, isFalse);
    });

    test('restoreStudentOfferings is a no-op for a non-student session', () {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.syncWithAuth(isActiveUser: true, role: 'teacher');
      provider.restoreStudentOfferings();

      expect(service.requestedOfferingIds, isEmpty);
    });
  });
}
