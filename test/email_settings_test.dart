import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_test/flutter_test.dart';

import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/core/services/auth_service.dart';
import 'package:academia/features/profile/models/student_profile.dart';
import 'package:academia/features/profile/providers/email_settings_provider.dart';
import 'package:academia/features/profile/services/profile_service.dart';

/*
 * إدارة البريد الأساسي والاحتياطي.
 *
 * ما تحرسه هذه الاختبارات ليس شكل الواجهة بل حدّين أمنيّين:
 *
 *   1. لا يصير عنوان "موثَّقًا" بادّعاء من العميل. الحفظ يكتب false دائمًا،
 *      وقاعدة Firestore ترفض true إلا في شكل تبديل تشهد به Firebase.
 *   2. لا يُكتب البريد الأساسي في Firestore قبل أن تغيّره Firebase فعلًا.
 *      فشل المصادقة يجب ألا يترك المستند يدّعي بريدًا ليس بريد الدخول.
 *
 * البدائل تنفّذ واجهتَي AuthService وProfileService بـ implements — أي دون
 * استدعاء مُنشِئهما — فلا تُلمس Firebase إطلاقًا.
 */

class _FakeAuthService implements AuthService {
  _FakeAuthService({this.email = 'primary@test.com'});

  String? email;

  /// خطأ يُرمى من verifyBeforeUpdatePrimaryEmail.
  FirebaseAuthException? verifyError;

  /// خطأ يُرمى من reauthenticateWithPassword.
  FirebaseAuthException? reauthError;

  final List<String> log = [];
  int reauthCalls = 0;
  int verifyCalls = 0;

  /// يحاكي نقر الرابط: Firebase غيّرت البريد فعلًا.
  void completeEmailChange(String newEmail) => email = newEmail;

  @override
  String? get currentPrimaryEmail => email;

  @override
  Future<User?> refreshCurrentUser() async {
    log.add('refresh');
    return null; // الاختبار يقرأ البريد من currentPrimaryEmail
  }

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    reauthCalls++;
    log.add('reauth');
    final e = reauthError;
    if (e != null) throw e;
  }

  @override
  Future<void> verifyBeforeUpdatePrimaryEmail(String newEmail) async {
    verifyCalls++;
    log.add('verifyBeforeUpdate:$newEmail');
    final e = verifyError;
    if (e != null) throw e;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfileService implements ProfileService {
  _FakeProfileService(this._profile);

  StudentProfile _profile;
  final List<String> log = [];

  /// حقول لا علاقة لها بالبريد — تُفحص أنها لم تُمَس.
  String fcmToken = 'device-token-1';

  @override
  Future<StudentProfile> getCurrentProfile() async => _profile;

  @override
  Future<void> saveSecondaryEmail(String email) async {
    log.add('saveSecondary:$email:verified=false');
    _profile = StudentProfile(
      uid: _profile.uid,
      fullName: _profile.fullName,
      studentId: _profile.studentId,
      email: _profile.email,
      major: _profile.major,
      academicLevel: _profile.academicLevel,
      photoUrl: _profile.photoUrl,
      secondaryEmail: email,
      // 🔴 لا يوجد مسار يجعلها true من هنا.
      secondaryEmailVerified: false,
      pendingPrimaryEmail: _profile.pendingPrimaryEmail,
    );
  }

  @override
  Future<void> removeSecondaryEmail() async {
    log.add('removeSecondary');
    _profile = StudentProfile(
      uid: _profile.uid,
      fullName: _profile.fullName,
      studentId: _profile.studentId,
      email: _profile.email,
      major: _profile.major,
      academicLevel: _profile.academicLevel,
      photoUrl: _profile.photoUrl,
    );
  }

  @override
  Future<void> markPrimaryEmailChangePending(String pendingEmail) async {
    log.add('pending:$pendingEmail');
    _profile = StudentProfile(
      uid: _profile.uid,
      fullName: _profile.fullName,
      studentId: _profile.studentId,
      email: _profile.email,
      major: _profile.major,
      academicLevel: _profile.academicLevel,
      photoUrl: _profile.photoUrl,
      secondaryEmail: _profile.secondaryEmail,
      secondaryEmailVerified: _profile.secondaryEmailVerified,
      pendingPrimaryEmail: pendingEmail,
    );
  }

  @override
  Future<void> syncPrimaryEmailAfterChange({
    required String newPrimary,
    required String previousPrimary,
  }) async {
    log.add('sync:$newPrimary<-$previousPrimary');
    _profile = StudentProfile(
      uid: _profile.uid,
      fullName: _profile.fullName,
      studentId: _profile.studentId,
      email: newPrimary,
      major: _profile.major,
      academicLevel: _profile.academicLevel,
      photoUrl: _profile.photoUrl,
      secondaryEmail: previousPrimary,
      secondaryEmailVerified: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

StudentProfile _profile({
  String email = 'primary@test.com',
  String? secondary,
  bool verified = false,
  String? pending,
}) =>
    StudentProfile(
      uid: 'student1',
      fullName: 'طالبة أكاديميا',
      studentId: '1234567',
      email: email,
      major: 'نظم المعلومات',
      academicLevel: 4,
      secondaryEmail: secondary,
      secondaryEmailVerified: verified,
      pendingPrimaryEmail: pending,
    );

FirebaseAuthException _err(String code) => FirebaseAuthException(code: code);

void main() {
  group('العرض والحالة', () {
    test('البريد الأساسي يُقرأ من Firebase لا من Firestore', () async {
      // مستند Firestore متأخّر عمدًا: المرجع هو المصادقة.
      final auth = _FakeAuthService(email: 'auth@test.com');
      final profiles = _FakeProfileService(_profile(email: 'auth@test.com'));
      final provider = EmailSettingsProvider(auth, profiles);

      await provider.load();

      expect(provider.primaryEmail, 'auth@test.com');
      expect(auth.log, contains('refresh'));
    });

    test('حالة عدم وجود بريد احتياطي', () async {
      final provider = EmailSettingsProvider(
        _FakeAuthService(),
        _FakeProfileService(_profile()),
      );
      await provider.load();

      expect(provider.secondaryEmail, isNull);
      expect(provider.isSecondaryVerified, isFalse);
      expect(provider.hasPendingChange, isFalse);
    });
  });

  group('التحقق من صيغة البريد الاحتياطي', () {
    late EmailSettingsProvider provider;
    late _FakeProfileService profiles;

    setUp(() async {
      profiles = _FakeProfileService(_profile());
      provider = EmailSettingsProvider(_FakeAuthService(), profiles);
      await provider.load();
    });

    test('عنوان فارغ مرفوض', () async {
      expect(await provider.saveSecondaryEmail('   '), isFalse);
      expect(provider.errorMessage, AppStrings.secondaryEmailRequired);
      expect(profiles.log, isEmpty);
    });

    test('صيغة غير صحيحة مرفوضة', () async {
      expect(await provider.saveSecondaryEmail('not-an-email'), isFalse);
      expect(provider.errorMessage, AppStrings.secondaryEmailInvalid);
      expect(profiles.log, isEmpty, reason: 'لا كتابة قبل اجتياز التحقق');
    });

    test('العنوان نفسه كالبريد الأساسي مرفوض', () async {
      expect(await provider.saveSecondaryEmail('primary@test.com'), isFalse);
      expect(provider.errorMessage, AppStrings.secondaryEmailSameAsPrimary);
      expect(profiles.log, isEmpty);
    });

    test('المقارنة بالبريد الأساسي لا تفرّق بين الحالات', () async {
      expect(await provider.saveSecondaryEmail('PRIMARY@Test.com'), isFalse);
      expect(provider.errorMessage, AppStrings.secondaryEmailSameAsPrimary);
    });

    test('عنوان صالح يُحفظ غير موثَّق', () async {
      expect(await provider.saveSecondaryEmail(' recovery@test.com '), isTrue);

      // 🔴 verified=false دائمًا: الإدخال ليس إثبات ملكية.
      expect(profiles.log.single, 'saveSecondary:recovery@test.com:verified=false');
      expect(provider.secondaryEmail, 'recovery@test.com');
      expect(provider.isSecondaryVerified, isFalse);
    });

    test('إزالة البريد الاحتياطي', () async {
      await provider.saveSecondaryEmail('recovery@test.com');
      expect(await provider.removeSecondaryEmail(), isTrue);

      expect(provider.secondaryEmail, isNull);
      expect(provider.isSecondaryVerified, isFalse);
    });
  });

  group('طلب تعيين الاحتياطي أساسيًا', () {
    test('يُرسل رابط التأكيد ولا يلمس بريد Firestore الأساسي', () async {
      /*
       * 🔴 جوهر الأمان: بعد نجاح الطلب، البريد الأساسي في Firestore كما هو.
       * Firebase لم تغيّر شيئًا بعد — الرابط لم يُفتح.
       */
      final auth = _FakeAuthService();
      final profiles = _FakeProfileService(
        _profile(secondary: 'recovery@test.com'),
      );
      final provider = EmailSettingsProvider(auth, profiles);
      await provider.load();

      final result = await provider.promoteSecondaryToPrimary();

      expect(result, PrimaryEmailChangeResult.verificationSent);
      expect(auth.log, contains('verifyBeforeUpdate:recovery@test.com'));
      expect(provider.profile!.email, 'primary@test.com');
      expect(profiles.log.any((e) => e.startsWith('sync:')), isFalse);
      expect(provider.hasPendingChange, isTrue);
      expect(provider.successMessage, AppStrings.primaryEmailChangeSent);
    });

    test('لا يُعلن نجاح التغيير قبل أن تؤكّده Firebase', () async {
      final provider = EmailSettingsProvider(
        _FakeAuthService(),
        _FakeProfileService(_profile(secondary: 'recovery@test.com')),
      );
      await provider.load();
      await provider.promoteSecondaryToPrimary();

      expect(
        provider.successMessage,
        isNot(AppStrings.primaryEmailChangeCompleted),
      );
    });

    test('بلا بريد احتياطي لا يجري أي طلب', () async {
      final auth = _FakeAuthService();
      final provider = EmailSettingsProvider(
        auth,
        _FakeProfileService(_profile()),
      );
      await provider.load();

      final result = await provider.promoteSecondaryToPrimary();

      expect(result, PrimaryEmailChangeResult.failed);
      expect(auth.verifyCalls, 0);
    });
  });

  group('إعادة تأكيد الهوية', () {
    test('requires-recent-login تُترجم إلى طلب كلمة المرور لا إلى فشل',
        () async {
      final auth = _FakeAuthService()
        ..verifyError = _err('requires-recent-login');
      final profiles = _FakeProfileService(
        _profile(secondary: 'recovery@test.com'),
      );
      final provider = EmailSettingsProvider(auth, profiles);
      await provider.load();

      final result = await provider.promoteSecondaryToPrimary();

      expect(result, PrimaryEmailChangeResult.reauthenticationRequired);
      expect(profiles.log.any((e) => e.startsWith('sync:')), isFalse);
    });

    test('كلمة المرور تُستعمل ثم تنجح المحاولة الثانية', () async {
      final auth = _FakeAuthService()
        ..verifyError = _err('requires-recent-login');
      final provider = EmailSettingsProvider(
        auth,
        _FakeProfileService(_profile(secondary: 'recovery@test.com')),
      );
      await provider.load();

      await provider.promoteSecondaryToPrimary();
      auth.verifyError = null; // الجلسة صارت حديثة بعد إعادة التأكيد

      final result =
          await provider.promoteSecondaryToPrimary(password: 'secret');

      expect(result, PrimaryEmailChangeResult.verificationSent);
      expect(auth.reauthCalls, 1);
      // الترتيب: إعادة التأكيد قبل طلب تغيير البريد.
      expect(auth.log.indexOf('reauth'),
          lessThan(auth.log.lastIndexOf('verifyBeforeUpdate:recovery@test.com')));
    });

    test('كلمة مرور خاطئة تعطي رسالة عربية ولا تكتب شيئًا', () async {
      final auth = _FakeAuthService()..reauthError = _err('wrong-password');
      final profiles = _FakeProfileService(
        _profile(secondary: 'recovery@test.com'),
      );
      final provider = EmailSettingsProvider(auth, profiles);
      await provider.load();

      final result =
          await provider.promoteSecondaryToPrimary(password: 'wrong');

      expect(result, PrimaryEmailChangeResult.failed);
      expect(provider.errorMessage, AppStrings.loginErrorInvalid);
      expect(auth.verifyCalls, 0, reason: 'لا طلب تغيير بلا هوية مؤكَّدة');
      expect(profiles.log.any((e) => e.startsWith('sync:')), isFalse);
    });
  });

  group('أخطاء Firebase تُترجم ولا تفسد Firestore', () {
    Future<EmailSettingsProvider> failing(String code,
        {required _FakeProfileService profiles}) async {
      final auth = _FakeAuthService()..verifyError = _err(code);
      final provider = EmailSettingsProvider(auth, profiles);
      await provider.load();
      return provider;
    }

    test('email-already-in-use', () async {
      final profiles =
          _FakeProfileService(_profile(secondary: 'taken@test.com'));
      final provider =
          await failing('email-already-in-use', profiles: profiles);

      final result = await provider.promoteSecondaryToPrimary();

      expect(result, PrimaryEmailChangeResult.failed);
      expect(provider.errorMessage, AppStrings.emailChangeErrorInUse);
      expect(provider.profile!.email, 'primary@test.com');
    });

    test('invalid-email', () async {
      final profiles =
          _FakeProfileService(_profile(secondary: 'recovery@test.com'));
      final provider = await failing('invalid-email', profiles: profiles);

      await provider.promoteSecondaryToPrimary();
      expect(provider.errorMessage, AppStrings.errorInvalidEmail);
    });

    test('network-request-failed', () async {
      final profiles =
          _FakeProfileService(_profile(secondary: 'recovery@test.com'));
      final provider =
          await failing('network-request-failed', profiles: profiles);

      await provider.promoteSecondaryToPrimary();
      expect(provider.errorMessage, AppStrings.errorNetwork);
      expect(profiles.log.any((e) => e.startsWith('sync:')), isFalse);
    });

    test('too-many-requests', () async {
      final profiles =
          _FakeProfileService(_profile(secondary: 'recovery@test.com'));
      final provider = await failing('too-many-requests', profiles: profiles);

      await provider.promoteSecondaryToPrimary();
      expect(provider.errorMessage, contains('محاولات كثيرة'));
    });

    test('خطأ غير متوقع لا يكشف رمز Firebase للطالبة', () async {
      final profiles =
          _FakeProfileService(_profile(secondary: 'recovery@test.com'));
      final provider = await failing('internal-error', profiles: profiles);

      await provider.promoteSecondaryToPrimary();

      expect(provider.errorMessage, AppStrings.emailChangeErrorGeneric);
      expect(provider.errorMessage, isNot(contains('internal-error')));
    });

    test('🔴 فشل المصادقة لا يترك Firestore يدّعي بريدًا أساسيًا جديدًا',
        () async {
      final profiles =
          _FakeProfileService(_profile(secondary: 'recovery@test.com'));
      final provider =
          await failing('email-already-in-use', profiles: profiles);

      await provider.promoteSecondaryToPrimary();

      expect(provider.profile!.email, 'primary@test.com');
      expect(provider.profile!.secondaryEmail, 'recovery@test.com');
      expect(provider.profile!.secondaryEmailVerified, isFalse);
    });
  });

  group('المزامنة بعد أن تغيّر Firebase البريد فعلًا', () {
    test('التبديل يقع عند التحميل التالي، والقديم ينزل احتياطيًا موثَّقًا',
        () async {
      final auth = _FakeAuthService();
      final profiles = _FakeProfileService(
        _profile(secondary: 'recovery@test.com', pending: 'recovery@test.com'),
      );
      final provider = EmailSettingsProvider(auth, profiles);
      await provider.load();

      // الطالبة فتحت الرابط من بريدها الاحتياطي خارج التطبيق.
      auth.completeEmailChange('recovery@test.com');
      await provider.load();

      expect(profiles.log, contains('sync:recovery@test.com<-primary@test.com'));
      expect(provider.primaryEmail, 'recovery@test.com');
      expect(provider.profile!.email, 'recovery@test.com');
      expect(provider.profile!.secondaryEmail, 'primary@test.com');
      // موثَّق بحق: كان بريد دخول لهذا الحساب.
      expect(provider.isSecondaryVerified, isTrue);
      expect(provider.hasPendingChange, isFalse);
      expect(provider.successMessage, AppStrings.primaryEmailChangeCompleted);
    });

    test('بلا تغيير في Firebase لا تجري أي مزامنة', () async {
      final profiles = _FakeProfileService(_profile());
      final provider = EmailSettingsProvider(_FakeAuthService(), profiles);

      await provider.load();
      await provider.load();

      expect(profiles.log.any((e) => e.startsWith('sync:')), isFalse);
    });

    test('المزامنة لا تغيّر UID ولا الحقول غير المتعلقة بالبريد', () async {
      final auth = _FakeAuthService();
      final profiles =
          _FakeProfileService(_profile(secondary: 'recovery@test.com'));
      final provider = EmailSettingsProvider(auth, profiles);
      await provider.load();

      final before = provider.profile!;
      auth.completeEmailChange('recovery@test.com');
      await provider.load();
      final after = provider.profile!;

      expect(after.uid, before.uid, reason: 'تغيير البريد لا ينشئ حسابًا جديدًا');
      expect(after.studentId, before.studentId);
      expect(after.fullName, before.fullName);
      expect(after.major, before.major);
      expect(after.academicLevel, before.academicLevel);
      // رمز الدفع خارج نطاق كتابة البريد تمامًا.
      expect(profiles.fcmToken, 'device-token-1');
    });
  });
}
