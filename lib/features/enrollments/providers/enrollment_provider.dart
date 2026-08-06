import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../admin/models/admin_student_model.dart';
import '../models/enrollment_model.dart';
import '../services/enrollment_service.dart';

class EnrollmentProvider extends ChangeNotifier {
  final EnrollmentService _service;

  EnrollmentProvider(this._service);

  List<AdminStudentModel> _students = [];
  List<EnrollmentModel> _selectedStudentEnrollments = [];
  AdminStudentModel? _selectedStudent;

  bool _isLoadingStudents = false;
  bool _isLoadingEnrollments = false;
  bool _isSaving = false;
  String? _errorMessage;

  StreamSubscription<List<AdminStudentModel>>? _studentsSubscription;
  StreamSubscription<List<EnrollmentModel>>? _enrollmentsSubscription;

  List<AdminStudentModel> get students => _students;
  List<EnrollmentModel> get selectedStudentEnrollments =>
      _selectedStudentEnrollments;
  AdminStudentModel? get selectedStudent => _selectedStudent;

  bool get isLoadingStudents => _isLoadingStudents;
  bool get isLoadingEnrollments => _isLoadingEnrollments;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  void listenToStudents() {
    stopListeningToStudents();
    _isLoadingStudents = true;
    _errorMessage = null;
    notifyListeners();

    _studentsSubscription = _service.watchStudents().listen(
      (data) {
        _students = data;
        _isLoadingStudents = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (err) {
        _isLoadingStudents = false;
        _errorMessage = AppStrings.courseLoadError;
        notifyListeners();
      },
    );
  }

  void stopListeningToStudents() {
    _studentsSubscription?.cancel();
    _studentsSubscription = null;
  }

  void selectStudent(AdminStudentModel student) {
    _selectedStudent = student;
    notifyListeners();
    loadStudentEnrollments(student.uid);
  }

  void loadStudentEnrollments(String userId) {
    _enrollmentsSubscription?.cancel();
    _enrollmentsSubscription = null;

    _isLoadingEnrollments = true;
    _errorMessage = null;
    notifyListeners();

    _enrollmentsSubscription = _service
        .watchStudentEnrollments(userId)
        .listen(
          (data) {
            _selectedStudentEnrollments = data;
            _isLoadingEnrollments = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (err) {
            _isLoadingEnrollments = false;
            _errorMessage = AppStrings.courseLoadError;
            notifyListeners();
          },
        );
  }

  Future<bool> assignCourse(String courseId) async {
    if (_selectedStudent == null || _isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.assignCourse(
        userId: _selectedStudent!.uid,
        courseId: courseId,
      );
      return true;
    } on EnrollmentException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.courseSaveError;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> removeCourse(String courseId) async {
    if (_selectedStudent == null || _isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.removeCourse(
        userId: _selectedStudent!.uid,
        courseId: courseId,
      );
      return true;
    } on EnrollmentException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.courseSaveError;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> restoreCourse(String courseId) async {
    if (_selectedStudent == null || _isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.restoreCourse(
        userId: _selectedStudent!.uid,
        courseId: courseId,
      );
      return true;
    } on EnrollmentException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.courseSaveError;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void stopListeningToSelectedStudentEnrollments() {
    _enrollmentsSubscription?.cancel();
    _enrollmentsSubscription = null;
  }

  void clearSelectedStudent({bool notify = true}) {
    _selectedStudent = null;
    _selectedStudentEnrollments = [];
    stopListeningToSelectedStudentEnrollments();
    if (notify) {
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListeningToStudents();
    _enrollmentsSubscription?.cancel();
    _enrollmentsSubscription = null;
    super.dispose();
  }
}
