import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المدير'),
        backgroundColor: AppColors.primary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, size: 80),
              const SizedBox(height: 20),

              const Text(
                'مرحبًا بك',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                auth.currentUserProfile?.fullName ?? '',
                style: const TextStyle(fontSize: 20),
              ),

              const SizedBox(height: 30),

              const Text(
                'هذه لوحة المدير المؤقتة.\nسنبدأ ببنائها في المرحلة القادمة.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);

                        final success = await auth.logout();

                        if (!success) {
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                auth.errorMessage ?? 'تعذر تسجيل الخروج.',
                              ),
                            ),
                          );
                          return;
                        }

                        final preferences =
                            await SharedPreferences.getInstance();

                        await preferences.setBool('has_account', false);

                        if (!context.mounted) return;

                        navigator.pushNamedAndRemoveUntil(
                          AppRoutes.login,
                          (route) => false,
                        );
                      },
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
