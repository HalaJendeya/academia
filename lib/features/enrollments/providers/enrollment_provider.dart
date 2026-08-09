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

  /// تنفيذ عملية كتابة واحدة مع إدارة حالة الحفظ ورسالة الخطأ.
  Future<bool> _runWrite(Future<void> Function(String userId) action) async {
    final student = _selectedStudent;
    if (student == null || _isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action(student.uid);
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

  Future<bool> assignToOffering(String offeringId) {
    return _runWrite(
      (userId) =>
          _service.assignToOffering(userId: userId, offeringId: offeringId),
    );
  }

  Future<bool> removeEnrollment(String offeringId) {
    return _runWrite(
      (userId) =>
          _service.removeEnrollment(userId: userId, offeringId: offeringId),
    );
  }

  Future<bool> restoreEnrollment(String offeringId) {
    return _runWrite(
      (userId) =>
          _service.restoreEnrollment(userId: userId, offeringId: offeringId),
    );
  }

  /// إنهاء المحاولة إداريًا دون تسجيل نتيجة أكاديمية.
  ///
  /// completionStatus يبقى null لأن نتيجة الطالب لا تُستنتج من كون المساق
  /// منتهيًا؛ تُسجَّل صراحةً عبر [setCompletionStatus].
  Future<bool> markEnrollmentCompleted(String offeringId) {
    return setEnrollmentStatus(
      offeringId: offeringId,
      status: EnrollmentModel.statusCompleted,
    );
  }

  Future<bool> setEnrollmentStatus({
    required String offeringId,
    required String status,
  }) {
    return _runWrite(
      (userId) => _service.setEnrollmentStatus(
        userId: userId,
        offeringId: offeringId,
        status: status,
      ),
    );
  }

  Future<bool> setCompletionStatus({
    required String offeringId,
    required String completionStatus,
    String? grade,
  }) {
    return _runWrite(
      (userId) => _service.setCompletionStatus(
        userId: userId,
        offeringId: offeringId,
        completionStatus: completionStatus,
        grade: grade,
      ),
    );
  }

  /// سجل تسجيل الطالب في طرح معيّن، أو null إن لم يكن مسجلًا فيه.
  EnrollmentModel? enrollmentForOffering(String offeringId) {
    for (final enrollment in _selectedStudentEnrollments) {
      if (enrollment.offeringId == offeringId) return enrollment;
    }
    return null;
  }

  /// أحدث محاولة للطالب في مساق دائم، أي صاحبة أكبر رقم محاولة.
  EnrollmentModel? latestAttemptForCourse(String courseId) {
    EnrollmentModel? latest;
    for (final enrollment in _selectedStudentEnrollments) {
      if (enrollment.courseId != courseId) continue;
      if (latest == null || enrollment.attemptNumber > latest.attemptNumber) {
        latest = enrollment;
      }
    }
    return latest;
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
