import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../services/support_service.dart';

class SupportProvider extends ChangeNotifier {
  final SupportService _service;

  SupportProvider(this._service);

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> submitRequest({
    required String subject,
    required String message,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.submitSupportRequest(subject: subject, message: message);
      return true;
    } on SupportException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.supportRequestError;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
