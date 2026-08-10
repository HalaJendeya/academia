import 'package:file_picker/file_picker.dart';

import '../../../core/constants/cloudinary_config.dart';

/// ملف اختاره المشرف من جهازه، قبل رفعه.
class PickedCourseFile {
  const PickedCourseFile({
    required this.fileName,
    required this.bytes,
    this.mimeType = '',
  });

  final String fileName;
  final List<int> bytes;
  final String mimeType;

  int get size => bytes.length;

  String get extension => CloudinaryConfig.normalizeExtension(fileName);
}

/// دالة اختيار الملف.
///
/// مجرّدة خلف نوع دالة حتى تبقى شاشة الرفع قابلة للاختبار بلا منتقي ملفات
/// حقيقي: الاختبار يمرّر بديلًا يعيد ملفًا مصطنعًا.
typedef CourseFilePickerFn = Future<PickedCourseFile?> Function();

/// الاختيار الفعلي عبر file_picker.
///
/// الصيغ المسموحة تأتي من CloudinaryConfig لا من قائمة مكتوبة هنا، فيبقى
/// مصدر واحد للحقيقة بين المنتقي والتحقق والرفع.
Future<PickedCourseFile?> pickCourseFile() async {
  // file_picker 11 يعرّف pickFiles كدالة ساكنة مباشرة، بلا وسيط platform.
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: CloudinaryConfig.allowedExtensions,
    allowMultiple: false,
    withData: true,
  );

  if (result == null || result.files.isEmpty) return null;

  final file = result.files.first;
  final bytes = file.bytes;
  if (bytes == null) return null;

  return PickedCourseFile(fileName: file.name, bytes: bytes);
}
