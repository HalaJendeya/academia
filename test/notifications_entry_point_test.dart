import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/app/akademia_app.dart';
import 'package:academia/app/app_routes.dart';
import 'package:academia/features/academics/models/major_model.dart';
import 'package:academia/features/assignments/models/course_assignment_model.dart';
import 'package:academia/features/assignments/providers/assignment_progress_provider.dart';
import 'package:academia/features/assignments/providers/course_assignment_provider.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/courses/screens/student_course_detail_screen.dart';
import 'package:academia/features/dashboard/screens/dashboard_screen.dart';
import 'package:academia/features/notifications/models/app_notification.dart';
import 'package:academia/features/notifications/providers/notification_provider.dart';
import 'package:academia/features/notifications/screens/notifications_screen.dart';
import 'package:academia/features/notifications/services/notification_service.dart';
import 'package:academia/features/notifications/widgets/notification_card.dart';
import 'package:academia/features/semesters/models/semester_model.dart';
import 'package:academia/features/tasks/models/task_model.dart';
import 'package:academia/features/tasks/providers/task_provider.dart';
import 'package:academia/core/widgets/app_top_bar.dart';

/*
 * مركز الإشعارات: من الجرس إلى الشاشة.
 *
 * العطل الذي يحرس منه هذا الملف لم يكن في الشاشة — الشاشة كانت مكتوبة
 * وسليمة. كان في وصولها: جرس الإشعارات ظاهر في AcademiaMainAppBar منذ
 * البداية، لكن لا لوحة الطالب ولا شاشة المساقات مرّرت
 * onNotificationsPressed، أي onPressed: null — زرّ يبدو قابلًا للضغط ولا
 * يستجيب. وNotificationsScreen نفسها لم تكن مسجَّلة في جدول مسارات
 * akademia_app، فلا مسار يؤدي إليها أصلًا.
 *
 * 🔴 اختبار "الجرس ظاهر" وحده كان سيمرّ طوال تلك المدة. لذلك يتحقّق
 * الاختبار الأول من onPressed != null تحديدًا، لا من وجود الأيقونة.
 */

// ------------------------------------------------------------------ fixtures

const _majorId = 'Bo7h3btN54SxANGuVqb1';

const _major = MajorModel(
  id: _majorId,
  name: 'نظم المعلومات الإدارية والتجارية المعاصرة',
  code: 'MIS',
  departmentId: 'dep1',
  totalLevels: 8,
  status: MajorModel.statusActive,
);

const _semester = SemesterModel(
  id: 'semester_2026_1',
  academicYear: '2026',
  semesterNumber: 1,
  semesterName: 'الفصل الأول 2026',
  status: SemesterModel.statusCurrent,
);

AppNotification _postNotification({
  String id = 'post_p1_student1',
  bool isRead = false,
  String? courseId = 'course_BMIS3344',
}) {
  return AppNotification(
    id: id,
    recipientId: 'student1',
    type: AppNotification.typeNewSharedSpacePost,
    title: 'منشور جديد في تحليل وتصميم النظم',
    body: 'نشرت زميلتك سؤالًا في ساحة المشاركة.',
    courseId: courseId,
    postId: 'p1',
    createdAt: DateTime(2026, 9, 1, 10),
    isRead: isRead,
  );
}

AppNotification _assignmentNotification({
  String id = 'assignment_a1_student1',
  bool isRead = false,
  String? courseId = 'course_BMIS3342',
}) {
  return AppNotification(
    id: id,
    recipientId: 'student1',
    type: AppNotification.typeNewAssignment,
    title: 'واجب جديد في قواعد البيانات',
    body: 'أُضيف واجب جديد إلى شعبتك.',
    courseId: courseId,
    assignmentId: 'a1',
    createdAt: DateTime(2026, 9, 1, 11),
    isRead: isRead,
  );
}

// --------------------------------------------------------------------- spies

/// خدمة إشعارات تُبدَّل تحت [NotificationProvider] الحقيقي.
///
/// 🔴 المزوّد هنا حقيقي لا مقلَّد: العدّاد ودورة الاشتراك وmarkAsRead كلها
/// منطق إنتاجي، وتقليد المزوّد كان سيختبر المقلَّد لا التطبيق.
///
/// [openSubscriptions] يتتبّع الاشتراكات **الحيّة** لا عدد الاستدعاءات:
/// التسريب الذي يهمّ هو اشتراك بقي مفتوحًا بعد الرجوع من الشاشة.
class SpyNotificationService extends NotificationService {
  SpyNotificationService();

  final StreamController<List<AppNotification>> _source =
      StreamController<List<AppNotification>>.broadcast();

  final List<String> markedRead = [];
  int watchCallCount = 0;
  int openSubscriptions = 0;

  List<AppNotification> _latest = const [];

  void emit(List<AppNotification> notifications) {
    _latest = notifications;
    _source.add(notifications);
  }

  @override
  Stream<List<AppNotification>> watchMyNotifications() {
    watchCallCount++;

    late final StreamController<List<AppNotification>> hop;
    StreamSubscription<List<AppNotification>>? inner;

    hop = StreamController<List<AppNotification>>(
      onListen: () {
        openSubscriptions++;
        inner = _source.stream.listen(hop.add, onError: hop.addError);
      },
      onCancel: () async {
        openSubscriptions--;
        await inner?.cancel();
      },
    );

    return hop.stream;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    markedRead.add(notificationId);

    // كما في Firestore: الكتابة لا تُحدّث الواجهة، التدفّق هو من يفعل.
    emit([
      for (final n in _latest)
        if (n.id == notificationId) _asRead(n) else n,
    ]);
  }

  static AppNotification _asRead(AppNotification n) => AppNotification(
        id: n.id,
        recipientId: n.recipientId,
        type: n.type,
        title: n.title,
        body: n.body,
        courseId: n.courseId,
        postId: n.postId,
        assignmentId: n.assignmentId,
        createdAt: n.createdAt,
        isRead: true,
      );
}

/// يسجّل كل مسار مدفوع بحجّته — به نثبت الوجهة لا مجرد اختفاء الشاشة.
class RouteRecorder extends NavigatorObserver {
  final List<RouteSettings> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route.settings);
    super.didPush(route, previousRoute);
  }
}

// ------------------------------------------------------------------- fakes

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  AppUserModel? get currentUserProfile => const AppUserModel(
        uid: 'student1',
        fullName: 'حلا جندية',
        email: 's@test.com',
        role: UserRole.student,
        status: 'active',
        emailVerified: true,
        onboardingCompleted: true,
        onboardingStatus: 'completed',
        majorId: _majorId,
        academicLevel: 4,
      );

  @override
  bool get isLoggedIn => true;

  @override
  bool get isAdmin => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStudentCoursesProvider extends ChangeNotifier
    implements StudentCoursesProvider {
  @override
  bool get isLoading => false;

  @override
  bool get hasLoaded => true;

  @override
  String? get errorMessage => null;

  @override
  bool get hasMajor => true;

  @override
  bool get hasCurrentSemester => true;

  @override
  SemesterModel? get currentSemester => _semester;

  @override
  MajorModel? get major => _major;

  @override
  String get majorName => _major.name;

  @override
  int? get academicLevel => 4;

  @override
  int get programTotalCreditHours => 134;

  @override
  List<StudentProgramEntryView> get recommendedForMyLevel => const [];

  @override
  int get recommendedCreditHours => 0;

  @override
  List<StudentCourseView> get currentCourses => const [];

  @override
  List<StudentAvailableCourseView> get availableNow => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTaskProvider extends ChangeNotifier implements TaskProvider {
  @override
  List<TaskModel> get tasks => const [];

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InertAssignmentProvider extends ChangeNotifier
    implements CourseAssignmentProvider {
  @override
  int? get activeAssignmentCount => 0;

  @override
  bool get isLoadingActiveAssignmentCount => false;

  @override
  Future<void> loadActiveAssignmentCount() async {}

  @override
  List<CourseAssignmentModel> get activeAssignments =>
      const <CourseAssignmentModel>[];

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InertProgressProvider extends ChangeNotifier
    implements AssignmentProgressProvider {
  @override
  Set<String> get completedAssignmentIds => const <String>{};

  @override
  Map<String, DateTime?> get completionTimes => const <String, DateTime?>{};

  @override
  bool isCompleted(String assignmentId) => false;

  @override
  DateTime? completedAt(String assignmentId) => null;

  @override
  bool isSaving(String assignmentId) => false;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// بديل شاشة تفاصيل المساق: الوجهة تُثبَت من [RouteRecorder]، وهذه لا
/// تحتاج مزوّدات المساقات كاملة.
class _CourseDetailStub extends StatelessWidget {
  const _CourseDetailStub();

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as StudentCourseDetailArgs?;
    return Scaffold(body: Center(child: Text('course:${args?.courseId}')));
  }
}

// ----------------------------------------------------------------- harness

Widget _app({
  required SpyNotificationService service,
  required RouteRecorder recorder,
  String initialRoute = AppRoutes.dashboard,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => _FakeAuthProvider()),
      ChangeNotifierProvider<StudentCoursesProvider>(
        create: (_) => _FakeStudentCoursesProvider(),
      ),
      ChangeNotifierProvider<TaskProvider>(create: (_) => _FakeTaskProvider()),
      ChangeNotifierProvider<CourseAssignmentProvider>(
        create: (_) => _InertAssignmentProvider(),
      ),
      ChangeNotifierProvider<AssignmentProgressProvider>(
        create: (_) => _InertProgressProvider(),
      ),
      ChangeNotifierProvider<NotificationProvider>(
        create: (_) => NotificationProvider(service),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('ar'),
      navigatorObservers: [recorder],
      initialRoute: initialRoute,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      routes: {
        AppRoutes.dashboard: (_) => const DashboardScreen(),
        AppRoutes.notifications: (_) => const NotificationsScreen(),
        AppRoutes.courseDetail: (_) => const _CourseDetailStub(),
      },
    ),
  );
}

/// يُنهي انتقال المسار بإطارات محدودة بدل pumpAndSettle.
///
/// 🔴 pumpAndSettle لا ينتهي أبدًا حين تكون شاشة الإشعارات في الشجرة: أول
/// ما تعرضه هو AppLoadingState، ومؤشّر التقدّم رسمٌ دائم لا يستقرّ. هذا
/// ليس التفافًا على العطل — الشاشة تنتظر أول دفعة من التدفّق فعلًا.
Future<void> _settleRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void _useNarrowScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// الجرس داخل شريط التطبيق تحديدًا.
///
/// 🔴 لا نبحث عن الأيقونة في الشجرة كلها: بطاقة "الإشعارات" في الإجراءات
/// السريعة تحمل الأيقونة نفسها وتفتح **إعدادات** الإشعارات لا مركزها،
/// فمطابقة عامة كانت ستلتقط الاثنتين وتخفي أيّهما نضغط.
Finder _appBarBell() => find.descendant(
      of: find.byType(AcademiaMainAppBar),
      matching: find.widgetWithIcon(
        IconButton,
        Icons.notifications_none_rounded,
      ),
    );

void main() {
  group('جدول المسارات', () {
    /*
     * 🔴 بقية اختبارات هذا الملف تبني جدول مسارات خاصًّا بها، فهي تثبت
     * أن الشاشة تعمل حين يُفتح مسارها — لا أنه مسجَّل في التطبيق. وهذا
     * نصف العطل الأصلي بالضبط: الشاشة موجودة، والمسار غير مسجَّل.
     *
     * لذلك نقرأ هنا جدول akademia_app نفسه. نستدعي build مباشرة ولا
     * نركّب الشجرة: initialRoute هو splash، وتركيبه يستدعي Firebase.
     */
    testWidgets('akademia_app يسجّل مسار الإشعارات فعلًا', (tester) async {
      MaterialApp? app;
      Widget? screen;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            app = const AkademiaApp().build(context) as MaterialApp;
            screen = app!.routes?[AppRoutes.notifications]?.call(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(app!.routes, contains(AppRoutes.notifications));
      expect(screen, isA<NotificationsScreen>());
    });
  });

  group('نقطة الدخول', () {
    testWidgets('جرس شريط اللوحة ظاهر ومفعَّل', (tester) async {
      _useNarrowScreen(tester);
      final service = SpyNotificationService();
      final recorder = RouteRecorder();

      await tester.pumpWidget(_app(service: service, recorder: recorder));
      await tester.pumpAndSettle();

      final bell = _appBarBell();
      expect(bell, findsOneWidget);

      // العطل الأصلي بالضبط: الأيقونة موجودة والمُعالِج null.
      expect(tester.widget<IconButton>(bell).onPressed, isNotNull);
    });

    testWidgets('الضغط على الجرس يفتح NotificationsScreen على مسارها',
        (tester) async {
      _useNarrowScreen(tester);
      final service = SpyNotificationService();
      final recorder = RouteRecorder();

      await tester.pumpWidget(_app(service: service, recorder: recorder));
      await tester.pumpAndSettle();

      await tester.tap(_appBarBell());
      await _settleRoute(tester);

      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(recorder.pushed.last.name, AppRoutes.notifications);
    });

    testWidgets('فتح الشاشة يبدأ تدفّق الإشعارات', (tester) async {
      _useNarrowScreen(tester);
      final service = SpyNotificationService();
      final recorder = RouteRecorder();

      await tester.pumpWidget(_app(service: service, recorder: recorder));
      await tester.pumpAndSettle();
      expect(service.openSubscriptions, 0);

      await tester.tap(_appBarBell());
      await _settleRoute(tester);

      expect(service.openSubscriptions, 1);
    });
  });

  group('عرض القائمة', () {
    testWidgets('حالة فارغة صحيحة حين لا إشعارات', (tester) async {
      final service = SpyNotificationService();
      final recorder = RouteRecorder();

      await tester.pumpWidget(_app(
        service: service,
        recorder: recorder,
        initialRoute: AppRoutes.notifications,
      ));
      // إطار واحد ينفّذ addPostFrameCallback الذي يبدأ التدفّق — انظر
      // [_settleRoute] لسبب تجنّب pumpAndSettle هنا.
      await tester.pump();

      service.emit(const []);
      await tester.pumpAndSettle();

      expect(find.text('لا توجد إشعارات بعد'), findsOneWidget);
      expect(find.byType(NotificationCard), findsNothing);
    });

    testWidgets('إشعار غير مقروء يظهر بعنوان عريض', (tester) async {
      final service = SpyNotificationService();
      final recorder = RouteRecorder();

      await tester.pumpWidget(_app(
        service: service,
        recorder: recorder,
        initialRoute: AppRoutes.notifications,
      ));
      // إطار واحد ينفّذ addPostFrameCallback الذي يبدأ التدفّق — انظر
      // [_settleRoute] لسبب تجنّب pumpAndSettle هنا.
      await tester.pump();

      final unread = _postNotification();
      service.emit([unread]);
      await tester.pumpAndSettle();

      expect(find.byType(NotificationCard), findsOneWidget);
      expect(find.text(unread.title), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(unread.title)).style?.fontWeight,
        FontWeight.bold,
      );
    });

    testWidgets('إشعار مقروء يظهر بعنوان عادي', (tester) async {
      final service = SpyNotificationService();
      final recorder = RouteRecorder();

      await tester.pumpWidget(_app(
        service: service,
        recorder: recorder,
        initialRoute: AppRoutes.notifications,
      ));
      // إطار واحد ينفّذ addPostFrameCallback الذي يبدأ التدفّق — انظر
      // [_settleRoute] لسبب تجنّب pumpAndSettle هنا.
      await tester.pump();

      final read = _postNotification(isRead: true);
      service.emit([read]);
      await tester.pumpAndSettle();

      expect(find.byType(NotificationCard), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(read.title)).style?.fontWeight,
        FontWeight.normal,
      );
    });

    testWidgets('newSharedSpacePost يُعرض بأيقونة ساحة المشاركة',
        (tester) async {
      final service = SpyNotificationService();
      final recorder = RouteRecorder();

      await tester.pumpWidget(_app(
        service: service,
        recorder: recorder,
        initialRoute: AppRoutes.notifications,
      ));
      // إطار واحد ينفّذ addPostFrameCallback الذي يبدأ التدفّق — انظر
      // [_settleRoute] لسبب تجنّب pumpAndSettle هنا.
      await tester.pump();

      service.emit([_postNotification()]);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(NotificationCard),
          matching: find.byIcon(Icons.forum_outlined),
        ),
        findsOneWidget,
      );
    });

    testWidgets('newAssignment يُعرض بأيقونة الواجبات لا بالأيقونة العامة',
        (tester) async {
      final service = SpyNotificationService();
      final recorder = RouteRecorder();

      await tester.pumpWidget(_app(
        service: service,
        recorder: recorder,
        initialRoute: AppRoutes.notifications,
      ));
      // إطار واحد ينفّذ addPostFrameCallback الذي يبدأ التدفّق — انظر
      // [_settleRoute] لسبب تجنّب pumpAndSettle هنا.
      await tester.pump();

      final assignment = _assignmentNotification();
      service.emit([assignment]);
      await tester.pumpAndSettle();

      expect(find.text(assignment.title), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(NotificationCard),
          matching: find.byIcon(Icons.assignment_outlined),
        ),
        findsOneWidget,
      );
    });

    testWidgets('الأحدث أولًا كما يصل من التدفّق', (tester) async {
      final service = SpyNotificationService();
      final recorder = RouteRecorder();

      await tester.pumpWidget(_app(
        service: service,
        recorder: recorder,
        initialRoute: AppRoutes.notifications,
      ));
      // إطار واحد ينفّذ addPostFrameCallback الذي يبدأ التدفّق — انظر
      // [_settleRoute] لسبب تجنّب pumpAndSettle هنا.
      await tester.pump();

      // الترتيب مسؤولية الاستعلام (orderBy createdAt descending)؛ الشاشة
      // تعرض ما تستلمه كما هو دون إعادة ترتيب.
      final newer = _assignmentNotification();
      final older = _postNotification();
      service.emit([newer, older]);
      await tester.pumpAndSettle();

      final cards = tester.widgetList<NotificationCard>(
        find.byType(NotificationCard),
      );
      expect(cards.map((c) => c.notification.id).toList(), [
        newer.id,
        older.id,
      ]);
    });
  });

  group('الضغط على إشعار', () {
    testWidgets('يُعلَّم مقروءًا ثم يُعاد رسمه عاديًا', (tester) async {
      final service = SpyNotificationService();
      final recorder = RouteRecorder();

      await tester.pumpWidget(_app(
        service: service,
        recorder: recorder,
        initialRoute: AppRoutes.notifications,
      ));
      // إطار واحد ينفّذ addPostFrameCallback الذي يبدأ التدفّق — انظر
      // [_settleRoute] لسبب تجنّب pumpAndSettle هنا.
      await tester.pump();

      final unread = _postNotification();
      service.emit([unread]);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NotificationCard));
      await tester.pumpAndSettle();

      expect(service.markedRead, [unread.id]);
    });

    testWidgets('منشور ساحة المشاركة يفتح مساقه بحجّة صحيحة', (tester) async {
      final service = SpyNotificationService();
      final recorder = RouteRecorder();

      await tester.pumpWidget(_app(
        service: service,
        recorder: recorder,
        initialRoute: AppRoutes.notifications,
      ));
      // إطار واحد ينفّذ addPostFrameCallback الذي يبدأ التدفّق — انظر
      // [_settleRoute] لسبب تجنّب pumpAndSettle هنا.
      await tester.pump();

      service.emit([_postNotification()]);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NotificationCard));
      await tester.pumpAndSettle();

      expect(recorder.pushed.last.name, AppRoutes.courseDetail);
      final args = recorder.pushed.last.arguments;
      expect(args, isA<StudentCourseDetailArgs>());
      expect((args as StudentCourseDetailArgs).courseId, 'course_BMIS3344');
    });

    testWidgets('الواجب الجديد يفتح مساقه لا شاشة «الواجب غير متاح»',
        (tester) async {
      final service = SpyNotificationService();
      final recorder = RouteRecorder();

      await tester.pumpWidget(_app(
        service: service,
        recorder: recorder,
        initialRoute: AppRoutes.notifications,
      ));
      // إطار واحد ينفّذ addPostFrameCallback الذي يبدأ التدفّق — انظر
      // [_settleRoute] لسبب تجنّب pumpAndSettle هنا.
      await tester.pump();

      service.emit([_assignmentNotification()]);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NotificationCard));
      await tester.pumpAndSettle();

      // 🔴 assignmentDetails يشترط CourseAssignmentModel كاملًا لا نملكه
      // من الإشعار، فتمريره فارغًا رابط مكسور. المساق وجهة صحيحة قائمة.
      expect(recorder.pushed.last.name, AppRoutes.courseDetail);
      expect(
        (recorder.pushed.last.arguments as StudentCourseDetailArgs).courseId,
        'course_BMIS3342',
      );
    });

    testWidgets('إشعار بلا courseId يُعلَّم مقروءًا ولا يُلاحِق وجهة',
        (tester) async {
      final service = SpyNotificationService();
      final recorder = RouteRecorder();

      await tester.pumpWidget(_app(
        service: service,
        recorder: recorder,
        initialRoute: AppRoutes.notifications,
      ));
      // إطار واحد ينفّذ addPostFrameCallback الذي يبدأ التدفّق — انظر
      // [_settleRoute] لسبب تجنّب pumpAndSettle هنا.
      await tester.pump();

      final orphan = _postNotification(courseId: null);
      service.emit([orphan]);
      await tester.pumpAndSettle();

      final pushesBefore = recorder.pushed.length;
      await tester.tap(find.byType(NotificationCard));
      await tester.pumpAndSettle();

      expect(service.markedRead, [orphan.id]);
      expect(recorder.pushed.length, pushesBefore);
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });
  });

  group('دورة الحياة', () {
    testWidgets('فتح ورجوع وفتح لا يترك اشتراكًا معلَّقًا ولا يرمي',
        (tester) async {
      _useNarrowScreen(tester);
      final service = SpyNotificationService();
      final recorder = RouteRecorder();

      await tester.pumpWidget(_app(service: service, recorder: recorder));
      await tester.pumpAndSettle();

      for (var round = 1; round <= 3; round++) {
        await tester.tap(_appBarBell());
        await _settleRoute(tester);
        expect(find.byType(NotificationsScreen), findsOneWidget);
        expect(
          service.openSubscriptions,
          1,
          reason: 'اشتراك واحد حيّ في الجولة $round',
        );

        service.emit([_postNotification()]);
        await tester.pumpAndSettle();

        // زر الرجوع في AcademiaSubAppBar — لا يملك شريط اللوحة مثله.
        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await _settleRoute(tester);

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(
          service.openSubscriptions,
          0,
          reason: 'dispose ألغى الاشتراك في الجولة $round',
        );
      }

      // 🔴 الخطأ المحروس منه: «Looking up a deactivated widget's ancestor»
      // من قراءة مزوّد داخل dispose. أي استثناء في أي جولة يظهر هنا.
      expect(tester.takeException(), isNull);
      expect(service.watchCallCount, 3);
    });

    testWidgets('التدفّق يتوقف بعد الرجوع فلا يبني على شجرة مفكَّكة',
        (tester) async {
      _useNarrowScreen(tester);
      final service = SpyNotificationService();
      final recorder = RouteRecorder();

      await tester.pumpWidget(_app(service: service, recorder: recorder));
      await tester.pumpAndSettle();

      await tester.tap(_appBarBell());
      await _settleRoute(tester);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await _settleRoute(tester);

      service.emit([_postNotification(), _assignmentNotification()]);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(NotificationCard), findsNothing);
    });
  });
}
