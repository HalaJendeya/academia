import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/features/auth/screens/login_screen.dart';
import 'package:academia/features/auth/screens/register_screen.dart';
import 'package:academia/features/auth/screens/forgot_password_screen.dart';
import 'package:academia/features/dashboard/screens/dashboard_screen.dart';

void main() {
  Widget buildTestApp() {
    return MaterialApp(
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.dashboard: (context) => const DashboardScreen(),
      },
    );
  }

  group('LoginScreen Tests', () {
    testWidgets('LoginScreen renders fields and labels correctly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(
        find.text('تسجيل الدخول'),
        findsWidgets,
      ); // matches title and button
      expect(find.text('الرقم الجامعي أو البريد الجامعي'), findsOneWidget);
      expect(find.text('كلمة المرور'), findsOneWidget);
      expect(find.text('أدخل رقمك الجامعي أو بريد الطالب'), findsOneWidget);
      expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
    });

    testWidgets('Validation error triggers on empty inputs or short password', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap login without typing anything
      await tester.tap(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'));
      await tester.pumpAndSettle();

      // Expect password incorrect validation message to appear
      expect(find.text('كلمة المرور غير صحيحة'), findsOneWidget);
    });

    testWidgets('Tapping footer navigate to Register Screen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login_to_register_btn')));
      await tester.pumpAndSettle();

      expect(find.text('الاسم الكامل'), findsOneWidget);
    });

    testWidgets('Successful input submission routes to Dashboard', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'student_123');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'));
      await tester.pumpAndSettle();

      // Verify navigated to Dashboard Screen
      expect(find.text('شاشة الرئيسية (Dashboard)'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_account'), isTrue);
    });
  });
}
