import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/features/auth/screens/register_screen.dart';
import 'package:academia/features/auth/screens/login_screen.dart';
import 'package:academia/features/auth/screens/student_verification_screen.dart';
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
  Future<bool> register({
    required String fullName,
    required String studentId,
    required String email,
    required String password,
  }) async {
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
        initialRoute: AppRoutes.register,
        routes: {
          AppRoutes.register: (context) => const RegisterScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.studentVerification: (context) =>
              const StudentVerificationScreen(),
        },
      ),
    );
  }

  group('RegisterScreen Tests', () {
    testWidgets('RegisterScreen renders all input fields and labels', (
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

      expect(find.text('الاسم الكامل'), findsOneWidget);
      expect(find.text('الرقم الجامعي'), findsOneWidget);
      expect(find.text('البريد الجامعي'), findsOneWidget);
      expect(find.text('كلمة المرور'), findsOneWidget);
      expect(find.text('تأكيد كلمة المرور'), findsOneWidget);

      expect(find.widgetWithText(ElevatedButton, 'إنشاء حساب'), findsOneWidget);
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

      // Tap register button without typing anything
      await tester.tap(find.widgetWithText(ElevatedButton, 'إنشاء حساب'));
      await tester.pumpAndSettle();

      // Expect password short validation error to show up
      expect(find.text('كلمة المرور مطلوبة'), findsOneWidget);
    });

    testWidgets('Tapping footer navigate to Login Screen', (
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

      await tester.tap(find.byKey(const Key('register_to_login_btn')));
      await tester.pumpAndSettle();

      expect(find.text('تسجيل الدخول'), findsWidgets);
    });

    testWidgets(
      'Successful registration input submission routes to Verification Screen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Fill in fields
        await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');
        await tester.enterText(find.byType(TextFormField).at(1), '20241234');
        await tester.enterText(
          find.byType(TextFormField).at(2),
          'john@university.edu',
        );
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');
        await tester.enterText(find.byType(TextFormField).at(4), 'password123');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'إنشاء حساب'));
        await tester.pumpAndSettle();

        // Verify routed to Student Verification Screen
        expect(find.text('التحقق من الطالب'), findsOneWidget);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('has_account'), isTrue);
      },
    );
  });
}
