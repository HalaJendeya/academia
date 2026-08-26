import '../../../core/constants/app_strings.dart';

/// صياغة مدة المذاكرة بالعربية.
///
/// العربية تميّز المفرد والمثنى والجمع، وكتابة «2 ساعة» أو «3 ساعة» تقرأ
/// ركيكة. الصياغة هنا تتبع القاعدة: ساعة، ساعتان، ٣–١٠ ساعات، ثم ١١ فأكثر
/// بالمفرد المميَّز.
///
/// دالة خالصة، بلا حالة ولا سياق، ليختبرها الاختبار مباشرة.
abstract final class StudyDurationFormat {
  StudyDurationFormat._();

  /// يحوّل الدقائق إلى نص عربي طبيعي.
  ///
  /// أمثلة: 0 → «0 دقيقة»، 45 → «45 دقيقة»، 60 → «ساعة»،
  /// 90 → «ساعة و30 دقيقة»، 120 → «ساعتان»، 195 → «3 ساعات و15 دقيقة».
  static String format(int totalMinutes) {
    // الصفر قيمة صحيحة لا حالة خطأ: طالب لم يذاكر بعد.
    if (totalMinutes <= 0) return '0 ${AppStrings.minutesUnit}';

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) return '$minutes ${AppStrings.minutesUnit}';

    final hoursText = _hours(hours);
    if (minutes == 0) return hoursText;

    return '$hoursText ${AppStrings.andSeparator}$minutes '
        '${AppStrings.minutesUnit}';
  }

  static String _hours(int hours) {
    if (hours == 1) return AppStrings.oneHour;
    if (hours == 2) return AppStrings.twoHours;
    if (hours <= 10) return '$hours ${AppStrings.hoursPlural}';
    return '$hours ${AppStrings.hoursSingularCounted}';
  }
}
