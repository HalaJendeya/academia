// lib/features/notifications/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/notification_preference_keys.dart';
import '../models/app_notification.dart';

class NotificationException implements Exception {
  final String message;
  const NotificationException(this.message);

  @override
  String toString() => message;
}

/// إشعارات داخل التطبيق (In-App) — بلا Cloud Functions وبلا Push حقيقي،
/// بما يتوافق مع خطة Firebase الحالية (Spark). كل الكتابة تصدر من جهاز
/// الطالب الناشر مباشرة (لا وسيط خادم)، وهذا يعني: الإشعار لن يظهر لأي
/// طالب إلا بعد أن يفتح التطبيق ويستمع للمجموعة، لا فور حدوثه فعليًا على
/// جهاز مغلق.
class NotificationService {
  NotificationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  String get _requireUserId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const NotificationException('يجب تسجيل الدخول أولًا.');
    }
    return uid;
  }

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

  /// إشعار كل زملاء الطالب في مساق واحد بمنشور جديد، باستثناء الناشر
  /// نفسه، وبشرط تفعيلهم صراحةً "تنبيهات المساحة المشتركة"
  /// (sharedSpaceNotifications — الافتراضي false، فغياب التفضيل يعني عدم
  /// الإرسال، لا إرسالًا افتراضيًا).
  ///
  /// لا تُستدعى من الشاشة مباشرة — PostService.createPost تستدعيها بعد
  /// نجاح إنشاء المنشور، وتُبتلع أخطاؤها هناك حتى لا يفشل نشر منشور
  /// صحيح بسبب عطل في إرسال إشعار ثانوي.
  Future<void> notifyCourseClassmatesOfNewPost({
    required String courseId,
    required String postId,
    required String authorName,
  }) async {
    final authorId = _requireUserId;

    // من هم المسجَّلون في هذا المساق؟ نفس مجموعة enrollments المستخدَمة
    // بميزة المساقات والملفات — لا مصدر بيانات جديد.
    final enrollmentsSnapshot = await _db
        .collection('enrollments')
        .where('courseId', isEqualTo: courseId)
        .where('status', isEqualTo: 'active')
        .get();

    final classmateIds = enrollmentsSnapshot.docs
        .map((doc) => doc.data()['userId'] as String?)
        .whereType<String>()
        .where((uid) => uid != authorId)
        .toSet();

    if (classmateIds.isEmpty) return;

    // فلترة حسب تفعيل التفضيل فرديًا — قراءة مستند كل زميل ضرورية هنا
    // لأن التفضيل مخزَّن داخل مستند المستخدم نفسه، لا في enrollments.
    final batch = _db.batch();
    var hasAnyWrite = false;

    for (final uid in classmateIds) {
      final userDoc = await _db.collection('users').doc(uid).get();
      final prefs = userDoc.data()?['notificationPreferences'] as Map?;
      final wantsSharedSpaceNotifications =
          prefs?[NotificationPreferenceKeys.sharedSpaceNotifications] == true;

      if (!wantsSharedSpaceNotifications) continue;

      final notification = AppNotification(
        id: '',
        recipientId: uid,
        type: AppNotification.typeNewSharedSpacePost,
        title: 'منشور جديد في المساحة المشتركة',
        body: '$authorName نشر منشورًا جديدًا في مساقك.',
        courseId: courseId,
        postId: postId,
        createdAt: DateTime.now(),
      );

      batch.set(_notifications.doc(), notification.toFirestore());
      hasAnyWrite = true;
    }

    if (hasAnyWrite) {
      await batch.commit();
    }
  }
}