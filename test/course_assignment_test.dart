import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/assignments/models/course_assignment_model.dart';
import 'package:academia/features/assignments/providers/course_assignment_provider.dart';
import 'package:academia/features/assignments/services/course_assignment_service.dart';

// ------------------------------------------------------------------ fakes

class FakeAssignmentService implements CourseAssignmentService {
  /// A controller per offering, so a test can drive each stream separately.
  final Map<String, StreamController<List<CourseAssignmentModel>>> perOffering =
      {};
  final globalController =
      StreamController<List<CourseAssignmentModel>>.broadcast();

  final requestedOfferingIds = <String>[];
  int globalWatchCount = 0;

  int? countValue;
  Object? countError;
  int countCalls = 0;

  StreamController<List<CourseAssignmentModel>> _controllerFor(String id) =>
      perOffering.putIfAbsent(
        id,
        () => StreamController<List<CourseAssignmentModel>>.broadcast(),
      );

  @override
  Stream<List<CourseAssignmentModel>> watchOfferingAssignments(
    String offeringId,
  ) {
    requestedOfferingIds.add(offeringId);
    return _controllerFor(offeringId).stream;
  }

  @override
  Stream<List<CourseAssignmentModel>> watchAllActiveAssignments() {
    globalWatchCount++;
    return globalController.stream;
  }

  @override
  Future<int> getActiveAssignmentCount() async {
    countCalls++;
    if (countError != null) throw countError!;
    return countValue ?? 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --------------------------------------------------------------- fixtures

CourseAssignmentModel _assignment({
  String id = 'a1',
  String offeringId = 'off1',
  String title = 'واجب',
  DateTime? dueAt,
  String priority = CourseAssignmentModel.priorityMedium,
  String status = CourseAssignmentModel.statusActive,
}) {
  return CourseAssignmentModel(
    id: id,
    offeringId: offeringId,
    courseId: 'c1',
    semesterId: 'semester_2026_1',
    title: title,
    description: 'تعليمات',
    dueAt: dueAt ?? DateTime(2026, 9, 1, 12),
    priority: priority,
    status: status,
    createdBy: 'teacher1',
  );
}

void main() {
  // ===================================================================
  //  Model — parsing and serialization
  // ===================================================================
  group('CourseAssignmentModel parsing', () {
    test('parses a complete Firestore document', () {
      final model = CourseAssignmentModel.fromFirestore({
        'offeringId': 'off1',
        'courseId': 'c1',
        'semesterId': 'semester_2026_1',
        'title': 'واجب البرمجة',
        'description': 'حل التمارين',
        'dueAt': Timestamp.fromDate(DateTime(2026, 9, 1, 23, 59)),
        'priority': 'high',
        'status': 'active',
        'createdBy': 'teacher1',
        'createdAt': Timestamp.fromDate(DateTime(2026, 8, 1)),
      }, 'a1');

      expect(model.id, 'a1');
      expect(model.offeringId, 'off1');
      expect(model.title, 'واجب البرمجة');
      expect(model.priority, CourseAssignmentModel.priorityHigh);
      expect(model.isActive, isTrue);
      expect(model.dueAt, DateTime(2026, 9, 1, 23, 59));
      expect(model.createdAt, DateTime(2026, 8, 1));
    });

    /*
     * A malformed priority or status must not become a new value that
     * spreads through the UI. Both fall back to the documented default.
     */
    test('an unknown priority falls back to medium', () {
      final model = CourseAssignmentModel.fromFirestore({
        'title': 'x',
        'dueAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
        'priority': 'urgent',
      }, 'a1');

      expect(model.priority, CourseAssignmentModel.priorityMedium);
    });

    test('an unknown status falls back to active', () {
      final model = CourseAssignmentModel.fromFirestore({
        'title': 'x',
        'dueAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
        'status': 'deleted',
      }, 'a1');

      expect(model.status, CourseAssignmentModel.statusActive);
    });

    test('a missing description reads as empty, never null', () {
      final model = CourseAssignmentModel.fromFirestore({
        'title': 'x',
        'dueAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
      }, 'a1');

      expect(model.description, isEmpty);
    });

    /*
     * A document with no dueAt is corrupt, but it must not take the whole
     * list down. Epoch reads immediately as overdue rather than passing
     * for a plausible deadline.
     */
    test('a missing dueAt yields an obviously-wrong epoch, not a throw', () {
      final model = CourseAssignmentModel.fromFirestore({'title': 'x'}, 'a1');

      expect(model.dueAt.millisecondsSinceEpoch, 0);
      expect(model.isOverdue(relativeTo: DateTime(2026, 1, 1)), isTrue);
    });

    test('toMap writes only stored fields — no derived state', () {
      final map = _assignment().toMap();

      expect(map.keys, containsAll(<String>['offeringId', 'courseId',
        'semesterId', 'title', 'description', 'dueAt', 'priority',
        'status', 'createdBy']));

      // The whole point: temporal state is computed, never persisted.
      for (final forbidden in [
        'isOverdue',
        'isDueToday',
        'isDueSoon',
        'isUrgent',
        'dueDateLabel',
      ]) {
        expect(map.containsKey(forbidden), isFalse, reason: forbidden);
      }
    });

    test('copyWith preserves untouched fields', () {
      final updated = _assignment().copyWith(title: 'جديد');
      expect(updated.title, 'جديد');
      expect(updated.offeringId, 'off1');
      expect(updated.createdBy, 'teacher1');
    });
  });

  // ===================================================================
  //  Model — derived temporal state at a fixed instant
  // ===================================================================
  group('CourseAssignmentModel derived state', () {
    final now = DateTime(2026, 9, 10, 12, 0);

    test('isOverdue is true once the instant has passed', () {
      final past = _assignment(dueAt: DateTime(2026, 9, 10, 11, 59));
      expect(past.isOverdue(relativeTo: now), isTrue);
    });

    /*
     * Unlike personal tasks, which are day-granular, an assignment has a
     * time. One due at 09:00 today is overdue at 12:00 today.
     */
    test('an assignment due earlier today is overdue, not merely due today', () {
      final earlierToday = _assignment(dueAt: DateTime(2026, 9, 10, 9));
      expect(earlierToday.isOverdue(relativeTo: now), isTrue);
      expect(earlierToday.isDueToday(relativeTo: now), isTrue);
      expect(earlierToday.isDueSoon(relativeTo: now), isFalse);
    });

    test('isDueToday follows the local calendar day', () {
      final laterToday = _assignment(dueAt: DateTime(2026, 9, 10, 23, 59));
      expect(laterToday.isDueToday(relativeTo: now), isTrue);
      expect(laterToday.isOverdue(relativeTo: now), isFalse);
    });

    test('isDueSoon covers exactly the next 24 hours', () {
      final inside = _assignment(dueAt: now.add(const Duration(hours: 23)));
      final boundary = _assignment(dueAt: now.add(const Duration(hours: 24)));
      final outside = _assignment(
        dueAt: now.add(const Duration(hours: 24, minutes: 1)),
      );

      expect(inside.isDueSoon(relativeTo: now), isTrue);
      expect(boundary.isDueSoon(relativeTo: now), isTrue);
      expect(outside.isDueSoon(relativeTo: now), isFalse);
    });

    /*
     * `inHours` truncation was the original bug: 24.5 hours truncates to
     * 24 and would wrongly read as "due soon".
     */
    test('a deadline 24.5 hours away is NOT due soon', () {
      final almost = _assignment(
        dueAt: now.add(const Duration(hours: 24, minutes: 30)),
      );
      expect(almost.isDueSoon(relativeTo: now), isFalse);
    });

    test('midnight boundary: 23:59 today vs 00:01 tomorrow', () {
      final justBeforeMidnight = _assignment(
        dueAt: DateTime(2026, 9, 10, 23, 59),
      );
      final justAfterMidnight = _assignment(
        dueAt: DateTime(2026, 9, 11, 0, 1),
      );

      expect(justBeforeMidnight.isDueToday(relativeTo: now), isTrue);
      expect(justAfterMidnight.isDueToday(relativeTo: now), isFalse);
      // Both are still within the 24-hour window.
      expect(justBeforeMidnight.isDueSoon(relativeTo: now), isTrue);
      expect(justAfterMidnight.isDueSoon(relativeTo: now), isTrue);
    });

    test('a due date at exactly now is overdue, not due soon', () {
      final exactly = _assignment(dueAt: now);
      expect(exactly.isOverdue(relativeTo: now), isFalse);
      expect(exactly.isDueSoon(relativeTo: now), isTrue);
    });

    /*
     * An archived assignment has no temporal state at all: it is not
     * pending anything, so it cannot be late.
     */
    test('an archived assignment is never overdue, due today, or due soon', () {
      final archived = _assignment(
        dueAt: DateTime(2020, 1, 1),
        status: CourseAssignmentModel.statusArchived,
      );

      expect(archived.isOverdue(relativeTo: now), isFalse);
      expect(archived.isDueToday(relativeTo: DateTime(2020, 1, 1, 12)), isFalse);
      expect(archived.isDueSoon(relativeTo: now), isFalse);
    });
  });

  // ===================================================================
  //  Provider — single and multi-offering listening
  // ===================================================================
  group('CourseAssignmentProvider listening', () {
    test('a single offering opens exactly one stream', () {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.listenToOfferingAssignments('off1');

      expect(service.requestedOfferingIds, ['off1']);
    });

    test('an empty offering id opens nothing', () {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.listenToOfferingAssignments('   ');

      expect(service.requestedOfferingIds, isEmpty);
      expect(provider.assignments, isEmpty);
    });

    /*
     * The authorized multi-offering pattern: one stream per offering,
     * merged in memory. A single unrestricted query would be denied.
     */
    test('multiple offerings open one stream each and merge', () async {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.listenToOfferingsAssignments(['off1', 'off2']);
      expect(service.requestedOfferingIds, containsAll(['off1', 'off2']));

      service.perOffering['off1']!.add([
        _assignment(id: 'a1', offeringId: 'off1', dueAt: DateTime(2026, 9, 5)),
      ]);
      service.perOffering['off2']!.add([
        _assignment(id: 'a2', offeringId: 'off2', dueAt: DateTime(2026, 9, 2)),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.assignments, hasLength(2));
      // Sorted by deadline: the earlier one first regardless of arrival.
      expect(provider.assignments.first.id, 'a2');
    });

    test('empty offering list clears without opening a stream', () async {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.listenToOfferingsAssignments(const <String>[]);

      expect(service.requestedOfferingIds, isEmpty);
      expect(provider.assignments, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('blank ids are filtered out of a multi-offering request', () {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.listenToOfferingsAssignments(['off1', '  ', '']);

      expect(service.requestedOfferingIds, ['off1']);
    });

    test('re-listening to the same set does not resubscribe', () {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.listenToOfferingsAssignments(['off1', 'off2']);
      provider.listenToOfferingsAssignments(['off2', 'off1']);

      expect(service.requestedOfferingIds, hasLength(2));
    });

    test('duplicate ids across streams are merged by assignment id', () async {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.listenToOfferingsAssignments(['off1', 'off2']);
      // Same document id delivered by both streams.
      service.perOffering['off1']!.add([_assignment(id: 'dup')]);
      service.perOffering['off2']!.add([_assignment(id: 'dup')]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.assignments, hasLength(1));
    });

    test('equal deadlines sort deterministically by id', () async {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);
      final same = DateTime(2026, 9, 3);

      provider.listenToOfferingsAssignments(['off1']);
      service.perOffering['off1']!.add([
        _assignment(id: 'z', dueAt: same),
        _assignment(id: 'a', dueAt: same),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.assignments.map((a) => a.id).toList(), ['a', 'z']);
    });

    test('a failing stream surfaces an error without losing the rest',
        () async {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.listenToOfferingsAssignments(['off1', 'off2']);
      service.perOffering['off1']!.add([_assignment(id: 'ok')]);
      await Future<void>.delayed(Duration.zero);
      service.perOffering['off2']!.addError(Exception('denied'));
      await Future<void>.delayed(Duration.zero);

      expect(provider.errorMessage, AppStrings.courseAssignmentsLoadError);
      expect(provider.assignments.map((a) => a.id), contains('ok'));
    });

    test('stopListening cancels every per-offering subscription', () async {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.listenToOfferingsAssignments(['off1', 'off2']);
      expect(service.perOffering['off1']!.hasListener, isTrue);
      expect(service.perOffering['off2']!.hasListener, isTrue);

      provider.stopListening();

      expect(service.perOffering['off1']!.hasListener, isFalse);
      expect(service.perOffering['off2']!.hasListener, isFalse);
    });

    test('global oversight uses the single global stream', () {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.listenToAllActiveAssignments();

      expect(service.globalWatchCount, 1);
      expect(service.requestedOfferingIds, isEmpty);
    });
  });

  // ===================================================================
  //  Provider — auth lifecycle
  // ===================================================================
  group('CourseAssignmentProvider auth lifecycle', () {
    test('logout cancels subscriptions and clears assignments', () async {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.syncWithAuth(isActiveUser: true, role: 'teacher');
      provider.listenToOfferingsAssignments(['off1']);
      service.perOffering['off1']!.add([_assignment()]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.assignments, hasLength(1));

      provider.syncWithAuth(isActiveUser: false);
      await Future<void>.delayed(Duration.zero);

      expect(service.perOffering['off1']!.hasListener, isFalse);
      expect(provider.assignments, isEmpty);
    });

    /*
     * A teacher's offering stream must not survive into a student session
     * on the same device — the new role is not authorized for it.
     */
    test('a role switch clears state and cancels subscriptions', () async {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.syncWithAuth(isActiveUser: true, role: 'teacher');
      provider.listenToOfferingsAssignments(['off1']);
      service.perOffering['off1']!.add([_assignment()]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.assignments, hasLength(1));

      provider.syncWithAuth(isActiveUser: true, role: 'student');

      expect(service.perOffering['off1']!.hasListener, isFalse);
      expect(provider.assignments, isEmpty);
    });

    test('the same role re-syncing keeps the existing subscription', () async {
      final service = FakeAssignmentService();
      final provider = CourseAssignmentProvider(service);

      provider.syncWithAuth(isActiveUser: true, role: 'teacher');
      provider.listenToOfferingsAssignments(['off1']);
      provider.syncWithAuth(isActiveUser: true, role: 'teacher');

      expect(service.perOffering['off1']!.hasListener, isTrue);
    });

    test('logout also clears the dashboard count', () async {
      final service = FakeAssignmentService()..countValue = 7;
      final provider = CourseAssignmentProvider(service);

      provider.syncWithAuth(isActiveUser: true, role: 'admin');
      await provider.loadActiveAssignmentCount();
      expect(provider.activeAssignmentCount, 7);

      provider.syncWithAuth(isActiveUser: false);
      await Future<void>.delayed(Duration.zero);

      expect(provider.activeAssignmentCount, isNull);
    });
  });

  // ===================================================================
  //  Provider — active assignment count
  // ===================================================================
  group('CourseAssignmentProvider count', () {
    test('starts unknown rather than zero', () {
      final provider = CourseAssignmentProvider(FakeAssignmentService());
      expect(provider.activeAssignmentCount, isNull);
    });

    test('a real zero is reported as zero', () async {
      final service = FakeAssignmentService()..countValue = 0;
      final provider = CourseAssignmentProvider(service);

      await provider.loadActiveAssignmentCount();

      expect(provider.activeAssignmentCount, 0);
    });

    test('a real count is reported', () async {
      final service = FakeAssignmentService()..countValue = 12;
      final provider = CourseAssignmentProvider(service);

      await provider.loadActiveAssignmentCount();

      expect(provider.activeAssignmentCount, 12);
    });

    /*
     * A failed count must stay null. Falling back to 0 would state that
     * there are no assignments, which is a claim the app cannot make.
     */
    test('a failed count stays null and does not become zero', () async {
      final service = FakeAssignmentService()
        ..countError = const CourseAssignmentException('boom');
      final provider = CourseAssignmentProvider(service);

      await provider.loadActiveAssignmentCount();

      expect(provider.activeAssignmentCount, isNull);
      // The list's error channel is untouched by a statistics failure.
      expect(provider.errorMessage, isNull);
    });

    test('concurrent calls do not double-read', () async {
      final service = FakeAssignmentService()..countValue = 3;
      final provider = CourseAssignmentProvider(service);

      await Future.wait([
        provider.loadActiveAssignmentCount(),
        provider.loadActiveAssignmentCount(),
      ]);

      expect(service.countCalls, 1);
    });
  });
}
