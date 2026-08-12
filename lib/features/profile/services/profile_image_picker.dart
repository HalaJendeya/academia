import 'package:image_picker/image_picker.dart';

import '../../../core/constants/cloudinary_config.dart';

/// صورة اختارها الطالب من جهازه، قبل رفعها.
class PickedProfileImage {
  const PickedProfileImage({required this.fileName, required this.bytes});

  final String fileName;
  final List<int> bytes;

  int get size => bytes.length;

  String get extension => CloudinaryConfig.normalizeExtension(fileName);
}

/// دالة اختيار الصورة.
///
/// مجرّدة خلف نوع دالة كما في منتقي ملفات المساقات، حتى تبقى شاشة تعديل
/// الملف الشخصي قابلة للاختبار بلا منتقي صور حقيقي.
typedef ProfileImagePickerFn = Future<PickedProfileImage?> Function();

/// الامتداد من اسم الملف، وإلا من نوع المحتوى.
///
/// بعض المنصات تعيد اسمًا بلا امتداد، ورفض الصورة عندئذٍ رفضٌ لسبب لا يخص
/// الصورة نفسها. mimeType هو المصدر الاحتياطي الوحيد المتاح هنا.
String resolveProfileImageFileName(String name, String? mimeType) {
  if (CloudinaryConfig.normalizeExtension(name).isNotEmpty) return name;

  final extension = switch (mimeType?.trim().toLowerCase()) {
    'image/jpeg' || 'image/jpg' => 'jpg',
    'image/png' => 'png',
    'image/webp' => 'webp',
    _ => '',
  };

  if (extension.isEmpty) return name;

  final base = name.trim().isEmpty ? 'profile' : name.trim();
  return '$base.$extension';
}

/// الاختيار الفعلي عبر image_picker، وهي الحزمة المستعملة أصلًا في الشاشة.
///
/// [imageQuality] يعيد الترميز ويقلّص الحجم قبل أن يصل إلى التحقق، فيقلّ
/// احتمال رفض الصورة لتجاوزها الحد.
Future<PickedProfileImage?> pickProfileImage() async {
  final picker = ImagePicker();
  final image = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 70,
  );

  if (image == null) return null;

  final bytes = await image.readAsBytes();

  return PickedProfileImage(
    fileName: resolveProfileImageFileName(image.name, image.mimeType),
    bytes: bytes,
  );
}
