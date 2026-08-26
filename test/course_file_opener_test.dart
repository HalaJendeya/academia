import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:academia/features/files/services/course_file_opener.dart';

/// Records every launch attempt so a test can assert the URL and the mode.
class RecordingLauncher {
  RecordingLauncher({this.succeedsOn, this.throwsAlways = false});

  /// Modes that should succeed. `null` means every mode succeeds.
  final Set<LaunchMode>? succeedsOn;
  final bool throwsAlways;

  final List<({Uri uri, LaunchMode mode})> calls = [];

  Future<bool> call(Uri uri, {required LaunchMode mode}) async {
    calls.add((uri: uri, mode: mode));
    if (throwsAlways) throw Exception('platform failure');
    if (succeedsOn == null) return true;
    return succeedsOn!.contains(mode);
  }
}

// A real stored URL shape from the project's Cloudinary cloud.
const _validUrl =
    'https://res.cloudinary.com/xmrgiypo/image/upload/v1755000000/'
    'academia/course_files/off1/wvozsf2aejtpl7w45miy.pdf';

void main() {
  group('valid URLs reach the launcher', () {
    test('an https Cloudinary URL is launched externally first', () async {
      final launcher = RecordingLauncher();

      final result = await openCourseFileUrl(
        _validUrl,
        launcher: launcher.call,
      );

      expect(result, CourseFileOpenResult.opened);
      expect(launcher.calls, hasLength(1));
      expect(launcher.calls.single.uri.toString(), _validUrl);
      expect(launcher.calls.single.mode, LaunchMode.externalApplication);
    });

    test('the stored URL is passed through untouched', () async {
      final launcher = RecordingLauncher();
      await openCourseFileUrl(_validUrl, launcher: launcher.call);

      // No re-signing, no resource-type rewriting: the asset lives where its
      // secure_url says it does.
      expect(launcher.calls.single.uri.host, 'res.cloudinary.com');
      expect(launcher.calls.single.uri.path, contains('/image/upload/'));
      expect(launcher.calls.single.uri.scheme, 'https');
    });

    test('plain http is also accepted', () async {
      final launcher = RecordingLauncher();
      final result = await openCourseFileUrl(
        'http://res.cloudinary.com/x/image/upload/v1/a.pdf',
        launcher: launcher.call,
      );
      expect(result, CourseFileOpenResult.opened);
    });
  });

  group('invalid URLs never reach the launcher', () {
    test('an empty URL is rejected up front', () async {
      final launcher = RecordingLauncher();
      final result = await openCourseFileUrl('', launcher: launcher.call);

      expect(result, CourseFileOpenResult.invalidUrl);
      expect(launcher.calls, isEmpty);
    });

    test('whitespace-only is rejected up front', () async {
      final launcher = RecordingLauncher();
      final result = await openCourseFileUrl('   ', launcher: launcher.call);

      expect(result, CourseFileOpenResult.invalidUrl);
      expect(launcher.calls, isEmpty);
    });

    test('a schemeless value is rejected — Uri.tryParse alone would pass it', () async {
      final launcher = RecordingLauncher();

      // Uri.tryParse returns a non-null relative Uri here, which is exactly
      // why a null check was not enough.
      expect(Uri.tryParse('res.cloudinary.com/a.pdf'), isNotNull);

      final result = await openCourseFileUrl(
        'res.cloudinary.com/a.pdf',
        launcher: launcher.call,
      );
      expect(result, CourseFileOpenResult.invalidUrl);
      expect(launcher.calls, isEmpty);
    });

    test('a non-web scheme is rejected', () async {
      final launcher = RecordingLauncher();
      final result = await openCourseFileUrl(
        'file:///data/local/a.pdf',
        launcher: launcher.call,
      );

      expect(result, CourseFileOpenResult.invalidUrl);
      expect(launcher.calls, isEmpty);
    });
  });

  group('launch failures are handled, never crash', () {
    test('a false result falls back to the default mode once', () async {
      final launcher = RecordingLauncher(
        succeedsOn: {LaunchMode.platformDefault},
      );

      final result = await openCourseFileUrl(
        _validUrl,
        launcher: launcher.call,
      );

      expect(result, CourseFileOpenResult.opened);
      expect(launcher.calls.map((c) => c.mode).toList(), [
        LaunchMode.externalApplication,
        LaunchMode.platformDefault,
      ]);
    });

    test('false from every mode reports launchFailed', () async {
      final launcher = RecordingLauncher(succeedsOn: const {});

      final result = await openCourseFileUrl(
        _validUrl,
        launcher: launcher.call,
      );

      expect(result, CourseFileOpenResult.launchFailed);
      expect(launcher.calls, hasLength(2));
    });

    test('a thrown platform exception is caught, not propagated', () async {
      final launcher = RecordingLauncher(throwsAlways: true);

      late CourseFileOpenResult result;
      await expectLater(
        () async {
          result = await openCourseFileUrl(_validUrl, launcher: launcher.call);
        }(),
        completes,
      );

      expect(result, CourseFileOpenResult.launchFailed);
    });
  });

  group('no download behaviour is introduced', () {
    test('opening never reports success without a launch', () async {
      final launcher = RecordingLauncher(succeedsOn: const {});
      final result = await openCourseFileUrl(
        _validUrl,
        launcher: launcher.call,
      );

      // The only success path is the platform actually opening the URL —
      // nothing is fetched, cached, or written locally.
      expect(result, isNot(CourseFileOpenResult.opened));
    });
  });
}
