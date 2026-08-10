// lib/features/files/services/student_file_service.dart

import '../models/student_app_file.dart';

class StudentFileException implements Exception {
  final String message;
  const StudentFileException(this.message);

  @override
  String toString() => message;
}

/// Provides file data for the Files feature.
///
/// Currently backed by Mock Data only (UI-development phase — no
/// Firebase, no backend). Keeps the exact async signature it would
/// have with a real data source, so swapping the implementation
/// later (Firestore) will not require any change in
/// [StudentFileProvider] or any screen/widget consuming this
/// service.
class StudentFileService {
  StudentFileService();

  static const Duration _mockDelay = Duration(milliseconds: 400);

  Future<List<StudentAppFile>> getAllFiles() async {
    await Future.delayed(_mockDelay);
    return _mockFiles;
  }

  Future<List<StudentAppFile>> getDownloadedFiles() async {
    await Future.delayed(_mockDelay);
    return _mockFiles.where((file) => file.isDownloaded).toList();
  }

  Future<StudentAppFile> getFileById(String id) async {
    await Future.delayed(_mockDelay);
    try {
      return _mockFiles.firstWhere((file) => file.id == id);
    } catch (_) {
      throw const StudentFileException('لم يتم العثور على الملف المطلوب.');
    }
  }

  // ---------------------------------------------------------------------
  // Mock Data — mirrors the Figma design (All Files screen).
  // ---------------------------------------------------------------------

  static final List<StudentAppFile> _mockFiles = [
    const StudentAppFile(
      id: 'file_advanced_math_summary',
      title: 'ملخص الرياضيات المتقدمة',
      subjectLabel: 'حساب التفاضل والتكامل',
      type: StudentAppFile.typePdf,
      sizeLabel: '2.4 MB',
      dateLabel: '12 أكتوبر 2023',
      downloadProgress: 1.0,
    ),
    const StudentAppFile(
      id: 'file_programming_intro',
      title: 'عرض مقدمة في البرمجة',
      subjectLabel: 'أساسيات CS',
      type: StudentAppFile.typePpt,
      sizeLabel: '5.1 MB',
      dateLabel: '15 أكتوبر 2023',
      downloadProgress: 0.45,
    ),
    const StudentAppFile(
      id: 'file_neural_network_diagram',
      title: 'مخطط الشبكة العصبية',
      subjectLabel: 'الذكاء الاصطناعي',
      type: StudentAppFile.typeImage,
      sizeLabel: '842 KB',
      dateLabel: '18 أكتوبر 2023',
      downloadProgress: 1.0,
      isNew: true,
    ),
  ];
}