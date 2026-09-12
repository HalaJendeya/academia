// lib/features/notifications/providers/notification_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/notification_service.dart';

/// حالة إشعارات المستخدم الحالي — Stream حي، بنفس مبدأ PostProvider مع
/// المنشورات: اشتراك يُلغى صراحة عند إغلاق الشاشة.
class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;

  NotificationProvider(this._service);

  StreamSubscription<List<AppNotification>>? _subscription;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void listenToNotifications() {
    _subscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _service.watchMyNotifications().listen(
          (notifications) {
        _notifications = notifications;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object e) {
        _errorMessage = e is NotificationException
            ? e.message
            : 'تعذر تحميل الإشعارات، حاول مرة أخرى.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// يوقف الاستماع دون إشعار المستمعين.
  ///
  /// 🔴 لا notifyListeners هنا — نفس نمط TaskProvider.stopListening وبقية
  /// المزوّدات المرتبطة بالمصادقة في المشروع.
  ///
  /// تُستدعى من مسارين لا يحتمل أيّهما إشعارًا متزامنًا: dispose الشاشة
  /// (الشجرة تُفكَّك، وطلب إعادة بناء الآن خطأ في ذاته)، وsyncWithAuth
  /// التي تعمل داخل ChangeNotifierProxyProvider.update أثناء البناء —
  /// والإشعار هناك يعني markNeedsBuild وسط بناء جارٍ.
  ///
  /// من يحتاج مسحًا مرئيًا يستدعي [clear].
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// يوقف الاستماع ويمسح المعروض ويُشعر — للاستدعاء خارج طور البناء.
  void clear() {
    stopListening();
    _notifications = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
    // لا داعي لاستدعاء notifyListeners هنا: الـ Stream نفسه سيُحدَّث تلقائيًا
    // فور نجاح الكتابة بـ Firestore وسيعكس isRead الجديدة.
  }

  String? _currentUid;

  /*
   * 🔴 هذا المزوّد لا يمسح رمز الدفع عند تسجيل الخروج.
   *
   * كان يفعل، وكان ذلك عطلًا حقيقيًا. المزوّد لا يعلم بالخروج إلا بعد أن
   * تكون FirebaseAuth قد سجّلت الخروج فعلًا (uid صار null)، وعندها تكون
   * request.auth قد أصبحت null كذلك، فترفض قاعدة users كتابة الحذف بـ
   * PERMISSION_DENIED. النتيجة: رمز قديم يبقى على الحساب، ورسالة فشل
   * تُبتلع بصمت مع كل تسجيل خروج.
   *
   * والأسوأ أن ذلك المسار كان يتسابق مع الدخول التالي: مسح غير متزامن
   * بدأ عند خروج «أ» قد ينتهي بعد أن سجّل «ب» دخوله، فيمحو رمز «ب» الذي
   * سُجِّل للتو.
   *
   * تنظيف الرمز صار ملكًا لمسار تسجيل الخروج وحده (AuthService.signOut عبر
   * runSignOutSequence)، حيث المستخدم ما زال مصادَقًا والترتيب مضمون.
   * ما يبقى هنا هو تنظيف الحالة المحلية فقط.
   */
  /*
   * تُستدعى من ChangeNotifierProxyProvider.update، أي **أثناء البناء**.
   * لذلك تبقى متزامنة (void) ولا تنتظر شيئًا ولا تُشعر المستمعين مباشرة:
   * الانتظار هنا يحجب البناء، والإشعار هنا markNeedsBuild وسط بناء جارٍ.
   * كل عمل فعلي يُؤجَّل إلى microtask — نفس نمط TaskProvider.syncWithAuth.
   */
  void syncWithAuth({String? uid}) {
    if (_currentUid == uid) return;
    _currentUid = uid;

    if (uid == null) {
      // خروج: تفكيك محلي فقط. تنظيف رمز الدفع يملكه مسار تسجيل الخروج.
      stopListening();
      _notifications = [];
      _isLoading = false;
      _errorMessage = null;
      scheduleMicrotask(notifyListeners);
      return;
    }

    scheduleMicrotask(startPushSession);
  }

  /// يهيّئ الدفع بأسلوب "أفضل جهد" ولا يرمي أبدًا.
  ///
  /// [NotificationService.initializePushNotifications] محروسة داخليًا خطوةً
  /// خطوة، لكن الالتقاط هنا كذلك يجعل الضمانة محليّة: لا شيء في مسار
  /// الدخول يستطيع أن يصير Future غير معالَج، مهما تغيّرت الخدمة لاحقًا.
  /// وفشل التهيئة لا يمسّ حالة المصادقة ولا يمنع الدخول — أسوأ نتيجة أن
  /// الجلسة تكمل بلا دفع.
  @visibleForTesting
  Future<void> startPushSession() async {
    try {
      await _service.initializePushNotifications();
    } catch (e) {
      debugPrint('FCM: push initialisation failed; the session continues without push.');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}