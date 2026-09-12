// lib/features/profile/providers/email_settings_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/auth_service.dart';
import '../models/student_profile.dart';
import '../services/profile_service.dart';

/// نتيجة طلب تغيير البريد الأساسي.
enum PrimaryEmailChangeResult {
  /// أُرسل رابط التأكيد ولم يتغيّر شيء بعد.
  verificationSent,

  /// Firebase تطلب إعادة تأكيد الهوية بكلمة المرور.
  reauthenticationRequired,

  /// فشل، والسبب في [EmailSettingsProvider.errorMessage].
  failed,
}

/*
 * إدارة البريد الأساسي والاحتياطي لحساب الطالب.
 *
 * ═══════════════════ الحدّ الأمني، مذكورًا صراحة ═══════════════════
 *
 * 🔴 لا توجد وسيلة في Firebase Auth من جهة العميل للتحقق من ملكية عنوان
 * بريد اعتباطي مع الإبقاء على البريد الأساسي كما هو.
 *
 *   - sendEmailVerification() تُرسل إلى البريد الأساسي وحده، ولا تقبل
 *     عنوانًا آخر.
 *   - verifyBeforeUpdateEmail() ترسل إلى العنوان الجديد، لكن نقر الرابط
 *     **يجعله البريد الأساسي**؛ فهي تحقّق وترقية في عملية واحدة لا تنفصل.
 *   - ربط بيانات اعتماد بريدية أخرى بنفس الحساب يصطدم بمزوّد البريد
 *     الموجود أصلًا، ولا يعطي "عنوانًا احتياطيًا موثَّقًا".
 *
 * لذلك: العنوان الاحتياطي يُخزَّن **غير موثَّق**، ولا يوجد زر "تحقق" مستقل.
 * لا نضع secondaryEmailVerified = true بضغطة زر — ذلك ادّعاءٌ من العميل لا
 * إثبات، وقاعدة Firestore ترفضه أصلًا.
 *
 * الطريق الوحيد الصادق ليصير عنوانٌ موثَّقًا هو أن يمرّ فعليًا عبر Firebase
 * Auth كبريد دخول: عند تعيينه أساسيًا يُرسل الرابط إليه، وبنقره تُثبت
 * الملكية. حينها ينزل البريد الأساسي القديم احتياطيًا **موثَّقًا** — وهو
 * موثَّق بحق، إذ كان بريد دخول لهذا الحساب.
 *
 * ما يحتاج خادمًا موثوقًا لاحقًا (خارج نطاق هذه المهمة):
 *   1. توثيق عنوان احتياطي دون تغيير البريد الأساسي.
 *   2. استعادة الحساب بالبريد الاحتياطي والمستخدم **خارج** التطبيق.
 * كلاهما يتطلب Admin SDK في بيئة موثوقة؛ ولا يجوز محاكاته في العميل.
 */
class EmailSettingsProvider extends ChangeNotifier {
  EmailSettingsProvider(this._authService, this._profileService);

  final AuthService _authService;
  final ProfileService _profileService;

  StudentProfile? _profile;
  String? _primaryEmail;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  StudentProfile? get profile => _profile;

  /// البريد الأساسي من Firebase Auth — المرجع الوحيد.
  String? get primaryEmail => _primaryEmail;

  String? get secondaryEmail => _profile?.secondaryEmail;
  bool get isSecondaryVerified => _profile?.secondaryEmailVerified ?? false;
  String? get pendingPrimaryEmail => _profile?.pendingPrimaryEmail;
  bool get hasPendingChange => (pendingPrimaryEmail ?? '').isNotEmpty;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// يحمّل الحالة ويصالح بين Firebase وFirestore.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // إعادة التحميل أولًا: لو نقر الطالب الرابط خارج التطبيق، فهنا يظهر
      // البريد الجديد لأول مرة.
      final user = await _authService.refreshCurrentUser();
      _primaryEmail = user?.email ?? _authService.currentPrimaryEmail;

      _profile = await _profileService.getCurrentProfile();
      await _reconcilePrimaryEmail();
    } on ProfileException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = AppStrings.profileLoadError;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /*
   * المصالحة: Firebase Auth هي الحقيقة، وFirestore نسخة تتبعها.
   *
   * 🔴 هذا هو الموضع الوحيد الذي يُكتب فيه حقل email، وهو يعمل **بعد** أن
   * أكّد Firebase البريد الجديد لا قبله. فلا يحدث أن يقول المستند إن بريدًا
   * صار أساسيًا بينما الدخول ما زال بالقديم.
   *
   * ولأن التغيير غير متزامن (ينتظر نقر الرابط)، فالمصالحة تجري عند كل
   * تحميل: التطبيق قد يكون مغلقًا لحظة النقر.
   */
  Future<void> _reconcilePrimaryEmail() async {
    final profile = _profile;
    final authEmail = _primaryEmail;
    if (profile == null || authEmail == null || authEmail.isEmpty) return;

    final storedPrimary = profile.email.trim();
    if (storedPrimary.toLowerCase() == authEmail.trim().toLowerCase()) return;
    if (storedPrimary.isEmpty) return;

    // Firebase غيّرت البريد فعلًا: يُزامَن المستند وينزل القديم احتياطيًا
    // موثَّقًا.
    await _profileService.syncPrimaryEmailAfterChange(
      newPrimary: authEmail,
      previousPrimary: storedPrimary,
    );
    _profile = await _profileService.getCurrentProfile();
    _successMessage = AppStrings.primaryEmailChangeCompleted;
  }

  /// يتحقق من صيغة العنوان الاحتياطي قبل حفظه.
  ///
  /// يعيد رسالة الخطأ، أو null إن كان صالحًا.
  String? validateSecondaryEmail(String input) {
    final value = input.trim();
    if (value.isEmpty) return AppStrings.secondaryEmailRequired;

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return AppStrings.secondaryEmailInvalid;

    final primary = (_primaryEmail ?? '').trim().toLowerCase();
    if (primary.isNotEmpty && value.toLowerCase() == primary) {
      return AppStrings.secondaryEmailSameAsPrimary;
    }
    return null;
  }

  Future<bool> saveSecondaryEmail(String input) async {
    final error = validateSecondaryEmail(input);
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _profileService.saveSecondaryEmail(input.trim());
      _profile = await _profileService.getCurrentProfile();
      _successMessage = AppStrings.secondaryEmailSaved;
      return true;
    } on ProfileException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.secondaryEmailSaveError;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> removeSecondaryEmail() async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _profileService.removeSecondaryEmail();
      _profile = await _profileService.getCurrentProfile();
      _successMessage = AppStrings.secondaryEmailRemoved;
      return true;
    } on ProfileException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.secondaryEmailSaveError;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /*
   * طلب جعل البريد الاحتياطي أساسيًا.
   *
   * [password] اختيارية: تُمرَّر فقط حين تطلب Firebase إعادة تأكيد الهوية.
   * لا تُخزَّن، ولا تُكتب في سجل، ولا تُرسل إلى Firestore — تُستعمل لحظيًا
   * لبناء بيانات الاعتماد ثم تُهمل.
   *
   * لا يُلمس Firestore هنا سوى تسجيل حالة "بانتظار التأكيد". حقل email لا
   * يتغيّر إطلاقًا في هذا المسار: تغييره يقع في [_reconcilePrimaryEmail]
   * بعد أن تؤكّد Firebase الأمر.
   */
  Future<PrimaryEmailChangeResult> promoteSecondaryToPrimary({
    String? password,
  }) async {
    final target = (secondaryEmail ?? '').trim();
    if (target.isEmpty) {
      _errorMessage = AppStrings.secondaryEmailRequired;
      notifyListeners();
      return PrimaryEmailChangeResult.failed;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      if (password != null && password.isNotEmpty) {
        await _authService.reauthenticateWithPassword(password);
      }

      await _authService.verifyBeforeUpdatePrimaryEmail(target);
      await _profileService.markPrimaryEmailChangePending(target);
      _profile = await _profileService.getCurrentProfile();

      // 🔴 لا نقول "تم التغيير" — لم يتغيّر شيء بعد.
      _successMessage = AppStrings.primaryEmailChangeSent;
      return PrimaryEmailChangeResult.verificationSent;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // ليست فشلًا: الشاشة تطلب كلمة المرور ثم تعيد المحاولة.
        _errorMessage = null;
        return PrimaryEmailChangeResult.reauthenticationRequired;
      }
      _errorMessage = mapEmailChangeError(e);
      return PrimaryEmailChangeResult.failed;
    } on ProfileException catch (e) {
      _errorMessage = e.message;
      return PrimaryEmailChangeResult.failed;
    } catch (e) {
      _errorMessage = AppStrings.emailChangeErrorGeneric;
      return PrimaryEmailChangeResult.failed;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// رسائل عربية بنفس أسلوب AuthProvider._mapFirebaseAuthException.
  @visibleForTesting
  String mapEmailChangeError(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'requires-recent-login':
        return AppStrings.emailChangeErrorRecentLogin;
      case 'email-already-in-use':
        return AppStrings.emailChangeErrorInUse;
      case 'invalid-email':
        return AppStrings.errorInvalidEmail;
      case 'wrong-password':
      case 'invalid-credential':
        return AppStrings.loginErrorInvalid;
      case 'network-request-failed':
        return AppStrings.errorNetwork;
      case 'too-many-requests':
        return 'تم إجراء محاولات كثيرة. حاولي مرة أخرى لاحقًا.';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب.';
      default:
        return AppStrings.emailChangeErrorGeneric;
    }
  }
}
