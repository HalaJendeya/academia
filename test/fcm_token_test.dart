import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:academia/core/services/sign_out_sequence.dart';
import 'package:academia/features/notifications/providers/notification_provider.dart';
import 'package:academia/features/notifications/services/fcm_gateway.dart';
import 'package:academia/features/notifications/services/notification_service.dart';

/*
 * دورة حياة رمز الدفع (FCM) — Phase 1.
 *
 * العطل الذي تحرس منه هذه الاختبارات لم يكن منطقًا خاطئًا داخل دالة، بل
 * **ترتيبًا** خاطئًا بين عمليات غير متزامنة:
 *
 *   AuthService.signOut()  →  FirebaseAuth.signOut()
 *   ثم لاحقًا: NotificationProvider يرصد uid == null  →  clearToken(oldUid)
 *
 * أي أن مسح الرمز كان يجري بعد انتهاء المصادقة، فترفضه قاعدة users
 * (PERMISSION_DENIED) ويبقى رمز قديم على الحساب. وبما أن المسح والحذف
 * المحلي كانا داخل try واحد، كان فشل الأول يقفز فوق الثاني فلا يُبطَل رمز
 * الجهاز إطلاقًا.
 *
 * البديل عن Firebase هنا [FcmGateway] — الواجهة الضيقة نفسها التي يستعملها
 * الإنتاج. البديل يسجّل ترتيب النداءات وحالة المصادقة لحظة كل كتابة، فيصير
 * الترتيب قابلًا للإثبات بدل الاستنتاج من قراءة الكود.
 */

class FakeFcmGateway implements FcmGateway {
  FakeFcmGateway({this.uid});

  /// من هو المصادَق الآن؛ null بعد تسجيل الخروج.
  String? uid;

  /// مستندات المستخدمين: uid -> الرمز المخزَّن (أو غياب المفتاح).
  final Map<String, String> storedTokens = {};

  /// رمز الجهاز الحالي، كما تراه FCM.
  String? deviceToken = 'device-token-1';

  /// سجل مرتَّب لكل ما جرى — عليه تُبنى تأكيدات الترتيب.
  final List<String> log = [];

  final _refresh = StreamController<String>.broadcast();
  int refreshListeners = 0;

  bool failSave = false;
  bool failClear = false;
  bool failDelete = false;

  /// يسمح للاختبار بإمساك الحذف مفتوحًا لمحاكاة تداخل خروج/دخول.
  Completer<void>? clearGate;

  @override
  String? get currentUid => uid;

  @override
  Future<String?> getToken() async => deviceToken;

  @override
  Future<void> deleteToken() async {
    log.add('deleteLocalToken');
    if (failDelete) throw Exception('messaging unavailable');
    deviceToken = null;
  }

  @override
  Stream<String> get onTokenRefresh {
    // بثّ يحصي مستمعيه: هكذا يصير "اشتراك واحد فقط" قابلًا للقياس.
    refreshListeners++;
    final controller = StreamController<String>();
    final sub = _refresh.stream.listen(controller.add);
    controller.onCancel = () {
      refreshListeners--;
      sub.cancel();
    };
    return controller.stream;
  }

  void emitRefresh(String token) => _refresh.add(token);

  @override
  Future<void> saveToken({required String uid, required String token}) async {
    // حالة المصادقة لحظة الكتابة — جوهر اختبار الترتيب.
    log.add('save($uid,$token,auth=$currentUid)');
    if (failSave) throw Exception('permission denied');
    storedTokens[uid] = token;
  }

  @override
  Future<void> clearToken({required String uid}) async {
    log.add('clearFirestore($uid,auth=$currentUid)');
    if (clearGate != null) await clearGate!.future;
    if (failClear) throw Exception('permission denied');
    storedTokens.remove(uid);
  }

  Future<void> dispose() => _refresh.close();
}

NotificationService _service(FakeFcmGateway gateway) =>
    NotificationService(fcmGateway: gateway);

/// يرصد ما يناديه [NotificationProvider] دون تنفيذ إعداد المنصّة الحقيقي.
class SpyNotificationService extends NotificationService {
  SpyNotificationService() : super(fcmGateway: FakeFcmGateway(uid: 'A'));

  int initCalls = 0;
  int clearCalls = 0;

  /// يحاكي انفجار تهيئة المنصّة: رفض إذن، أو MissingPluginException من
  /// إضافة الإشعارات المحلية على أجهزة MIUI.
  bool failInit = false;

  @override
  Future<void> initializePushNotifications() async {
    initCalls++;
    if (failInit) throw Exception('MissingPluginException');
  }

  @override
  Future<void> clearTokenForSignOut() async => clearCalls++;
}

void main() {
  group('ترتيب تسجيل الخروج', () {
    test('مسح الرمز يسبق تسجيل الخروج', () async {
      final order = <String>[];

      await runSignOutSequence(
        clearPushToken: () async => order.add('clearPushToken'),
        signOut: () async => order.add('signOut'),
      );

      expect(order, ['clearPushToken', 'signOut']);
    });

    test('الخروج يتم رغم فشل تنظيف الرمز', () async {
      final order = <String>[];

      await runSignOutSequence(
        clearPushToken: () async {
          order.add('clearPushToken');
          throw Exception('permission denied');
        },
        signOut: () async => order.add('signOut'),
      );

      // لا استثناء يصل إلى المستدعي، والخروج جرى فعلًا: المستخدم لا يعلق
      // داخل حساب أراد مغادرته بسبب عطل في الإشعارات.
      expect(order, ['clearPushToken', 'signOut']);
    });

    test('فشل الخروج نفسه يصل إلى المستدعي', () async {
      // خطأ الخروج لا يُبتلع — الواجهة تحتاجه لتعرض رسالة، ولا تبقى
      // تدور بلا نهاية.
      await expectLater(
        runSignOutSequence(
          clearPushToken: () async {},
          signOut: () async => throw Exception('network'),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('حذف الحقول يجري والمستخدم ما زال مصادَقًا', () async {
      final gateway = FakeFcmGateway(uid: 'A');
      addTearDown(gateway.dispose);
      final service = _service(gateway);
      await service.startTokenSession();

      await runSignOutSequence(
        clearPushToken: () => service.clearTokenForSignOut(),
        signOut: () async => gateway.uid = null,
      );

      // auth=A لحظة المسح — لا auth=null كما كان يحدث سابقًا.
      expect(gateway.log, contains('clearFirestore(A,auth=A)'));
      expect(gateway.storedTokens.containsKey('A'), isFalse);
    });

    test('فشل حذف الحقول لا يمنع إبطال رمز الجهاز محليًا', () async {
      // الخللان كانا داخل try واحد، فكان فشل الأول يلغي الثاني.
      final gateway = FakeFcmGateway(uid: 'A')..failClear = true;
      addTearDown(gateway.dispose);
      final service = _service(gateway);
      await service.startTokenSession();

      await service.clearTokenForSignOut();

      expect(gateway.log, contains('deleteLocalToken'));
    });

    test('فشل إبطال الرمز محليًا لا يرمي للمستدعي', () async {
      final gateway = FakeFcmGateway(uid: 'A')..failDelete = true;
      addTearDown(gateway.dispose);
      final service = _service(gateway);
      await service.startTokenSession();

      await expectLater(service.clearTokenForSignOut(), completes);
    });
  });

  group('لا كتابة بعد انتهاء المصادقة', () {
    test('المزوّد لا يمسح الرمز عند رصد uid == null', () async {
      // 🔴 هذا هو المسار الذي كان يفشل دائمًا بـ PERMISSION_DENIED.
      //
      // initializePushNotifications تتعامل مع أذونات النظام والإشعارات
      // المحلية، وهي إعداد منصّة لا يعمل خارج جهاز؛ لذلك يراقَب هنا
      // *ما الذي يناديه المزوّد* لا تنفيذه الفعلي.
      final service = SpyNotificationService();
      final provider = NotificationProvider(service);
      addTearDown(provider.dispose);

      provider.syncWithAuth(uid: 'A');
      // التهيئة مؤجَّلة إلى microtask حتى لا تحجب البناء.
      await Future<void>.delayed(Duration.zero);
      expect(service.initCalls, 1);

      provider.syncWithAuth(uid: null);
      await Future<void>.delayed(Duration.zero);

      // المزوّد لم يعد يملك تنظيف الرمز — مسار الخروج وحده يملكه.
      expect(service.clearCalls, 0);
      // وتكرار نفس الحالة لا يعيد التهيئة.
      provider.syncWithAuth(uid: null);
      await Future<void>.delayed(Duration.zero);
      expect(service.initCalls, 1);
    });

    test('فشل تهيئة الدفع لا يصير Future غير معالَج', () async {
      /*
       * 🔴 هذا هو العطل: syncWithAuth تُطلق التهيئة بلا await، فإن رمت
       * صار الخطأ Future غير معالَج — لا مكان يلتقطه، ويظهر كخطأ غير
       * ملتقَط في وضع التصحيح.
       *
       * الالتقاط يتم داخل الاختبار عبر runZonedGuarded: أي خطأ يفلت من
       * المنطقة يُسجَّل هنا، فيصير "لا شيء أفلت" تأكيدًا لا ادّعاءً.
       */
      final escaped = <Object>[];

      await runZonedGuarded(() async {
        final service = SpyNotificationService()..failInit = true;
        final provider = NotificationProvider(service);
        addTearDown(provider.dispose);

        provider.syncWithAuth(uid: 'A');

        // مهلة تكفي لتشغيل الـ microtask المؤجَّل وانفجار التهيئة داخله.
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(service.initCalls, 1);
      }, (error, stack) {
        escaped.add(error);
      });

      expect(escaped, isEmpty, reason: 'لا خطأ غير معالَج يفلت من مسار الدخول');
    });

    test('فشل التهيئة لا يفسد حالة الجلسة ولا يمنع الخروج لاحقًا', () async {
      final service = SpyNotificationService()..failInit = true;
      final provider = NotificationProvider(service);
      addTearDown(provider.dispose);

      provider.syncWithAuth(uid: 'A');
      await provider.startPushSession(); // لا يرمي
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // الحالة سليمة: الخروج بعدها يُرصد ويُفكَّك محليًا كالمعتاد.
      provider.syncWithAuth(uid: null);
      await Future<void>.delayed(Duration.zero);

      expect(provider.notifications, isEmpty);
      expect(service.clearCalls, 0, reason: 'التنظيف يبقى ملك مسار الخروج');
    });

    test('startPushSession تبتلع الخطأ ولا ترمي للمستدعي', () async {
      final service = SpyNotificationService()..failInit = true;
      final provider = NotificationProvider(service);
      addTearDown(provider.dispose);

      await expectLater(provider.startPushSession(), completes);
    });

    test('syncWithAuth لا تُشعر المستمعين بشكل متزامن', () async {
      /*
       * تُستدعى من ChangeNotifierProxyProvider.update أثناء البناء؛ إشعار
       * متزامن هناك يعني markNeedsBuild وسط بناء جارٍ.
       */
      final service = SpyNotificationService();
      final provider = NotificationProvider(service);
      addTearDown(provider.dispose);

      var notified = 0;
      provider.addListener(() => notified++);

      provider.syncWithAuth(uid: 'A');
      expect(notified, 0, reason: 'الدخول لا يُشعر أثناء البناء');

      provider.syncWithAuth(uid: null);
      expect(notified, 0, reason: 'الخروج لا يُشعر أثناء البناء');

      // الإشعار يصل، لكن بعد انتهاء الإطار.
      await Future<void>.delayed(Duration.zero);
      expect(notified, 1);
    });

    test('stopListening لا تُشعر — تُستدعى من dispose الشاشة', () async {
      final service = SpyNotificationService();
      final provider = NotificationProvider(service);
      addTearDown(provider.dispose);

      var notified = 0;
      provider.addListener(() => notified++);

      provider.stopListening();

      expect(notified, 0);
    });

    test('رمز جهاز غائب (getToken == null) لا يكتب شيئًا ولا يرمي', () async {
      final gateway = FakeFcmGateway(uid: 'A')..deviceToken = null;
      addTearDown(gateway.dispose);
      final service = _service(gateway);

      await expectLater(service.startTokenSession(), completes);

      expect(gateway.log.where((e) => e.startsWith('save')), isEmpty);
      expect(gateway.storedTokens, isEmpty);
      // ومع ذلك الجلسة قائمة: تجديد لاحق سيُكتب.
      expect(service.hasTokenRefreshListener, isTrue);
      gateway.emitRefresh('late-but-valid');
      await Future<void>.delayed(Duration.zero);
      expect(gateway.storedTokens['A'], 'late-but-valid');
    });

    test('جلسة الرمز لا تبدأ بلا مستخدم مصادَق', () async {
      final gateway = FakeFcmGateway(uid: null);
      addTearDown(gateway.dispose);
      final service = _service(gateway);

      await service.startTokenSession();

      expect(gateway.log, isEmpty);
      expect(service.hasTokenRefreshListener, isFalse);
    });
  });

  group('تبديل الحسابات', () {
    test('أ ← خروج ← ب: الرمز ينتهي لحساب ب وحده', () async {
      final gateway = FakeFcmGateway(uid: 'A');
      addTearDown(gateway.dispose);
      final service = _service(gateway);

      await service.startTokenSession();
      expect(gateway.storedTokens['A'], 'device-token-1');

      await service.clearTokenForSignOut();
      gateway.uid = null;
      expect(gateway.storedTokens.containsKey('A'), isFalse);

      // جهاز يُصدر رمزًا جديدًا بعد الإبطال، ثم يدخل ب.
      gateway.deviceToken = 'device-token-2';
      gateway.uid = 'B';
      await service.startTokenSession();

      expect(gateway.storedTokens['B'], 'device-token-2');
      expect(gateway.storedTokens.containsKey('A'), isFalse);
    });

    test('مسح متأخّر من خروج «أ» لا يمحو رمز «ب» بعد دخوله', () async {
      // السباق الذي كان ممكنًا: المزوّد يبدأ مسحًا غير متزامن عند خروج أ،
      // فينتهي بعد أن سجّل ب دخوله. المسح صار جزءًا من تسلسل الخروج
      // ويكتمل قبله، لكن نثبّت هنا أن حتى مسحًا معلّقًا لا يطال ب.
      final gateway = FakeFcmGateway(uid: 'A')..clearGate = Completer<void>();
      addTearDown(gateway.dispose);
      final service = _service(gateway);
      await service.startTokenSession();

      final pendingClear = service.clearTokenForSignOut();

      // ب يدخل بينما المسح ما زال معلّقًا.
      gateway.uid = 'B';
      gateway.deviceToken = 'device-token-2';
      await service.startTokenSession();
      expect(gateway.storedTokens['B'], 'device-token-2');

      gateway.clearGate!.complete();
      await pendingClear;

      // المسح استهدف مستند أ باسمه، فلم يمسّ ب.
      expect(gateway.storedTokens['B'], 'device-token-2');
    });
  });

  group('اشتراك تجديد الرمز', () {
    test('دخول/خروج متكرر لا يراكم مستمعين', () async {
      final gateway = FakeFcmGateway(uid: 'A');
      addTearDown(gateway.dispose);
      final service = _service(gateway);

      for (var i = 0; i < 3; i++) {
        gateway.uid = 'A';
        await service.startTokenSession();
        expect(gateway.refreshListeners, 1, reason: 'دورة ${i + 1}');

        await service.clearTokenForSignOut();
        gateway.uid = null;
        expect(gateway.refreshListeners, 0, reason: 'دورة ${i + 1}');
      }
    });

    test('بدء جلسة مرتين بلا خروج يستبدل الاشتراك ولا يضاعفه', () async {
      final gateway = FakeFcmGateway(uid: 'A');
      addTearDown(gateway.dispose);
      final service = _service(gateway);

      await service.startTokenSession();
      await service.startTokenSession();

      expect(gateway.refreshListeners, 1);
    });

    test('تجديد أثناء الجلسة يُكتب لصاحبها', () async {
      final gateway = FakeFcmGateway(uid: 'A');
      addTearDown(gateway.dispose);
      final service = _service(gateway);
      await service.startTokenSession();

      gateway.emitRefresh('refreshed-token');
      await Future<void>.delayed(Duration.zero);

      expect(gateway.storedTokens['A'], 'refreshed-token');
    });

    test('تجديد متأخر بعد الخروج لا يكتب شيئًا', () async {
      final gateway = FakeFcmGateway(uid: 'A');
      addTearDown(gateway.dispose);
      final service = _service(gateway);
      await service.startTokenSession();

      await service.clearTokenForSignOut();
      gateway.uid = null;
      gateway.log.clear();

      gateway.emitRefresh('late-token');
      await Future<void>.delayed(Duration.zero);

      expect(gateway.log.where((e) => e.startsWith('save')), isEmpty);
      expect(gateway.storedTokens, isEmpty);
    });

    test('تجديد متأخر من جلسة «أ» لا يكتب على مستند «ب»', () async {
      // الخطر الحقيقي: حدث كان في الطريق لحظة الإلغاء فأكمل تنفيذه بعده.
      // الحارس ليس الإلغاء وحده، بل التحقق من صاحب الجلسة قبل كل كتابة.
      final gateway = FakeFcmGateway(uid: 'A');
      addTearDown(gateway.dispose);
      final service = _service(gateway);
      await service.startTokenSession();

      // «ب» يدخل، فيصير هو صاحب الجلسة.
      gateway.uid = 'B';
      gateway.deviceToken = 'device-token-2';
      await service.startTokenSession();
      expect(service.sessionUid, 'B');

      // تجديد يصل الآن يُنسب لـ ب — لا لـ أ.
      gateway.emitRefresh('refreshed-token');
      await Future<void>.delayed(Duration.zero);

      expect(gateway.storedTokens['B'], 'refreshed-token');
      // مستند أ بقي على رمزه القديم دون أن يمسّه التجديد. (لم يُمسح هنا
      // لأن هذا السيناريو تبديل بلا تسجيل خروج — المسح يختبَر أعلاه.)
      expect(gateway.storedTokens['A'], 'device-token-1');
    });

    test('تجديد يصل بعد تبدّل المصادقة وقبل بدء الجلسة الجديدة لا يُكتب',
        () async {
      /*
       * أضيق نافذة سباق، وهي التي يحرسها فحص المالك تحديدًا.
       *
       * FirebaseAuth تبدّل المستخدم بالفعل، لكن startTokenSession للجلسة
       * الجديدة لم تعمل بعد (المزوّد يُستدعى في إطار لاحق). لو وصل تجديد
       * في هذه اللحظة، فـ _sessionUid ما زال يشير إلى «أ» بينما المصادَق
       * هو «ب» — فتُكتب بيانات على مستند حساب لم يعد هو المستخدم.
       *
       * إلغاء الاشتراك وحده لا يغطّي هذه الحالة: الاشتراك ما زال قائمًا
       * ومشروعًا، والمتبدّل هو الهوية تحته.
       */
      final gateway = FakeFcmGateway(uid: 'A');
      addTearDown(gateway.dispose);
      final service = _service(gateway);
      await service.startTokenSession();
      gateway.log.clear();

      // المصادقة تبدّلت، ولم تبدأ جلسة «ب» بعد.
      gateway.uid = 'B';
      gateway.emitRefresh('in-flight-token');
      await Future<void>.delayed(Duration.zero);

      expect(gateway.log.where((e) => e.startsWith('save')), isEmpty);
      expect(gateway.storedTokens['A'], 'device-token-1');
      expect(gateway.storedTokens.containsKey('B'), isFalse);
    });

    test('فشل كتابة الرمز لا يرمي ولا يوقف الجلسة', () async {
      final gateway = FakeFcmGateway(uid: 'A')..failSave = true;
      addTearDown(gateway.dispose);
      final service = _service(gateway);

      await expectLater(service.startTokenSession(), completes);
      expect(service.hasTokenRefreshListener, isTrue);
    });
  });
}
