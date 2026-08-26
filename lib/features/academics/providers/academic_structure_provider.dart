import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../models/department_model.dart';
import '../models/major_model.dart';
import '../services/department_service.dart';
import '../services/major_service.dart';

/// الهيكل الأكاديمي: الأقسام والتخصصات معًا.
///
/// جُمعا في مزوّد واحد لأنهما يُقرآن دائمًا معًا: كل شاشة تعرض تخصصًا تحتاج
/// اسم قسمه، وفصلهما يعني مستمعَين ودورة تحميل مزدوجة بلا فائدة.
class AcademicStructureProvider extends ChangeNotifier {
  final DepartmentService _departmentService;
  final MajorService _majorService;

  AcademicStructureProvider(this._departmentService, this._majorService);

  List<DepartmentModel> _departments = [];
  List<MajorModel> _majors = [];
  Map<String, DepartmentModel> _departmentsById = {};
  Map<String, MajorModel> _majorsById = {};

  bool _isLoadingDepartments = false;
  bool _isLoadingMajors = false;
  bool _isSaving = false;
  String? _errorMessage;

  StreamSubscription<List<DepartmentModel>>? _departmentsSubscription;
  StreamSubscription<List<MajorModel>>? _majorsSubscription;

  List<DepartmentModel> get departments => _departments;
  List<MajorModel> get majors => _majors;

  Map<String, DepartmentModel> get departmentsById => _departmentsById;
  Map<String, MajorModel> get majorsById => _majorsById;

  List<DepartmentModel> get activeDepartments =>
      _departments.where((department) => department.isActive).toList();
  List<MajorModel> get activeMajors =>
      _majors.where((major) => major.isActive).toList();

  bool get isLoading => _isLoadingDepartments || _isLoadingMajors;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  bool get hasDepartments => _departments.isNotEmpty;
  bool get hasMajors => _majors.isNotEmpty;

  bool _isAdminSession = false;

  /// يتبع حالة المصادقة. يُستدعى من ProxyProvider في app_providers.
  ///
  /// الأقسام والتخصصات يقرأها المشرف من شاشات الإدارة. المزوّد عالمي ولا
  /// يُستدعى dispose أثناء الجلسة، فبقاء الاستماع بعد الخروج ينتج
  /// PERMISSION_DENIED على departments. القواعد صحيحة؛ الخلل في دورة الحياة.
  void syncWithAuth({required bool isActiveAdmin}) {
    if (isActiveAdmin) {
      _isAdminSession = true;
      return;
    }

    final hadAdminState = _isAdminSession ||
        _departmentsSubscription != null ||
        _majorsSubscription != null ||
        _departments.isNotEmpty ||
        _majors.isNotEmpty;
    _isAdminSession = false;
    if (!hadAdminState) return;

    stopListening();
    _departments = [];
    _majors = [];
    _departmentsById = {};
    _majorsById = {};
    _isLoadingDepartments = false;
    _isLoadingMajors = false;
    _errorMessage = null;

    scheduleMicrotask(notifyListeners);
  }

  /// اسم القسم للعرض، مع قيمة بديلة آمنة للمساقات التي لم تُربط بقسم بعد.
  String departmentNameFor(String? departmentId) {
    if (departmentId == null || departmentId.trim().isEmpty) {
      return AppStrings.unknownDepartment;
    }
    return _departmentsById[departmentId]?.name ?? AppStrings.unknownDepartment;
  }

  String majorNameFor(String? majorId) {
    if (majorId == null || majorId.trim().isEmpty) {
      return AppStrings.unknownMajor;
    }
    return _majorsById[majorId]?.name ?? AppStrings.unknownMajor;
  }

  MajorModel? majorById(String? majorId) {
    if (majorId == null || majorId.trim().isEmpty) return null;
    return _majorsById[majorId];
  }

  /// تخصصات قسم معيّن، مشتقة محليًا بدل استعلام إضافي.
  List<MajorModel> majorsOfDepartment(String departmentId) =>
      _majors.where((major) => major.departmentId == departmentId).toList();

  void listenToStructure() {
    listenToDepartments();
    listenToMajors();
  }

  void listenToDepartments() {
    _departmentsSubscription?.cancel();
    _departmentsSubscription = null;

    _isLoadingDepartments = true;
    _errorMessage = null;
    notifyListeners();

    _departmentsSubscription = _departmentService.watchDepartments().listen(
      (data) {
        _departments = data;
        _departmentsById = {
          for (final department in data) department.id: department,
        };
        _isLoadingDepartments = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoadingDepartments = false;
        _errorMessage = AppStrings.departmentLoadError;
        notifyListeners();
      },
    );
  }

  void listenToMajors() {
    _majorsSubscription?.cancel();
    _majorsSubscription = null;

    _isLoadingMajors = true;
    _errorMessage = null;
    notifyListeners();

    _majorsSubscription = _majorService.watchMajors().listen(
      (data) {
        _majors = data;
        _majorsById = {for (final major in data) major.id: major};
        _isLoadingMajors = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoadingMajors = false;
        _errorMessage = AppStrings.majorLoadError;
        notifyListeners();
      },
    );
  }

  Future<void> loadStructure() async {
    _isLoadingDepartments = true;
    _isLoadingMajors = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final departments = await _departmentService.getDepartments();
      _departments = departments;
      _departmentsById = {
        for (final department in departments) department.id: department,
      };
    } on DepartmentException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = AppStrings.departmentLoadError;
    } finally {
      _isLoadingDepartments = false;
    }

    try {
      final majors = await _majorService.getMajors();
      _majors = majors;
      _majorsById = {for (final major in majors) major.id: major};
    } on MajorException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = AppStrings.majorLoadError;
    } finally {
      _isLoadingMajors = false;
      notifyListeners();
    }
  }

  void stopListening() {
    _departmentsSubscription?.cancel();
    _departmentsSubscription = null;
    _majorsSubscription?.cancel();
    _majorsSubscription = null;
  }

  Future<bool> createDepartment(DepartmentModel department) async {
    return _runWrite(
      () => _departmentService.createDepartment(department),
      AppStrings.departmentSaveError,
    );
  }

  Future<bool> updateDepartment(DepartmentModel department) async {
    return _runWrite(
      () => _departmentService.updateDepartment(department),
      AppStrings.departmentSaveError,
    );
  }

  Future<bool> createMajor(MajorModel major) async {
    return _runWrite(
      () => _majorService.createMajor(major),
      AppStrings.majorSaveError,
    );
  }

  Future<bool> updateMajor(MajorModel major) async {
    return _runWrite(
      () => _majorService.updateMajor(major),
      AppStrings.majorSaveError,
    );
  }

  Future<bool> _runWrite(
    Future<void> Function() action,
    String fallbackError,
  ) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on DepartmentException catch (e) {
      _errorMessage = e.message;
      return false;
    } on MajorException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = fallbackError;
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
    super.dispose();
  }
}
