import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../courses/models/course_offering_model.dart';
import '../models/course_file_model.dart';
import '../services/cloudinary_upload_service.dart';
import '../services/course_file_service.dart';

/// المزوّد الوحيد لملفات المساقات — للمشرف وللطالب معًا.
///
/// كل قراءة مقيَّدة بطرح: الاستعلام دائمًا `offeringId == X`. لا يوجد
/// استعلام عام على courseFiles، ولا يمكن أن يوجد: قاعدة القراءة تمنح
/// الطالب حق قراءة ملف طرح مسجَّل فيه فقط، فاستعلام غير مقيَّد يُرفض كله.
///
/// من هنا شكل الاستماع: طرح واحد لشاشة تفاصيل المساق وشاشات المشرف،
/// وعدة طروح — مستمع لكل طرح مصرَّح به — لشاشة "كل الملفات". الدمج يتم في
/// الذاكرة لا في الاستعلام.
///
/// [activeFileCount] استثناء مقصود ومحدود: لوحة المشرف تحتاج رقمًا واحدًا
/// لا قائمة، ويُقرأ باستعلام تجميعي منفصل لا يمسّ [files] ولا يُحمّل أي
/// مستند.
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

  /// مستمع لكل طرح مصرَّح به. طرح واحد في معظم الشاشات، وعدة طروح في
  /// شاشة "كل الملفات".
  final Map<String, StreamSubscription<List<CourseFileModel>>> _subscriptions =
      {};

  /// نتائج كل طرح على حدة، تُدمج في [_files] بعد كل تحديث.
  final Map<String, List<CourseFileModel>> _filesByOffering = {};

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

  /// ملفات طرح واحد: شاشة تفاصيل المساق للطالب، وشاشات الملفات للمشرف.
  void listenToOfferingFiles(String offeringId) {
    if (_offeringId == offeringId &&
        _subscriptions.length == 1 &&
        _subscriptions.containsKey(offeringId)) {
      return;
    }

    stopListening();
    _offeringId = offeringId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscribe(offeringId);
  }

  /// ملفات عدة طروح مصرَّح بها — شاشة "كل الملفات" للطالب.
  ///
  /// [offeringIds] تأتي من تسجيلات الطالب نفسها (الحالية والسابقة). لا
  /// يُشتق شيء هنا: ما لا يرد في القائمة لا يُستمع إليه أصلًا، والتسجيل
  /// المُزال لا ينتج معرّف طرح فلا ملفات له. وحتى لو ورد معرّف غير مصرَّح
  /// به، فإن القاعدة ترفض استعلامه ويظل الطرح فارغًا.
  void listenToOfferingsFiles(List<String> offeringIds) {
    final wanted = offeringIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    // نفس المجموعة: لا داعي لإعادة بناء المستمعين عند كل إعادة بناء للشاشة.
    if (wanted.length == _subscriptions.length &&
        wanted.every(_subscriptions.containsKey)) {
      return;
    }

    // نلغي ما لم يعد مصرَّحًا به فقط، ونبقي المستمعين القائمين كما هم.
    for (final id in _subscriptions.keys.toList()) {
      if (wanted.contains(id)) continue;
      _subscriptions.remove(id)?.cancel();
      _filesByOffering.remove(id);
    }

    _offeringId = null;

    if (wanted.isEmpty) {
      _isLoading = false;
      _files = const <CourseFileModel>[];
      _errorMessage = null;
      notifyListeners();
      return;
    }

    /*
     * إعادة الدمج فورًا بعد الإلغاء.
     *
     * بدونها تبقى ملفات طرح لم يعد مصرَّحًا به معروضةً حتى يبثّ طرح آخر
     * تحديثًا — أي أن سحب الصلاحية لا يُخفي الملفات مباشرة.
     */
    _mergeFiles();

    _isLoading = _filesByOffering.isEmpty;
    _errorMessage = null;
    notifyListeners();

    for (final id in wanted) {
      if (_subscriptions.containsKey(id)) continue;
      _subscribe(id);
    }
  }

  void _subscribe(String offeringId) {
    _subscriptions[offeringId] =
        _fileService.watchOfferingFiles(offeringId).listen(
          (data) {
            _filesByOffering[offeringId] = data;
            _mergeFiles();
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            /*
             * فشل طرح واحد لا يُفرغ الباقي: الطالب قد يكون مصرَّحًا له
             * بخمسة طروح وممنوعًا من سادس، وإخفاء الخمسة عقابًا على السادس
             * خسارة بلا سبب.
             */
            _filesByOffering[offeringId] = const <CourseFileModel>[];
            _mergeFiles();
            _isLoading = false;
            if (_files.isEmpty) _errorMessage = AppStrings.fileLoadError;
            notifyListeners();
          },
        );
  }

  /// الأحدث أولًا عبر كل الطروح. الترتيب محليًا: الاستعلامات مساواة فقط.
  void _mergeFiles() {
    final merged = <CourseFileModel>[
      for (final list in _filesByOffering.values) ...list,
    ];
    merged.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    _files = merged;
  }

  /// يتبع حالة المصادقة. يُستدعى من ProxyProvider في app_providers.
  ///
  /// الشرط هنا "مستخدم نشط" لا "مشرف": هذا المزوّد يخدم الطالب أيضًا،
  /// ومسحه لكل غير مشرف كان يفرغ ملفات الطالب فور تحميلها. ما يجب أن يوقف
  /// الاستماع هو الخروج من الحساب، وهو ما ينتج PERMISSION_DENIED.
  void syncWithAuth({required bool isActiveUser, String? role}) {
    if (isActiveUser) {
      if (_hadSession && _lastRole != null && _lastRole != role) {
        // Role switched while keeping session active (e.g. from teacher to student)
        // We MUST cancel current file listeners to avoid leaking file subscriptions
        // that the new role might not be authorized to read.
        stopListening();
        _offeringId = null;
        _files = const <CourseFileModel>[];
        _activeFileCount = null;
        _isLoading = false;
        _errorMessage = null;
      }
      _hadSession = true;
      _lastRole = role;
      return;
    }

    final hadState =
        _hadSession || _subscriptions.isNotEmpty || _files.isNotEmpty;
    _hadSession = false;
    _lastRole = null;
    if (!hadState) return;

    stopListening();
    _offeringId = null;
    _files = const <CourseFileModel>[];
    _activeFileCount = null;
    _isLoading = false;
    _errorMessage = null;

    scheduleMicrotask(notifyListeners);
  }

  bool _hadSession = false;
  String? _lastRole;

  void stopListening() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _filesByOffering.clear();
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
