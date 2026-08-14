import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../profile/models/support_request.dart';
import '../../profile/services/support_service.dart';

/// تصفية صندوق وارد الدعم. حالة عرض محلية لا تُخزَّن.
enum SupportRequestFilter { all, open, resolved }

/// صندوق وارد طلبات الدعم للمشرف.
///
/// منفصل عن SupportProvider عن قصد: ذاك يملك حالة إرسال الطالب
/// (isSubmitting) وحدها، وحشو حالة قائمة المشرف فيه يجعل مزوّدًا واحدًا
/// يخدم دورين لا يشتركان في شيء.
///
/// الخدمة نفسها مشتركة: SupportService يملك مجموعة supportRequests كتابةً
/// وقراءةً، فلا خدمة ثانية.
class AdminSupportProvider extends ChangeNotifier {
  final SupportService _service;

  AdminSupportProvider(this._service);

  List<SupportRequest> _requests = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  StreamSubscription<List<SupportRequest>>? _subscription;

  List<SupportRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  List<SupportRequest> get openRequests =>
      _requests.where((request) => request.isOpen).toList();

  List<SupportRequest> get resolvedRequests =>
      _requests.where((request) => request.isResolved).toList();

  List<SupportRequest> filtered(SupportRequestFilter filter) {
    switch (filter) {
      case SupportRequestFilter.all:
        return _requests;
      case SupportRequestFilter.open:
        return openRequests;
      case SupportRequestFilter.resolved:
        return resolvedRequests;
    }
  }

  void listenToRequests() {
    if (_subscription != null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _service.watchSupportRequests().listen(
      (data) {
        _requests = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = AppStrings.supportRequestsLoadError;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<bool> markResolved(String requestId) =>
      _setStatus(requestId, SupportRequest.statusResolved);

  Future<bool> reopen(String requestId) =>
      _setStatus(requestId, SupportRequest.statusOpen);

  /// القائمة تستمع إلى Firestore، فالحالة الجديدة تصل من المصدر لا من
  /// تعديل محلي متفائل قد يخالف ما حُفظ فعلًا.
  Future<bool> _setStatus(String requestId, String status) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.setRequestStatus(requestId: requestId, status: status);
      return true;
    } on SupportException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.supportRequestStatusError;
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
