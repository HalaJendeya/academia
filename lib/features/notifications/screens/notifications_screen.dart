// lib/features/notifications/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';

/// قائمة إشعارات الطالب — In-App بالكامل (لا Push، انظر توثيق
/// NotificationService). تُفتح عادة من جرس الإشعارات بأعلى الشاشات.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().listenToNotifications();
    });
  }

  @override
  void dispose() {
    context.read<NotificationProvider>().stopListening();
    super.dispose();
  }

  void _handleNavigation(int index) {
    handleMainNavigation(
      context,
      index,
      currentIndex: AcademiaBottomNavigation.homeIndex,
    );
  }

  /// عند الضغط: تحديد الإشعار كمقروء، ثم الانتقال لسياقه إن كان معروفًا
  /// (منشور ساحة مشاركة حاليًا؛ أنواع مستقبلية قد لا تحمل وجهة، فتبقى
  /// الشاشة كما هي وقتها بدل ملاحة فارغة).
  Future<void> _openNotification(AppNotification notification) async {
    await context.read<NotificationProvider>().markAsRead(notification.id);
    if (!mounted) return;

    if (notification.type == AppNotification.typeNewSharedSpacePost &&
        notification.postId != null) {
      // لا نملك هنا نسخة PostModel كاملة ولا عنوان المساق — الإشعار يحمل
      // فقط معرّفات السياق (courseId, postId)، لا بيانات المنشور نفسه.
      // فتح المنشور مباشرة يتطلب استعلامًا لا تملكه هذه الشاشة؛ يبقى
      // نطاق هذه النسخة الانتقال المباشر مؤجَّلًا لتفادي استعلام مكرر أو
      // تمرير بيانات غير موثوقة عبر التنقّل.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('افتحي المساق من صفحة مساقاتك لمتابعة المنشور'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return AuthenticatedPageScaffold(
      currentIndex: AcademiaBottomNavigation.homeIndex,
      onNavigationTap: _handleNavigation,
      appBar: const AcademiaSubAppBar(title: 'الإشعارات'),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(NotificationProvider provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const AppLoadingState();
    }

    if (provider.errorMessage != null && provider.notifications.isEmpty) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: () => context.read<NotificationProvider>().listenToNotifications(),
      );
    }

    if (provider.notifications.isEmpty) {
      return const AppEmptyState(
        title: 'لا توجد إشعارات بعد',
        description: 'ستظهر هنا إشعارات المنشورات الجديدة في مساقاتك.',
        icon: Icons.notifications_none_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      itemCount: provider.notifications.length,
      itemBuilder: (context, index) {
        final notification = provider.notifications[index];
        return NotificationCard(
          notification: notification,
          onTap: () => _openNotification(notification),
        );
      },
    );
  }
}
