import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import 'quick_action_card.dart';

/// خانة "مهام اليوم" في التصميم الأصلي.
///
/// ميزة المهام بلا نموذج ولا خدمة ولا مجموعة في قاعدة البيانات، لذلك تبقى
/// البطاقة محافظةً على مكانها في التصميم لكنها تعلن أنها غير مفعَّلة بدل
/// عرض عدد مهام أو موعد تسليم لا وجود له.
class TodayTasksCard extends StatelessWidget {
  const TodayTasksCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonCard(
      icon: Icons.assignment_outlined,
      title: AppStrings.dashboardTasksTitle,
      description: AppStrings.dashboardTasksComingSoon,
      badgeLabel: AppStrings.dashboardComingSoonBadge,
    );
  }
}
