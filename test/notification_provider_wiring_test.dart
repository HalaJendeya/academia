import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/app/app_providers.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/core/services/auth_service.dart';
import 'package:academia/features/notifications/providers/notification_provider.dart';
import 'package:academia/features/notifications/services/fcm_gateway.dart';
import 'package:academia/features/notifications/services/notification_service.dart';

/*
 * توصيل NotificationProvider بشجرة المزوّدات.
 *
 * العطل الذي يحرس منه هذا الملف لم يكن في منطق الدفع — كان الدفع سليمًا
 * ولم يُستدعَ قط. مزوّدات provider كسولة افتراضيًا، وNotificationProvider
 * لا يقرأه شيء في التطبيق سوى شاشة الإشعارات، فلم يكن يُبنى بعد تسجيل
 * الدخول: لا update، ولا syncWithAuth، ولا جلسة رمز، ولا حتى سطر تشخيص
 * واحد. على الجهاز بدا الدخول ناجحًا وحقل fcmToken غائبًا بلا أي خطأ.
 *
 * 🔴 الاختبار يستعمل [notificationProviderEntry] نفسها التي يبني بها
 * التطبيق شجرته — لا نسخة مماثلة منها.
 *
 * نسخة مماثلة كانت ستمرّ حتى لو حُذفت lazy: false من الإنتاج، وهي بالضبط
 * الحالة التي وقعنا فيها. وبما أن التسجيل معرَّف في مكان واحد، فحذف
 * lazy: false من الإنتاج يُسقط هذا الاختبار فورًا.
 *
 * وأهم شرط هنا: لا شيء في الشجرة يقرأ NotificationProvider — فالقراءة
 * وحدها كانت تبني المزوّد وتخفي العطل تمامًا.
 */

class _FakeUser implements User {
  _FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// ينفّذ واجهة AuthService دون استدعاء مُنشِئها، فلا يُلمس Firebase.
class _FakeAuthService implements AuthService {
  _FakeAuthService();

  User? _user;
  AppUserModel? _profile;

  void signIn(String uid, {String status = 'active'}) {
    _user = _FakeUser(uid);
    _profile = AppUserModel(
      uid: uid,
      fullName: 'طالبة أكاديميا',
      email: 'student@test.com',
      role: UserRole.student,
      status: status,
      emailVerified: true,
      onboardingCompleted: true,
      onboardingStatus: 'completed',
    );
  }

  @override
  User? get currentUser => _user;

  @override
  bool get isLoggedIn => _user != null;

  @override
  Future<AppUserModel?> getCurrentUserProfile() async => _profile;

  @override
  Future<void> signOut() async {
    _user = null;
    _profile = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// بديل بوابة FCM: يمنع أي لمس لـ Firebase ويسجّل ما جرى.
class _RecordingGateway implements FcmGateway {
  String? uid;
  final Map<String, String> storedTokens = {};

  @override
  String? get currentUid => uid;

  @override
  Future<String?> getToken() async => 'device-token-1';

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Future<void> saveToken({required String uid, required String token}) async {
    storedTokens[uid] = token;
  }

  @override
  Future<void> clearToken({required String uid}) async {
    storedTokens.remove(uid);
  }
}

/// يرصد ما يصل إلى الخدمة دون تنفيذ إعداد المنصّة الحقيقي.
class _SpyNotificationService extends NotificationService {
  _SpyNotificationService(this.gateway) : super(fcmGateway: gateway);

  final _RecordingGateway gateway;
  int initCalls = 0;

  @override
  Future<void> initializePushNotifications() async {
    initCalls++;
    await startTokenSession();
  }
}

/// شجرة الاختبار — بلا أي قارئ لـ NotificationProvider.
Widget _tree(AuthProvider auth, NotificationService service) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      // التسجيل الإنتاجي نفسه.
      notificationProviderEntry(service),
    ],
    child: const MaterialApp(
      home: Scaffold(body: Text('لا شيء هنا يقرأ مزوّد الإشعارات')),
    ),
  );
}

void main() {
  testWidgets('المزوّد يُبنى دون أن يقرأه أحد، ويستقبل الهوية بعد الدخول',
      (tester) async {
    final authService = _FakeAuthService();
    final auth = AuthProvider(authService: authService);
    final gateway = _RecordingGateway();
    final service = _SpyNotificationService(gateway);

    await tester.pumpWidget(_tree(auth, service));

    // 1) أول update يصل وuid == null (لا مستخدم بعد) — ويمرّ بلا أثر.
    expect(tester.takeException(), isNull);
    expect(service.initCalls, 0, reason: 'لا تهيئة دفع بلا مستخدم');

    // 2) تسجيل دخول حقيقي عبر AuthProvider: يحمّل الملف ثم يُشعر.
    authService.signIn('student1');
    gateway.uid = 'student1';
    await auth.loadCurrentUserProfile();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    // 3) 🔴 جوهر الاختبار: وصلت الهوية وبدأت جلسة الرمز — دون أن تقرأ
    //    أي وِدجِت المزوّد. مع lazy الافتراضية يبقى العدّاد صفرًا.
    expect(
      service.initCalls,
      1,
      reason: 'المزوّد لم يُبنَ بلا قارئ — أُزيلت lazy: false؟',
    );
    expect(gateway.storedTokens['student1'], 'device-token-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('حساب غير نشط لا يبدأ جلسة رمز', (tester) async {
    // البوابة نفسها الموجودة في التسجيل الإنتاجي:
    // isLoggedIn && isAccountActive.
    final authService = _FakeAuthService();
    final auth = AuthProvider(authService: authService);
    final gateway = _RecordingGateway();
    final service = _SpyNotificationService(gateway);

    await tester.pumpWidget(_tree(auth, service));

    authService.signIn('student1', status: 'disabled');
    gateway.uid = 'student1';
    await auth.loadCurrentUserProfile();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(service.initCalls, 0);
    expect(gateway.storedTokens, isEmpty);
  });

  testWidgets('المزوّد متاح للقراءة بعد البناء المبكر', (tester) async {
    // البناء المبكر لا يكسر الاستعمال العادي من الشاشة.
    final authService = _FakeAuthService();
    final auth = AuthProvider(authService: authService);
    final service = _SpyNotificationService(_RecordingGateway());

    late NotificationProvider read;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          notificationProviderEntry(service),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              read = context.watch<NotificationProvider>();
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(read.notifications, isEmpty);
    expect(read.unreadCount, 0);
    expect(tester.takeException(), isNull);
  });
}
