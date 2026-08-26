import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/features/shared_space/models/comment_model.dart';
import 'package:academia/features/shared_space/models/post_model.dart';
import 'package:academia/features/shared_space/providers/post_provider.dart';
import 'package:academia/features/shared_space/screens/post_details_screen.dart';
import 'package:academia/features/shared_space/services/post_service.dart';

/*
 * اختبارات انحدار لأخطاء ساحة المشاركة التي ظهرت على جهاز حقيقي:
 *
 * 1. الخروج من تفاصيل المنشور كان يرمي «Looking up a deactivated widget's
 *    ancestor is unsafe» لأن dispose كانت تبحث عن المزوّد من الشجرة.
 * 2. التعليق كان يطلب «أعيدي تسجيل الدخول» من مستخدم جلسته سليمة، لأن
 *    الهوية كانت تُؤخذ من ProfileProvider الخاص بالطالب وحده.
 * 3. كل نقرة إعجاب تفتح معاملة Firestore، بلا أي حارس من النقر المتكرر.
 *
 * البديل عن PostService هنا يقلّد سلوكه الحقيقي، لا نتيجته المرجوّة:
 * كل watchComments يعيد Stream مستقلًا (كما تفعل snapshots تمامًا)، حتى
 * يصير إفلات المستمع قابلًا للإثبات لا مجرد ادّعاء.
 */

class FakePostService implements PostService {
  FakePostService({this.uid = 'student1', this.userDoc});

  /// بديل FirebaseAuth.currentUser?.uid — null يعني غير مسجَّل دخول.
  final String? uid;

  /// بديل مستند users/{uid} — null يعني أن المستند نفسه غير موجود.
  final Map<String, dynamic>? userDoc;

  final postsController = StreamController<List<PostModel>>.broadcast();
  final commentControllers = <StreamController<List<CommentModel>>>[];
  final addCommentCalls = <Map<String, String>>[];
  final toggleLikeCalls = <String>[];

  /// يُمسك معاملة الإعجاب مفتوحة حتى يقرّر الاختبار حسمها.
  Completer<void>? likeGate;

  int get liveCommentListeners =>
      commentControllers.where((c) => c.hasListener && !c.isClosed).length;

  /// يعكس PostService._requireAuthorName: المصادقة أولًا، ثم users/{uid}.
  String _requireAuthorName() {
    if (uid == null) {
      throw const PostException('يجب تسجيل الدخول أولًا.');
    }
    if (userDoc == null) {
      throw const PostException(
        'لم يتم العثور على بيانات حسابك. تواصل مع إدارة النظام.',
      );
    }
    final name = (userDoc!['fullName'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      throw const PostException('اسم حسابك غير مسجَّل. تواصل مع إدارة النظام.');
    }
    return name;
  }

  @override
  Stream<List<PostModel>> watchPostsForCourse(
    String courseId, {
    int limit = PostService.pageSize,
  }) =>
      postsController.stream;

  @override
  Stream<List<CommentModel>> watchComments(String postId) {
    final controller = StreamController<List<CommentModel>>();
    commentControllers.add(controller);
    return controller.stream;
  }

  @override
  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    final authorName = _requireAuthorName();
    addCommentCalls.add({
      'postId': postId,
      'content': content,
      'authorId': uid!,
      'authorName': authorName,
    });
  }

  @override
  Future<bool> toggleLike(String postId) async {
    toggleLikeCalls.add(postId);
    if (likeGate != null) await likeGate!.future;
    return true;
  }

  @override
  Future<bool> isPostLikedByMe(String postId) async => false;

  Future<void> disposeAll() async {
    for (final c in commentControllers) {
      if (!c.isClosed) await c.close();
    }
    await postsController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingLikeService extends FakePostService {
  @override
  Future<bool> toggleLike(String postId) async {
    throw const PostException('تعذر تسجيل الإعجاب، حاول مرة أخرى.');
  }
}

PostModel _post({String id = 'p1', String authorId = 'other'}) => PostModel(
      id: id,
      courseId: 'c1',
      authorId: authorId,
      authorName: 'زميل',
      content: 'محتوى المنشور',
      createdAt: DateTime(2026, 8, 20),
    );

CommentModel _comment(String id, String text) => CommentModel(
      id: id,
      postId: 'p1',
      authorId: 'someone',
      authorName: 'معلّق',
      content: text,
      createdAt: DateTime(2026, 8, 21),
    );

/// شجرة الاختبار: PostProvider فقط.
///
/// لا ProfileProvider هنا عمدًا — وجوده يخفي بالضبط العطل المُختبَر.
Widget _app(PostProvider provider) {
  return ChangeNotifierProvider<PostProvider>.value(
    value: provider,
    child: MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  PostDetailsScreen.route(
                    post: _post(),
                    courseTitle: 'قواعد البيانات',
                  ),
                ),
                child: const Text('open-details'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// يفتح التفاصيل ويوصل أول دفعة تعليقات.
///
/// بلا الدفعة تبقى الشاشة على مؤشر تحميل لا ينتهي، فيتعلّق pumpAndSettle
/// إلى الأبد — تمامًا كما يحدث بالتطبيق قبل وصول أول snapshot.
Future<void> _openDetails(
  WidgetTester tester,
  FakePostService service, {
  List<CommentModel> comments = const [],
}) async {
  await tester.tap(find.text('open-details'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  service.commentControllers.last.add(comments);
  await tester.pumpAndSettle();
}

Future<void> _closeDetails(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void _phoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('دورة حياة شاشة تفاصيل المنشور', () {
    testWidgets('فتح التفاصيل ثم الخروج منها بلا استثناء سياق مفصول',
        (tester) async {
      _phoneViewport(tester);
      final service = FakePostService();
      final provider = PostProvider(service);
      addTearDown(service.disposeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_app(provider));
      await _openDetails(tester, service);
      expect(find.byType(PostDetailsScreen), findsOneWidget);

      await _closeDetails(tester);

      // هنا بالضبط كان يظهر «deactivated widget's ancestor».
      expect(tester.takeException(), isNull);
      expect(find.byType(PostDetailsScreen), findsNothing);
    });

    testWidgets('القائمة ← التفاصيل ← رجوع ← التفاصيل ← رجوع تبقى نظيفة',
        (tester) async {
      _phoneViewport(tester);
      final service = FakePostService();
      final provider = PostProvider(service);
      addTearDown(service.disposeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_app(provider));

      for (var visit = 1; visit <= 2; visit++) {
        await _openDetails(tester, service);
        expect(find.byType(PostDetailsScreen), findsOneWidget,
            reason: 'الزيارة $visit');

        await _closeDetails(tester);
        expect(tester.takeException(), isNull, reason: 'الزيارة $visit');
        expect(find.byType(PostDetailsScreen), findsNothing,
            reason: 'الزيارة $visit');
      }
    });

    testWidgets('مستمع التعليقات يُفلَت عند إغلاق الشاشة', (tester) async {
      _phoneViewport(tester);
      final service = FakePostService();
      final provider = PostProvider(service);
      addTearDown(service.disposeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_app(provider));
      await _openDetails(tester, service);
      expect(service.liveCommentListeners, 1);

      await _closeDetails(tester);

      // وإلا بقي التطبيق يقرأ تعليقات منشور غادرته الطالبة أصلًا.
      expect(service.liveCommentListeners, 0);
    });

    testWidgets('إعادة الفتح لا تكدّس مستمعًا فوق آخر', (tester) async {
      _phoneViewport(tester);
      final service = FakePostService();
      final provider = PostProvider(service);
      addTearDown(service.disposeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_app(provider));
      for (var visit = 1; visit <= 3; visit++) {
        await _openDetails(tester, service);
        expect(service.liveCommentListeners, 1, reason: 'الزيارة $visit');
        await _closeDetails(tester);
      }

      expect(service.commentControllers, hasLength(3));
      expect(service.liveCommentListeners, 0);
    });

    testWidgets('التعليقات الواصلة من الـ Stream تُعرض فعلًا', (tester) async {
      _phoneViewport(tester);
      final service = FakePostService();
      final provider = PostProvider(service);
      addTearDown(service.disposeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_app(provider));
      await _openDetails(tester, service, comments: [_comment('c1', 'أول رد')]);

      expect(find.text('أول رد'), findsOneWidget);
      expect(find.text('لا توجد تعليقات بعد، كوني أول من يرد.'), findsNothing);
    });
  });

  group('هوية صاحب التعليق', () {
    testWidgets('مستخدم مصادَق يعلّق دون وجود ProfileProvider بالشجرة إطلاقًا',
        (tester) async {
      _phoneViewport(tester);
      final service = FakePostService(
        uid: 'student1',
        userDoc: {'fullName': 'طالبة أكاديميا', 'role': 'student'},
      );
      final provider = PostProvider(service);
      addTearDown(service.disposeAll);
      addTearDown(provider.dispose);

      await tester.pumpWidget(_app(provider));
      await _openDetails(tester, service);

      await tester.enterText(find.byType(TextField), 'ردّي على المنشور');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(service.addCommentCalls, hasLength(1));
      expect(service.addCommentCalls.single['content'], 'ردّي على المنشور');
      // ولا رسالة «أعيدي تسجيل الدخول» على الشاشة.
      expect(find.byType(SnackBar), findsNothing);
    });

    test('هوية التعليق هي هوية المصادقة، لا حالة الواجهة', () async {
      final service = FakePostService(
        uid: 'student1',
        userDoc: {'fullName': 'طالبة أكاديميا'},
      );
      final provider = PostProvider(service);
      addTearDown(provider.dispose);

      final ok = await provider.addComment(postId: 'p1', content: 'تعليق');

      expect(ok, isTrue);
      expect(service.addCommentCalls.single['authorId'], 'student1');
      expect(service.addCommentCalls.single['authorName'], 'طالبة أكاديميا');
    });

    test('المعلّم والمشرف يعلّقان أيضًا — الهوية لا تعرف الأدوار', () async {
      for (final role in ['teacher', 'admin']) {
        final service = FakePostService(
          uid: 'user_$role',
          userDoc: {'fullName': 'اسم $role', 'role': role},
        );
        final provider = PostProvider(service);

        final ok = await provider.addComment(postId: 'p1', content: 'تعليق');

        expect(ok, isTrue, reason: role);
        expect(service.addCommentCalls.single['authorId'], 'user_$role');
        provider.dispose();
      }
    });

    test('غياب صورة الملف الشخصي لا يمنع التعليق', () async {
      // لا photoUrl بالمستند إطلاقًا — وهي بيانات عرض اختيارية أصلًا.
      final service = FakePostService(
        uid: 'student1',
        userDoc: {'fullName': 'طالبة أكاديميا'},
      );
      final provider = PostProvider(service);
      addTearDown(provider.dispose);

      expect(await provider.addComment(postId: 'p1', content: 'تعليق'), isTrue);
      expect(provider.lastCommentError, isNull);
    });

    test('التعليق بلا مصادقة يُرفض برسالة مصادقة', () async {
      final service = FakePostService(uid: null);
      final provider = PostProvider(service);
      addTearDown(provider.dispose);

      final ok = await provider.addComment(postId: 'p1', content: 'تعليق');

      expect(ok, isFalse);
      expect(provider.lastCommentError, contains('تسجيل الدخول'));
      expect(service.addCommentCalls, isEmpty);
    });

    test('غياب مستند المستخدم خطأ بيانات حساب، لا خطأ مصادقة', () async {
      // الحالة نفسها التي كانت تقول «أعيدي تسجيل الدخول» لجلسة سليمة.
      final service = FakePostService(uid: 'student1', userDoc: null);
      final provider = PostProvider(service);
      addTearDown(provider.dispose);

      final ok = await provider.addComment(postId: 'p1', content: 'تعليق');

      expect(ok, isFalse);
      expect(provider.lastCommentError, contains('بيانات حسابك'));
      expect(provider.lastCommentError, isNot(contains('تسجيل الدخول')));
    });

    test('الرسالة المعروضة نص عربي، لا نص استثناء خام', () async {
      final service = FakePostService(uid: 'student1', userDoc: null);
      final provider = PostProvider(service);
      addTearDown(provider.dispose);

      await provider.addComment(postId: 'p1', content: 'تعليق');

      expect(provider.lastCommentError, isNot(contains('Exception')));
      expect(provider.lastCommentError, isNot(contains('خطأ حقيقي')));
    });
  });

  group('الإعجاب', () {
    Future<PostProvider> seededProvider(FakePostService service) async {
      final provider = PostProvider(service);
      provider.listenToCoursePosts('c1');
      service.postsController.add([_post(id: 'p1')]);
      await pumpEventQueue();
      expect(provider.posts, hasLength(1));
      return provider;
    }

    test('الإعجاب يصل إلى الخدمة ويحدّث الحالة تفاؤليًا', () async {
      final service = FakePostService();
      final provider = await seededProvider(service);
      addTearDown(service.disposeAll);
      addTearDown(provider.dispose);

      expect(provider.posts.single.isLikedByMe, isFalse);

      await provider.toggleLike('p1');

      expect(service.toggleLikeCalls, ['p1']);
      expect(provider.posts.single.isLikedByMe, isTrue);
      expect(provider.posts.single.likesCount, 1);
    });

    test('نقرة ثانية أثناء معاملة جارية لا تفتح معاملة ثانية', () async {
      final service = FakePostService()..likeGate = Completer<void>();
      final provider = await seededProvider(service);
      addTearDown(service.disposeAll);
      addTearDown(provider.dispose);

      final first = provider.toggleLike('p1');
      expect(provider.isLikeInFlight('p1'), isTrue);

      // نقر سريع مكرر: يجب ألا يفتح معاملة Firestore ثانية على المستند نفسه.
      await provider.toggleLike('p1');
      expect(service.toggleLikeCalls, hasLength(1));

      service.likeGate!.complete();
      await first;

      // ويُرفع الحارس، فيبقى المنشور قابلًا للإعجاب بعدها.
      expect(provider.isLikeInFlight('p1'), isFalse);
      await provider.toggleLike('p1');
      expect(service.toggleLikeCalls, hasLength(2));
    });

    test('فشل المعاملة يرجع الحالة ويرفع الحارس ولا يكشف نص الاستثناء',
        () async {
      final service = _FailingLikeService();
      final provider = await seededProvider(service);
      addTearDown(service.disposeAll);
      addTearDown(provider.dispose);

      await provider.toggleLike('p1');

      expect(provider.isLikeInFlight('p1'), isFalse);
      expect(provider.posts.single.isLikedByMe, isFalse);
      expect(provider.posts.single.likesCount, 0);
      expect(provider.errorMessage, 'تعذر تسجيل الإعجاب، حاول مرة أخرى.');
      expect(provider.errorMessage, isNot(contains('Exception')));
    });
  });
}
