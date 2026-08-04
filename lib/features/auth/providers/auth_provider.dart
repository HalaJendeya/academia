import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/auth_service.dart';
import '../models/app_user_model.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  bool _isLoading = false;
  String? _errorMessage;
  AppUserModel? _currentUserProfile;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  /// مستخدم Firebase Authentication الحالي.
  User? get currentUser => _authService.currentUser;

  /// بيانات المستخدم المحفوظة داخل Firestore.
  AppUserModel? get currentUserProfile => _currentUserProfile;

  /// هل يوجد مستخدم مسجل الدخول؟
  bool get isLoggedIn => currentUser != null;

  /// هل المستخدم الحالي مدير؟
  bool get isAdmin => _currentUserProfile?.isAdmin ?? false;

  /// هل المستخدم الحالي طالب؟
  bool get isStudent => _currentUserProfile?.isStudent ?? false;

  /// هل الحساب الحالي نشط؟
  bool get isAccountActive => _currentUserProfile?.isActive ?? false;

  /// هل أكمل المستخدم الإعداد الأولي؟
  bool get onboardingCompleted =>
      _currentUserProfile?.onboardingCompleted ?? false;

  /// حالة الإعداد الأولي المحفوظة في Firestore.
  String get onboardingStatus =>
      _currentUserProfile?.onboardingStatus ?? 'pending';

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _mapFirebaseAuthException(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'user-not-found':
        return AppStrings.errorUserNotFound;

      case 'wrong-password':
      case 'invalid-credential':
        return AppStrings.loginErrorInvalid;

      case 'email-already-in-use':
        return AppStrings.errorEmailAlreadyInUse;

      case 'weak-password':
        return AppStrings.errorWeakPassword;

      case 'invalid-email':
        return AppStrings.errorInvalidEmail;

      case 'network-request-failed':
        return AppStrings.errorNetwork;

      case 'too-many-requests':
        return 'تم إجراء محاولات كثيرة. حاولي مرة أخرى لاحقًا.';

      case 'user-disabled':
        return 'تم تعطيل هذا الحساب.';

      default:
        return AppStrings.errorUnknown;
    }
  }

  /// تحميل بيانات المستخدم الحالي من Firestore.
  Future<bool> loadCurrentUserProfile() async {
    try {
      _currentUserProfile = await _authService.getCurrentUserProfile();

      notifyListeners();

      return _currentUserProfile != null;
    } catch (_) {
      _currentUserProfile = null;
      _setError('تعذر تحميل بيانات الحساب من قاعدة البيانات.');

      return false;
    }
  }

  /// تسجيل الدخول وتحميل دور المستخدم وبياناته.
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.signInWithEmailAndPassword(email, password);

      final profileLoaded = await loadCurrentUserProfile();

      if (!profileLoaded) {
        await _authService.signOut();
        _currentUserProfile = null;
        return false;
      }

      if (!isAccountActive) {
        await _authService.signOut();
        _currentUserProfile = null;
        _setError('هذا الحساب غير نشط.');
        return false;
      }

      return true;
    } on FirebaseAuthException catch (exception) {
      _setError(_mapFirebaseAuthException(exception));

      return false;
    } catch (_) {
      _setError(AppStrings.errorUnknown);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// تسجيل طالب جديد.
  ///
  /// جميع الحسابات المنشأة من شاشة التسجيل تحصل على دور student.
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
  }) async {
    _setLoading(true);
    _setError(null);

    User? createdUser;

    try {
      final credential = await _authService.createUserWithEmailAndPassword(
        email,
        password,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        _setError(AppStrings.errorUnknown);
        return false;
      }

      await _authService.createStudentProfile(
        uid: createdUser.uid,
        fullName: fullName,
        email: email,
        studentId: studentId,
      );

      await _authService.sendEmailVerification();

      await loadCurrentUserProfile();

      return true;
    } on FirebaseAuthException catch (exception) {
      _setError(_mapFirebaseAuthException(exception));

      return false;
    } catch (_) {
      /*
       * إذا تم إنشاء الحساب داخل Authentication لكن فشل إنشاء
       * مستند Firestore، نسجل الخروج حتى لا يدخل المستخدم إلى
       * التطبيق بدون ملف مستخدم.
       */
      if (createdUser != null) {
        await _authService.signOut();
      }

      _currentUserProfile = null;
      _setError(AppStrings.errorUnknown);

      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// تسجيل الخروج ومسح بيانات المستخدم المحلية.
  Future<bool> logout() async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.signOut();
      _currentUserProfile = null;
      return true;
    } on FirebaseAuthException catch (exception) {
      _setError(_mapFirebaseAuthException(exception));
      return false;
    } catch (_) {
      _setError(AppStrings.errorUnknown);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// إرسال رسالة تحقق جديدة.
  Future<bool> sendEmailVerification() async {
    _setError(null);

    try {
      await _authService.sendEmailVerification();
      return true;
    } on FirebaseAuthException catch (exception) {
      _setError(_mapFirebaseAuthException(exception));

      return false;
    } catch (_) {
      _setError(AppStrings.errorUnknown);
      return false;
    }
  }

  /// إرسال رابط استعادة كلمة المرور.
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (exception) {
      _setError(_mapFirebaseAuthException(exception));

      return false;
    } catch (_) {
      _setError(AppStrings.errorUnknown);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// التحقق من البريد ثم تحديث بيانات المستخدم المحملة.
  Future<bool> checkEmailVerified() async {
    _setError(null);

    try {
      final isVerified = await _authService.checkEmailVerified();

      if (isVerified) {
        await loadCurrentUserProfile();
      }

      return isVerified;
    } on FirebaseAuthException catch (exception) {
      _setError(_mapFirebaseAuthException(exception));

      return false;
    } catch (_) {
      _setError(AppStrings.errorUnknown);
      return false;
    }
  }

  /// تستخدم عند تشغيل التطبيق والمستخدم مسجل مسبقًا.
  Future<bool> initializeCurrentUser() async {
    if (!isLoggedIn) {
      _currentUserProfile = null;
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final loaded = await loadCurrentUserProfile();

      if (!loaded || !isAccountActive) {
        await _authService.signOut();
        _currentUserProfile = null;

        if (loaded && !isAccountActive) {
          _setError('هذا الحساب غير نشط.');
        }

        return false;
      }

      return true;
    } finally {
      _setLoading(false);
    }
  }
}
