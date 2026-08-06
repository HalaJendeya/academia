// lib/features/courses/providers/course_provider.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../models/course.dart';
import '../models/course_assignment_preview.dart';
import '../services/student_course_service.dart';

class CourseProvider extends ChangeNotifier {
  final CourseService _courseService;

  CourseProvider(this._courseService);

  List<Course> _activeCourses = [];
  List<Course> _archivedCourses = [];
  bool _isLoadingCourses = false;
  String? _coursesErrorMessage;
  bool _hasLoadedCourses = false;

  List<Course> get activeCourses => _activeCourses;
  List<Course> get archivedCourses => _archivedCourses;
  bool get isLoadingCourses => _isLoadingCourses;
  String? get coursesErrorMessage => _coursesErrorMessage;

  Course? _selectedCourse;
  bool _isLoadingCourseDetail = false;
  String? _courseDetailErrorMessage;

  Course? get selectedCourse => _selectedCourse;
  bool get isLoadingCourseDetail => _isLoadingCourseDetail;
  String? get courseDetailErrorMessage => _courseDetailErrorMessage;

  List<CourseAssignmentPreview> _courseAssignments = [];
  bool _isLoadingAssignments = false;
  String? _assignmentsErrorMessage;
  String? _loadedAssignmentsCourseId;

  List<CourseAssignmentPreview> get courseAssignments => _courseAssignments;
  bool get isLoadingAssignments => _isLoadingAssignments;
  String? get assignmentsErrorMessage => _assignmentsErrorMessage;

  void clearCoursesError() {
    _coursesErrorMessage = null;
    notifyListeners();
  }

  void clearCourseDetailError() {
    _courseDetailErrorMessage = null;
    notifyListeners();
  }

  void clearSelectedCourse() {
    _selectedCourse = null;
    _courseDetailErrorMessage = null;
    _isLoadingCourseDetail = false;
    _courseAssignments = [];
    _loadedAssignmentsCourseId = null;
    notifyListeners();
  }

  Future<void> loadCourses({bool forceRefresh = false}) async {
    if (_hasLoadedCourses && !forceRefresh) return;
    if (_isLoadingCourses) return;

    _isLoadingCourses = true;
    _coursesErrorMessage = null;
    notifyListeners();

    try {
      final active = await _courseService.getActiveCourses();
      final archived = await _courseService.getArchivedCourses();
      _activeCourses = active;
      _archivedCourses = archived;
      _hasLoadedCourses = true;
    } on CourseException catch (e) {
      _coursesErrorMessage = e.message;
    } catch (e) {
      _coursesErrorMessage = 'DEBUG: $e';
    } finally {
      _isLoadingCourses = false;
      notifyListeners();
    }
  }

  Future<void> loadCourseDetail(
      String courseId, {
        bool forceRefresh = false,
      }) async {
    if (_selectedCourse?.id == courseId && !forceRefresh) return;
    if (_isLoadingCourseDetail) return;

    _isLoadingCourseDetail = true;
    _courseDetailErrorMessage = null;
    notifyListeners();

    try {
      _selectedCourse = await _courseService.getCourseById(courseId);
    } on CourseException catch (e) {
      _courseDetailErrorMessage = e.message;
    } catch (e) {
      _courseDetailErrorMessage = AppStrings.courseDetailLoadError;
    } finally {
      _isLoadingCourseDetail = false;
      notifyListeners();
    }
  }

  Future<void> loadCourseAssignments(
      String courseId, {
        bool forceRefresh = false,
      }) async {
    if (_loadedAssignmentsCourseId == courseId && !forceRefresh) return;
    if (_isLoadingAssignments) return;

    _isLoadingAssignments = true;
    _assignmentsErrorMessage = null;
    notifyListeners();

    try {
      _courseAssignments = await _courseService.getCourseAssignments(
        courseId,
      );
      _loadedAssignmentsCourseId = courseId;
    } on CourseException catch (e) {
      _assignmentsErrorMessage = e.message;
    } catch (e) {
      _assignmentsErrorMessage = AppStrings.courseAssignmentsLoadError;
    } finally {
      _isLoadingAssignments = false;
      notifyListeners();
    }
  }
}