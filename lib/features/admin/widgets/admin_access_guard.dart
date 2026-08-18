import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class AdminAccessGuard extends StatefulWidget {
  final Widget child;

  const AdminAccessGuard({super.key, required this.child});

  @override
  State<AdminAccessGuard> createState() => _AdminAccessGuardState();
}

class _AdminAccessGuardState extends State<AdminAccessGuard> {
  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  @override
  void didUpdateWidget(covariant AdminAccessGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAccess();
  }

  void _checkAccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      if (!authProvider.isLoggedIn) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      } else if (!authProvider.isAdmin) {
        /*
         * كل دور يعود إلى واجهته.
         *
         * كان غير المشرف يُعاد دائمًا إلى لوحة الطالب، فيهبط المعلّم في
         * تطبيق الطالب. الدور غير المعروف يعود إلى تسجيل الدخول لا إلى
         * واجهة الطالب.
         */
        final String destination;
        if (authProvider.isTeacher) {
          destination = AppRoutes.teacherShell;
        } else if (authProvider.isStudent) {
          destination = AppRoutes.dashboard;
        } else {
          destination = AppRoutes.login;
        }

        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(destination, (route) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isLoggedIn || !authProvider.isAdmin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return widget.child;
  }
}
