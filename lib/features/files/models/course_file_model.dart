import 'package:cloud_firestore/cloud_firestore.dart';

/// بيانات ملف مرفوع لطرح مساق.
///
/// الملف الثنائي نفسه في Cloudinary؛ هذا المستند هو البيانات الوصفية في
/// Firestore. الملف يخص طرحًا (مساق × فصل × شعبة) لا مساقًا دائمًا: مادة
/// الفصل الحالي ليست بالضرورة مادة فصل سابق، ونسخها تلقائيًا بين الفصول
/// يفترض ما لا يصح افتراضه.
///
/// courseId و semesterId منسوخان من الطرح للاستعلام والعرض، ويُشتقّان دائمًا
/// من مستند الطرح لا من إدخال المستخدم.
class CourseFileModel {
  final String id;

  final String offeringId;
  final String courseId;
  final String semesterId;

  final String title;
  final String description;
  final String category;

  final String fileName;
  final String fileExtension;
  final String mimeType;
  final int fileSize;

  final String cloudinaryUrl;
  final String cloudinaryPublicId;

  /// ما أعادته Cloudinary فعلًا: image أو raw أو video.
  final String cloudinaryResourceType;

  final String uploadedBy;
  final String status;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CourseFileModel({
    required this.id,
    required this.offeringId,
    required this.courseId,
    required this.semesterId,
    required this.title,
    this.description = '',
    required this.category,
    required this.fileName,
    required this.fileExtension,
    this.mimeType = '',
    required this.fileSize,
    required this.cloudinaryUrl,
    required this.cloudinaryPublicId,
    required this.cloudinaryResourceType,
    required this.uploadedBy,
    this.status = statusActive,
    this.createdAt,
    this.updatedAt,
  });

  // ---- categories ----
  static const String categoryLecture = 'lecture';
  static const String categorySummary = 'summary';
  static const String categoryAssignmentMaterial = 'assignment_material';
  static const String categoryReference = 'reference';
  static const String categoryOther = 'other';

  static const List<String> allowedCategories = <String>[
    categoryLecture,
    categorySummary,
    categoryAssignmentMaterial,
    categoryReference,
    categoryOther,
  ];

  // ---- status ----
  static const String statusActive = 'active';
  static const String statusArchived = 'archived';

  static const List<String> allowedStatuses = <String>[
    statusActive,
    statusArchived,
  ];

  bool get isActive => status == statusActive;
  bool get isArchived => status == statusArchived;

  // ---- مساعدات عرض ----
  //
  // مشتقة من الحقول المخزَّنة وقت العرض، ولا يُخزَّن أي منها. وجودها هنا
  // يغني عن نموذج عرض ثانٍ للملفات.

  static const String typePdf = 'pdf';
  static const String typeDoc = 'doc';
  static const String typePpt = 'ppt';
  static const String typeImage = 'image';
  static const String typeOther = 'other';

  /// تصنيف نوع الملف للأيقونة والتصفية، مشتقّ من الامتداد المخزَّن.
  ///
  /// التصفية في الواجهة تعتمد هذا لا حقلًا جديدًا في قاعدة البيانات.
  String get typeGroup {
    switch (fileExtension.trim().toLowerCase()) {
      case 'pdf':
        return typePdf;
      case 'doc':
      case 'docx':
      case 'txt':
        return typeDoc;
      case 'ppt':
      case 'pptx':
        return typePpt;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return typeImage;
      default:
        return typeOther;
    }
  }

  /// رُفع حديثًا، لشارة «جديد».
  ///
  /// مشتق من createdAt لا من علم مخزَّن: العلم المخزَّن يبقى صحيحًا للأبد
  /// ما لم يحدّثه أحد.
  bool isRecent({DateTime? now, Duration window = const Duration(days: 7)}) {
    final created = createdAt;
    if (created == null) return false;
    return (now ?? DateTime.now()).difference(created) <= window;
  }

  /// حجم الملف بصيغة مقروءة. يُبنى وقت العرض ولا يُخزَّن.
  String get readableSize {
    if (fileSize <= 0) return '';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(0)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory CourseFileModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return CourseFileModel(
      id: id,
      offeringId: data['offeringId'] as String? ?? '',
      courseId: data['courseId'] as String? ?? '',
      semesterId: data['semesterId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? categoryOther,
      fileName: data['fileName'] as String? ?? '',
      fileExtension: (data['fileExtension'] as String? ?? '').toLowerCase(),
      mimeType: data['mimeType'] as String? ?? '',
      fileSize: (data['fileSize'] as num?)?.toInt() ?? 0,
      cloudinaryUrl: data['cloudinaryUrl'] as String? ?? '',
      cloudinaryPublicId: data['cloudinaryPublicId'] as String? ?? '',
      cloudinaryResourceType:
          data['cloudinaryResourceType'] as String? ?? 'raw',
      uploadedBy: data['uploadedBy'] as String? ?? '',
      status: data['status'] as String? ?? statusActive,
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'offeringId': offeringId,
      'courseId': courseId,
      'semesterId': semesterId,
      'title': title,
      'description': description,
      'category': category,
      'fileName': fileName,
      'fileExtension': fileExtension,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'cloudinaryUrl': cloudinaryUrl,
      'cloudinaryPublicId': cloudinaryPublicId,
      'cloudinaryResourceType': cloudinaryResourceType,
      'uploadedBy': uploadedBy,
      'status': status,
    };
  }

  CourseFileModel copyWith({
    String? id,
    String? offeringId,
    String? courseId,
    String? semesterId,
    String? title,
    String? description,
    String? category,
    String? fileName,
    String? fileExtension,
    String? mimeType,
    int? fileSize,
    String? cloudinaryUrl,
    String? cloudinaryPublicId,
    String? cloudinaryResourceType,
    String? uploadedBy,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseFileModel(
      id: id ?? this.id,
      offeringId: offeringId ?? this.offeringId,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      fileName: fileName ?? this.fileName,
      fileExtension: fileExtension ?? this.fileExtension,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      cloudinaryUrl: cloudinaryUrl ?? this.cloudinaryUrl,
      cloudinaryPublicId: cloudinaryPublicId ?? this.cloudinaryPublicId,
      cloudinaryResourceType:
          cloudinaryResourceType ?? this.cloudinaryResourceType,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
