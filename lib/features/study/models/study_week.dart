import '../../../core/constants/app_strings.dart';

/// أسماء الأيام العربية مقابل ترقيم [DateTime.weekday] (1=الاثنين … 7=الأحد).
///
/// تُقرأ من AppStrings نفسها التي تستعملها تفضيلات المذاكرة، فلا يظهر
/// اليوم باسمين مختلفين في شاشتين.
abstract final class ArabicWeekday {
  ArabicWeekday._();

  static const Map<int, String> _names = {
    DateTime.saturday: AppStrings.saturday,
    DateTime.sunday: AppStrings.sunday,
    DateTime.monday: AppStrings.monday,
    DateTime.tuesday: AppStrings.tuesday,
    DateTime.wednesday: AppStrings.wednesday,
    DateTime.thursday: AppStrings.thursday,
    DateTime.friday: AppStrings.friday,
  };

  static String? name(int? weekday) => weekday == null ? null : _names[weekday];
}

/// أسماء الشهور الميلادية بالعربية، لعرض مدى الأسبوع في التقرير.
abstract final class ArabicMonth {
  ArabicMonth._();

  static const List<String> names = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  static String of(int month) => names[(month - 1).clamp(0, 11)];
}

/// حدود الأسبوع الدراسي.
///
/// الأسبوع يبدأ السبت وينتهي الجمعة، وهو ترتيب [StudyDayConstants.orderedDays]
/// نفسه المستعمل في تفضيلات المذاكرة والإعداد الأولي. لو بدأ الأسبوع هنا
/// من الاثنين لاختلف «هذا الأسبوع» في التقرير عن «أيام مذاكرتي» في
/// التفضيلات، وهو تناقض يراه الطالب ولا يفهم سببه.
///
/// الحدود محلية لا UTC: الطالب يقيس أسبوعه بساعته لا بساعة الخادم.
class StudyWeek {
  /// السبت 00:00 المحلي.
  final DateTime start;

  /// السبت التالي 00:00 — حدّ أعلى مفتوح، أي `start <= t < end`.
  final DateTime end;

  const StudyWeek({required this.start, required this.end});

  /// الأسبوع الذي تقع فيه [reference].
  factory StudyWeek.containing(DateTime reference) {
    final day = DateTime(reference.year, reference.month, reference.day);
    // DateTime.weekday: الاثنين 1 … الأحد 7، والسبت 6.
    // الفرق إلى السبت السابق: (weekday + 1) % 7.
    final daysSinceSaturday = (day.weekday + 1) % 7;
    final start = day.subtract(Duration(days: daysSinceSaturday));
    return StudyWeek(start: start, end: start.add(const Duration(days: 7)));
  }

  /// الأسبوع السابق مباشرةً، لحساب المقارنة حسابًا حقيقيًا.
  StudyWeek get previous => StudyWeek(
    start: start.subtract(const Duration(days: 7)),
    end: start,
  );

  bool contains(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);

  /// اليوم الأخير المعروض للطالب (الجمعة)، لا الحدّ المفتوح.
  DateTime get lastDay => end.subtract(const Duration(days: 1));
}
