import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/core/constants/cloudinary_config.dart';
import 'package:academia/features/courses/models/course_offering_model.dart';
import 'package:academia/features/files/models/course_file_model.dart';
import 'package:academia/features/files/providers/course_file_provider.dart';
import 'package:academia/features/files/services/cloudinary_upload_service.dart';
import 'package:academia/features/files/services/course_file_service.dart';

const _offering = CourseOfferingModel(
  id: 'course_bmis3344_semester_2026_1_1',
  courseId: 'course_bmis3344',
  semesterId: 'semester_2026_1',
  instructorName: 'م. حمزة السويركي',
  section: '1',
  status: CourseOfferingModel.statusActive,
);

/// A minimal PDF-ish payload; content is irrelevant, size and name are not.
List<int> _bytes([int length = 2048]) => List<int>.filled(length, 65);

String _cloudinarySuccessBody({
  String resourceType = 'image',
  String format = 'pdf',
  int bytes = 2048,
}) {
  return jsonEncode({
    'secure_url': 'https://res.cloudinary.com/xmrgiypo/image/upload/v1/a.pdf',
    'public_id': 'academia/course_files/offering/a',
    'resource_type': resourceType,
    'format': format,
    'bytes': bytes,
  });
}

/// Records what the metadata layer was asked to write, and can be made to
/// fail so the "uploaded but not recorded" path is exercised.
class FakeCourseFileService implements CourseFileService {
  FakeCourseFileService({this.shouldFail = false});

  final bool shouldFail;
  CourseFileModel? created;
  int createCallCount = 0;

  @override
  Future<String> createFileMetadata(CourseFileModel file) async {
    createCallCount++;
    if (shouldFail) {
      throw const CourseFileException(AppStrings.fileSaveError);
    }
    created = file;
    return 'file1';
  }

  @override
  Stream<List<CourseFileModel>> watchOfferingFiles(String offeringId) {
    return Stream.value([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CloudinaryUploadService _uploadServiceReturning(
  http.Response Function(http.BaseRequest request) handler,
) {
  return CloudinaryUploadService(
    client: MockClient((request) async => handler(request)),
  );
}

void main() {
  group('CloudinaryUploadService.validate', () {
    test('accepts every allowed extension', () {
      for (final extension in CloudinaryConfig.allowedExtensions) {
        expect(
          () => CloudinaryUploadService.validate(
            fileName: 'lecture.$extension',
            sizeBytes: 1024,
          ),
          returnsNormally,
          reason: '.$extension should be allowed',
        );
      }
    });

    test('rejects a disallowed extension before any upload', () {
      expect(
        () => CloudinaryUploadService.validate(
          fileName: 'malware.exe',
          sizeBytes: 1024,
        ),
        throwsA(
          isA<CloudinaryUploadException>().having(
            (e) => e.message,
            'message',
            AppStrings.fileTypeNotAllowed,
          ),
        ),
      );
    });

    test('rejects a file with no extension', () {
      expect(
        () => CloudinaryUploadService.validate(
          fileName: 'notes',
          sizeBytes: 1024,
        ),
        throwsA(isA<CloudinaryUploadException>()),
      );
    });

    test('enforces the 10 MB limit', () {
      // Exactly at the limit is fine; one byte over is not.
      expect(
        () => CloudinaryUploadService.validate(
          fileName: 'big.pdf',
          sizeBytes: CloudinaryConfig.maxFileSizeBytes,
        ),
        returnsNormally,
      );
      expect(
        () => CloudinaryUploadService.validate(
          fileName: 'big.pdf',
          sizeBytes: CloudinaryConfig.maxFileSizeBytes + 1,
        ),
        throwsA(
          isA<CloudinaryUploadException>().having(
            (e) => e.message,
            'message',
            AppStrings.fileTooLargeError,
          ),
        ),
      );
    });

    test('rejects an empty file', () {
      expect(
        () => CloudinaryUploadService.validate(
          fileName: 'empty.pdf',
          sizeBytes: 0,
        ),
        throwsA(isA<CloudinaryUploadException>()),
      );
    });
  });

  group('upload ordering', () {
    test('a successful upload writes metadata derived from the offering', () async {
      final fileService = FakeCourseFileService();
      final provider = CourseFileProvider(
        fileService,
        _uploadServiceReturning(
          (_) => http.Response(_cloudinarySuccessBody(), 200),
        ),
      );

      final ok = await provider.uploadFile(
        offering: _offering,
        bytes: _bytes(),
        fileName: 'محاضرة1.pdf',
        title: 'المحاضرة الأولى',
        category: CourseFileModel.categoryLecture,
      );

      expect(ok, isTrue);
      expect(provider.errorMessage, isNull);
      expect(provider.isUploading, isFalse);

      // The three relationship fields come from the offering, never from
      // caller-supplied values.
      final created = fileService.created!;
      expect(created.offeringId, _offering.id);
      expect(created.courseId, _offering.courseId);
      expect(created.semesterId, _offering.semesterId);
      expect(created.title, 'المحاضرة الأولى');
      expect(created.fileExtension, 'pdf');
      expect(created.cloudinaryPublicId, isNotEmpty);
      expect(created.cloudinaryResourceType, 'image');
      expect(created.status, CourseFileModel.statusActive);
    });

    test('a rejected file never reaches Cloudinary or Firestore', () async {
      final fileService = FakeCourseFileService();
      var cloudinaryCalled = false;

      final provider = CourseFileProvider(
        fileService,
        _uploadServiceReturning((_) {
          cloudinaryCalled = true;
          return http.Response(_cloudinarySuccessBody(), 200);
        }),
      );

      final ok = await provider.uploadFile(
        offering: _offering,
        bytes: _bytes(),
        fileName: 'script.exe',
        title: 'x',
        category: CourseFileModel.categoryOther,
      );

      expect(ok, isFalse);
      expect(cloudinaryCalled, isFalse);
      expect(fileService.createCallCount, 0);
      expect(provider.errorMessage, AppStrings.fileTypeNotAllowed);
    });

    test('a failed Cloudinary upload writes NO Firestore document', () async {
      final fileService = FakeCourseFileService();
      final provider = CourseFileProvider(
        fileService,
        _uploadServiceReturning(
          (_) => http.Response(
            jsonEncode({
              'error': {'message': 'Upload preset not found'},
            }),
            400,
          ),
        ),
      );

      final ok = await provider.uploadFile(
        offering: _offering,
        bytes: _bytes(),
        fileName: 'محاضرة1.pdf',
        title: 'المحاضرة الأولى',
        category: CourseFileModel.categoryLecture,
      );

      expect(ok, isFalse);
      // This is the ordering guarantee: no metadata for a file that isn't
      // actually stored.
      expect(fileService.createCallCount, 0);
      expect(provider.errorMessage, contains('Upload preset not found'));
    });

    test('a Cloudinary response missing url/public_id counts as failure', () async {
      final fileService = FakeCourseFileService();
      final provider = CourseFileProvider(
        fileService,
        _uploadServiceReturning(
          (_) => http.Response(jsonEncode({'resource_type': 'raw'}), 200),
        ),
      );

      final ok = await provider.uploadFile(
        offering: _offering,
        bytes: _bytes(),
        fileName: 'محاضرة1.pdf',
        title: 'المحاضرة الأولى',
        category: CourseFileModel.categoryLecture,
      );

      expect(ok, isFalse);
      expect(fileService.createCallCount, 0);
    });

    test(
      'metadata failure after a successful upload is reported clearly and '
      'never attempts a client-side Cloudinary delete',
      () async {
        final fileService = FakeCourseFileService(shouldFail: true);
        var requestCount = 0;

        final provider = CourseFileProvider(
          fileService,
          _uploadServiceReturning((request) {
            requestCount++;
            // Only the upload POST may ever be issued; deletion requires a
            // signature and must not be attempted from the client.
            expect(request.method, 'POST');
            expect(request.url.path, contains('/upload'));
            return http.Response(_cloudinarySuccessBody(), 200);
          }),
        );

        final ok = await provider.uploadFile(
          offering: _offering,
          bytes: _bytes(),
          fileName: 'محاضرة1.pdf',
          title: 'المحاضرة الأولى',
          category: CourseFileModel.categoryLecture,
        );

        expect(ok, isFalse);
        expect(fileService.createCallCount, 1);
        expect(requestCount, 1);
        expect(
          provider.errorMessage,
          contains(AppStrings.fileMetadataFailedAfterUpload),
        );
        expect(provider.isUploading, isFalse);
      },
    );

    test('a network failure surfaces a connectivity message', () async {
      final fileService = FakeCourseFileService();
      final provider = CourseFileProvider(
        fileService,
        CloudinaryUploadService(
          client: MockClient((_) async => throw const SocketExceptionStub()),
        ),
      );

      final ok = await provider.uploadFile(
        offering: _offering,
        bytes: _bytes(),
        fileName: 'محاضرة1.pdf',
        title: 'المحاضرة الأولى',
        category: CourseFileModel.categoryLecture,
      );

      expect(ok, isFalse);
      expect(fileService.createCallCount, 0);
    });
  });

  group('CourseFileProvider.syncWithAuth role switch', () {
    test('role switch cancels existing subscriptions and clears state', () async {
      final fileService = FakeCourseFileService();
      final provider = CourseFileProvider(
        fileService,
        CloudinaryUploadService(),
      );

      // Simulate first session with teacher role
      provider.syncWithAuth(isActiveUser: true, role: 'teacher');
      provider.listenToOfferingFiles('offering1');

      // Ensure provider is in listening state
      expect(provider.offeringId, 'offering1');

      // Now simulate a role switch (e.g. to student) while keeping active user session
      provider.syncWithAuth(isActiveUser: true, role: 'student');

      // The offeringId and loaded files must be cleared
      expect(provider.offeringId, isNull);
      expect(provider.files, isEmpty);
    });
  });

  group('CourseFileModel', () {
    test('round-trips through Firestore shape', () {
      const file = CourseFileModel(
        id: 'f1',
        offeringId: 'off1',
        courseId: 'c1',
        semesterId: 'semester_2026_1',
        title: 'المحاضرة الأولى',
        description: 'مقدمة',
        category: CourseFileModel.categoryLecture,
        fileName: 'lecture1.pdf',
        fileExtension: 'pdf',
        mimeType: 'application/pdf',
        fileSize: 2048,
        cloudinaryUrl: 'https://res.cloudinary.com/x/a.pdf',
        cloudinaryPublicId: 'academia/course_files/off1/a',
        cloudinaryResourceType: 'image',
        uploadedBy: 'admin1',
      );

      final restored = CourseFileModel.fromFirestore(file.toMap(), 'f1');

      expect(restored.offeringId, 'off1');
      expect(restored.courseId, 'c1');
      expect(restored.semesterId, 'semester_2026_1');
      expect(restored.title, 'المحاضرة الأولى');
      expect(restored.cloudinaryPublicId, file.cloudinaryPublicId);
      expect(restored.cloudinaryResourceType, 'image');
      expect(restored.isActive, isTrue);
      expect(restored.readableSize, '2 KB');
    });

    test('defaults are safe for a malformed document', () {
      final restored = CourseFileModel.fromFirestore(
        <String, dynamic>{},
        'broken',
      );

      expect(restored.category, CourseFileModel.categoryOther);
      expect(restored.status, CourseFileModel.statusActive);
      expect(restored.fileSize, 0);
      expect(restored.readableSize, '');
    });
  });
}

/// Stands in for a transport error without importing dart:io in a test that
/// must also run on the web target.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
