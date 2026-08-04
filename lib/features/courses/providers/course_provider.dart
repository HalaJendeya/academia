import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';

class CourseProvider extends ChangeNotifier {
  final CourseService _service;

  CourseProvider(this._service);

  List<CourseModel> _courses = [];
  CourseModel? _selectedCourse;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  StreamSubscription<List<CourseModel>>? _subscription;

  List<CourseModel> get courses => _courses;
  CourseModel? get selectedCourse => _selectedCourse;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> loadCourses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _courses = await _service.getCourses();
    } on CourseException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = AppStrings.courseLoadError;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void listenToCourses() {
    stopListening();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _service.watchCourses().listen(
      (data) {
        _courses = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = AppStrings.courseLoadError;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void selectCourse(CourseModel? course) {
    _selectedCourse = course;
    notifyListeners();
  }

  Future<bool> createCourse(CourseModel course) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.createCourse(course);
      return true;
    } on CourseException catch (e) {
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

  Future<bool> updateCourse(CourseModel course) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.updateCourse(course);
      return true;
    } on CourseException catch (e) {
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

  Future<bool> archiveCourse(String courseId) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.archiveCourse(courseId);
      return true;
    } on CourseException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.courseSaveError;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> deleteCourse(String courseId) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.deleteCourse(courseId);
      return true;
    } on CourseException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.courseSaveError;
      return false;
    } finally {
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
