import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/features/auth/screens/student_verification_screen.dart';
import 'package:academia/features/auth/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/onboarding/providers/onboarding_provider.dart';
import 'package:academia/features/auth/models/app_user_model.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool get isLoggedIn => false;
  @override
  bool get isAdmin => false;
  @override
  bool get isStudent => true;
  @override
  bool get isTeacher => false;
  @override
  bool get isAccountActive => true;
  @override
  bool get onboardingCompleted => true;
  @override
  String? get errorMessage => null;
  @override
  bool get isLoading => false;
  @override
  AppUserModel? get currentUserProfile => null;

  @override
  Future<bool> sendEmailVerification() async {
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeOnboardingProvider extends ChangeNotifier implements OnboardingProvider {
  @override
  void initializeForUser(String userId) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildTestApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
        ChangeNotifierProvider<OnboardingProvider>(create: (_) => FakeOnboardingProvider()),
      ],
      child: MaterialApp(
        initialRoute: AppRoutes.studentVerification,
        routes: {
          AppRoutes.studentVerification: (context) =>
              const StudentVerificationScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
        },
      ),
    );
  }

  group('StudentVerificationScreen Link Flow Tests', () {
    testWidgets('StudentVerificationScreen renders elements correctly', (
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

      expect(find.text('التحقق من الطالب'), findsOneWidget);
      expect(find.text('رابط التحقق الأكاديمي'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'تحقق'),
        findsOneWidget,
      );
      expect(find.text('إعادة إرسال الرابط'), findsOneWidget);
    });

    testWidgets(
      'Resend button respects cooldown timer and lockout after 3 attempts',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        SharedPreferences.setMockInitialValues({
          'verification_resend_count': 0,
        });

        await tester.pumpWidget(buildTestApp());
        await tester.pump();
        await tester.idle();
        await tester.pump();

        // Cooldown timer is active initially (30s)
        expect(
          find.textContaining('إعادة الإرسال بعد 30 ثانية'),
          findsOneWidget,
        );

        // Fast forward 30 seconds
        await tester.pump(const Duration(seconds: 30));

        // Now allowed to resend
        expect(
          find.text('يمكنك إعادة إرسال رابط التأكيد الآن'),
          findsOneWidget,
        );

        // Attempt 1 resend
        await tester.tap(find.widgetWithText(TextButton, 'إعادة إرسال الرابط'));
        await tester.pump();

        // Cooldown should reset to 30s
        expect(
          find.textContaining('إعادة الإرسال بعد 30 ثانية'),
          findsOneWidget,
        );

        // Fast forward 30 seconds again
        await tester.pump(const Duration(seconds: 30));

        // Attempt 2 resend
        await tester.tap(find.widgetWithText(TextButton, 'إعادة إرسال الرابط'));
        await tester.pump();

        // Fast forward 30 seconds again
        await tester.pump(const Duration(seconds: 30));

        // Attempt 3 resend (triggers lockout)
        await tester.tap(find.widgetWithText(TextButton, 'إعادة إرسال الرابط'));
        await tester.pump();

        // Should be locked out (exceeded limit warning)
        expect(
          find.textContaining('تجاوزت الحد. يرجى الانتظار'),
          findsOneWidget,
        );
      },
    );
  });
}
