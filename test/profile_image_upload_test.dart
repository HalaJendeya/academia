import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/core/constants/cloudinary_config.dart';
import 'package:academia/core/services/auth_service.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/files/services/cloudinary_upload_service.dart';
import 'package:academia/features/profile/models/student_profile.dart';
import 'package:academia/features/profile/providers/profile_provider.dart';
import 'package:academia/features/profile/screens/edit_profile_screen.dart';
import 'package:academia/features/profile/services/profile_image_picker.dart';
import 'package:academia/features/profile/services/profile_service.dart';

const _uid = 'student_uid_1';

const _profile = StudentProfile(
  uid: _uid,
  fullName: 'حلا جندية',
  studentId: '2021001',
  email: 's@test.com',
  major: 'هندسة البرمجيات',
  academicLevel: 4,
);

const _uploadedUrl =
    'https://res.cloudinary.com/xmrgiypo/image/upload/v1/avatar.jpg';

/// Content is irrelevant; size is not. 65 keeps the multipart body decodable
/// so a test can assert on the preset and folder fields.
List<int> _bytes([int length = 4096]) => List<int>.filled(length, 65);

String _cloudinarySuccessBody() => jsonEncode({
  'secure_url': _uploadedUrl,
  'public_id': 'academia/profile_images/$_uid/avatar',
  'resource_type': 'image',
  'format': 'jpg',
  'bytes': 4096,
});

/// Records what the profile layer was asked to write, and can be made to fail
/// so the "uploaded but not recorded" path is exercised.
class FakeProfileService implements ProfileService {
  FakeProfileService({this.shouldFailPhotoUpdate = false});

  final bool shouldFailPhotoUpdate;

  int photoUpdateCallCount = 0;
  String? savedPhotoUrl;

  @override
  String? get currentUid => _uid;

  @override
  Future<StudentProfile> getCurrentProfile() async => _profile;

  @override
  Future<void> updateProfilePhoto(String photoUrl) async {
    photoUpdateCallCount++;
    if (shouldFailPhotoUpdate) {
      throw const ProfileException(
        AppStrings.profileImageSavedButProfileNotUpdated,
      );
    }
    savedPhotoUrl = photoUrl;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthService {
  FakeAuthService(this.profile);

  final AppUserModel profile;

  @override
  Future<AppUserModel?> getCurrentUserProfile() async => profile;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mirrors AuthProvider's surface for the widget tree, and records the refresh
/// the screen is expected to trigger after a successful upload.
class RecordingAuthProvider extends ChangeNotifier implements AuthProvider {
  String? appliedPhotoUrl;
  int applyCallCount = 0;

  @override
  void applyPhotoUrl(String? photoUrl) {
    applyCallCount++;
    appliedPhotoUrl = photoUrl;
    notifyListeners();
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

Future<ProfileProvider> _loadedProvider(
  FakeProfileService service,
  CloudinaryUploadService uploadService,
) async {
  final provider = ProfileProvider(service, uploadService);
  await provider.loadProfile();
  return provider;
}

Widget _wrap({
  required ProfileProvider profileProvider,
  required RecordingAuthProvider authProvider,
  ProfileImagePickerFn? picker,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ],
    child: MaterialApp(
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: EditProfileScreen(picker: picker),
      ),
    ),
  );
}

void main() {
  group('CloudinaryConfig — profile images', () {
    test('profile images use a preset separate from course files', () {
      expect(
        CloudinaryConfig.profileImageUploadPreset,
        isNot(CloudinaryConfig.uploadPreset),
      );
      expect(
        CloudinaryConfig.profileImageUploadPreset,
        'academia_profile_images',
      );
    });

    test('only real image formats are accepted', () {
      for (final extension in ['jpg', 'jpeg', 'png', 'webp']) {
        expect(CloudinaryConfig.isAllowedImageExtension(extension), isTrue);
      }
      // Documents are valid course files but are not profile pictures.
      for (final extension in ['pdf', 'docx', 'txt', 'exe']) {
        expect(CloudinaryConfig.isAllowedImageExtension(extension), isFalse);
      }
    });

    test('the size limit is 5 MB and rejects empty content', () {
      expect(CloudinaryConfig.maxProfileImageSizeBytes, 5 * 1024 * 1024);
      expect(CloudinaryConfig.isWithinProfileImageSizeLimit(0), isFalse);
      expect(
        CloudinaryConfig.isWithinProfileImageSizeLimit(5 * 1024 * 1024),
        isTrue,
      );
      expect(
        CloudinaryConfig.isWithinProfileImageSizeLimit(5 * 1024 * 1024 + 1),
        isFalse,
      );
    });

    test('the folder is scoped to one user', () {
      expect(
        CloudinaryConfig.folderForProfileImage(_uid),
        'academia/profile_images/$_uid',
      );
    });
  });

  group('CloudinaryUploadService.validateProfileImage', () {
    test('accepts every allowed image extension', () {
      for (final extension in CloudinaryConfig.allowedImageExtensions) {
        expect(
          () => CloudinaryUploadService.validateProfileImage(
            fileName: 'avatar.$extension',
            sizeBytes: 1024,
          ),
          returnsNormally,
          reason: '.$extension should be allowed',
        );
      }
    });

    test('rejects a document even though course files allow it', () {
      expect(
        () => CloudinaryUploadService.validateProfileImage(
          fileName: 'notes.pdf',
          sizeBytes: 1024,
        ),
        throwsA(
          isA<CloudinaryUploadException>().having(
            (e) => e.message,
            'message',
            AppStrings.profileImageTypeNotAllowed,
          ),
        ),
      );
    });

    test('rejects an image with no extension', () {
      expect(
        () => CloudinaryUploadService.validateProfileImage(
          fileName: 'avatar',
          sizeBytes: 1024,
        ),
        throwsA(isA<CloudinaryUploadException>()),
      );
    });
  });

  group('resolveProfileImageFileName', () {
    test('keeps a name that already carries an extension', () {
      expect(
        resolveProfileImageFileName('avatar.png', 'image/png'),
        'avatar.png',
      );
    });

    test('falls back to the mime type when the name has none', () {
      expect(resolveProfileImageFileName('avatar', 'image/jpeg'), 'avatar.jpg');
      expect(resolveProfileImageFileName('avatar', 'image/webp'), 'avatar.webp');
    });

    test('leaves the name alone when the mime type is unusable', () {
      expect(resolveProfileImageFileName('avatar', null), 'avatar');
    });
  });

  group('ProfileProvider.uploadProfilePicture — ordering', () {
    test('an unsupported image never reaches Cloudinary or Firestore', () async {
      final service = FakeProfileService();
      var cloudinaryCalled = false;

      final provider = await _loadedProvider(
        service,
        _uploadServiceReturning((_) {
          cloudinaryCalled = true;
          return http.Response(_cloudinarySuccessBody(), 200);
        }),
      );

      final url = await provider.uploadProfilePicture(
        bytes: _bytes(),
        fileName: 'resume.pdf',
      );

      expect(url, isNull);
      expect(cloudinaryCalled, isFalse);
      expect(service.photoUpdateCallCount, 0);
      expect(provider.errorMessage, AppStrings.profileImageTypeNotAllowed);
      expect(provider.profile!.photoUrl, isNull);
      expect(provider.isUploadingPhoto, isFalse);
    });

    test('an oversized image never reaches Cloudinary or Firestore', () async {
      final service = FakeProfileService();
      var cloudinaryCalled = false;

      final provider = await _loadedProvider(
        service,
        _uploadServiceReturning((_) {
          cloudinaryCalled = true;
          return http.Response(_cloudinarySuccessBody(), 200);
        }),
      );

      final url = await provider.uploadProfilePicture(
        bytes: _bytes(CloudinaryConfig.maxProfileImageSizeBytes + 1),
        fileName: 'huge.jpg',
      );

      expect(url, isNull);
      expect(cloudinaryCalled, isFalse);
      expect(service.photoUpdateCallCount, 0);
      expect(provider.errorMessage, AppStrings.profileImageTooLarge);
    });

    test('an empty image never reaches Cloudinary or Firestore', () async {
      final service = FakeProfileService();
      var cloudinaryCalled = false;

      final provider = await _loadedProvider(
        service,
        _uploadServiceReturning((_) {
          cloudinaryCalled = true;
          return http.Response(_cloudinarySuccessBody(), 200);
        }),
      );

      final url = await provider.uploadProfilePicture(
        bytes: const <int>[],
        fileName: 'empty.jpg',
      );

      expect(url, isNull);
      expect(cloudinaryCalled, isFalse);
      expect(service.photoUpdateCallCount, 0);
      expect(provider.errorMessage, AppStrings.profileImageEmpty);
    });

    test(
      'a successful upload writes the returned URL to the user document',
      () async {
        final service = FakeProfileService();
        String? sentBody;

        final provider = await _loadedProvider(
          service,
          _uploadServiceReturning((request) {
            sentBody = (request as http.Request).body;
            return http.Response(_cloudinarySuccessBody(), 200);
          }),
        );

        final url = await provider.uploadProfilePicture(
          bytes: _bytes(),
          fileName: 'avatar.jpg',
        );

        expect(url, _uploadedUrl);
        expect(provider.errorMessage, isNull);
        expect(provider.isUploadingPhoto, isFalse);

        // The image preset and the user-scoped folder, not the course-files ones.
        expect(sentBody, contains(CloudinaryConfig.profileImageUploadPreset));
        expect(
          sentBody,
          contains(CloudinaryConfig.folderForProfileImage(_uid)),
        );

        // Firestore receives exactly what Cloudinary returned.
        expect(service.photoUpdateCallCount, 1);
        expect(service.savedPhotoUrl, _uploadedUrl);

        // And the in-memory profile shows it immediately.
        expect(provider.profile!.photoUrl, _uploadedUrl);
      },
    );

    test('a failed Cloudinary upload writes nothing and keeps the old image', () async {
      final service = FakeProfileService();

      final provider = await _loadedProvider(
        service,
        _uploadServiceReturning(
          (_) => http.Response(
            jsonEncode({
              'error': {'message': 'Upload preset not found'},
            }),
            400,
          ),
        ),
      );

      final url = await provider.uploadProfilePicture(
        bytes: _bytes(),
        fileName: 'avatar.jpg',
      );

      expect(url, isNull);
      expect(service.photoUpdateCallCount, 0);
      expect(provider.profile!.photoUrl, isNull);
      expect(provider.errorMessage, isNotNull);
      expect(provider.isUploadingPhoto, isFalse);
    });

    test(
      'a Firestore failure after a successful upload is reported as such',
      () async {
        final service = FakeProfileService(shouldFailPhotoUpdate: true);

        final provider = await _loadedProvider(
          service,
          _uploadServiceReturning(
            (_) => http.Response(_cloudinarySuccessBody(), 200),
          ),
        );

        final url = await provider.uploadProfilePicture(
          bytes: _bytes(),
          fileName: 'avatar.jpg',
        );

        // The upload happened, so the message must say so rather than claim
        // a generic upload failure.
        expect(url, isNull);
        expect(service.photoUpdateCallCount, 1);
        expect(
          provider.errorMessage,
          AppStrings.profileImageSavedButProfileNotUpdated,
        );

        // The old image survives — nothing was recorded.
        expect(provider.profile!.photoUrl, isNull);
        expect(provider.isUploadingPhoto, isFalse);
      },
    );

    test('a second upload while one is in flight is ignored', () async {
      final service = FakeProfileService();

      final provider = await _loadedProvider(
        service,
        _uploadServiceReturning(
          (_) => http.Response(_cloudinarySuccessBody(), 200),
        ),
      );

      final first = provider.uploadProfilePicture(
        bytes: _bytes(),
        fileName: 'avatar.jpg',
      );
      final second = provider.uploadProfilePicture(
        bytes: _bytes(),
        fileName: 'avatar.jpg',
      );

      expect(await second, isNull);
      expect(await first, _uploadedUrl);
      expect(service.photoUpdateCallCount, 1);
    });
  });

  group('AuthProvider photo refresh', () {
    test('applyPhotoUrl replaces the loaded model without a reload', () async {
      const model = AppUserModel(
        uid: _uid,
        fullName: 'حلا جندية',
        email: 's@test.com',
        role: UserRole.student,
        status: 'active',
        emailVerified: true,
        onboardingCompleted: true,
        onboardingStatus: 'completed',
      );

      final auth = AuthProvider(authService: FakeAuthService(model));
      await auth.loadCurrentUserProfile();

      expect(auth.currentUserProfile!.photoUrl, isNull);

      var notified = 0;
      auth.addListener(() => notified++);

      auth.applyPhotoUrl(_uploadedUrl);

      expect(auth.currentUserProfile!.photoUrl, _uploadedUrl);
      // Everything else on the model survives the replacement.
      expect(auth.currentUserProfile!.fullName, 'حلا جندية');
      expect(auth.currentUserProfile!.role, UserRole.student);
      expect(notified, 1);
    });

    test('applyPhotoUrl is a no-op when no profile is loaded', () {
      final auth = AuthProvider(
        authService: FakeAuthService(
          const AppUserModel(
            uid: _uid,
            fullName: '',
            email: '',
            role: UserRole.student,
            status: 'active',
            emailVerified: true,
            onboardingCompleted: true,
            onboardingStatus: 'completed',
          ),
        ),
      );

      auth.applyPhotoUrl(_uploadedUrl);

      expect(auth.currentUserProfile, isNull);
    });
  });

  group('AppUserModel.photoUrl', () {
    test('copyWith carries the photo URL', () {
      const model = AppUserModel(
        uid: _uid,
        fullName: 'حلا جندية',
        email: 's@test.com',
        role: UserRole.student,
        status: 'active',
        emailVerified: true,
        onboardingCompleted: true,
        onboardingStatus: 'completed',
      );

      expect(model.copyWith(photoUrl: _uploadedUrl).photoUrl, _uploadedUrl);
      expect(model.toMap().containsKey('photoUrl'), isFalse);
      expect(
        model.copyWith(photoUrl: _uploadedUrl).toMap()['photoUrl'],
        _uploadedUrl,
      );
    });
  });

  group('EditProfileScreen — avatar', () {
    testWidgets('a cancelled picker uploads nothing and shows no error', (
      tester,
    ) async {
      final service = FakeProfileService();
      var cloudinaryCalled = false;

      final provider = await _loadedProvider(
        service,
        _uploadServiceReturning((_) {
          cloudinaryCalled = true;
          return http.Response(_cloudinarySuccessBody(), 200);
        }),
      );
      final auth = RecordingAuthProvider();

      await tester.pumpWidget(
        _wrap(
          profileProvider: provider,
          authProvider: auth,
          picker: () async => null,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.changeProfilePicture));
      await tester.pumpAndSettle();

      expect(cloudinaryCalled, isFalse);
      expect(service.photoUpdateCallCount, 0);
      expect(auth.applyCallCount, 0);
      expect(provider.errorMessage, isNull);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a rejected image surfaces an Arabic error and keeps the avatar', (
      tester,
    ) async {
      final service = FakeProfileService();
      var cloudinaryCalled = false;

      final provider = await _loadedProvider(
        service,
        _uploadServiceReturning((_) {
          cloudinaryCalled = true;
          return http.Response(_cloudinarySuccessBody(), 200);
        }),
      );
      final auth = RecordingAuthProvider();

      await tester.pumpWidget(
        _wrap(
          profileProvider: provider,
          authProvider: auth,
          picker: () async =>
              PickedProfileImage(fileName: 'notes.pdf', bytes: _bytes()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.changeProfilePicture));
      await tester.pumpAndSettle();

      expect(cloudinaryCalled, isFalse);
      expect(service.photoUpdateCallCount, 0);
      expect(auth.applyCallCount, 0);
      expect(find.text(AppStrings.profileImageTypeNotAllowed), findsOneWidget);

      // The default avatar is still what is shown.
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('with no stored photo the default avatar is used', (
      tester,
    ) async {
      final provider = await _loadedProvider(
        FakeProfileService(),
        _uploadServiceReturning(
          (_) => http.Response(_cloudinarySuccessBody(), 200),
        ),
      );

      await tester.pumpWidget(
        _wrap(
          profileProvider: provider,
          authProvider: RecordingAuthProvider(),
          picker: () async => null,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundImage, isNull);
    });
  });
}
