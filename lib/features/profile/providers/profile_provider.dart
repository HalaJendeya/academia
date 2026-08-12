import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../files/services/cloudinary_upload_service.dart';
import '../models/student_profile.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService;

  /// خدمة الرفع نفسها التي ترفع ملفات المساقات.
  ///
  /// معمارية تخزين واحدة للتطبيق كله: Cloudinary للملف الثنائي و Firestore
  /// للبيانات الوصفية. الصورة الشخصية تختلف في preset والمجلد فقط.
  final CloudinaryUploadService _uploadService;

  ProfileProvider(this._profileService, this._uploadService);

  StudentProfile? _profile;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;
  String? _loadedUserId;

  StudentProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  /// رفع الصورة جارٍ. حالة غير محدَّدة عمدًا: الرفع عبر multipart لا يوفّر
  /// تقدّمًا حقيقيًا، ونسبة مُختلقة توهم بدقة لا نملكها.
  bool get isUploadingPhoto => _isUploadingPhoto;

  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearProfile() {
    _profile = null;
    _errorMessage = null;
    _isLoading = false;
    _isSaving = false;
    _isUploadingPhoto = false;
    _loadedUserId = null;
    notifyListeners();
  }

  Future<void> loadProfile({bool forceRefresh = false}) async {
    final currentUid = _profileService.currentUid;

    // Account switch check
    if (currentUid != _loadedUserId) {
      _profile = null;
      _errorMessage = null;
      _loadedUserId = currentUid;
    } else if (_profile != null && !forceRefresh) {
      // Avoid duplicate fetches if profile is already loaded
      return;
    }

    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _profileService.getCurrentProfile();
      _loadedUserId = currentUid;
    } on ProfileException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = AppStrings.profileLoadError;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    String? major,
    int? academicLevel,
  }) async {
    if (_isSaving) return false;

    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = AppStrings.fullNameRequired;
      notifyListeners();
      return false;
    }
    if (trimmedName.length < 2) {
      _errorMessage = AppStrings.fullNameTooShort;
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileService.updateProfile(
        fullName: trimmedName,
        major: major,
        academicLevel: academicLevel,
      );

      // Normalize optional values locally
      final normalizedMajor = (major != null && major.trim().isNotEmpty)
          ? major.trim()
          : null;
      final normalizedAcademicLevel = (academicLevel != null && academicLevel > 0)
          ? academicLevel
          : null;

      // Immediate local cache update to prevent duplicate fetches
      _profile = _profile?.copyWith(
        fullName: trimmedName,
        major: normalizedMajor ?? _profile?.major,
        academicLevel: normalizedAcademicLevel ?? _profile?.academicLevel,
      );

      notifyListeners();
      return true;
    } on ProfileException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.profileUpdateError;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// رفع صورة شخصية جديدة وربطها بالحساب.
  ///
  /// الترتيب مقصود: Cloudinary أولًا، ثم Firestore. فشل الرفع يعني ألا
  /// يُكتب أي رابط، فتبقى الصورة القديمة كما هي.
  ///
  /// إن نجح الرفع وفشلت الكتابة، تبقى الصورة القديمة معروضة وتُبلَّغ
  /// الحالة صراحةً. لا نحاول حذف النسخة من Cloudinary: الحذف يتطلب توقيعًا
  /// بمفتاح سري لا مكان له في تطبيق العميل.
  ///
  /// يعيد رابط الصورة عند النجاح، و null عند أي فشل، ليستطيع النداء تحديث
  /// نموذج المستخدم في AuthProvider دون قراءة إضافية.
  Future<String?> uploadProfilePicture({
    required List<int> bytes,
    required String fileName,
  }) async {
    if (_isUploadingPhoto) return null;

    final uid = _profile?.uid;
    if (uid == null || uid.isEmpty) {
      _errorMessage = AppStrings.profileImageNoProfileLoaded;
      notifyListeners();
      return null;
    }

    /*
     * التحقق قبل أي طلب شبكة: صورة مرفوضة لصيغتها أو حجمها يجب ألا تستهلك
     * اتصال الطالبة، ورسالة الرفض تصلها فورًا بالعربية.
     */
    try {
      CloudinaryUploadService.validateProfileImage(
        fileName: fileName,
        sizeBytes: bytes.length,
      );
    } on CloudinaryUploadException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    }

    _isUploadingPhoto = true;
    _errorMessage = null;
    notifyListeners();

    CloudinaryUploadResult uploadResult;
    try {
      uploadResult = await _uploadService.uploadProfileImage(
        bytes: bytes,
        fileName: fileName,
        uid: uid,
      );
    } on CloudinaryUploadException catch (e) {
      _errorMessage = e.message;
      _isUploadingPhoto = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = AppStrings.profileImageUploadError;
      _isUploadingPhoto = false;
      notifyListeners();
      return null;
    }

    // من هنا فصاعدًا الصورة موجودة فعلًا في Cloudinary.
    try {
      await _profileService.updateProfilePhoto(uploadResult.secureUrl);

      _profile = _profile?.copyWith(photoUrl: uploadResult.secureUrl);
      return uploadResult.secureUrl;
    } on ProfileException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = AppStrings.profileImageSavedButProfileNotUpdated;
      return null;
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }
}
