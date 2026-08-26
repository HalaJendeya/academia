/// إعدادات Cloudinary لتخزين ملفات المساقات.
///
/// الرفع غير موقَّع (unsigned upload preset)، وهذا مقصود: التطبيق لا يحمل
/// أي مفتاح سري. المفتاح السري يسمح بالحذف وإعادة التوقيع، ووجوده داخل
/// تطبيق Flutter يعني تسليمه لكل من يفكّ حزمة التطبيق.
///
/// نتيجة ذلك أن الحذف من Cloudinary غير ممكن من العميل، ولهذا تعتمد إزالة
/// الملف على الأرشفة في Firestore لا على حذف الملف الثنائي.
class CloudinaryConfig {
  const CloudinaryConfig._();

  static const String cloudName = 'xmrgiypo';

  /// preset غير موقَّع مضبوط في لوحة Cloudinary.
  static const String uploadPreset = 'academia_course_files';

  /// حد الحجم من جهة العميل: 10 ميغابايت.
  ///
  /// يُفحص قبل بدء الرفع حتى لا نستهلك شبكة الطالب في رفع سيفشل.
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// الامتدادات المسموح بها، مطابِقة لما يقبله الـ preset.
  ///
  /// القائمة هنا للتحقق المبكر ورسالة الخطأ الواضحة؛ الحجية النهائية
  /// لإعدادات Cloudinary نفسها.
  static const List<String> allowedExtensions = <String>[
    'pdf',
    'doc',
    'docx',
    'ppt',
    'pptx',
    'xls',
    'xlsx',
    'txt',
    'jpg',
    'jpeg',
    'png',
  ];

  // ===== الصور الشخصية (المرحلة 7H1) =====
  //
  // preset منفصل عن ملفات المساقات عن قصد. preset ملفات المساقات يقبل
  // المستندات ويودعها في شجرة مجلدات الطروحات، وهما شرطان لا يصحّان لصورة
  // شخصية: الصورة ليست مادة تعليمية، ولا تنتمي إلى طرح.

  /// preset غير موقَّع مخصص للصور الشخصية.
  ///
  /// يجب إنشاؤه يدويًا في لوحة Cloudinary باسم مطابق ووضع Unsigned. لا
  /// يُنشأ من التطبيق: إنشاء presets يتطلب مفتاحًا سريًا لا مكان له هنا.
  static const String profileImageUploadPreset = 'academia_profile_images';

  /// حد حجم الصورة الشخصية: 5 ميغابايت.
  ///
  /// أقل من حد ملفات المساقات لأن الصورة تُعرض في دائرة صغيرة، ولا فائدة
  /// من تحميل الطالب ملفًا أكبر مما ستظهر به.
  static const int maxProfileImageSizeBytes = 5 * 1024 * 1024;

  /// صيغ الصور الشخصية المقبولة، أضيق من allowedExtensions عمدًا: الصورة
  /// الشخصية صورة، لا مستند.
  static const List<String> allowedImageExtensions = <String>[
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  /// نقطة الرفع. نستخدم `auto` ليحدّد Cloudinary نوع المورد بنفسه، ثم نخزّن
  /// ما يعيده: ملفات PDF مثلًا تُصنَّف image لا raw، وتخمين ذلك في العميل
  /// مصدر أخطاء.
  static Uri uploadUri() => Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/auto/upload',
  );

  /// المجلد الذي تُحفظ فيه ملفات طرح معيّن داخل Cloudinary.
  ///
  /// تنظيمي فقط: صلاحية الوصول تُدار في Firestore لا في Cloudinary.
  static String folderForOffering(String offeringId) =>
      'academia/course_files/$offeringId';

  /// مجلد صور المستخدم الواحد. تنظيمي فقط، كما في مجلد الطروحات.
  ///
  /// كل رفع ينشئ مورداً جديداً ولا يستبدل السابق: الاستبدال يحتاج توقيعًا،
  /// والرابط الجديد وحده هو ما يُخزَّن في Firestore.
  static String folderForProfileImage(String uid) =>
      'academia/profile_images/$uid';

  static String normalizeExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).trim().toLowerCase();
  }

  static bool isAllowedExtension(String extension) =>
      allowedExtensions.contains(extension.trim().toLowerCase());

  static bool isWithinSizeLimit(int sizeBytes) =>
      sizeBytes > 0 && sizeBytes <= maxFileSizeBytes;

  static bool isAllowedImageExtension(String extension) =>
      allowedImageExtensions.contains(extension.trim().toLowerCase());

  static bool isWithinProfileImageSizeLimit(int sizeBytes) =>
      sizeBytes > 0 && sizeBytes <= maxProfileImageSizeBytes;
}
