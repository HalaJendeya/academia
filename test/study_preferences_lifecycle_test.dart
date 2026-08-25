import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/app/app_routes.dart';
import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/profile/models/study_preferences.dart';
import 'package:academia/features/profile/providers/study_preferences_provider.dart';
import 'package:academia/features/profile/screens/study_preferences_screen.dart';

/*
 * TextEditingController lifecycle on the study-preferences screen.
 *
 * The Android red screen began with:
 *
 *   A TextEditingController was used after being disposed.
 *   ChangeNotifier.debugAssertNotDisposed
 *   ChangeNotifier.addListener
 *   _MergingListenable.addListener
 *   _AnimatedState.didUpdateWidget
 *
 * The controller for the custom-duration sheet was disposed in
 * `showModalBottomSheet(...).then(...)`. That future completes at
 * `Navigator.pop`, while the sheet content stays mounted for the whole
 * dismissal animation — so the field's animated decoration re-subscribed to
 * an already-disposed controller on the next frame.
 *
 * The decisive detail in every test below is `pumpAndSettle()` AFTER the
 * sheet closes: without running the exit animation to completion the bug
 * cannot appear at all.
 */

/// Starts empty and only yields preferences when the test says so, so the
/// screen goes through the real "build first, data arrives later" sequence
/// that Firebase produces. A fake pre-populated with data would miss it.
class LateLoadingPreferencesProvider extends ChangeNotifier
    implements StudyPreferencesProvider {
  LateLoadingPreferencesProvider({this.startLoaded = false}) {
    if (startLoaded) _preferences = _initial;
  }

  static const _initial = StudyPreferences(
    studyDays: ['الأحد', 'الثلاثاء'],
    preferredSessionDuration: 45,
  );

  final bool startLoaded;
  StudyPreferences? _preferences;
  bool _loading = false;
  int loadCalls = 0;

  @override
  StudyPreferences? get preferences => _preferences;
  @override
  bool get isLoading => _loading;
  @override
  String? get errorMessage => null;
  @override
  bool get isSaving => false;
  @override
  bool get hasUnsavedChanges => false;

  @override
  Future<void> loadPreferences({bool forceRefresh = false}) async {
    loadCalls++;
    if (_preferences != null && !forceRefresh) return;
    _loading = true;
    notifyListeners();
  }

  /// The provider notification that lands after the first build.
  void completeLoad() {
    _loading = false;
    _preferences = _initial;
    notifyListeners();
  }

  @override
  void setPreferredSessionDuration(int duration) {
    _preferences = _preferences?.copyWith(preferredSessionDuration: duration);
    notifyListeners();
  }

  /// An unrelated notification, to prove a rebuild does not kill the
  /// controller of an open sheet.
  void poke() => notifyListeners();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapDirect(LateLoadingPreferencesProvider provider) {
  return ChangeNotifierProvider<StudyPreferencesProvider>.value(
    value: provider,
    child: const MaterialApp(
      locale: Locale('ar'),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('ar')],
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: StudyPreferencesScreen(),
      ),
    ),
  );
}

/// A launcher screen standing in for either entry point (Profile or Study
/// Hub). Both reach the preferences screen with the identical
/// `Navigator.pushNamed(context, AppRoutes.studyPreferences)` call.
Widget _wrapPushed(LateLoadingPreferencesProvider provider, String label) {
  return ChangeNotifierProvider<StudyPreferencesProvider>.value(
    value: provider,
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar')],
      routes: {
        AppRoutes.studyPreferences: (_) => const StudyPreferencesScreen(),
      },
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.studyPreferences),
                child: Text(label),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openCustomDurationSheet(WidgetTester tester) async {
  // textContaining, not text: once a custom duration is set the trigger
  // relabels itself to «مدة مخصصة: 40 دقيقة», so an exact match would only
  // ever find it on the first visit.
  final trigger = find.textContaining(AppStrings.customDuration);
  await tester.ensureVisible(trigger.first);
  await tester.pumpAndSettle();
  await tester.tap(trigger.first);
  await tester.pumpAndSettle();
}

void main() {
  group('custom-duration sheet controller lifecycle', () {
    testWidgets('confirming closes the sheet without a disposed controller',
        (tester) async {
      _phone(tester);
      final provider = LateLoadingPreferencesProvider();

      await tester.pumpWidget(_wrapDirect(provider));
      // Discrete frames, not pumpAndSettle: the loading state shows an
      // indeterminate spinner that never settles.
      await tester.pump();
      await tester.pump();
      provider.completeLoad();
      await tester.pumpAndSettle();

      await _openCustomDurationSheet(tester);
      expect(find.byType(TextFormField), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '50');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.confirm));

      // Running the dismissal animation to completion is the whole point:
      // the old code disposed the controller at pop, mid-animation.
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(provider.preferences!.preferredSessionDuration, 50);
    });

    testWidgets('cancelling closes the sheet without a disposed controller',
        (tester) async {
      _phone(tester);
      final provider = LateLoadingPreferencesProvider();

      await tester.pumpWidget(_wrapDirect(provider));
      // Discrete frames, not pumpAndSettle: the loading state shows an
      // indeterminate spinner that never settles.
      await tester.pump();
      await tester.pump();
      provider.completeLoad();
      await tester.pumpAndSettle();

      await _openCustomDurationSheet(tester);
      await tester.enterText(find.byType(TextFormField), '77');
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Cancel must not write anything.
      expect(provider.preferences!.preferredSessionDuration, 45);
    });

    testWidgets('an invalid value keeps the field alive and usable',
        (tester) async {
      _phone(tester);
      final provider = LateLoadingPreferencesProvider();

      await tester.pumpWidget(_wrapDirect(provider));
      // Discrete frames, not pumpAndSettle: the loading state shows an
      // indeterminate spinner that never settles.
      await tester.pump();
      await tester.pump();
      provider.completeLoad();
      await tester.pumpAndSettle();

      await _openCustomDurationSheet(tester);
      await tester.enterText(find.byType(TextFormField), '999');
      await tester.tap(find.text(AppStrings.confirm));
      await tester.pumpAndSettle();

      // Sheet stays open with an error; the controller is still live.
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.invalidCustomDuration), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '60');
      await tester.tap(find.text(AppStrings.confirm));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(provider.preferences!.preferredSessionDuration, 60);
    });

    testWidgets('a provider notification while the sheet is open is harmless',
        (tester) async {
      _phone(tester);
      final provider = LateLoadingPreferencesProvider();

      await tester.pumpWidget(_wrapDirect(provider));
      // Discrete frames, not pumpAndSettle: the loading state shows an
      // indeterminate spinner that never settles.
      await tester.pump();
      await tester.pump();
      provider.completeLoad();
      await tester.pumpAndSettle();

      await _openCustomDurationSheet(tester);
      await tester.enterText(find.byType(TextFormField), '35');
      await tester.pumpAndSettle();

      // The screen underneath rebuilds; the sheet's controller must survive
      // and must not lose what the student is typing.
      provider.poke();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('35'), findsOneWidget);

      await tester.tap(find.text(AppStrings.confirm));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('opening the sheet twice in one screen life is safe',
        (tester) async {
      _phone(tester);
      final provider = LateLoadingPreferencesProvider();

      await tester.pumpWidget(_wrapDirect(provider));
      // Discrete frames, not pumpAndSettle: the loading state shows an
      // indeterminate spinner that never settles.
      await tester.pump();
      await tester.pump();
      provider.completeLoad();
      await tester.pumpAndSettle();

      for (final value in ['25', '95']) {
        await _openCustomDurationSheet(tester);
        await tester.enterText(find.byType(TextFormField), value);
        await tester.tap(find.text(AppStrings.confirm));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      expect(provider.preferences!.preferredSessionDuration, 95);
    });
  });

  group('screen lifecycle across entry points', () {
    testWidgets('data arriving after the first build does not break the screen',
        (tester) async {
      _phone(tester);
      final provider = LateLoadingPreferencesProvider();

      await tester.pumpWidget(_wrapDirect(provider));
      await tester.pump();
      await tester.pump();

      // First build happened with no preferences at all.
      provider.completeLoad();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.customDuration), findsWidgets);
    });

    testWidgets('Profile → preferences → back → reopen is safe',
        (tester) async {
      _phone(tester);
      final provider = LateLoadingPreferencesProvider(startLoaded: true);

      await tester.pumpWidget(_wrapPushed(provider, 'profile-entry'));
      await tester.pumpAndSettle();

      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('profile-entry'));
        await tester.pumpAndSettle();
        expect(find.byType(StudyPreferencesScreen), findsOneWidget);

        // Exercise the controller on each visit: disposal bugs surface on
        // the second screen lifetime, not the first.
        await _openCustomDurationSheet(tester);
        await tester.enterText(find.byType(TextFormField), '40');
        await tester.tap(find.text(AppStrings.confirm));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip(AppStrings.back));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(StudyPreferencesScreen), findsNothing);
      }
    });

    testWidgets('Study Hub → preferences uses the same safe path',
        (tester) async {
      _phone(tester);
      final provider = LateLoadingPreferencesProvider(startLoaded: true);

      // The hub issues an identical pushNamed; what matters is that the
      // destination survives being opened from a second place.
      await tester.pumpWidget(_wrapPushed(provider, 'study-hub-entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('study-hub-entry'));
      await tester.pumpAndSettle();

      await _openCustomDurationSheet(tester);
      await tester.enterText(find.byType(TextFormField), '30');
      await tester.tap(find.text(AppStrings.confirm));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(AppStrings.back));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(provider.preferences!.preferredSessionDuration, 30);
    });

    testWidgets('no layout exception at 360x780 with the sheet open',
        (tester) async {
      _phone(tester);
      final provider = LateLoadingPreferencesProvider(startLoaded: true);

      await tester.pumpWidget(_wrapDirect(provider));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await _openCustomDurationSheet(tester);

      // No RenderFlex overflow, absurd or otherwise, once the controller
      // lifecycle is correct.
      expect(tester.takeException(), isNull);
    });
  });
}
