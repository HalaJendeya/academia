import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/features/auth/screens/student_verification_screen.dart';
import 'package:academia/features/auth/screens/login_screen.dart';

void main() {
  Widget buildTestApp() {
    return MaterialApp(
      initialRoute: AppRoutes.studentVerification,
      routes: {
        AppRoutes.studentVerification: (context) =>
            const StudentVerificationScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
      },
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
      expect(find.text('رابط تفعيل الحساب'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'افتح البريد الإلكتروني'),
        findsOneWidget,
      );
      expect(find.text('إعادة إرسال الرابط'), findsOneWidget);
    });

    testWidgets('Verification email link flow works end-to-end', (
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

      // Tap Open Email
      await tester.tap(find.byKey(const Key('open_email_btn')));
      await tester.pumpAndSettle();

      // Check inbox title and email item exist
      expect(find.text('صندوق الوارد (Inbox)'), findsOneWidget);
      expect(find.text('تأكيد البريد الإلكتروني لحسابك'), findsOneWidget);

      // Tap Email list item
      await tester.tap(find.byKey(const Key('inbox_email_item')));
      await tester.pumpAndSettle();

      // Check email details page renders link button
      expect(find.text('العودة إلى صندوق الوارد'), findsOneWidget);
      expect(find.byKey(const Key('verify_link_btn')), findsOneWidget);

      // Tap Verify Account Link
      await tester.tap(find.byKey(const Key('verify_link_btn')));
      await tester.pump(); // starts verifying timer

      // Verify progress indicator shows up
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Fast forward 1.0 second to complete verification
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Verify redirected back to Login Screen directly
      expect(find.text('الرقم الجامعي أو البريد الجامعي'), findsOneWidget);
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
