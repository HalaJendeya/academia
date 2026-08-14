import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/admin/providers/admin_support_provider.dart';
import 'package:academia/features/admin/screens/admin_settings_screen.dart';
import 'package:academia/features/admin/screens/admin_support_requests_screen.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/profile/models/support_request.dart';

// --------------------------------------------------------------- fixtures

SupportRequest _request({
  String id = 'req1',
  String subject = 'مشكلة في تسجيل المساقات',
  String fullName = 'حلا جندية',
  String email = 's@test.com',
  String message = 'لا أستطيع رؤية مساقات الفصل الحالي.',
  String status = SupportRequest.statusOpen,
  DateTime? createdAt,
}) {
  return SupportRequest(
    id: id,
    uid: 'student1',
    fullName: fullName,
    email: email,
    subject: subject,
    message: message,
    status: status,
    createdAt: createdAt ?? DateTime(2026, 8, 12, 10, 30),
  );
}

// ------------------------------------------------------------------ fakes

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool get isLoggedIn => true;

  @override
  bool get isAdmin => true;

  @override
  AppUserModel? get currentUserProfile => const AppUserModel(
    uid: 'admin1',
    fullName: 'Admin',
    email: 'admin@test.com',
    role: UserRole.admin,
    status: 'active',
    emailVerified: true,
    onboardingCompleted: true,
    onboardingStatus: 'completed',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records what the screen asks the provider to do, without touching
/// Firestore. Mirrors the real provider's derived getters exactly.
class FakeAdminSupportProvider extends ChangeNotifier
    implements AdminSupportProvider {
  FakeAdminSupportProvider({
    this.requestsValue = const [],
    this.isLoadingValue = false,
    this.errorValue,
    this.succeeds = true,
  });

  List<SupportRequest> requestsValue;
  final bool isLoadingValue;
  String? errorValue;
  final bool succeeds;

  int listenCallCount = 0;
  final List<String> resolvedIds = <String>[];
  final List<String> reopenedIds = <String>[];

  @override
  List<SupportRequest> get requests => requestsValue;

  @override
  bool get isLoading => isLoadingValue;

  @override
  bool get isSaving => false;

  @override
  String? get errorMessage => errorValue;

  @override
  List<SupportRequest> get openRequests =>
      requestsValue.where((r) => r.isOpen).toList();

  @override
  List<SupportRequest> get resolvedRequests =>
      requestsValue.where((r) => r.isResolved).toList();

  @override
  List<SupportRequest> filtered(SupportRequestFilter filter) {
    switch (filter) {
      case SupportRequestFilter.all:
        return requests;
      case SupportRequestFilter.open:
        return openRequests;
      case SupportRequestFilter.resolved:
        return resolvedRequests;
    }
  }

  @override
  void listenToRequests() => listenCallCount++;

  @override
  Future<bool> markResolved(String requestId) async {
    resolvedIds.add(requestId);
    if (!succeeds) errorValue = AppStrings.supportRequestStatusError;
    return succeeds;
  }

  @override
  Future<bool> reopen(String requestId) async {
    reopenedIds.add(requestId);
    if (!succeeds) errorValue = AppStrings.supportRequestStatusError;
    return succeeds;
  }

  @override
  void clearError() {
    errorValue = null;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RouteRecorder extends NavigatorObserver {
  final List<String?> pushed = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}

Widget _wrap(FakeAdminSupportProvider provider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
      ChangeNotifierProvider<AdminSupportProvider>.value(value: provider),
    ],
    child: const MaterialApp(
      locale: Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: AdminSupportRequestsScreen(),
      ),
    ),
  );
}

void _useNarrowScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar', null);
  });

  group('model tolerance', () {
    test('legacy documents missing optional fields still parse', () {
      // Only the two fields the very first writes are guaranteed to carry.
      final request = SupportRequest.fromFirestore(
        {'uid': 'student1', 'subject': 'موضوع'},
        'legacy1',
      );

      expect(request.id, 'legacy1');
      expect(request.uid, 'student1');
      expect(request.subject, 'موضوع');
      expect(request.fullName, isEmpty);
      expect(request.email, isEmpty);
      expect(request.createdAt, isNull);
      expect(request.updatedAt, isNull);
      // A document with no status must stay visible, not vanish into
      // "resolved".
      expect(request.status, SupportRequest.statusOpen);
      expect(request.isOpen, isTrue);
    });

    test('an unrecognised status is read as open', () {
      final request = SupportRequest.fromFirestore(
        {'uid': 'u', 'status': 'escalated'},
        'r',
      );
      expect(request.status, SupportRequest.statusOpen);
    });

    test('the student write shape is unchanged', () {
      final map = _request().toFirestore();
      expect(
        map.keys.toSet(),
        {'uid', 'fullName', 'email', 'subject', 'message', 'status', 'source'},
      );
      // id / createdAt / updatedAt are never part of the written document.
      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('createdAt'), isFalse);
    });
  });

  group('status model', () {
    test('the lifecycle is exactly open and resolved', () {
      // Deliberately small: no priorities, no assignees, no ticket states.
      expect(SupportRequest.allowedStatuses, ['open', 'resolved']);
      expect(
        SupportRequest.allowedStatuses.contains('escalated'),
        isFalse,
      );
    });
  });

  group('inbox list', () {
    testWidgets('zero requests shows the honest empty state', (tester) async {
      final provider = FakeAdminSupportProvider();
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(provider.listenCallCount, 1);
      expect(find.text(AppStrings.supportRequestsEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.supportRequestsEmptyDesc), findsOneWidget);
    });

    testWidgets('an open request renders subject, requester and status', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(FakeAdminSupportProvider(requestsValue: [_request()])),
      );
      await tester.pumpAndSettle();

      expect(find.text('مشكلة في تسجيل المساقات'), findsOneWidget);
      expect(find.text('حلا جندية'), findsOneWidget);
      expect(find.text(AppStrings.supportStatusOpen), findsOneWidget);
      expect(find.text(AppStrings.supportStatusResolved), findsNothing);
    });

    testWidgets('a resolved request renders with the resolved badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          FakeAdminSupportProvider(
            requestsValue: [
              _request(status: SupportRequest.statusResolved),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.supportStatusResolved), findsOneWidget);
      expect(find.text(AppStrings.supportStatusOpen), findsNothing);
    });

    testWidgets('legacy fields fall back to a clear placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          FakeAdminSupportProvider(
            requestsValue: [
              SupportRequest(
                id: 'legacy1',
                uid: 'student1',
                fullName: '',
                email: '',
                subject: 'موضوع قديم',
                message: '',
                status: SupportRequest.statusOpen,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('موضوع قديم'), findsOneWidget);
      // Name, message and date all resolve to the same honest placeholder.
      expect(
        find.text(AppStrings.supportRequestUnknownValue),
        findsNWidgets(3),
      );
    });
  });

  group('filters', () {
    testWidgets('all / open / resolved narrow the list correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          FakeAdminSupportProvider(
            requestsValue: [
              _request(id: 'r1', subject: 'طلب مفتوح'),
              _request(
                id: 'r2',
                subject: 'طلب محلول',
                status: SupportRequest.statusResolved,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Counts come from the loaded list, not from a literal.
      expect(find.text('${AppStrings.supportFilterAll} (2)'), findsOneWidget);
      expect(find.text('${AppStrings.supportFilterOpen} (1)'), findsOneWidget);
      expect(
        find.text('${AppStrings.supportFilterResolved} (1)'),
        findsOneWidget,
      );

      expect(find.text('طلب مفتوح'), findsOneWidget);
      expect(find.text('طلب محلول'), findsOneWidget);

      await tester.tap(find.text('${AppStrings.supportFilterOpen} (1)'));
      await tester.pumpAndSettle();
      expect(find.text('طلب مفتوح'), findsOneWidget);
      expect(find.text('طلب محلول'), findsNothing);

      await tester.tap(find.text('${AppStrings.supportFilterResolved} (1)'));
      await tester.pumpAndSettle();
      expect(find.text('طلب مفتوح'), findsNothing);
      expect(find.text('طلب محلول'), findsOneWidget);
    });

    testWidgets('a filter with no matches is distinct from an empty inbox', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          FakeAdminSupportProvider(requestsValue: [_request()]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('${AppStrings.supportFilterResolved} (0)'));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.supportRequestsEmptyFilteredTitle),
        findsOneWidget,
      );
      expect(find.text(AppStrings.supportRequestsEmptyTitle), findsNothing);
    });
  });

  group('details and actions', () {
    testWidgets('opening a request shows the full stored message', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          FakeAdminSupportProvider(
            requestsValue: [
              _request(message: 'الرسالة الكاملة كما كتبها الطالب.'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('مشكلة في تسجيل المساقات'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.supportRequestDetailsTitle), findsOneWidget);

      // The list card shows a clipped preview; the dialog must carry the
      // whole stored message.
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('الرسالة الكاملة كما كتبها الطالب.'),
        ),
        findsOneWidget,
      );
      expect(find.text('s@test.com'), findsOneWidget);
      expect(find.text(AppStrings.supportMarkResolvedAction), findsOneWidget);
      // No messaging surface anywhere in the dialog.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('marking resolved calls the provider with that request id', (
      tester,
    ) async {
      final provider = FakeAdminSupportProvider(
        requestsValue: [_request(id: 'req-42')],
      );
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('مشكلة في تسجيل المساقات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.supportMarkResolvedAction));
      await tester.pumpAndSettle();

      expect(provider.resolvedIds, ['req-42']);
      expect(provider.reopenedIds, isEmpty);
      expect(
        find.text(AppStrings.supportRequestResolvedSuccess),
        findsOneWidget,
      );
    });

    testWidgets('a resolved request offers reopen instead', (tester) async {
      final provider = FakeAdminSupportProvider(
        requestsValue: [
          _request(id: 'req-7', status: SupportRequest.statusResolved),
        ],
      );
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('مشكلة في تسجيل المساقات'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.supportReopenAction), findsOneWidget);
      expect(find.text(AppStrings.supportMarkResolvedAction), findsNothing);

      await tester.tap(find.text(AppStrings.supportReopenAction));
      await tester.pumpAndSettle();

      expect(provider.reopenedIds, ['req-7']);
      expect(provider.resolvedIds, isEmpty);
      expect(
        find.text(AppStrings.supportRequestReopenedSuccess),
        findsOneWidget,
      );
    });

    testWidgets('a failed status change surfaces the error', (tester) async {
      final provider = FakeAdminSupportProvider(
        requestsValue: [_request()],
        succeeds: false,
      );
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('مشكلة في تسجيل المساقات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.supportMarkResolvedAction));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.supportRequestStatusError),
        findsOneWidget,
      );
    });
  });

  group('provider states', () {
    testWidgets('a load error stays on this screen with a retry', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          FakeAdminSupportProvider(
            errorValue: AppStrings.supportRequestsLoadError,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.supportRequestsLoadError), findsOneWidget);
      // The screen frame survives: title and filters are still there.
      expect(find.text(AppStrings.supportRequestsTitle), findsOneWidget);
      expect(find.text(AppStrings.supportFilterAll), findsOneWidget);
      // No counts are claimed when the data could not be read.
      expect(find.text('${AppStrings.supportFilterAll} (0)'), findsNothing);
    });

    testWidgets('while loading no counts are fabricated', (tester) async {
      await tester.pumpWidget(
        _wrap(FakeAdminSupportProvider(isLoadingValue: true)),
      );
      await tester.pump();

      expect(find.text('${AppStrings.supportFilterAll} (0)'), findsNothing);
      expect(find.text(AppStrings.supportRequestsEmptyTitle), findsNothing);
    });
  });

  group('navigation', () {
    testWidgets('admin settings opens the support inbox', (tester) async {
      final recorder = RouteRecorder();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => FakeAuthProvider(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            navigatorObservers: [recorder],
            onGenerateRoute: (settings) => MaterialPageRoute(
              settings: settings,
              builder: (_) => settings.name == Navigator.defaultRouteName
                  ? const Directionality(
                      textDirection: TextDirection.rtl,
                      child: AdminSettingsScreen(),
                    )
                  : const Scaffold(body: Center(child: Text('INBOX-STUB'))),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final entry = find.text(AppStrings.supportRequestsTitle);
      await tester.ensureVisible(entry);
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();

      expect(recorder.pushed.last, AppRoutes.adminSupportRequests);
      expect(find.text('INBOX-STUB'), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('no overflow at 360px with long Arabic content', (
      tester,
    ) async {
      _useNarrowScreen(tester);

      await tester.pumpWidget(
        _wrap(
          FakeAdminSupportProvider(
            requestsValue: [
              _request(
                id: 'r1',
                subject:
                    'مشكلة طويلة جدًا في تسجيل مساقات الفصل الدراسي الحالي',
                fullName: 'حلا هيثم جندية عبد الرحمن',
                message:
                    'لا أستطيع رؤية أي مساق من مساقات الفصل الحالي رغم أن '
                    'المشرف سجّلني فيها، وأرجو المساعدة في أقرب وقت ممكن.',
              ),
              _request(
                id: 'r2',
                subject: 'طلب ثانٍ',
                status: SupportRequest.statusResolved,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
