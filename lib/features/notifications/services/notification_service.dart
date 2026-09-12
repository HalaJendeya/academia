// lib/features/notifications/services/notification_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_notification.dart';
import 'fcm_gateway.dart';

class NotificationException implements Exception {
  final String message;
  const NotificationException(this.message);

  @override
  String toString() => message;
}

/// إشعارات المستخدم: القراءة من مجموعة notifications، ودورة حياة رمز
/// الدفع (FCM).
///
/// ما لم يعد من مسؤوليته: إنشاء إشعارات لمستخدمين آخرين. ذلك يجري الآن في
/// Cloud Functions موثوقة تُشغَّل بأحداث Firestore وتعمل بـ Admin SDK —
/// فالإشعار يصل حتى والتطبيق مغلق، ولا يحتاج العميل أي صلاحية على بيانات
/// زملائه.
class NotificationService {
  NotificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FcmGateway? fcmGateway,
  })  : _injectedDb = firestore,
        _injectedAuth = auth,
        _injectedFcm = fcmGateway;

  final FirebaseFirestore? _injectedDb;
  final FirebaseAuth? _injectedAuth;
  final FcmGateway? _injectedFcm;

  /*
   * حقول كسولة (late final) لا تُبنى إلا عند أول استعمال فعلي.
   *
   * بناؤها في قائمة التهيئة كان يستدعي FirebaseFirestore.instance لكل نسخة
   * من الخدمة، فيتعذّر اختبار دورة حياة الرمز أصلًا: أي اختبار يبني الخدمة
   * — ولو حقن بديل [FcmGateway] كاملًا — كان يسقط بـ «No Firebase App».
   * الآن اختبار يمسّ رمز الدفع وحده لا يلمس Firestore ولا Auth إطلاقًا.
   */
  late final FirebaseFirestore _db = _injectedDb ?? FirebaseFirestore.instance;
  late final FirebaseAuth _auth = _injectedAuth ?? FirebaseAuth.instance;

  /// كل تعامل مع رمز الدفع يمرّ من هنا — انظر [FcmGateway].
  late final FcmGateway _fcm = _injectedFcm ??
      FirebaseFcmGateway(firestore: _injectedDb, auth: _injectedAuth);

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  /// إشعارات المستخدم الحالي، الأحدث أولًا.
  Stream<List<AppNotification>> watchMyNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _notifications
        .where('recipientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => AppNotification.fromFirestore(doc.data(), doc.id))
        .toList())
        .handleError((_) {
      throw const NotificationException('تعذر تحميل الإشعارات، حاول مرة أخرى.');
    });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notifications.doc(notificationId).update({'isRead': true});
    } catch (e) {
      // لا نرمي هنا: فشل تحديد إشعار كمقروء ليس خطأً يستحق مقاطعة تجربة
      // المستخدم أو رسالة خطأ ظاهرة — أسوأ نتيجة أنه يبقى "غير مقروء".
    }
  }

  /* ═══════════════════════════════════════════════════════════════════
   * حُذف من هنا notifyCourseClassmatesOfNewPost.
   *
   * كان يستعلم enrollments بـ courseId ثم يقرأ مستند كل زميل ليفحص
   * تفضيله — وكلاهما ممنوع على الطالب بقواعد Firestore، فكان يفشل دائمًا
   * ويُبتلع خطؤه في PostService: المنشور ينجح ولا إشعار يُنشأ.
   *
   * التوزيع صار في Cloud Function موثوقة (onSharedSpacePostCreated) تعمل
   * بـ Admin SDK وتتجاوز القواعد، فلا حاجة لمنح الطالب أي صلاحية إضافية.
   * ما بقي هنا للعميل: قراءة إشعاراته هو، وتحديدها مقروءة، ودورة حياة
   * رمز الدفع.
   * ═══════════════════════════════════════════════════════════════════ */

  // ===========================================================================
  //  FCM (Real Push) Phase 1
  // ===========================================================================

  StreamSubscription<String>? _tokenRefreshSub;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /*
   * الحساب الذي تخصّه جلسة الرمز الحالية.
   *
   * 🔴 هذا ما يمنع رمزًا من الوصول إلى مستند الحساب الخطأ.
   *
   * onTokenRefresh بثّ طويل العمر، وردّ النداء عليه غير متزامن: قد يصل
   * حدث تجديد متأخر بعد أن خرج صاحب الجلسة ودخل غيره، فيُكتب الرمز على
   * مستند من يصادف أنه مسجَّل الآن. إلغاء الاشتراك وحده لا يكفي — حدث
   * كان في الطريق أصلًا قد يكمل تنفيذه بعد الإلغاء.
   *
   * لذلك كل كتابة تتحقق من أمرين معًا: أن الجلسة لم تُغلق (_sessionUid
   * ليس null)، وأن المستخدم المصادَق الآن هو نفسه صاحب الجلسة. إن اختلّ
   * أحدهما، تُهمَل الكتابة بصمت — الجلسة التي طلبتها لم تعد قائمة.
   */
  String? _sessionUid;

  /// اشتراك واحد لا أكثر — للاختبار والتشخيص.
  @visibleForTesting
  bool get hasTokenRefreshListener => _tokenRefreshSub != null;

  @visibleForTesting
  String? get sessionUid => _sessionUid;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'academia_notifications',
    'إشعارات أكاديميا',
    importance: Importance.max,
  );

  StreamSubscription<RemoteMessage>? _foregroundMessageSub;

  /*
   * تهيئة الدفع — "أفضل جهد"، ولا ترمي أبدًا.
   *
   * 🔴 هذه الدالة تُستدعى من مسار تسجيل الدخول بلا await. لذلك أي استثناء
   * يخرج منها يصير Future غير معالَج: لا مكان يلتقطه، ويُبلَّغ عنه كخطأ
   * غير ملتقَط قد يُسقط الجلسة في وضع التصحيح. فكل خطوة هنا محروسة.
   *
   * والأهم: الخطوات **مستقلة**. كانت كلها متسلسلة داخل شرط واحد، فأي فشل
   * في إعداد الإشعارات المحلية (وهو وارد جدًا على أجهزة MIUI:
   * MissingPluginException) كان يقفز فوق تسجيل الرمز فلا يُكتب fcmToken
   * إطلاقًا — يبدو الدخول ناجحًا والدفع لا يعمل ولا رسالة خطأ. صارت
   * جلسة الرمز مستقلة عن إعداد العرض المحلي: فشل العرض لا يمنع التسجيل.
   */
  Future<void> initializePushNotifications() async {
    if (!await _requestPermission()) {
      // رفض الإذن قرار مشروع للمستخدم، لا عطل: لا رمز يُسجَّل ولا رسالة
      // خطأ تُعرض.
      debugPrint('FCM: notification permission not granted; push stays off.');
      return;
    }

    // إعداد العرض المحلي لرسائل المقدّمة. فشله لا يوقف ما بعده.
    await _setUpLocalNotifications();

    // جلسة الرمز — الجزء الذي يجعل الدفع يصل أصلًا.
    try {
      await startTokenSession();
    } catch (e) {
      debugPrint('FCM: could not start the token session for this account.');
    }
  }

  Future<bool> _requestPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('FCM: permission request failed.');
      return false;
    }
  }

  Future<void> _setUpLocalNotifications() async {
    try {
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await _localNotificationsPlugin.initialize(settings: initializationSettings);

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // إلغاء ثم استبدال: كل تهيئة كانت تضيف مستمعًا جديدًا لرسائل
      // المقدّمة دون إزالة سابقه، فمع كل دخول/خروج/دخول يتضاعف عدد
      // الإشعارات المحلية المعروضة عن الرسالة الواحدة.
      await _foregroundMessageSub?.cancel();
      _foregroundMessageSub =
          FirebaseMessaging.onMessage.listen(_showForegroundMessage);
    } catch (e) {
      debugPrint('FCM: local notification setup failed; push still registers.');
    }
  }

  void _showForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = notification?.android;
    if (notification == null || android == null) return;

    try {
      _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      debugPrint('FCM: could not display a foreground notification.');
    }
  }

  /// يبدأ جلسة رمز للمستخدم المصادَق حاليًا: يسجّل رمز الجهاز على مستنده
  /// ثم يتابع تجديدات الرمز حتى تُغلق الجلسة عند تسجيل الخروج.
  ///
  /// إعادة الاستدعاء آمنة: الاشتراك السابق يُلغى قبل إنشاء غيره، فلا
  /// يتراكم مستمعون مع تكرار دخول/خروج.
  Future<void> startTokenSession() async {
    final uid = _fcm.currentUid;
    if (uid == null) return;

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _sessionUid = uid;

    await _saveTokenForSession(await _readDeviceToken());

    _tokenRefreshSub = _fcm.onTokenRefresh.listen((newToken) {
      // بلا await: المستمع لا ينتظر الكتابة، والكتابة نفسها تتحقق من
      // الجلسة قبل أن تلمس أي مستند.
      _saveTokenForSession(newToken);
    });
  }

  Future<String?> _readDeviceToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('FCM: could not read the device token.');
      return null;
    }
  }

  /// يكتب الرمز على مستند صاحب الجلسة، وعلى مستنده وحده.
  Future<void> _saveTokenForSession(String? token) async {
    if (token == null) return;

    final owner = _sessionUid;
    // الجلسة أُغلقت (تسجيل خروج)، أو تبدّل المستخدم بينما كان هذا الحدث
    // في الطريق — الكتابة لم تعد تخصّ أحدًا.
    if (owner == null || _fcm.currentUid != owner) return;

    try {
      await _fcm.saveToken(uid: owner, token: token);
    } catch (e) {
      debugPrint('FCM: could not store the device token for the current account.');
    }
  }

  /// ينهي جلسة الرمز قبل تسجيل الخروج مباشرة.
  ///
  /// 🔴 يجب أن يُستدعى والمستخدم ما زال مصادَقًا — انظر [runSignOutSequence].
  ///
  /// الخطوات الثلاث مستقلة عمدًا، كلٌّ بـ try خاص به: كان المسح ونزع الرمز
  /// المحلي داخل try واحد، فكان فشل الكتابة على Firestore يقفز فوق
  /// deleteToken فلا يُبطَل رمز الجهاز إطلاقًا. فشل خطوة لا يلغي ما بعدها.
  Future<void> clearTokenForSignOut() async {
    // 1) إيقاف المتابعة أولًا: بعد هذه اللحظة لا يستطيع أي حدث تجديد أن
    //    يعيد كتابة رمز على الحساب الذي نغادره.
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    final owner = _sessionUid ?? _fcm.currentUid;
    _sessionUid = null;

    if (owner == null) return;

    // 2) حذف الحقلين من مستند المستخدم — بينما المصادقة قائمة.
    try {
      await _fcm.clearToken(uid: owner);
    } catch (e) {
      debugPrint('FCM: could not clear the stored token for the signing-out account.');
    }

    // 3) إبطال رمز الجهاز محليًا، حتى لا تصل رسائل معلّقة لحساب غادر.
    try {
      await _fcm.deleteToken();
    } catch (e) {
      debugPrint('FCM: could not delete the local device token.');
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _foregroundMessageSub?.cancel();
    _foregroundMessageSub = null;
    _sessionUid = null;
  }
}
