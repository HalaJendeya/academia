// lib/features/notifications/services/fcm_gateway.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// كل ما تحتاجه دورة حياة رمز الدفع (FCM) من Firebase، خلف واجهة واحدة
/// ضيقة.
///
/// سبب وجودها: العطل الحقيقي في هذه الميزة لم يكن في منطق داخل دالة، بل في
/// **ترتيب** عمليات غير متزامنة — مسح الرمز بعد تسجيل الخروج بدل ما قبله،
/// وسباق محتمل بين خروج حساب ودخول آخر. ترتيب كهذا لا يُثبَت بقراءة الكود،
/// يُثبَت باختبار يشغّل التسلسل فعليًا. وFirebaseMessaging وFirebaseAuth
/// وFirestore لا يمكن استبدالها في الاختبار مباشرة، فجُمِع ما تحتاجه هذه
/// الميزة منها هنا في واجهة صغيرة لها تنفيذ حقيقي واحد وبديل اختباري.
///
/// النطاق مقصود ضيّق: رمز الدفع وحده. بقية NotificationService تبقى على
/// Firestore مباشرة كما هي.
abstract class FcmGateway {
  /// معرّف المستخدم المصادَق حاليًا، أو null إن لم يكن هناك أحد.
  String? get currentUid;

  /// رمز الجهاز الحالي من FCM.
  Future<String?> getToken();

  /// إبطال رمز الجهاز محليًا (عند تسجيل الخروج).
  Future<void> deleteToken();

  /// بثّ يُصدر رمزًا جديدًا كلما جدّدته خدمة FCM.
  Stream<String> get onTokenRefresh;

  /// كتابة الرمز على مستند المستخدم.
  Future<void> saveToken({required String uid, required String token});

  /// حذف حقلَي الرمز من مستند المستخدم.
  Future<void> clearToken({required String uid});
}

/// التنفيذ الحقيقي فوق Firebase.
class FirebaseFcmGateway implements FcmGateway {
  FirebaseFcmGateway({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseMessaging? messaging,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseMessaging _messaging;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Future<void> deleteToken() => _messaging.deleteToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Future<void> saveToken({required String uid, required String token}) {
    return _db.collection('users').doc(uid).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> clearToken({required String uid}) {
    // حذف الحقلين لا تصفيرهما: قاعدة users تسمح بذلك لأن الاسمين ضمن
    // studentSelfEditable، وحقل غائب أصدق من رمز قديم لم يعد صالحًا.
    return _db.collection('users').doc(uid).update({
      'fcmToken': FieldValue.delete(),
      'fcmTokenUpdatedAt': FieldValue.delete(),
    });
  }
}
