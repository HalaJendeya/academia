// lib/features/notifications/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../courses/screens/student_course_detail_screen.dart';
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
  /*
   * مرجع محفوظ للمزوّد.
   *
   * 🔴 لا يجوز البحث عن مزوّد من الشجرة داخل dispose: الوِدجِت حينها
   * مفصولة، فيرمي Flutter «Looking up a deactivated widget's ancestor is
   * unsafe» — وهو العطل نفسه الذي أُصلح في شاشة تفاصيل المنشور.
   *
   * المرجع يُلتقط في didChangeDependencies حيث الشجرة ما زالت قائمة.
   */
  NotificationProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationProvider>().listenToNotifications();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<NotificationProvider>();
  }

  @override
  void dispose() {
    _provider?.stopListening();
    super.dispose();
  }

  void _handleNavigation(int index) {
    handleMainNavigation(
      context,
      index,
      currentIndex: AcademiaBottomNavigation.homeIndex,
    );
  }

  /// عند الضغط: تحديد الإشعار كمقروء، ثم الانتقال إلى سياقه.
  ///
  /// الوجهة هي شاشة المساق لكلا النوعين، وهي مسار قائم بحجّة قائمة
  /// ([StudentCourseDetailArgs])، وتبويباتها تضمّ ساحة المشاركة والواجبات
  /// معًا.
  ///
  /// 🔴 لا نمرّ بـ assignmentDetails رغم وجوده: ذلك المسار يشترط
  /// CourseAssignmentModel كاملًا في حجّته، والإشعار لا يحمل سوى
  /// المعرّفات. فتحه بحجّة ناقصة يعرض «الواجب غير متاح» — رابط مكسور لا
  /// ملاحة. وكذلك المنشور: لا PostModel هنا.
  ///
  /// إشعار بلا courseId (نوع لاحق مثلًا) يُعلَّم مقروءًا وتبقى الشاشة
  /// مكانها — أصدق من ملاحة إلى لا شيء.
  Future<void> _openNotification(AppNotification notification) async {
    await context.read<NotificationProvider>().markAsRead(notification.id);
    if (!mounted) return;

    final courseId = notification.courseId;
    if (courseId == null || courseId.trim().isEmpty) return;

    final hasDestination =
        notification.type == AppNotification.typeNewSharedSpacePost ||
            notification.type == AppNotification.typeNewAssignment;
    if (!hasDestination) return;

    Navigator.pushNamed(
      context,
      AppRoutes.courseDetail,
      arguments: StudentCourseDetailArgs(courseId: courseId),
    );
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
        description: 'ستظهر هنا إشعارات المنشورات والواجبات الجديدة في مساقاتك.',
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
