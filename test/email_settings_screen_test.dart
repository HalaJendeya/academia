import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/core/services/auth_service.dart';
import 'package:academia/features/profile/models/student_profile.dart';
import 'package:academia/features/profile/providers/email_settings_provider.dart';
import 'package:academia/features/profile/screens/email_settings_screen.dart';
import 'package:academia/features/profile/services/profile_service.dart';

/*
 * شاشة إدارة البريد — العرض وسلامة التخطيط.
 *
 * اختبارات المزوّد تغطّي الأمان والمنطق؛ هذا الملف يغطّي ما تراه الطالبة،
 * وبالذات أمرين:
 *
 *   1. **الصدق**: لا تُعرض حالة "مؤكَّد" لعنوان غير مؤكَّد، ولا يُقال إن
 *      البريد تغيّر ما دام الرابط لم يُفتح.
 *   2. **عرض 360 بكسل**: جهاز الاختبار (Redmi) من هذه الفئة، وقد تكرّر في
 *      هذا المشروع طفح بكسل في صفوف تجمع نصًا وشارة. كل حالة تُفحص عند
 *      360 بكسل، وبعناوين بريد طويلة لأنها أسوأ حالة واقعية.
 */

void _useNarrowScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _FakeAuthService implements AuthService {
  _FakeAuthService({this.email = 'student@example.com'});

  String? email;

  @override
  String? get currentPrimaryEmail => email;

  @override
  Future<User?> refreshCurrentUser() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfileService implements ProfileService {
  _FakeProfileService(this.profile);

  StudentProfile profile;

  @override
  Future<StudentProfile> getCurrentProfile() async => profile;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

StudentProfile _profile({
  String email = 'student@example.com',
  String? secondary,
  bool verified = false,
  String? pending,
}) =>
    StudentProfile(
      uid: 'student1',
      fullName: 'طالبة أكاديميا',
      studentId: '1234567',
      email: email,
      secondaryEmail: secondary,
      secondaryEmailVerified: verified,
      pendingPrimaryEmail: pending,
    );

Future<EmailSettingsProvider> _pumpScreen(
  WidgetTester tester, {
  required StudentProfile profile,
  String primaryEmail = 'student@example.com',
}) async {
  final provider = EmailSettingsProvider(
    _FakeAuthService(email: primaryEmail),
    _FakeProfileService(profile),
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<EmailSettingsProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: EmailSettingsScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return provider;
}

void main() {
  group('العرض', () {
    testWidgets('يعرض البريد الأساسي وشارة بريد الدخول', (tester) async {
      _useNarrowScreen(tester);
      await _pumpScreen(tester, profile: _profile());

      expect(find.text('student@example.com'), findsOneWidget);
      expect(find.text(AppStrings.primaryEmailBadge), findsOneWidget);
      expect(find.text(AppStrings.primaryEmailLabel), findsOneWidget);
    });

    testWidgets('بلا بريد احتياطي: نص فارغ صريح وزر إضافة', (tester) async {
      _useNarrowScreen(tester);
      await _pumpScreen(tester, profile: _profile());

      expect(find.text(AppStrings.secondaryEmailEmpty), findsOneWidget);
      expect(find.text(AppStrings.secondaryEmailAdd), findsOneWidget);
      // لا زر ترقية بلا عنوان يُرقّى، ولا زر إزالة.
      expect(find.text(AppStrings.secondaryEmailPromote), findsNothing);
      expect(find.text(AppStrings.secondaryEmailRemove), findsNothing);
    });

    testWidgets('🔴 عنوان احتياطي غير مؤكَّد يُعرض كذلك صراحةً',
        (tester) async {
      _useNarrowScreen(tester);
      await _pumpScreen(
        tester,
        profile: _profile(secondary: 'recovery@example.com'),
      );

      expect(find.text('recovery@example.com'), findsOneWidget);
      expect(find.text(AppStrings.secondaryEmailUnverifiedBadge), findsOneWidget);
      // لا تُعرض شارة "مؤكَّد" لعنوان لم تُثبت ملكيته.
      expect(find.text(AppStrings.secondaryEmailVerifiedBadge), findsNothing);
      expect(find.text(AppStrings.secondaryEmailChange), findsOneWidget);
      expect(find.text(AppStrings.secondaryEmailPromote), findsOneWidget);
    });

    testWidgets('عنوان مؤكَّد يُعرض بشارة مؤكَّد', (tester) async {
      _useNarrowScreen(tester);
      await _pumpScreen(
        tester,
        profile: _profile(secondary: 'old@example.com', verified: true),
      );

      expect(find.text(AppStrings.secondaryEmailVerifiedBadge), findsOneWidget);
      expect(find.text(AppStrings.secondaryEmailUnverifiedBadge), findsNothing);
    });

    testWidgets('الشرح الصادق عن آلية التأكيد معروض دائمًا', (tester) async {
      _useNarrowScreen(tester);
      await _pumpScreen(tester, profile: _profile());

      expect(find.text(AppStrings.secondaryEmailVerificationNote), findsOneWidget);
    });

    testWidgets('حدّ الاسترجاع قبل تسجيل الدخول مذكور للطالبة',
        (tester) async {
      _useNarrowScreen(tester);
      await _pumpScreen(tester, profile: _profile());

      expect(
        find.text(AppStrings.secondaryEmailRecoveryLimitation),
        findsOneWidget,
      );
    });

    testWidgets('لا يوجد زر تحقق مستقل — لأنه لا يمكن تنفيذه بأمان',
        (tester) async {
      /*
       * حارس ضد "إكمال" الواجهة لاحقًا بزر يضع verified = true بضغطة.
       * التأكيد الوحيد الممكن من جهة العميل يمرّ عبر تعيين العنوان أساسيًا.
       */
      _useNarrowScreen(tester);
      await _pumpScreen(
        tester,
        profile: _profile(secondary: 'recovery@example.com'),
      );

      expect(find.text('تحقق من البريد'), findsNothing);
    });
  });

  group('حالة الانتظار', () {
    testWidgets('طلب معلَّق يظهر كبطاقة انتظار لا كنجاح', (tester) async {
      _useNarrowScreen(tester);
      await _pumpScreen(
        tester,
        profile: _profile(
          secondary: 'recovery@example.com',
          pending: 'recovery@example.com',
        ),
      );

      expect(find.text(AppStrings.primaryEmailChangePendingTitle), findsOneWidget);
      expect(find.text(AppStrings.primaryEmailChangePendingBody), findsOneWidget);
      expect(find.text(AppStrings.primaryEmailRefresh), findsOneWidget);
      // 🔴 لا تُعلن الشاشة اكتمال التغيير قبل أن يحدث.
      expect(find.text(AppStrings.primaryEmailChangeCompleted), findsNothing);
    });

    testWidgets('أثناء الانتظار يختفي زر الترقية فلا يُرسل طلب ثانٍ',
        (tester) async {
      _useNarrowScreen(tester);
      await _pumpScreen(
        tester,
        profile: _profile(
          secondary: 'recovery@example.com',
          pending: 'recovery@example.com',
        ),
      );

      expect(find.text(AppStrings.secondaryEmailPromote), findsNothing);
    });

    testWidgets('البريد الأساسي المعروض يبقى القديم أثناء الانتظار',
        (tester) async {
      _useNarrowScreen(tester);
      await _pumpScreen(
        tester,
        profile: _profile(
          email: 'student@example.com',
          secondary: 'recovery@example.com',
          pending: 'recovery@example.com',
        ),
        primaryEmail: 'student@example.com',
      );

      // العنوان الجديد يظهر كـ"بانتظار"، لا كبريد دخول.
      expect(find.text('student@example.com'), findsOneWidget);
      expect(find.text(AppStrings.primaryEmailBadge), findsOneWidget);
    });
  });

  group('سلامة التخطيط عند 360 بكسل', () {
    // طفح البكسل يظهر كاستثناء أثناء البناء، فـ takeException هو الفحص.
    testWidgets('الحالة الفارغة بلا طفح', (tester) async {
      _useNarrowScreen(tester);
      await _pumpScreen(tester, profile: _profile());
      expect(tester.takeException(), isNull);
    });

    testWidgets('حالة العنوان الاحتياطي بلا طفح', (tester) async {
      _useNarrowScreen(tester);
      await _pumpScreen(
        tester,
        profile: _profile(secondary: 'recovery@example.com'),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('حالة الانتظار بلا طفح', (tester) async {
      _useNarrowScreen(tester);
      await _pumpScreen(
        tester,
        profile: _profile(
          secondary: 'recovery@example.com',
          verified: true,
          pending: 'recovery@example.com',
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('عناوين طويلة جدًا مع الشارات بلا طفح', (tester) async {
      // أسوأ حالة واقعية: عنوان جامعي طويل بجانب شارة، داخل صف واحد.
      _useNarrowScreen(tester);
      const longPrimary =
          'student.fullname.longaddress.2026@students.university.edu.ps';
      const longSecondary =
          'personal.recovery.address.longer.still@mail.example.com';

      await _pumpScreen(
        tester,
        profile: _profile(
          email: longPrimary,
          secondary: longSecondary,
          pending: longSecondary,
        ),
        primaryEmail: longPrimary,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('حالات التحميل والخطأ', () {
    testWidgets('فشل تحميل الملف يعرض حالة خطأ لا شاشة فارغة',
        (tester) async {
      _useNarrowScreen(tester);

      final provider = EmailSettingsProvider(
        _FakeAuthService(),
        _FailingProfileService(),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<EmailSettingsProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: EmailSettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(provider.errorMessage, isNotNull);
      expect(tester.takeException(), isNull);
    });
  });
}

class _FailingProfileService implements ProfileService {
  @override
  Future<StudentProfile> getCurrentProfile() async =>
      throw const ProfileException(AppStrings.profileLoadError);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
