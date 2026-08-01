import '../../../core/constants/study_day_constants.dart';

class StudyPreferences {
  final List<String> studyDays;
  final int preferredSessionDuration;

  const StudyPreferences({
    required this.studyDays,
    required this.preferredSessionDuration,
  });

  factory StudyPreferences.defaults() {
    return const StudyPreferences(
      studyDays: StudyDayConstants.defaultStudyDays,
      preferredSessionDuration: 45,
    );
  }

  factory StudyPreferences.fromFirestore(Map<String, dynamic> data) {
    final rawDays = data['studyDays'];
    List<String> parsedDays = [];

    if (rawDays is List) {
      for (final item in rawDays) {
        if (item is String && StudyDayConstants.orderedDays.contains(item)) {
          if (!parsedDays.contains(item)) {
            parsedDays.add(item);
          }
        }
      }
      // Sort using StudyDayConstants.orderedDays index
      parsedDays.sort((a, b) {
        final indexA = StudyDayConstants.orderedDays.indexOf(a);
        final indexB = StudyDayConstants.orderedDays.indexOf(b);
        return indexA.compareTo(indexB);
      });
    }

    if (parsedDays.isEmpty) {
      parsedDays = List.from(StudyDayConstants.defaultStudyDays);
    }

    final rawDuration = data['preferredSessionDuration'];
    int parsedDuration = 45;
    if (rawDuration is int && rawDuration >= 5 && rawDuration <= 180) {
      parsedDuration = rawDuration;
    }

    return StudyPreferences(
      studyDays: parsedDays,
      preferredSessionDuration: parsedDuration,
    );
  }

  StudyPreferences copyWith({
    List<String>? studyDays,
    int? preferredSessionDuration,
  }) {
    return StudyPreferences(
      studyDays: studyDays ?? this.studyDays,
      preferredSessionDuration:
          preferredSessionDuration ?? this.preferredSessionDuration,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studyDays': studyDays,
      'preferredSessionDuration': preferredSessionDuration,
    };
  }
}
