// lib/features/files/models/student_app_file.dart

/// Represents a single file resource visible to the student
/// (course material, shared file, etc).
///
/// Powers three screens: All Files list, File Preview, and the
/// Offline (downloaded) files list — all reuse this same shape.
class StudentAppFile {
  final String id;
  final String title;

  /// Course/subject label shown under the title, e.g. "حساب التفاضل والتكامل".
  final String subjectLabel;

  /// One of [typePdf] / [typeDoc] / [typePpt] / [typeImage] / [typeOther].
  final String type;

  final String sizeLabel;
  final String dateLabel;

  /// Download state:
  /// - `null`      → not downloaded yet.
  /// - `0.0–0.99`  → currently downloading, this is the progress.
  /// - `1.0`       → fully downloaded (available offline).
  final double? downloadProgress;

  /// Whether this file was added recently, to show a "جديد" badge.
  final bool isNew;

  /// Optional course id this file belongs to, if any
  /// (links back to `features/courses`).
  final String? courseId;

  const StudentAppFile({
    required this.id,
    required this.title,
    required this.subjectLabel,
    required this.type,
    required this.sizeLabel,
    required this.dateLabel,
    this.downloadProgress,
    this.isNew = false,
    this.courseId,
  });

  static const String typePdf = 'pdf';
  static const String typeDoc = 'doc';
  static const String typePpt = 'ppt';
  static const String typeImage = 'image';
  static const String typeOther = 'other';

  bool get isDownloaded => downloadProgress == 1.0;
  bool get isDownloading =>
      downloadProgress != null && downloadProgress! < 1.0;

  factory StudentAppFile.fromFirestore(String id, Map<String, dynamic> data) {
    return StudentAppFile(
      id: id,
      title: data['title'] as String? ?? '',
      subjectLabel: data['subjectLabel'] as String? ?? '',
      type: data['type'] as String? ?? typeOther,
      sizeLabel: data['sizeLabel'] as String? ?? '',
      dateLabel: data['dateLabel'] as String? ?? '',
      downloadProgress: (data['downloadProgress'] as num?)?.toDouble(),
      isNew: data['isNew'] as bool? ?? false,
      courseId: data['courseId'] as String?,
    );
  }

  Map<String, dynamic> toEditableFirestore() {
    return {
      'title': title,
      'subjectLabel': subjectLabel,
      'type': type,
      'sizeLabel': sizeLabel,
      'dateLabel': dateLabel,
      'downloadProgress': downloadProgress,
      'isNew': isNew,
      'courseId': courseId,
    };
  }

  StudentAppFile copyWith({
    String? id,
    String? title,
    String? subjectLabel,
    String? type,
    String? sizeLabel,
    String? dateLabel,
    double? downloadProgress,
    bool? isNew,
    String? courseId,
  }) {
    return StudentAppFile(
      id: id ?? this.id,
      title: title ?? this.title,
      subjectLabel: subjectLabel ?? this.subjectLabel,
      type: type ?? this.type,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      dateLabel: dateLabel ?? this.dateLabel,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isNew: isNew ?? this.isNew,
      courseId: courseId ?? this.courseId,
    );
  }
}