import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../models/semester_model.dart';
import '../services/semester_service.dart';

class SemesterProvider extends ChangeNotifier {
  final SemesterService _service;

  SemesterProvider(this._service);

  List<SemesterModel> _semesters = [];
  Map<String, SemesterModel> _byId = {};
  SemesterModel? _currentSemester;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  StreamSubscription<List<SemesterModel>>? _subscription;

  List<SemesterModel> get semesters => _semesters;

  /// بحث سريع عن الفصل الدراسي بالمعرّف، تستخدمه شاشات المساقات لعرض
  /// اسم الفصل بدل معرّفه.
  Map<String, SemesterModel> get byId => _byId;

  /// الفصل الدراسي الحالي مشتق من القائمة نفسها، لذلك لا نحتاج مستمعًا ثانيًا.
  SemesterModel? get currentSemester => _currentSemester;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  bool _isAdminSession = false;

  /// يتبع حالة المصادقة. يُستدعى من ProxyProvider في app_providers.
  ///
  /// شاشات الفصول الدراسية إدارية. المزوّد عالمي، فيبقى اشتراكه حيًّا بعد
  /// الخروج ما لم يُوقَف صراحةً.
  void syncWithAuth({required bool isActiveAdmin}) {
    if (isActiveAdmin) {
      _isAdminSession = true;
      return;
    }

    final hadAdminState =
        _isAdminSession || _subscription != null || _semesters.isNotEmpty;
    _isAdminSession = false;
    if (!hadAdminState) return;

    stopListening();
    _semesters = [];
    _byId = {};
    _currentSemester = null;
    _isLoading = false;
    _errorMessage = null;

    scheduleMicrotask(notifyListeners);
  }

  bool get hasSemesters => _semesters.isNotEmpty;

  /// اسم الفصل الدراسي للعرض، مع قيمة بديلة آمنة للمساقات القديمة التي
  /// لم تُربط بفصل دراسي بعد أو التي تشير إلى فصل محذوف.
  String semesterNameFor(String? semesterId) {
    if (semesterId == null || semesterId.trim().isEmpty) {
      return AppStrings.unknownSemester;
    }
    return _byId[semesterId]?.semesterName ?? AppStrings.unknownSemester;
  }

  void _applyData(List<SemesterModel> data) {
    _semesters = data;
    _byId = {for (final semester in data) semester.id: semester};

    SemesterModel? current;
    for (final semester in data) {
      if (semester.isCurrent) {
        current = semester;
        break;
      }
    }
    _currentSemester = current;
  }

  void listenToSemesters() {
    stopListening();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _service.watchSemesters().listen(
      (data) {
        _applyData(data);
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = AppStrings.semesterLoadError;
        notifyListeners();
      },
    );
  }

  Future<void> loadSemesters() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _applyData(await _service.getSemesters());
    } on SemesterException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = AppStrings.semesterLoadError;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<bool> createSemester(SemesterModel semester) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createSemester(semester);
      return true;
    } on SemesterException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.semesterSaveError;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateSemester(SemesterModel semester) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateSemester(semester);
      return true;
    } on SemesterException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.semesterSaveError;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> setCurrentSemester(String semesterId) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.setCurrentSemester(semesterId);
      return true;
    } on SemesterException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.semesterSaveError;
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
