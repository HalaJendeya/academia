import 'app_strings.dart';

abstract final class StudyDayConstants {
  StudyDayConstants._();

  static const List<String> orderedDays = [
    AppStrings.saturday,
    AppStrings.sunday,
    AppStrings.monday,
    AppStrings.tuesday,
    AppStrings.wednesday,
    AppStrings.thursday,
    AppStrings.friday,
  ];

  static const List<String> defaultStudyDays = [
    AppStrings.sunday,
    AppStrings.monday,
    AppStrings.tuesday,
    AppStrings.wednesday,
    AppStrings.thursday,
  ];
}
