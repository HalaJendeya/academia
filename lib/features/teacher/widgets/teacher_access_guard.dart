import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

/// حارس واجهة المعلّم، على نمط AdminAccessGuard.
///
/// كل دور يُعاد إلى واجهته هو، لا إلى واجهة الطالب افتراضيًا. الدور غير
/// المعروف يُعاد إلى تسجيل الدخول: لا واجهة له.
///
/// هذا الحارس للراحة ووضوح التوجيه؛ التطبيق الفعلي للصلاحيات في قواعد
/// Firestore.
class TeacherAccessGuard extends StatefulWidget {
  const TeacherAccessGuard({super.key, required this.child});

  final Widget child;

  @override
  State<TeacherAccessGuard> createState() => _TeacherAccessGuardState();
}

class _TeacherAccessGuardState extends State<TeacherAccessGuard> {
  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  @override
  void didUpdateWidget(covariant TeacherAccessGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAccess();
  }

  void _checkAccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();

      if (!authProvider.isLoggedIn) {
        _replaceWith(AppRoutes.login);
        return;
      }

      // حساب معطَّل: يُعامل كغير مصرَّح له، تمامًا كما في نقطة الدخول.
      if (!authProvider.isAccountActive) {
        _replaceWith(AppRoutes.login);
        return;
      }

      if (authProvider.isAdmin) {
        _replaceWith(AppRoutes.adminShell);
        return;
      }

      if (authProvider.isStudent) {
        _replaceWith(AppRoutes.dashboard);
        return;
      }

      // ليس معلّمًا ولا أي دور معروف.
      if (!authProvider.isTeacher) {
        _replaceWith(AppRoutes.login);
      }
    });
  }

  void _replaceWith(String route) {
    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final allowed = authProvider.isLoggedIn &&
        authProvider.isAccountActive &&
        authProvider.isTeacher;

    if (!allowed) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return widget.child;
  }
}
