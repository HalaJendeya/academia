import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../services/admin_user_service.dart';

/// إجراءات المشرف على حسابات المستخدمين.
///
/// كتابة فقط: لا يحمل قائمة الطلاب. القائمة تصل من EnrollmentProvider عبر
/// بثّ مباشر من مجموعة users، فتغيّر الحالة يظهر فيها من تلقائه دون أن
/// يحتفظ هذا المزوّد بنسخة ثانية قد تتناقض معها.
class AdminUserProvider extends ChangeNotifier {
  final AdminUserService _service;

  AdminUserProvider(this._service);

  bool _isSaving = false;
  String? _errorMessage;

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> disableStudent(String userId) =>
      setAccountStatus(userId: userId, status: AdminUserService.statusDisabled);

  Future<bool> activateStudent(String userId) =>
      setAccountStatus(userId: userId, status: AdminUserService.statusActive);

  /// يعيد true عند نجاح الكتابة فقط.
  ///
  /// الشاشة لا تعرض الحالة الجديدة إلا بناءً على هذه القيمة: عرض متفائل
  /// قبل تأكيد الكتابة يجعل الواجهة تدّعي تغييرًا قد يكون مرفوضًا.
  Future<bool> setAccountStatus({
    required String userId,
    required String status,
  }) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.setStudentAccountStatus(userId: userId, status: status);
      return true;
    } on AdminUserException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.accountStatusUpdateError;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
