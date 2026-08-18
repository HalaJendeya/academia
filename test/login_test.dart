import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/features/auth/screens/login_screen.dart';
import 'package:academia/features/auth/screens/register_screen.dart';
import 'package:academia/features/auth/screens/forgot_password_screen.dart';

import 'package:provider/provider.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/onboarding/providers/onboarding_provider.dart';
import 'package:academia/features/auth/models/app_user_model.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  FakeAuthProvider({
    this.isLoggedInValue = false,
    this.isAdminValue = true,
    this.isTeacherValue = false,
    this.isStudentValue = false,
  });

  bool isLoggedInValue;
  bool isAdminValue;
  bool isTeacherValue;
  bool isStudentValue;
  String? errorValue;

  @override
  bool get isLoggedIn => isLoggedInValue;

  @override
  bool get isAdmin => isAdminValue;

  @override
  bool get isStudent => isStudentValue;

  @override
  bool get isTeacher => isTeacherValue;

  @override
  bool get isAccountActive => true;

  @override
  bool get onboardingCompleted => true;

  @override
  String? get errorMessage => errorValue;

  @override
  AppUserModel? get currentUserProfile => const AppUserModel(
        uid: 'admin_123',
        fullName: 'Test Admin',
        email: 'admin@test.com',
        role: UserRole.admin,
        status: 'active',
        emailVerified: true,
        onboardingCompleted: true,
        onboardingStatus: 'completed',
      );

  @override
  bool get isLoading => false;

  @override
  Future<bool> login(String email, String password) async {
    if (email == 'student_123' && password == 'password123') {
      isLoggedInValue = true;
      return true;
    }
    errorValue = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    return false;
  }

  @override
  Future<bool> logout() async {
    isLoggedInValue = false;
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
  Widget buildTestApp({AuthProvider? auth}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth ?? FakeAuthProvider()),
        ChangeNotifierProvider<OnboardingProvider>(create: (_) => FakeOnboardingProvider()),
      ],
      child: MaterialApp(
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.register: (context) => const RegisterScreen(),
          AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
          AppRoutes.adminShell: (context) => const Scaffold(
                body: Text('شاشة الرئيسية (Dashboard)'),
              ),
        },
      ),
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
      expect(find.text('الرقم الجامعي'), findsOneWidget);
      expect(find.text('كلمة المرور'), findsOneWidget);
      expect(find.text('أدخل بريدك الجامعي'), findsOneWidget);
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
      expect(find.text('كلمة المرور مطلوبة'), findsOneWidget);
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
