import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/courses/widgets/student_file_list_item_card.dart';
import 'package:academia/features/files/models/course_file_model.dart';
import 'package:academia/features/files/providers/course_file_provider.dart';
import 'package:academia/features/files/services/cloudinary_upload_service.dart';
import 'package:academia/features/files/services/course_file_service.dart';
import 'package:academia/features/files/widgets/student_all_file_card.dart';

// --------------------------------------------------------------- fixtures

final DateTime _now = DateTime(2026, 8, 14, 12);

CourseFileModel _file({
  required String id,
  required String offeringId,
  String title = 'المحاضرة الأولى',
  String extension = 'pdf',
  String courseId = 'course_1',
  String status = CourseFileModel.statusActive,
  int size = 2048,
  DateTime? createdAt,
}) {
  return CourseFileModel(
    id: id,
    offeringId: offeringId,
    courseId: courseId,
    semesterId: 'semester_2026_1',
    title: title,
    category: CourseFileModel.categoryLecture,
    fileName: '$title.$extension',
    fileExtension: extension,
    fileSize: size,
    cloudinaryUrl:
        'https://res.cloudinary.com/xmrgiypo/image/upload/v1/$id.$extension',
    cloudinaryPublicId: 'academia/course_files/$offeringId/$id',
    cloudinaryResourceType: 'image',
    uploadedBy: 'admin1',
    status: status,
    createdAt: createdAt ?? DateTime(2026, 8, 10),
  );
}

/// Hands out one controller per offering, so a test can prove exactly which
/// offerings were subscribed to — and which were not.
class FakeCourseFileService implements CourseFileService {
  final Map<String, StreamController<List<CourseFileModel>>> controllers = {};
  final List<String> watched = [];

  StreamController<List<CourseFileModel>> _controllerFor(String offeringId) {
    return controllers.putIfAbsent(
      offeringId,
      () => StreamController<List<CourseFileModel>>.broadcast(),
    );
  }

  @override
  Stream<List<CourseFileModel>> watchOfferingFiles(String offeringId) {
    watched.add(offeringId);
    return _controllerFor(offeringId).stream;
  }

  void emit(String offeringId, List<CourseFileModel> files) {
    _controllerFor(offeringId).add(files);
  }

  void fail(String offeringId) {
    _controllerFor(offeringId).addError(Exception('denied'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CourseFileProvider _provider(FakeCourseFileService service) =>
    CourseFileProvider(service, CloudinaryUploadService());

Widget _wrapWidget(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar', null);
  });

  group('CourseFileModel presentation helpers', () {
    test('type group is derived from the stored extension', () {
      expect(_file(id: 'a', offeringId: 'o', extension: 'pdf').typeGroup,
          CourseFileModel.typePdf);
      expect(_file(id: 'a', offeringId: 'o', extension: 'docx').typeGroup,
          CourseFileModel.typeDoc);
      expect(_file(id: 'a', offeringId: 'o', extension: 'pptx').typeGroup,
          CourseFileModel.typePpt);
      expect(_file(id: 'a', offeringId: 'o', extension: 'png').typeGroup,
          CourseFileModel.typeImage);
      expect(_file(id: 'a', offeringId: 'o', extension: 'zip').typeGroup,
          CourseFileModel.typeOther);
    });

    test('"new" is derived from createdAt, never stored', () {
      final fresh = _file(
        id: 'a',
        offeringId: 'o',
        createdAt: _now.subtract(const Duration(days: 2)),
      );
      final old = _file(
        id: 'b',
        offeringId: 'o',
        createdAt: _now.subtract(const Duration(days: 40)),
      );

      expect(fresh.isRecent(now: _now), isTrue);
      expect(old.isRecent(now: _now), isFalse);
      // A file with no timestamp is never claimed to be new.
      expect(
        CourseFileModel(
          id: 'c',
          offeringId: 'o',
          courseId: 'c1',
          semesterId: 's1',
          title: 't',
          category: CourseFileModel.categoryOther,
          fileName: 'f.pdf',
          fileExtension: 'pdf',
          fileSize: 1,
          cloudinaryUrl: 'u',
          cloudinaryPublicId: 'p',
          cloudinaryResourceType: 'raw',
          uploadedBy: 'a',
        ).isRecent(now: _now),
        isFalse,
      );
    });
  });

  group('course detail — single offering', () {
    test('listens to the selected offering and nothing else', () async {
      final service = FakeCourseFileService();
      final provider = _provider(service);

      provider.listenToOfferingFiles('offering_A');
      service.emit('offering_A', [_file(id: 'f1', offeringId: 'offering_A')]);
      await Future<void>.delayed(Duration.zero);

      expect(service.watched, ['offering_A']);
      expect(provider.files, hasLength(1));
      expect(provider.files.single.offeringId, 'offering_A');
    });

    test('archived files are excluded from the student view', () async {
      final service = FakeCourseFileService();
      final provider = _provider(service);

      provider.listenToOfferingFiles('offering_A');
      service.emit('offering_A', [
        _file(id: 'f1', offeringId: 'offering_A'),
        _file(
          id: 'f2',
          offeringId: 'offering_A',
          status: CourseFileModel.statusArchived,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.files, hasLength(2));
      expect(provider.activeFiles, hasLength(1));
      expect(provider.activeFiles.single.id, 'f1');
    });

    test('an error with no data surfaces an error message', () async {
      final service = FakeCourseFileService();
      final provider = _provider(service);

      provider.listenToOfferingFiles('offering_A');
      service.fail('offering_A');
      await Future<void>.delayed(Duration.zero);

      expect(provider.errorMessage, AppStrings.fileLoadError);
      expect(provider.activeFiles, isEmpty);
    });
  });

  group('All Files — multiple authorized offerings', () {
    test('subscribes once per authorized offering and merges results', () async {
      final service = FakeCourseFileService();
      final provider = _provider(service);

      // current enrollment + completed (history) enrollment
      provider.listenToOfferingsFiles(['offering_current', 'offering_history']);
      service.emit('offering_current', [
        _file(
          id: 'f1',
          offeringId: 'offering_current',
          createdAt: DateTime(2026, 8, 12),
        ),
      ]);
      service.emit('offering_history', [
        _file(
          id: 'f2',
          offeringId: 'offering_history',
          createdAt: DateTime(2026, 8, 13),
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(
        service.watched.toSet(),
        {'offering_current', 'offering_history'},
      );
      expect(provider.activeFiles, hasLength(2));
      // Newest first across offerings.
      expect(provider.activeFiles.first.id, 'f2');
    });

    test('historical (completed) offering files remain visible', () async {
      final service = FakeCourseFileService();
      final provider = _provider(service);

      provider.listenToOfferingsFiles(['offering_history']);
      service.emit('offering_history', [
        _file(id: 'old', offeringId: 'offering_history'),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.activeFiles.single.id, 'old');
    });

    test('an offering not in the authorized list is never queried', () async {
      final service = FakeCourseFileService();
      final provider = _provider(service);

      // A removed enrollment yields no offering id, so it never appears here.
      provider.listenToOfferingsFiles(['offering_current']);
      await Future<void>.delayed(Duration.zero);

      expect(service.watched, ['offering_current']);
      expect(service.watched, isNot(contains('offering_removed')));
      expect(service.watched, isNot(contains('offering_unrelated')));
    });

    test('dropping an offering cancels only that listener', () async {
      final service = FakeCourseFileService();
      final provider = _provider(service);

      provider.listenToOfferingsFiles(['offering_a', 'offering_b']);
      service.emit('offering_a', [_file(id: 'f1', offeringId: 'offering_a')]);
      service.emit('offering_b', [_file(id: 'f2', offeringId: 'offering_b')]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.activeFiles, hasLength(2));

      // Re-sync with a narrower authorization set.
      provider.listenToOfferingsFiles(['offering_a']);
      await Future<void>.delayed(Duration.zero);

      expect(provider.activeFiles, hasLength(1));
      expect(provider.activeFiles.single.offeringId, 'offering_a');
      // offering_a was not re-subscribed; only one watch call for it.
      expect(service.watched.where((id) => id == 'offering_a'), hasLength(1));
    });

    test('an empty authorization list queries nothing', () async {
      final service = FakeCourseFileService();
      final provider = _provider(service);

      provider.listenToOfferingsFiles(const []);
      await Future<void>.delayed(Duration.zero);

      expect(service.watched, isEmpty);
      expect(provider.activeFiles, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('one denied offering does not blank the others', () async {
      final service = FakeCourseFileService();
      final provider = _provider(service);

      provider.listenToOfferingsFiles(['offering_ok', 'offering_denied']);
      service.emit('offering_ok', [_file(id: 'f1', offeringId: 'offering_ok')]);
      service.fail('offering_denied');
      await Future<void>.delayed(Duration.zero);

      expect(provider.activeFiles, hasLength(1));
      expect(provider.errorMessage, isNull);
    });
  });

  group('provider lifecycle — student must not be cleared', () {
    test('an active student session keeps its files', () async {
      final service = FakeCourseFileService();
      final provider = _provider(service);

      provider.listenToOfferingFiles('offering_A');
      service.emit('offering_A', [_file(id: 'f1', offeringId: 'offering_A')]);
      await Future<void>.delayed(Duration.zero);

      // A student is not an admin — this must NOT wipe their files.
      provider.syncWithAuth(isActiveUser: true);
      await Future<void>.delayed(Duration.zero);

      expect(provider.activeFiles, hasLength(1));
    });

    test('sign-out cancels every offering listener', () async {
      final service = FakeCourseFileService();
      final provider = _provider(service);

      provider.listenToOfferingsFiles(['offering_a', 'offering_b']);
      service.emit('offering_a', [_file(id: 'f1', offeringId: 'offering_a')]);
      await Future<void>.delayed(Duration.zero);

      provider.syncWithAuth(isActiveUser: false);
      await Future<void>.delayed(Duration.zero);

      expect(provider.files, isEmpty);
      expect(service.controllers['offering_a']!.hasListener, isFalse);
      expect(service.controllers['offering_b']!.hasListener, isFalse);
    });
  });

  group('teammate widgets render real CourseFileModel', () {
    testWidgets('AllFileCard shows title, subject and real size', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWidget(
          AllFileCard(
            file: _file(
              id: 'f1',
              offeringId: 'o1',
              title: 'ملخص الفصل الثاني',
              size: 2048,
              createdAt: _now.subtract(const Duration(days: 1)),
            ),
            subjectLabel: 'تحليل وتصميم النظم',
            now: _now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ملخص الفصل الثاني'), findsOneWidget);
      expect(find.text('تحليل وتصميم النظم • 2 KB'), findsOneWidget);
      // Recently uploaded → the "new" badge is derived, not stored.
      expect(find.text(AppStrings.newFileBadgeLabel), findsOneWidget);
    });

    testWidgets('AllFileCard offers no download or delete affordance', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWidget(
          AllFileCard(
            file: _file(id: 'f1', offeringId: 'o1'),
            subjectLabel: 'مساق',
            now: _now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Offline download is deferred; students cannot delete course files.
      expect(find.byIcon(Icons.download_rounded), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('FileListItemCard renders date and size from the model', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWidget(
          FileListItemCard(
            file: _file(
              id: 'f1',
              offeringId: 'o1',
              title: 'المحاضرة الأولى',
              size: 1024 * 1024,
              createdAt: DateTime(2026, 8, 10),
            ),
            now: _now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('المحاضرة الأولى'), findsOneWidget);
      expect(find.text('2026/08/10 • 1.0 MB'), findsOneWidget);
      // Opening replaces the deferred download action.
      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsNothing);
    });

    testWidgets('tapping a file row triggers the open callback', (
      tester,
    ) async {
      var opened = 0;
      await tester.pumpWidget(
        _wrapWidget(
          FileListItemCard(
            file: _file(id: 'f1', offeringId: 'o1'),
            now: _now,
            onTap: () => opened++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('المحاضرة الأولى'));
      await tester.pumpAndSettle();

      expect(opened, 1);
    });

    testWidgets('no overflow at 360px with long Arabic content', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrapWidget(
          Column(
            children: [
              AllFileCard(
                file: _file(
                  id: 'f1',
                  offeringId: 'o1',
                  title:
                      'ملخص شامل للفصل الثاني من مساق تحليل وتصميم النظم المعاصرة',
                  createdAt: _now,
                ),
                subjectLabel: 'تحليل وتصميم النظم المعلوماتية المعاصرة',
                now: _now,
              ),
              FileListItemCard(
                file: _file(
                  id: 'f2',
                  offeringId: 'o1',
                  title:
                      'واجب الأسبوع الثالث في البرمجة الكائنية التوجه المتقدمة',
                  createdAt: _now,
                ),
                now: _now,
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
