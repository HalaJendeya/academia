import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/features/auth/screens/splash_screen.dart';
import 'package:academia/features/auth/screens/welcome_screen.dart';
import 'package:academia/features/auth/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/onboarding/providers/onboarding_provider.dart';
import 'package:academia/features/auth/models/app_user_model.dart';

// Mocks
class FakeUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final bool emailVerified;

  FakeUser({
    required this.uid,
    this.email,
    this.displayName,
    this.emailVerified = true,
  });

  @override
  Future<void> reload() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFirebaseAuth implements FirebaseAuth {
  User? mockUser;

  @override
  User? get currentUser => mockUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  final MockFirebaseAuth mockAuth;
  FakeAuthProvider(this.mockAuth);

  @override
  bool get isLoggedIn => mockAuth.currentUser != null;
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
  AppUserModel? get currentUserProfile => mockAuth.currentUser != null
      ? AppUserModel(
          uid: mockAuth.currentUser!.uid,
          fullName: 'Test Student',
          email: mockAuth.currentUser!.email ?? 'student@test.com',
          role: UserRole.student,
          status: 'active',
          emailVerified: true,
          onboardingCompleted: true,
          onboardingStatus: 'completed',
        )
      : null;

  @override
  Future<bool> initializeCurrentUser() async {
    return isLoggedIn;
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
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockAuth = MockFirebaseAuth();
  });

  Widget buildTestApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider(mockAuth)),
        ChangeNotifierProvider<OnboardingProvider>(create: (_) => FakeOnboardingProvider()),
      ],
      child: MaterialApp(
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => SplashScreen(auth: mockAuth),
          AppRoutes.welcome: (context) => const WelcomeScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.dashboard: (context) => const Scaffold(
                body: Text('شاشة الرئيسية (Dashboard)'),
              ),
        },
      ),
    );
  }

  group('SplashScreen Routing Tests', () {
    testWidgets('If no account, routes to WelcomeScreen after 2 seconds', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({'has_account': false});

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Verify still on splash screen initially
      expect(find.text('رفيقك الذكي لتنظيم الدراسة'), findsOneWidget);
      expect(find.text('نظّم دراستك بذكاء'), findsNothing);

      // Advance timer by 2 seconds
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verify routed to Welcome Screen
      expect(find.text('نظّم دراستك بذكاء'), findsOneWidget);
    });

    testWidgets(
      'If has account but not logged in, routes to LoginScreen after 2 seconds',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        SharedPreferences.setMockInitialValues({'has_account': true});
        mockAuth.mockUser = null;

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Advance timer by 2 seconds
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Verify routed to Login Screen
        expect(find.text('تسجيل الدخول'), findsWidgets);
      },
    );

    testWidgets(
      'If has account and logged in, routes to DashboardScreen after 2 seconds',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        SharedPreferences.setMockInitialValues({'has_account': true});
        mockAuth.mockUser = FakeUser(uid: 'user_123');

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Advance timer by 2 seconds
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Verify routed to Dashboard Screen
        expect(find.text('شاشة الرئيسية (Dashboard)'), findsOneWidget);
      },
    );
  });
}
