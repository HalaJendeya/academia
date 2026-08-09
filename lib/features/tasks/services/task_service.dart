import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskException implements Exception {
  final String message;
  const TaskException(this.message);

  @override
  String toString() => message;
}

class TaskService {
  final FirebaseFirestore _firestore;

  TaskService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection('tasks');

  /// Returns a real-time Stream of tasks for the student, sorted client-side.
  Stream<List<TaskModel>> watchTasks(String userId) {
    return _tasks
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc.data(), doc.id))
              .toList();

          // Sort client-side:
          // 1. Completed tasks at the bottom.
          // 2. Pending tasks:
          //    - dueAt ascending (nulls last)
          //    - createdAt descending
          tasks.sort((a, b) {
            if (a.isCompleted && !b.isCompleted) return 1;
            if (!a.isCompleted && b.isCompleted) return -1;

            if (a.dueAt != null && b.dueAt == null) return -1;
            if (a.dueAt == null && b.dueAt != null) return 1;
            if (a.dueAt != null && b.dueAt != null) {
              final dueCompare = a.dueAt!.compareTo(b.dueAt!);
              if (dueCompare != 0) return dueCompare;
            }

            return b.createdAt.compareTo(a.createdAt);
          });

          return tasks;
        });
  }

  Future<void> createTask(TaskModel task) async {
    final docRef = _tasks.doc();
    final data = task.toMap();

    // Override with server timestamps and generated ID
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data.remove('completedAt');

    await docRef.set(data);
  }

  Future<void> updateTask(TaskModel task) async {
    final data = task.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data.remove('createdAt');

    await _tasks.doc(task.id).update(data);
  }

  Future<void> completeTask(String taskId) async {
    await _tasks.doc(taskId).update({
      'status': TaskStatus.completed.name,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reopenTask(String taskId) async {
    await _tasks.doc(taskId).update({
      'status': TaskStatus.pending.name,
      'completedAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTask(String taskId) async {
    await _tasks.doc(taskId).delete();
  }
}
