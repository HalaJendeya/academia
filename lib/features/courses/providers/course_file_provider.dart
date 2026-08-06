// lib/features/courses/providers/course_file_provider.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../models/course_file.dart';
import '../services/student_course_file_service.dart';

class CourseFileProvider extends ChangeNotifier {
  final CourseFileService _courseFileService;

  CourseFileProvider(this._courseFileService);

  List<CourseFile> _files = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _loadedCourseId;

  List<CourseFile> get files => _files;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadFiles(String courseId, {bool forceRefresh = false}) async {
    if (_loadedCourseId == courseId && !forceRefresh) return;
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _files = await _courseFileService.getCourseFiles(courseId);
      _loadedCourseId = courseId;
    } on CourseFileException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = AppStrings.courseFilesLoadError;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}