import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/constants/app_strings.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _authService.currentUser;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  // Clear errors
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Handle Firebase Exceptions
  String _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AppStrings.errorUserNotFound;
      case 'wrong-password':
      case 'invalid-credential': // Modern Firebase Auth code for invalid logins
        return AppStrings.loginErrorInvalid;
      case 'email-already-in-use':
        return AppStrings.errorEmailAlreadyInUse;
      case 'weak-password':
        return AppStrings.errorWeakPassword;
      case 'invalid-email':
        return AppStrings.errorInvalidEmail;
      case 'network-request-failed':
        return AppStrings.errorNetwork;
      default:
        return AppStrings.errorUnknown;
    }
  }

  // Login Method
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.signInWithEmailAndPassword(email, password);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseAuthException(e));
    } catch (e) {
      _setError(AppStrings.errorUnknown);
    }

    _setLoading(false);
    return false;
  }

  // Register Method
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // 1. Create Firebase User
      final credential = await _authService.createUserWithEmailAndPassword(
        email,
        password,
      );
      final user = credential.user;

      if (user != null) {
        // 2. Save info in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullName,
          'studentId': studentId,
          'email': email,
          'emailVerified': false,
          'onboardingCompleted': false,
          'onboardingStatus': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 3. Send Verification Email
        await _authService.sendEmailVerification();
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseAuthException(e));
    } catch (e) {
      _setError(AppStrings.errorUnknown);
    }

    _setLoading(false);
    return false;
  }

  // Logout Method
  Future<void> logout() async {
    await _authService.signOut();
    notifyListeners();
  }

  // Send Email Verification
  Future<void> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
    } catch (e) {
      // Propagation if needed
    }
  }

  // Send Password Reset Email Method
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseAuthException(e));
    } catch (e) {
      _setError(AppStrings.errorUnknown);
    }

    _setLoading(false);
    return false;
  }

  // Check Email Verified status
  Future<bool> checkEmailVerified() async {
    final isVerified = await _authService.checkEmailVerified();
    if (isVerified && currentUser != null) {
      // Update the verification status in Firestore
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update({'emailVerified': true})
          .catchError((_) {
            // Ignore firestore write error in local check
          });
    }
    return isVerified;
  }
}
