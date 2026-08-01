import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/features/auth/screens/welcome_screen.dart';
import 'package:academia/features/auth/screens/login_screen.dart';
import 'package:academia/features/auth/screens/register_screen.dart';

void main() {
  Widget buildTestApp() {
    return MaterialApp(
      initialRoute: AppRoutes.welcome,
      routes: {
        AppRoutes.welcome: (context) => const WelcomeScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
      },
    );
  }

  group('WelcomeScreen Widgets & Navigation Tests', () {
    testWidgets('WelcomeScreen renders texts correctly', (
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

      // Check title and subtitle
      expect(find.text('نظّم دراستك بذكاء'), findsOneWidget);
      expect(
        find.text('تابع مساقاتك، مهامك، وجلساتك الدراسية في مكان واحد'),
        findsOneWidget,
      );
      expect(
        find.text('صُمم لمساعدتك على إدارة يومك الدراسي بسهولة'),
        findsOneWidget,
      );

      // Check buttons
      expect(find.widgetWithText(ElevatedButton, 'إنشاء حساب'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'لدي حساب بالفعل'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping Create Account navigates to Register Screen', (
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

      await tester.tap(find.widgetWithText(ElevatedButton, 'إنشاء حساب'));
      await tester.pumpAndSettle();

      // Verify routed to Register Screen
      expect(find.text('الاسم الكامل'), findsOneWidget);
    });

    testWidgets('Tapping Already Have Account navigates to Login Screen', (
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

      await tester.tap(find.widgetWithText(OutlinedButton, 'لدي حساب بالفعل'));
      await tester.pumpAndSettle();

      // Verify routed to Login Screen
      expect(find.text('تسجيل الدخول'), findsWidgets);
    });
  });
}
