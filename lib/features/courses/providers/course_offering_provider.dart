import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../models/course_offering_model.dart';
import '../services/course_offering_service.dart';

/// طروحات المساقات لفصل دراسي واحد في كل مرة.
///
/// الطروحات دائمًا مقيَّدة بفصل: عرض كل الطروحات عبر كل الفصول ليس سؤالًا
/// تطرحه أي شاشة، بينما "ما المطروح في هذا الفصل؟" هو السؤال الوحيد المتكرر.
class CourseOfferingProvider extends ChangeNotifier {
  final CourseOfferingService _service;

  CourseOfferingProvider(this._service);

  List<CourseOfferingModel> _offerings = [];
  Map<String, CourseOfferingModel> _byId = {};
  Map<String, List<CourseOfferingModel>> _byCourseId = {};

  String? _semesterId;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  StreamSubscription<List<CourseOfferingModel>>? _subscription;

  List<CourseOfferingModel> get offerings => _offerings;
  Map<String, CourseOfferingModel> get byId => _byId;

  /// الفصل الدراسي الذي تعود إليه القائمة الحالية.
  String? get semesterId => _semesterId;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  List<CourseOfferingModel> get activeOfferings =>
      _offerings.where((offering) => offering.isActive).toList();

  bool _isAdminSession = false;

  /// يتبع حالة المصادقة. يُستدعى من ProxyProvider في app_providers.
  ///
  /// مزوّد عالمي لا يُستدعى dispose أثناء الجلسة، فلا بد من إيقاف الاستماع
  /// صراحةً عند الخروج بدل ترك الاشتراك حيًّا.
  void syncWithAuth({required bool isActiveAdmin}) {
    if (isActiveAdmin) {
      _isAdminSession = true;
      return;
    }

    final hadAdminState =
        _isAdminSession || _subscription != null || _offerings.isNotEmpty;
    _isAdminSession = false;
    if (!hadAdminState) return;

    stopListening();
    _offerings = [];
    _byId = {};
    _byCourseId = {};
    _semesterId = null;
    _isLoading = false;
    _errorMessage = null;

    scheduleMicrotask(notifyListeners);
  }

  /// كل شعب مساق دائم داخل الفصل المحمَّل.
  List<CourseOfferingModel> offeringsOfCourse(String courseId) =>
      _byCourseId[courseId] ?? const <CourseOfferingModel>[];

  /// أول طرح نشط لمساق دائم داخل الفصل المحمَّل، أو null إن لم يُطرح.
  ///
  /// يُستخدم في التسجيل: الطالب يُسجَّل في طرح، والمساق وحده لا يكفي.
  CourseOfferingModel? activeOfferingForCourse(String courseId) {
    for (final offering in offeringsOfCourse(courseId)) {
      if (offering.isActive) return offering;
    }
    return null;
  }

  String instructorNameFor(String? offeringId) {
    if (offeringId == null || offeringId.trim().isEmpty) return '';
    return _byId[offeringId]?.instructorName ?? '';
  }

  void _applyData(List<CourseOfferingModel> data) {
    _offerings = data;
    _byId = {for (final offering in data) offering.id: offering};

    final grouped = <String, List<CourseOfferingModel>>{};
    for (final offering in data) {
      grouped.putIfAbsent(offering.courseId, () => []).add(offering);
    }
    _byCourseId = grouped;
  }

  void listenToSemesterOfferings(String semesterId) {
    stopListening();

    _semesterId = semesterId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _service.watchOfferingsBySemester(semesterId).listen(
      (data) {
        _applyData(data);
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = AppStrings.offeringLoadError;
        notifyListeners();
      },
    );
  }

  Future<void> loadSemesterOfferings(String semesterId) async {
    _semesterId = semesterId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _applyData(await _service.getOfferingsBySemester(semesterId));
    } on CourseOfferingException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = AppStrings.offeringLoadError;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void clearOfferings() {
    stopListening();
    _semesterId = null;
    _applyData(const <CourseOfferingModel>[]);
    notifyListeners();
  }

  Future<bool> createOffering(CourseOfferingModel offering) {
    return _runWrite(() => _service.createOffering(offering));
  }

  Future<bool> updateOffering(CourseOfferingModel offering) {
    return _runWrite(() => _service.updateOffering(offering));
  }

  Future<bool> archiveOffering(String offeringId) {
    return _runWrite(() => _service.archiveOffering(offeringId));
  }

  /// عدد الطروحات المنسوخة، أو null عند الفشل.
  ///
  /// يعيد العدد لا مجرد نجاح، لأن نسخ صفر طرح عملية ناجحة لكنها لا تعني شيئًا
  /// للمشرف ما لم تُعرض.
  Future<int?> duplicateSemesterOfferings({
    required String fromSemesterId,
    required String toSemesterId,
  }) async {
    if (_isSaving) return null;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _service.duplicateSemesterOfferings(
        fromSemesterId: fromSemesterId,
        toSemesterId: toSemesterId,
      );
    } on CourseOfferingException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = AppStrings.offeringSaveError;
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> _runWrite(Future<void> Function() action) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on CourseOfferingException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.offeringSaveError;
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
