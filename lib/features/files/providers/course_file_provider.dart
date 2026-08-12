import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../courses/models/course_offering_model.dart';
import '../models/course_file_model.dart';
import '../services/cloudinary_upload_service.dart';
import '../services/course_file_service.dart';

/// ملفات طرح واحد في كل مرة، وعدّاد إجمالي منفصل للوحة المشرف.
///
/// القائمة دائمًا مقيَّدة بطرح: "ما ملفات هذا الطرح؟" هو السؤال الذي تطرحه
/// شاشات الملفات، ولا معنى لقائمة ملفات عابرة للفصول.
///
/// [activeFileCount] استثناء مقصود ومحدود: لوحة المشرف تحتاج رقمًا واحدًا
/// لا قائمة، ويُقرأ باستعلام تجميعي منفصل لا يمسّ [files] ولا يُحمّل أي
/// مستند. لذلك لا يمسحه [clearFiles]: الخروج من شاشة ملفات طرح لا يعني أن
/// إجمالي ملفات النظام تغيّر.
class CourseFileProvider extends ChangeNotifier {
  final CourseFileService _fileService;
  final CloudinaryUploadService _uploadService;

  CourseFileProvider(this._fileService, this._uploadService);

  List<CourseFileModel> _files = [];
  String? _offeringId;

  bool _isLoading = false;
  bool _isUploading = false;
  bool _isSaving = false;
  String? _errorMessage;

  int? _activeFileCount;
  bool _isLoadingActiveFileCount = false;

  StreamSubscription<List<CourseFileModel>>? _subscription;

  List<CourseFileModel> get files => _files;

  /// الملفات النشطة وحدها، وهي ما يُعرض للطالب.
  List<CourseFileModel> get activeFiles =>
      _files.where((file) => file.isActive).toList();

  String? get offeringId => _offeringId;

  bool get isLoading => _isLoading;

  /// الرفع جارٍ. حالة غير محدَّدة عمدًا: الرفع عبر multipart لا يوفّر تقدّمًا
  /// حقيقيًا هنا، وشريط نسبة مُختلق يوهم المستخدم بدقة لا نملكها.
  bool get isUploading => _isUploading;

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  /// عدد الملفات النشطة في النظام كله، أو null إن لم يُقرأ بعد أو فشلت
  /// قراءته.
  ///
  /// null ليس صفرًا: الصفر يعني "لا ملفات"، وعرضه عند فشل القراءة رقمٌ
  /// مختلق. الواجهة تعرض شرطة مكانه.
  int? get activeFileCount => _activeFileCount;

  bool get isLoadingActiveFileCount => _isLoadingActiveFileCount;

  /// قراءة واحدة محدودة للعدّاد. تُستدعى عند فتح لوحة المشرف.
  Future<void> loadActiveFileCount() async {
    if (_isLoadingActiveFileCount) return;

    _isLoadingActiveFileCount = true;
    notifyListeners();

    try {
      _activeFileCount = await _fileService.getActiveFileCount();
    } catch (e) {
      // لا رسالة خطأ في errorMessage: ذاك يخص قائمة ملفات الطرح، وفشل
      // عدّاد إحصائي لا يجب أن يظهر كخطأ في شاشة الملفات.
      _activeFileCount = null;
    } finally {
      _isLoadingActiveFileCount = false;
      notifyListeners();
    }
  }

  List<CourseFileModel> filesByCategory(String category) =>
      _files.where((file) => file.category == category).toList();

  void listenToOfferingFiles(String offeringId) {
    if (_offeringId == offeringId && _subscription != null) return;

    stopListening();
    _offeringId = offeringId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _fileService.watchOfferingFiles(offeringId).listen(
      (data) {
        _files = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = AppStrings.fileLoadError;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void clearFiles() {
    stopListening();
    _offeringId = null;
    _files = const <CourseFileModel>[];
    _errorMessage = null;
    notifyListeners();
  }

  /// رفع ملف لطرح مساق.
  ///
  /// الطرح يُمرَّر كاملًا لا كثلاثة معرّفات: offeringId و courseId و
  /// semesterId تُشتقّ منه هنا، فلا تستطيع الواجهة تركيب ملف ينسب مساقًا
  /// إلى فصل لا ينتمي إليه.
  ///
  /// الترتيب مقصود: Cloudinary أولًا، ثم Firestore. فشل الرفع يعني ألا
  /// يُكتب أي مستند إطلاقًا.
  Future<bool> uploadFile({
    required CourseOfferingModel offering,
    required List<int> bytes,
    required String fileName,
    required String title,
    required String category,
    String description = '',
    String mimeType = '',
  }) async {
    if (_isUploading) return false;

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    CloudinaryUploadResult uploadResult;
    try {
      uploadResult = await _uploadService.upload(
        bytes: bytes,
        fileName: fileName,
        offeringId: offering.id,
      );
    } on CloudinaryUploadException catch (e) {
      _errorMessage = e.message;
      _isUploading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = AppStrings.fileUploadError;
      _isUploading = false;
      notifyListeners();
      return false;
    }

    // من هنا فصاعدًا الملف موجود فعلًا في Cloudinary.
    try {
      final file = CourseFileModel(
        id: '',
        offeringId: offering.id,
        courseId: offering.courseId,
        semesterId: offering.semesterId,
        title: title.trim(),
        description: description.trim(),
        category: category,
        fileName: fileName,
        fileExtension: _extensionOf(fileName, uploadResult.format),
        mimeType: mimeType,
        fileSize: uploadResult.bytes,
        cloudinaryUrl: uploadResult.secureUrl,
        cloudinaryPublicId: uploadResult.publicId,
        cloudinaryResourceType: uploadResult.resourceType,
        uploadedBy: '',
        status: CourseFileModel.statusActive,
      );

      await _fileService.createFileMetadata(file);
      return true;
    } on CourseFileException catch (e) {
      /*
       * الرفع نجح والكتابة فشلت: الملف موجود في التخزين ولا يظهر في
       * التطبيق. لا نحاول حذفه من Cloudinary — الحذف يتطلب توقيعًا بمفتاح
       * سري لا مكان له في تطبيق العميل. نُبلغ بوضوح بدل الصمت.
       */
      _errorMessage = '${AppStrings.fileMetadataFailedAfterUpload} (${e.message})';
      return false;
    } catch (e) {
      _errorMessage = AppStrings.fileMetadataFailedAfterUpload;
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// الامتداد من اسم الملف، وإلا من صيغة Cloudinary.
  String _extensionOf(String fileName, String cloudinaryFormat) {
    final fromName = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    return fromName.isNotEmpty ? fromName : cloudinaryFormat;
  }

  Future<bool> updateFileMetadata(CourseFileModel file) {
    return _runWrite(() => _fileService.updateFileMetadata(file));
  }

  Future<bool> archiveFile(String fileId) {
    return _runWrite(() => _fileService.archiveFile(fileId));
  }

  Future<bool> _runWrite(Future<void> Function() action) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on CourseFileException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.fileSaveError;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
