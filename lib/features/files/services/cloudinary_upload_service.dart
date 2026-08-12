import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/cloudinary_config.dart';

class CloudinaryUploadException implements Exception {
  final String message;
  const CloudinaryUploadException(this.message);

  @override
  String toString() => message;
}

/// نتيجة رفع ناجح إلى Cloudinary.
///
/// لا تُخزَّن في Firestore كما هي؛ تُبنى منها البيانات الوصفية.
class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.resourceType,
    required this.format,
    required this.bytes,
  });

  final String secureUrl;
  final String publicId;
  final String resourceType;
  final String format;
  final int bytes;
}

/// رفع غير موقَّع إلى Cloudinary.
///
/// غير موقَّع بمعنى أنه يستعمل upload preset معلنًا فقط، بلا مفتاح سري.
/// لهذا السبب لا توجد هنا — ولن توجد — عملية حذف: الحذف يحتاج توقيعًا،
/// وتضمين المفتاح السري في التطبيق يعني كشفه لكل من يفكّ الحزمة.
class CloudinaryUploadService {
  final http.Client _client;

  CloudinaryUploadService({http.Client? client})
    : _client = client ?? http.Client();

  /// التحقق قبل الرفع.
  ///
  /// يُنفَّذ محليًا كي لا يُستهلك اتصال المستخدم في رفع سيرفضه الخادم،
  /// وكي تكون الرسالة عربية واضحة بدل خطأ HTTP خام.
  static void validate({required String fileName, required int sizeBytes}) {
    final extension = CloudinaryConfig.normalizeExtension(fileName);

    if (extension.isEmpty || !CloudinaryConfig.isAllowedExtension(extension)) {
      throw const CloudinaryUploadException(AppStrings.fileTypeNotAllowed);
    }
    if (sizeBytes <= 0) {
      throw const CloudinaryUploadException(AppStrings.fileEmptyError);
    }
    if (!CloudinaryConfig.isWithinSizeLimit(sizeBytes)) {
      throw const CloudinaryUploadException(AppStrings.fileTooLargeError);
    }
  }

  /// التحقق من الصورة الشخصية قبل الرفع.
  ///
  /// منفصل عن [validate]: حدود الصورة الشخصية أضيق (صيغ صور فقط، و5
  /// ميغابايت)، ورسائلها يجب أن تتحدث عن صورة لا عن ملف مساق.
  static void validateProfileImage({
    required String fileName,
    required int sizeBytes,
  }) {
    final extension = CloudinaryConfig.normalizeExtension(fileName);

    if (extension.isEmpty ||
        !CloudinaryConfig.isAllowedImageExtension(extension)) {
      throw const CloudinaryUploadException(
        AppStrings.profileImageTypeNotAllowed,
      );
    }
    if (sizeBytes <= 0) {
      throw const CloudinaryUploadException(AppStrings.profileImageEmpty);
    }
    if (!CloudinaryConfig.isWithinProfileImageSizeLimit(sizeBytes)) {
      throw const CloudinaryUploadException(AppStrings.profileImageTooLarge);
    }
  }

  /// رفع محتوى الملف. يعيد بيانات Cloudinary عند النجاح فقط.
  ///
  /// [bytes] محتوى الملف كاملًا: الحد الأقصى 10 ميغابايت يجعل تحميله في
  /// الذاكرة مقبولًا ويغني عن بثّ متدرّج.
  Future<CloudinaryUploadResult> upload({
    required List<int> bytes,
    required String fileName,
    required String offeringId,
  }) {
    validate(fileName: fileName, sizeBytes: bytes.length);

    return _send(
      bytes: bytes,
      fileName: fileName,
      uploadPreset: CloudinaryConfig.uploadPreset,
      folder: CloudinaryConfig.folderForOffering(offeringId),
    );
  }

  /// رفع صورة شخصية لمستخدم واحد.
  ///
  /// يستعمل preset الصور ومجلد المستخدم، ويشترك مع [upload] في النقل نفسه:
  /// طلب multipart بلا مفتاح سري، ولا حذف.
  Future<CloudinaryUploadResult> uploadProfileImage({
    required List<int> bytes,
    required String fileName,
    required String uid,
  }) {
    validateProfileImage(fileName: fileName, sizeBytes: bytes.length);

    return _send(
      bytes: bytes,
      fileName: fileName,
      uploadPreset: CloudinaryConfig.profileImageUploadPreset,
      folder: CloudinaryConfig.folderForProfileImage(uid),
    );
  }

  /// النقل المشترك: preset والمجلد وحدهما ما يختلف بين الاستعمالين.
  Future<CloudinaryUploadResult> _send({
    required List<int> bytes,
    required String fileName,
    required String uploadPreset,
    required String folder,
  }) async {
    final request = http.MultipartRequest('POST', CloudinaryConfig.uploadUri())
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

    http.Response response;
    try {
      final streamed = await _client.send(request);
      response = await http.Response.fromStream(streamed);
    } catch (e) {
      throw const CloudinaryUploadException(AppStrings.fileUploadNetworkError);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CloudinaryUploadException(_messageFor(response));
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw const CloudinaryUploadException(AppStrings.fileUploadError);
    }

    final secureUrl = body['secure_url'] as String?;
    final publicId = body['public_id'] as String?;

    // بدون هذين لا يمكن عرض الملف لاحقًا ولا التعرّف عليه؛ نعدّ الرفع فاشلًا
    // بدل كتابة مستند بيانات وصفية معطوب.
    if (secureUrl == null ||
        secureUrl.isEmpty ||
        publicId == null ||
        publicId.isEmpty) {
      throw const CloudinaryUploadException(AppStrings.fileUploadError);
    }

    return CloudinaryUploadResult(
      secureUrl: secureUrl,
      publicId: publicId,
      resourceType: body['resource_type'] as String? ?? 'raw',
      format: (body['format'] as String? ?? '').toLowerCase(),
      bytes: (body['bytes'] as num?)?.toInt() ?? bytes.length,
    );
  }

  /// رسالة Cloudinary إن وُجدت، وإلا رسالة عامة.
  String _messageFor(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final error = body['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return '${AppStrings.fileUploadError}: $message';
          }
        }
      }
    } catch (_) {
      // يسقط إلى الرسالة العامة أدناه.
    }
    return AppStrings.fileUploadError;
  }

  void dispose() => _client.close();
}
