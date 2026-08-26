import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../courses/models/course_offering_model.dart';
import '../../courses/services/course_offering_service.dart';
import '../models/admin_teacher_model.dart';
import '../services/admin_teacher_service.dart';

/// حسابات المعلّمين في واجهة المشرف.
///
/// مستمع واحد إلى كل المعلّمين، والنشطون منهم يُشتقّون في الذاكرة: قائمة
/// المعلّمين قصيرة بطبيعتها، ومستمع ثانٍ لاستعلام status لا يشتري شيئًا
/// مقابل اشتراك إضافي يجب إيقافه.
class AdminTeacherProvider extends ChangeNotifier {
  final AdminTeacherService _service;
  final CourseOfferingService _offeringService;

  AdminTeacherProvider(this._service, this._offeringService);

  List<AdminTeacherModel> _teachers = [];
  List<CourseOfferingModel> _selectedTeacherOfferings = [];
  AdminTeacherModel? _selectedTeacher;

  bool _isLoading = false;
  bool _isLoadingOfferings = false;
  bool _isSaving = false;
  String? _errorMessage;

  StreamSubscription<List<AdminTeacherModel>>? _subscription;
  StreamSubscription<List<CourseOfferingModel>>? _offeringsSubscription;

  List<AdminTeacherModel> get teachers => _teachers;

  /// المعلّمون الذين يصح إسناد طرح إليهم.
  List<AdminTeacherModel> get activeTeachers =>
      _teachers.where((teacher) => teacher.isActive).toList();

  List<CourseOfferingModel> get selectedTeacherOfferings =>
      _selectedTeacherOfferings;
  AdminTeacherModel? get selectedTeacher => _selectedTeacher;

  bool get isLoading => _isLoading;
  bool get isLoadingOfferings => _isLoadingOfferings;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  bool _isAdminSession = false;

  /// يتبع حالة المصادقة. يُستدعى من ProxyProvider في app_providers.
  ///
  /// المستمع هنا هو users حيث role == teacher، وهو استعلام قائمة مسموح
  /// للمشرف وحده. بقاؤه حيًّا بعد الخروج أو بعد تبديل الحساب ينتج
  /// PERMISSION_DENIED متكررة، والعلاج إيقاف المستمع لا إضعاف القاعدة.
  void syncWithAuth({required bool isActiveAdmin}) {
    if (isActiveAdmin) {
      _isAdminSession = true;
      return;
    }

    final hadAdminState = _isAdminSession ||
        _subscription != null ||
        _offeringsSubscription != null ||
        _teachers.isNotEmpty;
    _isAdminSession = false;
    if (!hadAdminState) return;

    stopListening();
    stopListeningToOfferings();

    _teachers = [];
    _selectedTeacherOfferings = [];
    _selectedTeacher = null;
    _isLoading = false;
    _isLoadingOfferings = false;
    _errorMessage = null;

    scheduleMicrotask(notifyListeners);
  }

  void listenToTeachers() {
    stopListening();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _service.watchTeachers().listen(
      (data) {
        _teachers = data;
        // المعلّم المفتوح في شاشة التفاصيل يتبع البثّ: تعطيل الحساب يجب أن
        // يظهر في الشاشة نفسها التي عُطِّل منها.
        final selected = _selectedTeacher;
        if (selected != null) {
          for (final teacher in data) {
            if (teacher.uid == selected.uid) {
              _selectedTeacher = teacher;
              break;
            }
          }
        }
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = AppStrings.teacherLoadError;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void selectTeacher(AdminTeacherModel teacher) {
    _selectedTeacher = teacher;
    notifyListeners();
    listenToTeacherOfferings(teacher.uid);
  }

  /// الطروحات المسندة إلى معلّم — ما يملكه فعلًا، لا عدد مُقدَّر.
  void listenToTeacherOfferings(String teacherId) {
    stopListeningToOfferings();

    _isLoadingOfferings = true;
    notifyListeners();

    _offeringsSubscription = _offeringService
        .watchOfferingsByTeacher(teacherId)
        .listen(
          (data) {
            _selectedTeacherOfferings = data;
            _isLoadingOfferings = false;
            notifyListeners();
          },
          onError: (error) {
            _selectedTeacherOfferings = [];
            _isLoadingOfferings = false;
            _errorMessage = AppStrings.offeringLoadError;
            notifyListeners();
          },
        );
  }

  void stopListeningToOfferings() {
    _offeringsSubscription?.cancel();
    _offeringsSubscription = null;
    _selectedTeacherOfferings = [];
  }

  Future<bool> setTeacherStatus({
    required String uid,
    required String status,
  }) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.setTeacherStatus(uid: uid, status: status);
      return true;
    } on AdminTeacherException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.teacherSaveError;
      return false;
    } finally {
      _isSaving = false;
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
    stopListeningToOfferings();
    super.dispose();
  }
}
