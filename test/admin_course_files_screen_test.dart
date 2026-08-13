import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/core/constants/cloudinary_config.dart';
import 'package:academia/core/widgets/primary_button.dart';
import 'package:academia/features/admin/screens/admin_course_files_screen.dart';
import 'package:academia/features/admin/screens/admin_upload_file_screen.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/course_offering_model.dart';
import 'package:academia/features/files/models/course_file_model.dart';
import 'package:academia/features/files/providers/course_file_provider.dart';
import 'package:academia/features/files/services/course_file_picker.dart';

const _offering = CourseOfferingModel(
  id: 'course_bmis3344_semester_2026_1_1',
  courseId: 'course_bmis3344',
  semesterId: 'semester_2026_1',
  instructorName: 'م. حمزة السويركي',
  section: '1',
  status: CourseOfferingModel.statusActive,
);

const _courseTitle = 'برمجة تطبيقات الهواتف الذكية';

CourseFileModel _file({
  String id = 'file1',
  String title = 'المحاضرة الأولى',
  String category = CourseFileModel.categoryLecture,
  String status = CourseFileModel.statusActive,
}) {
  return CourseFileModel(
    id: id,
    offeringId: _offering.id,
    courseId: _offering.courseId,
    semesterId: _offering.semesterId,
    title: title,
    description: 'مقدمة المساق',
    category: category,
    fileName: 'lecture1.pdf',
    fileExtension: 'pdf',
    mimeType: 'application/pdf',
    fileSize: 2048,
    cloudinaryUrl: 'https://res.cloudinary.com/xmrgiypo/image/upload/v1/a.pdf',
    cloudinaryPublicId: 'academia/course_files/off/a',
    cloudinaryResourceType: 'image',
    uploadedBy: 'admin1',
    status: status,
    createdAt: DateTime(2026, 8, 9),
  );
}

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

/// Records everything the screens ask the provider to do.
class FakeCourseFileProvider extends ChangeNotifier
    implements CourseFileProvider {
  FakeCourseFileProvider({
    this.filesValue = const [],
    this.isLoadingValue = false,
    this.uploadSucceeds = true,
    this.errorValue,
  });

  List<CourseFileModel> filesValue;
  final bool isLoadingValue;
  final bool uploadSucceeds;
  String? errorValue;

  String? listenedOfferingId;
  int uploadCallCount = 0;
  CourseOfferingModel? uploadedOffering;
  String? uploadedFileName;
  String? uploadedTitle;
  String? uploadedCategory;
  String? uploadedDescription;
  List<int>? uploadedBytes;

  CourseFileModel? updatedFile;
  String? archivedFileId;

  bool _isUploading = false;

  @override
  List<CourseFileModel> get files => filesValue;

  @override
  bool get isLoading => isLoadingValue;

  @override
  bool get isUploading => _isUploading;

  @override
  bool get isSaving => false;

  @override
  String? get errorMessage => errorValue;

  @override
  void listenToOfferingFiles(String offeringId) {
    listenedOfferingId = offeringId;
  }

  @override
  void clearFiles() {}

  @override
  Future<bool> uploadFile({
    required CourseOfferingModel offering,
    required List<int> bytes,
    required String fileName,
    required String title,
    required String category,
    String description = '',
    String mimeType = '',
  }) async {
    uploadCallCount++;
    uploadedOffering = offering;
    uploadedBytes = bytes;
    uploadedFileName = fileName;
    uploadedTitle = title;
    uploadedCategory = category;
    uploadedDescription = description;

    // Mimic the real provider's in-flight flag so the screen can block a
    // second submission while the first is running.
    _isUploading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _isUploading = false;
    if (!uploadSucceeds) errorValue = AppStrings.fileMetadataFailedAfterUpload;
    notifyListeners();

    return uploadSucceeds;
  }

  @override
  Future<bool> updateFileMetadata(CourseFileModel file) async {
    updatedFile = file;
    return true;
  }

  @override
  Future<bool> archiveFile(String fileId) async {
    archivedFileId = fileId;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapFiles(FakeCourseFileProvider provider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
      ChangeNotifierProvider<CourseFileProvider>.value(value: provider),
    ],
    child: MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            settings: const RouteSettings(
              arguments: OfferingFilesArgs(
                offering: _offering,
                courseTitle: _courseTitle,
              ),
            ),
            builder: (_) => const AdminCourseFilesScreen(),
          ),
        ),
      ),
    ),
  );
}

Widget _wrapUpload(
  FakeCourseFileProvider provider,
  CourseFilePickerFn picker,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
      ChangeNotifierProvider<CourseFileProvider>.value(value: provider),
    ],
    child: MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            settings: const RouteSettings(
              arguments: UploadFileArgs(
                offering: _offering,
                courseTitle: _courseTitle,
              ),
            ),
            builder: (_) => AdminUploadFileScreen(picker: picker),
          ),
        ),
      ),
    ),
  );
}

CourseFilePickerFn _pickerReturning({
  required String fileName,
  required int size,
}) {
  return () async => PickedCourseFile(
    fileName: fileName,
    bytes: List<int>.filled(size, 65),
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
  group('files list', () {
    testWidgets('scopes itself to the offering it was given', (tester) async {
      _useNarrowScreen(tester);
      final provider = FakeCourseFileProvider();
      await tester.pumpWidget(_wrapFiles(provider));
      await tester.pumpAndSettle();

      // The screen never asks for courseId/semesterId; it listens by offering.
      expect(provider.listenedOfferingId, _offering.id);
      expect(find.text(_courseTitle), findsOneWidget);
    });

    testWidgets('zero files shows an actionable empty state', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(_wrapFiles(FakeCourseFileProvider()));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noOfferingFilesTitle), findsOneWidget);
      expect(find.text('${AppStrings.offeringFilesCountLabel}: 0'), findsOneWidget);
      expect(find.text(AppStrings.uploadFileTitle), findsWidgets);
    });

    testWidgets('a populated list renders the required file fields', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapFiles(
          FakeCourseFileProvider(
            filesValue: [
              _file(),
              _file(
                id: 'file2',
                title: 'ملخص الوحدة',
                category: CourseFileModel.categorySummary,
                status: CourseFileModel.statusArchived,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('المحاضرة الأولى'), findsOneWidget);
      expect(find.text('lecture1.pdf'), findsNWidgets(2));
      expect(find.text('PDF'), findsNWidgets(2));
      expect(find.text('2 KB'), findsNWidgets(2));
      expect(find.text('2026-08-09'), findsNWidgets(2));

      // Arabic category labels at render time; stored values stay canonical.
      expect(find.text(AppStrings.fileCategoryLecture), findsOneWidget);
      expect(find.text(AppStrings.fileCategorySummary), findsOneWidget);

      expect(find.text(AppStrings.fileStatusActive), findsOneWidget);
      expect(find.text(AppStrings.fileStatusArchived), findsOneWidget);
      expect(find.text('${AppStrings.offeringFilesCountLabel}: 2'), findsOneWidget);
    });

    testWidgets('there is no hard-delete action', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapFiles(FakeCourseFileProvider(filesValue: [_file()])),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
      expect(find.byIcon(Icons.delete_rounded), findsNothing);
      expect(find.byIcon(Icons.archive_rounded), findsOneWidget);
    });

    testWidgets('archiving asks for confirmation and archives on confirm', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      final provider = FakeCourseFileProvider(filesValue: [_file()]);
      await tester.pumpWidget(_wrapFiles(provider));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.archive_rounded));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.archiveFileTitle), findsOneWidget);

      // Cancelling must not archive.
      await tester.tap(find.text(AppStrings.cancelAction));
      await tester.pumpAndSettle();
      expect(provider.archivedFileId, isNull);

      await tester.tap(find.byIcon(Icons.archive_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.confirmAction));
      await tester.pumpAndSettle();

      expect(provider.archivedFileId, 'file1');
    });

    testWidgets('editing metadata sends only descriptive changes', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      final provider = FakeCourseFileProvider(filesValue: [_file()]);
      await tester.pumpWidget(_wrapFiles(provider));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.editFileTitle), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'المحاضرة الأولى'),
        'عنوان محدَّث',
      );
      await tester.tap(find.text(AppStrings.saveChanges));
      await tester.pumpAndSettle();

      final updated = provider.updatedFile!;
      expect(updated.title, 'عنوان محدَّث');
      // Everything identifying the file is carried through untouched.
      expect(updated.id, 'file1');
      expect(updated.offeringId, _offering.id);
      expect(updated.courseId, _offering.courseId);
      expect(updated.semesterId, _offering.semesterId);
      expect(updated.cloudinaryUrl, _file().cloudinaryUrl);
      expect(updated.cloudinaryPublicId, _file().cloudinaryPublicId);
      expect(updated.cloudinaryResourceType, 'image');
      expect(updated.uploadedBy, 'admin1');
    });

    testWidgets('no overflow at 360px with files listed', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapFiles(
          FakeCourseFileProvider(
            filesValue: [_file(), _file(id: 'file2', title: 'ملخص')],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('upload screen', () {
    testWidgets('a valid file reaches the provider with the full offering', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      final provider = FakeCourseFileProvider();
      await tester.pumpWidget(
        _wrapUpload(
          provider,
          _pickerReturning(fileName: 'محاضرة1.pdf', size: 2048),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.selectFileAction));
      await tester.pumpAndSettle();
      expect(find.text('محاضرة1.pdf'), findsOneWidget);

      await tester.tap(find.text(AppStrings.confirmUploadAction));
      await tester.pumpAndSettle();

      expect(provider.uploadCallCount, 1);
      // The offering object itself is handed over — the screen never
      // assembles offeringId/courseId/semesterId by hand.
      expect(provider.uploadedOffering, same(_offering));
      expect(provider.uploadedFileName, 'محاضرة1.pdf');
      expect(provider.uploadedTitle, 'محاضرة1');
      expect(provider.uploadedCategory, CourseFileModel.categoryLecture);
      expect(provider.uploadedBytes, hasLength(2048));
    });

    testWidgets('an unsupported extension is rejected before upload', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      final provider = FakeCourseFileProvider();
      await tester.pumpWidget(
        _wrapUpload(
          provider,
          _pickerReturning(fileName: 'script.exe', size: 2048),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.selectFileAction));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.fileTypeNotAllowed), findsOneWidget);
      expect(find.text('script.exe'), findsNothing);

      // Scroll the submit button into view so the tap genuinely lands:
      // otherwise "not called" would pass even for a missed tap.
      await tester.ensureVisible(find.byType(AppPrimaryButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppPrimaryButton));
      await tester.pumpAndSettle();
      expect(provider.uploadCallCount, 0);
    });

    testWidgets('a file above 10 MB is rejected before upload', (tester) async {
      _useNarrowScreen(tester);
      final provider = FakeCourseFileProvider();
      await tester.pumpWidget(
        _wrapUpload(
          provider,
          _pickerReturning(
            fileName: 'huge.pdf',
            size: CloudinaryConfig.maxFileSizeBytes + 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.selectFileAction));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.fileTooLargeError), findsOneWidget);

      // Scroll the submit button into view so the tap genuinely lands:
      // otherwise "not called" would pass even for a missed tap.
      await tester.ensureVisible(find.byType(AppPrimaryButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppPrimaryButton));
      await tester.pumpAndSettle();
      expect(provider.uploadCallCount, 0);
    });

    testWidgets('submitting with no file selected does not call the provider', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      final provider = FakeCourseFileProvider();
      await tester.pumpWidget(
        _wrapUpload(provider, () async => null),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.confirmUploadAction));
      await tester.pumpAndSettle();

      expect(provider.uploadCallCount, 0);
      expect(find.text(AppStrings.noFileSelected), findsWidgets);
    });

    testWidgets('a second submission is blocked while uploading', (
      tester,
    ) async {
      _useNarrowScreen(tester);
      final provider = FakeCourseFileProvider();
      await tester.pumpWidget(
        _wrapUpload(
          provider,
          _pickerReturning(fileName: 'محاضرة1.pdf', size: 2048),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.selectFileAction));
      await tester.pumpAndSettle();

      // Tap the button widget, not its label: while uploading the label is
      // replaced by a spinner, so a text finder would match nothing and the
      // guard would go untested.
      final submit = find.byType(AppPrimaryButton);
      await tester.tap(submit);
      await tester.pump(); // upload in flight

      expect(provider.isUploading, isTrue);
      expect(find.text(AppStrings.fileUploadingLabel), findsOneWidget);

      // Tapping again while in flight must not queue a duplicate upload.
      await tester.tap(submit, warnIfMissed: false);
      await tester.pump();
      expect(provider.uploadCallCount, 1);

      await tester.pumpAndSettle();
      expect(provider.uploadCallCount, 1);
    });

    testWidgets(
      'the metadata-after-upload failure is surfaced verbatim',
      (tester) async {
        _useNarrowScreen(tester);
        final provider = FakeCourseFileProvider(uploadSucceeds: false);
        await tester.pumpWidget(
          _wrapUpload(
            provider,
            _pickerReturning(fileName: 'محاضرة1.pdf', size: 2048),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.selectFileAction));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.confirmUploadAction));
        await tester.pumpAndSettle();

        // The admin must learn the binary reached storage but was not recorded.
        expect(
          find.text(AppStrings.fileMetadataFailedAfterUpload),
          findsOneWidget,
        );
      },
    );

    testWidgets('no overflow at 360px on the upload form', (tester) async {
      _useNarrowScreen(tester);
      await tester.pumpWidget(
        _wrapUpload(
          FakeCourseFileProvider(),
          _pickerReturning(fileName: 'محاضرة1.pdf', size: 2048),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.selectFileAction));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

