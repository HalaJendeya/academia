import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/enrollments/models/enrollment_model.dart';
import 'package:academia/features/tasks/models/task_model.dart';
import 'package:academia/features/tasks/services/task_service.dart';
import 'package:academia/features/tasks/providers/task_provider.dart';

class FakeTaskService implements TaskService {
  final StreamController<List<TaskModel>> _controller =
      StreamController<List<TaskModel>>.broadcast();

  List<TaskModel> tasksList = [];
  int watchCallCount = 0;
  String? watchedUserId;

  @override
  Stream<List<TaskModel>> watchTasks(String userId) {
    watchCallCount++;
    watchedUserId = userId;
    return _controller.stream;
  }

  void emit(List<TaskModel> list) {
    tasksList = List.from(list);
    _controller.add(tasksList);
  }

  @override
  Future<void> createTask(TaskModel task) async {
    final newId = task.id.isEmpty ? 'task_${tasksList.length + 1}' : task.id;
    final newTask = task.copyWith(
      id: newId,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
    );
    tasksList.add(newTask);
    _controller.add(tasksList);
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    final index = tasksList.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasksList[index] = task;
      _controller.add(tasksList);
    }
  }

  @override
  Future<void> completeTask(String taskId) async {
    final index = tasksList.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      tasksList[index] = tasksList[index].copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _controller.add(tasksList);
    }
  }

  @override
  Future<void> reopenTask(String taskId) async {
    final index = tasksList.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      tasksList[index] = tasksList[index].copyWith(
        status: TaskStatus.pending,
        clearCompletedAt: true,
        updatedAt: DateTime.now(),
      );
      _controller.add(tasksList);
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    tasksList.removeWhere((t) => t.id == taskId);
    _controller.add(tasksList);
  }

  void close() {
    _controller.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TaskModel Derivation Tests', () {
    final now = DateTime(2026, 8, 9, 12, 0);

    test('completed task is never overdue, today, or upcoming', () {
      final task = TaskModel(
        id: 't1',
        userId: 'u1',
        title: 'Task 1',
        status: TaskStatus.completed,
        dueAt: DateTime(2026, 8, 8, 12, 0), // yesterday
        createdAt: now,
        updatedAt: now,
      );

      expect(task.isOverdue(relativeTo: now), isFalse);
      expect(task.isToday(relativeTo: now), isFalse);
      expect(task.isUpcoming(relativeTo: now), isFalse);
    });

    test('overdue derivation (due in past, not same day)', () {
      final task = TaskModel(
        id: 't1',
        userId: 'u1',
        title: 'Task 1',
        dueAt: DateTime(2026, 8, 8, 23, 59), // yesterday
        createdAt: now,
        updatedAt: now,
      );

      expect(task.isOverdue(relativeTo: now), isTrue);
      expect(task.isToday(relativeTo: now), isFalse);
      expect(task.isUpcoming(relativeTo: now), isFalse);
    });

    test('today derivation (due today, any time)', () {
      final task = TaskModel(
        id: 't1',
        userId: 'u1',
        title: 'Task 1',
        dueAt: DateTime(2026, 8, 9, 8, 0), // today earlier
        createdAt: now,
        updatedAt: now,
      );

      expect(task.isOverdue(relativeTo: now), isFalse);
      expect(task.isToday(relativeTo: now), isTrue);
      expect(task.isUpcoming(relativeTo: now), isFalse);
    });

    test('upcoming derivation (due tomorrow, any time)', () {
      final task = TaskModel(
        id: 't1',
        userId: 'u1',
        title: 'Task 1',
        dueAt: DateTime(2026, 8, 10, 14, 0), // tomorrow
        createdAt: now,
        updatedAt: now,
      );

      expect(task.isOverdue(relativeTo: now), isFalse);
      expect(task.isToday(relativeTo: now), isFalse);
      expect(task.isUpcoming(relativeTo: now), isTrue);
    });
  });

  group('TaskProvider Lifecycle & CRUD Tests', () {
    late FakeTaskService fakeService;
    late TaskProvider provider;

    final student1Enrollment = StudentCourseView(
      enrollment: EnrollmentModel(
        id: 'enrollment_student1_c1',
        userId: 'student1',
        offeringId: 'c1_offering',
        courseId: 'c1',
        semesterId: 'semester_1',
        status: EnrollmentModel.statusActive,
        assignedBy: 'admin',
      ),
    );

    setUp(() {
      fakeService = FakeTaskService();
      provider = TaskProvider(fakeService);
    });

    tearDown(() {
      fakeService.close();
      provider.dispose();
    });

    test('starts out in zero tasks / idle state', () {
      expect(provider.userId, isNull);
      expect(provider.tasks, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('syncing with active user starts listening and loads tasks', () async {
      provider.syncWithUserAndCourses(
        userId: 'student1',
        isLoggedIn: true,
        currentCourses: [student1Enrollment],
      );

      // Provider notifies inside a microtask, so we wait.
      await Future<void>.delayed(Duration.zero);

      expect(provider.userId, 'student1');
      expect(provider.isLoading, isTrue);

      final mockTasks = [
        TaskModel(
          id: 'task_1',
          userId: 'student1',
          title: 'Study Math',
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      fakeService.emit(mockTasks);
      await Future<void>.delayed(Duration.zero);

      expect(provider.isLoading, isFalse);
      expect(provider.tasks, hasLength(1));
      expect(provider.tasks.first.title, 'Study Math');
    });

    test('switching student drops previous student state and triggers new stream', () async {
      provider.syncWithUserAndCourses(
        userId: 'student1',
        isLoggedIn: true,
        currentCourses: [student1Enrollment],
      );
      await Future<void>.delayed(Duration.zero);

      fakeService.emit([
        TaskModel(
          id: 't1',
          userId: 'student1',
          title: 'Student 1 Task',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.tasks, hasLength(1));

      // Switch to student2
      provider.syncWithUserAndCourses(
        userId: 'student2',
        isLoggedIn: true,
        currentCourses: [],
      );
      await Future<void>.delayed(Duration.zero);

      expect(provider.userId, 'student2');
      // Previous state is cleared instantly to prevent leakage
      expect(provider.tasks, isEmpty);

      fakeService.emit([
        TaskModel(
          id: 't2',
          userId: 'student2',
          title: 'Student 2 Task',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.tasks, hasLength(1));
      expect(provider.tasks.first.title, 'Student 2 Task');
    });

    test('logout clears all task state and cancels listener', () async {
      provider.syncWithUserAndCourses(
        userId: 'student1',
        isLoggedIn: true,
        currentCourses: [student1Enrollment],
      );
      await Future<void>.delayed(Duration.zero);

      fakeService.emit([
        TaskModel(
          id: 't1',
          userId: 'student1',
          title: 'Task',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.tasks, isNotEmpty);

      // Logout
      provider.syncWithUserAndCourses(
        userId: null,
        isLoggedIn: false,
        currentCourses: [],
      );
      await Future<void>.delayed(Duration.zero);

      expect(provider.userId, isNull);
      expect(provider.tasks, isEmpty);
    });

    test('creating task with no course linkage succeeds', () async {
      provider.syncWithUserAndCourses(
        userId: 'student1',
        isLoggedIn: true,
        currentCourses: [student1Enrollment],
      );
      await Future<void>.delayed(Duration.zero);
      fakeService.emit([]);

      await provider.createTask(
        title: 'Simple Task',
        description: 'No course linkage',
        dueAt: null,
        priority: TaskPriority.low,
        type: TaskType.study,
        currentCourses: [student1Enrollment],
      );

      expect(fakeService.tasksList, hasLength(1));
      final created = fakeService.tasksList.first;
      expect(created.title, 'Simple Task');
      expect(created.userId, 'student1');
      expect(created.enrollmentId, isNull);
      expect(created.offeringId, isNull);
      expect(created.courseId, isNull);
    });

    test('creating task with valid course linkage copies enrollment details atomically', () async {
      provider.syncWithUserAndCourses(
        userId: 'student1',
        isLoggedIn: true,
        currentCourses: [student1Enrollment],
      );
      await Future<void>.delayed(Duration.zero);
      fakeService.emit([]);

      await provider.createTask(
        title: 'Linked Task',
        description: 'Linked to course',
        dueAt: null,
        priority: TaskPriority.high,
        type: TaskType.assignment,
        enrollmentId: 'enrollment_student1_c1',
        currentCourses: [student1Enrollment],
      );

      expect(fakeService.tasksList, hasLength(1));
      final created = fakeService.tasksList.first;
      expect(created.title, 'Linked Task');
      expect(created.userId, 'student1');
      expect(created.enrollmentId, 'enrollment_student1_c1');
      expect(created.offeringId, 'c1_offering');
      expect(created.courseId, 'c1');
    });

    test('linking an enrollment NOT in currentCourses throws TaskException', () async {
      provider.syncWithUserAndCourses(
        userId: 'student1',
        isLoggedIn: true,
        currentCourses: [student1Enrollment],
      );
      await Future<void>.delayed(Duration.zero);
      fakeService.emit([]);

      expect(
        () => provider.createTask(
          title: 'Linked Task',
          description: 'Linked to wrong course',
          dueAt: null,
          priority: TaskPriority.high,
          type: TaskType.assignment,
          enrollmentId: 'enrollment_another_student_c1',
          currentCourses: [student1Enrollment],
        ),
        throwsA(isA<TaskException>()),
      );
    });

    test('complete, reopen, update, and delete state mutations', () async {
      provider.syncWithUserAndCourses(
        userId: 'student1',
        isLoggedIn: true,
        currentCourses: [student1Enrollment],
      );
      await Future<void>.delayed(Duration.zero);

      final task = TaskModel(
        id: 't1',
        userId: 'student1',
        title: 'Incomplete Task',
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      fakeService.emit([task]);
      await Future<void>.delayed(Duration.zero);

      // Complete
      await provider.completeTask('t1');
      expect(provider.tasks.first.status, TaskStatus.completed);
      expect(provider.tasks.first.completedAt, isNotNull);

      // Reopen
      await provider.reopenTask('t1');
      expect(provider.tasks.first.status, TaskStatus.pending);
      expect(provider.tasks.first.completedAt, isNull);

      // Update
      await provider.updateTask(
        taskId: 't1',
        title: 'Updated Task Title',
        description: 'New Description',
        dueAt: null,
        priority: TaskPriority.high,
        type: TaskType.exam,
        currentCourses: [student1Enrollment],
        status: TaskStatus.pending,
      );
      expect(provider.tasks.first.title, 'Updated Task Title');
      expect(provider.tasks.first.priority, TaskPriority.high);

      // Delete
      await provider.deleteTask('t1');
      expect(provider.tasks, isEmpty);
    });

    test('another student\'s tasks are not loaded (isolation test)', () async {
      provider.syncWithUserAndCourses(
        userId: 'student1',
        isLoggedIn: true,
        currentCourses: [student1Enrollment],
      );
      await Future<void>.delayed(Duration.zero);

      // In real app, the where('userId', isEqualTo: userId) ensures this.
      // We verify that the FakeTaskService received the correct userId.
      expect(fakeService.watchedUserId, 'student1');
    });
  });
}
