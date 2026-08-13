import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../../courses/models/student_course_view.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _taskService;

  TaskProvider(this._taskService);

  String? _userId;
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<TaskModel>>? _tasksSubscription;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userId => _userId;

  /// Synchronizes task subscription with Auth State and current student courses.
  /// Invoked by ProxyProvider in app_providers.
  void syncWithUserAndCourses({
    required String? userId,
    required bool isLoggedIn,
    required List<StudentCourseView> currentCourses,
  }) {
    final sameUser = userId == _userId;

    if (!isLoggedIn || userId == null) {
      if (_userId != null || _tasks.isNotEmpty) {
        _userId = null;
        _tasks = [];
        _isLoading = false;
        _errorMessage = null;
        stopListening();
        scheduleMicrotask(notifyListeners);
      }
      return;
    }

    if (sameUser && (_tasksSubscription != null || _isLoading)) {
      return;
    }

    if (!sameUser) {
      _userId = userId;
      _tasks = [];
      _isLoading = true;
      _errorMessage = null;
      stopListening();
    }

    scheduleMicrotask(() => _initListening(userId));
  }

  void _initListening(String userId) {
    stopListening();
    _userId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _tasksSubscription = _taskService.watchTasks(userId).listen(
      (data) {
        _tasks = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل المهام الدراسية.';
        notifyListeners();
      },
    );
  }

  Future<void> createTask({
    required String title,
    required String description,
    required DateTime? dueAt,
    required TaskPriority priority,
    required TaskType type,
    String? enrollmentId,
    required List<StudentCourseView> currentCourses,
  }) async {
    if (_userId == null) {
      throw const TaskException('يجب تسجيل الدخول لإضافة مهمة.');
    }

    String? offeringId;
    String? courseId;

    if (enrollmentId != null && enrollmentId.trim().isNotEmpty) {
      final match = currentCourses.firstWhere(
        (c) => c.enrollment.id == enrollmentId,
        orElse: () => throw const TaskException('المساق المحدد غير موجود في مساقاتك الحالية.'),
      );
      offeringId = match.offeringId;
      courseId = match.courseId;
    }

    final task = TaskModel(
      id: '',
      userId: _userId!,
      title: title.trim(),
      description: description.trim(),
      enrollmentId: enrollmentId,
      offeringId: offeringId,
      courseId: courseId,
      dueAt: dueAt,
      priority: priority,
      status: TaskStatus.pending,
      type: type,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _taskService.createTask(task);
  }

  Future<void> updateTask({
    required String taskId,
    required String title,
    required String description,
    required DateTime? dueAt,
    required TaskPriority priority,
    required TaskType type,
    String? enrollmentId,
    required List<StudentCourseView> currentCourses,
    required TaskStatus status,
  }) async {
    if (_userId == null) {
      throw const TaskException('يجب تسجيل الدخول لتعديل مهمة.');
    }

    final existingTask = _tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw const TaskException('المهمة غير موجودة أو لا تملك صلاحية تعديلها.'),
    );

    String? offeringId;
    String? courseId;

    if (enrollmentId != null && enrollmentId.trim().isNotEmpty) {
      final match = currentCourses.firstWhere(
        (c) => c.enrollment.id == enrollmentId,
        orElse: () => throw const TaskException('المساق المحدد غير موجود في مساقاتك الحالية.'),
      );
      offeringId = match.offeringId;
      courseId = match.courseId;
    }

    final updated = existingTask.copyWith(
      title: title.trim(),
      description: description.trim(),
      enrollmentId: enrollmentId,
      offeringId: offeringId,
      courseId: courseId,
      dueAt: dueAt,
      priority: priority,
      type: type,
      status: status,
      clearCourseLink: enrollmentId == null || enrollmentId.trim().isEmpty,
    );

    await _taskService.updateTask(updated);
  }

  Future<void> completeTask(String taskId) async {
    final exists = _tasks.any((t) => t.id == taskId);
    if (!exists) {
      throw const TaskException('المهمة غير موجودة أو لا تملك صلاحية إكمالها.');
    }
    await _taskService.completeTask(taskId);
  }

  Future<void> reopenTask(String taskId) async {
    final exists = _tasks.any((t) => t.id == taskId);
    if (!exists) {
      throw const TaskException('المهمة غير موجودة أو لا تملك صلاحية إعادة فتحها.');
    }
    await _taskService.reopenTask(taskId);
  }

  Future<void> deleteTask(String taskId) async {
    final exists = _tasks.any((t) => t.id == taskId);
    if (!exists) {
      throw const TaskException('المهمة غير موجودة أو لا تملك صلاحية حذفها.');
    }
    await _taskService.deleteTask(taskId);
  }

  void stopListening() {
    _tasksSubscription?.cancel();
    _tasksSubscription = null;
  }

  void clear() {
    stopListening();
    _userId = null;
    _tasks = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
