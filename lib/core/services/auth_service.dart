import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/models/app_user_model.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// المستخدم الحالي من Firebase Authentication.
  User? get currentUser => _auth.currentUser;

  /// هل يوجد مستخدم مسجل دخوله حاليًا؟
  bool get isLoggedIn => currentUser != null;

  /// تغيّرات حالة تسجيل الدخول والخروج.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// تسجيل الدخول بالبريد الإلكتروني وكلمة المرور.
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// إنشاء حساب جديد في Firebase Authentication.
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// قراءة بيانات المستخدم الحالي من مجموعة users في Firestore.
  ///
  /// يعيد null إذا لم يوجد مستخدم مسجل الدخول.
  Future<AppUserModel?> getCurrentUserProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    return getUserProfile(user.uid);
  }

  /// قراءة بيانات مستخدم من Firestore باستخدام Firebase UID.
  ///
  /// المسار المستخدم:
  /// users/{uid}
  Future<AppUserModel> getUserProfile(String uid) async {
    final document = await _firestore.collection('users').doc(uid).get();

    if (!document.exists) {
      throw StateError(
        'لم يتم العثور على بيانات المستخدم داخل قاعدة البيانات.',
      );
    }

    return AppUserModel.fromFirestore(document);
  }

  /// التحقق من وجود مستند للمستخدم داخل Firestore.
  Future<bool> userProfileExists(String uid) async {
    final document = await _firestore.collection('users').doc(uid).get();

    return document.exists;
  }

  /// إنشاء مستند طالب جديد داخل Firestore.
  ///
  /// الدور لا يُؤخذ من شاشة التسجيل؛ بل يُحفظ دائمًا student.
  Future<void> createStudentProfile({
    required String uid,
    required String fullName,
    required String email,
    required String studentId,
  }) async {
    final now = FieldValue.serverTimestamp();

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'fullName': fullName.trim(),
      'email': email.trim(),
      'studentId': studentId.trim(),

      // لا تسمحي للمستخدم باختيار الدور أثناء التسجيل.
      'role': 'student',
      'status': 'active',

      'emailVerified': false,
      'onboardingCompleted': false,
      'onboardingStatus': 'pending',

      'createdAt': now,
      'updatedAt': now,
    });
  }

  /// تحديث حالة التحقق من البريد داخل Firestore.
  Future<void> updateEmailVerificationStatus({
    required bool emailVerified,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw StateError('لا يوجد مستخدم مسجل الدخول.');
    }

    await _firestore.collection('users').doc(user.uid).update({
      'emailVerified': emailVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// إرسال رسالة التحقق من البريد الإلكتروني.
  Future<void> sendEmailVerification() async {
    final user = currentUser;

    if (user == null) {
      throw StateError('لا يوجد مستخدم مسجل الدخول.');
    }

    await user.sendEmailVerification();
  }

  /// إعادة تحميل بيانات Firebase Authentication والتحقق من البريد.
  Future<bool> checkEmailVerified() async {
    final user = currentUser;

    if (user == null) {
      return false;
    }

    await user.reload();

    final updatedUser = currentUser;
    final isVerified = updatedUser?.emailVerified ?? false;

    // نحافظ على تطابق حالة التحقق بين Authentication وFirestore.
    if (updatedUser != null) {
      await updateEmailVerificationStatus(emailVerified: isVerified);
    }

    return isVerified;
  }

  /// إرسال رابط استعادة كلمة المرور.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// تسجيل الخروج.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
