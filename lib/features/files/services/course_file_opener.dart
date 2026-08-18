import 'package:url_launcher/url_launcher.dart';

/// دالة الفتح الفعلية. مجرّدة خلف نوع دالة حتى يبقى الفتح قابلًا للاختبار
/// بلا منصّة حقيقية.
typedef UrlLauncherFn =
    Future<bool> Function(Uri uri, {required LaunchMode mode});

enum CourseFileOpenResult {
  opened,

  /// الرابط المخزَّن فارغ أو غير صالح — لا يُستدعى المشغّل أصلًا.
  invalidUrl,

  /// المشغّل رُفض أو رمى: لا تطبيق يفتح الرابط على هذا الجهاز.
  launchFailed,
}

/// فتح ملف مساق برابط Cloudinary المخزَّن.
///
/// تطبيق واحد يستعمله المشرف والطالب معًا؛ كان المنطق نفسه مكرَّرًا في ثلاث
/// شاشات، فيصلح في واحدة ويبقى معطوبًا في الأخريات.
///
/// الرابط يُستعمل كما أعادته Cloudinary عند الرفع (secure_url). لا يُعاد
/// تركيبه ولا يُبدَّل نوع المورد فيه: المورد مخزَّن حيث يقول رابطه، وتغيير
/// المسار يدويًا ينتج 404.
Future<CourseFileOpenResult> openCourseFileUrl(
  String url, {
  UrlLauncherFn? launcher,
}) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return CourseFileOpenResult.invalidUrl;

  final uri = Uri.tryParse(trimmed);

  /*
   * Uri.tryParse متساهل: يقبل النص الفارغ والمسارات النسبية ويعيد كائنًا
   * غير null. لذلك لا يكفي فحص null — نشترط رابطًا مطلقًا بمخطط ويب، وإلا
   * أبلغنا بخطأ دقيق بدل تمرير قيمة لا يمكن فتحها إلى المنصّة.
   */
  if (uri == null ||
      !uri.hasScheme ||
      !uri.hasAuthority ||
      (uri.scheme != 'https' && uri.scheme != 'http')) {
    return CourseFileOpenResult.invalidUrl;
  }

  final launch = launcher ?? _defaultLauncher;

  // التطبيق الخارجي أولًا: الملف يُفتح في المتصفح أو في قارئ PDF.
  try {
    if (await launch(uri, mode: LaunchMode.externalApplication)) {
      return CourseFileOpenResult.opened;
    }
  } catch (_) {
    // نتابع إلى المحاولة الاحتياطية بدل إسقاط الشاشة.
  }

  /*
   * محاولة احتياطية واحدة بالوضع الافتراضي.
   *
   * على جهاز بلا متصفح خارجي — وهو حال أغلب المحاكيات — يفشل
   * externalApplication لعدم وجود تطبيق يستقبل الرابط، بينما ينجح الوضع
   * الافتراضي عبر عرض داخلي. الفشل النهائي وحده يُبلَّغ للمستخدم.
   */
  try {
    if (await launch(uri, mode: LaunchMode.platformDefault)) {
      return CourseFileOpenResult.opened;
    }
  } catch (_) {
    return CourseFileOpenResult.launchFailed;
  }

  return CourseFileOpenResult.launchFailed;
}

Future<bool> _defaultLauncher(Uri uri, {required LaunchMode mode}) =>
    launchUrl(uri, mode: mode);
