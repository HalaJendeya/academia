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

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _notifications = [];
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
    // لا داعي لاستدعاء notifyListeners هنا: الـ Stream نفسه سيُحدَّث تلقائيًا
    // فور نجاح الكتابة بـ Firestore وسيعكس isRead الجديدة.
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}