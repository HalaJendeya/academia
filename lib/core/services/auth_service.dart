import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/models/app_user_model.dart';
import '../../features/notifications/services/notification_service.dart';
import 'sign_out_sequence.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       // الحقل خاص والوسيط مسمّى؛ وDart يمنع أن يبدأ اسم وسيط مسمّى بشرطة
       // سفلية، فصيغة this._notificationService التي يقترحها التحليل غير
       // قانونية هنا.
       // ignore: prefer_initializing_formals
       _notificationService = notificationService;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// اختياري عمدًا: لا يُنشأ تلقائيًا هنا حتى لا يلمس أي اختبار يبني
  /// AuthService حزمَ Firebase الحقيقية. يُحقن في app_providers بنفس
  /// النسخة التي يستعملها NotificationProvider — انظر التعليق هناك.
  final NotificationService? _notificationService;

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

    /*
     * reload() يحدّث كائن المستخدم محليًا فقط ولا يصدر رمز هوية جديدًا،
     * بينما تعتمد قواعد Firestore على الادعاء email_verified الموجود داخل
     * رمز الهوية. لذلك نجبر تحديث الرمز قبل كتابة القيمة في Firestore،
     * وإلا فقد ترفض القاعدة الكتابة لأن الرمز ما زال يحمل القيمة القديمة.
     */
    await user.getIdToken(true);

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

  // ---------------------------------------------------------------------
  //  إدارة البريد الأساسي
  // ---------------------------------------------------------------------

  /// البريد الأساسي الفعلي كما تعرفه Firebase Authentication.
  ///
  /// 🔴 هذا هو المرجع، لا حقل email في Firestore.
  ///
  /// حقل Firestore نسخة معروضة تُزامَن بعد نجاح التغيير؛ أما ما يُسجَّل به
  /// الدخول فعلًا فهو هذا.
  String? get currentPrimaryEmail => _auth.currentUser?.email;

  /// إعادة التحقق من الهوية بكلمة المرور الحالية.
  ///
  /// تغيير البريد عملية حسّاسة، وFirebase ترفضها إن مضى وقت على آخر تسجيل
  /// دخول (requires-recent-login). كلمة المرور تُستعمل هنا لحظيًا لبناء
  /// بيانات الاعتماد ولا تُخزَّن ولا تُسجَّل في أي مكان.
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No authenticated user with an email address.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// يطلب من Firebase تغيير البريد الأساسي إلى [newEmail] — **بعد** أن
  /// يثبت صاحب الحساب ملكيته للعنوان الجديد.
  ///
  /// 🔴 هذه العملية غير فورية، وهذا مقصود.
  ///
  /// firebase_auth 6.x حذفت updateEmail نهائيًا؛ الطريق الوحيد المدعوم هو
  /// verifyBeforeUpdateEmail: تُرسل Firebase رابطًا إلى العنوان الجديد، ولا
  /// يتغيّر البريد الأساسي إلا عند فتح ذلك الرابط. أي أن نقر الرابط هو
  /// إثبات الملكية نفسه — ولا يمكن للعميل تزويره ولا تخطّيه.
  ///
  /// لذلك لا يجوز للتطبيق أن يعلن نجاح التغيير بمجرد عودة هذه الدالة.
  Future<void> verifyBeforeUpdatePrimaryEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No authenticated user.',
      );
    }
    await user.verifyBeforeUpdateEmail(newEmail.trim());
  }

  /// يعيد تحميل حساب Firebase ويجدّد رمز الهوية، ثم يعيد المستخدم المحدَّث.
  ///
  /// تجديد الرمز ضروري لا تجميلي: قواعد Firestore تتحقق من البريد الجديد
  /// عبر request.auth.token.email، والرمز القديم ما زال يحمل البريد السابق
  /// حتى يُجدَّد — فبدون هذا السطر تُرفض كتابة المزامنة.
  Future<User?> refreshCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    await user.reload();
    await _auth.currentUser?.getIdToken(true);
    return _auth.currentUser;
  }

  /// تسجيل الخروج.
  ///
  /// 🔴 المالك الوحيد لتنظيف رمز الدفع عند الخروج.
  ///
  /// كان التنظيف يجري في مكانين: هنا بكتابة Firestore مباشرة، وفي
  /// NotificationProvider بعد أن يرصد uid == null. الثاني كان يفشل دائمًا
  /// (المصادقة انتهت) ويتسابق مع الدخول التالي. صار المسار واحدًا: هذه
  /// الدالة تطلب من NotificationService إنهاء جلسة الرمز — حذف الحقلين
  /// وإبطال رمز الجهاز — **قبل** الخروج، ثم تخرج.
  ///
  /// [runSignOutSequence] هي ما يضمن الترتيب وأن فشل التنظيف لا يمنع
  /// الخروج.
  Future<void> signOut() {
    return runSignOutSequence(
      clearPushToken: () async {
        await _notificationService?.clearTokenForSignOut();
      },
      signOut: () => _auth.signOut(),
    );
  }
}
