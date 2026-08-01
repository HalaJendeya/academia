import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/study_day_constants.dart';
import '../models/study_preferences.dart';

class StudyPreferencesException implements Exception {
  final String message;
  const StudyPreferencesException(this.message);

  @override
  String toString() => message;
}

class StudyPreferencesService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  StudyPreferencesService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Future<StudyPreferences> getCurrentPreferences() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const StudyPreferencesException(AppStrings.authenticationRequired);
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!doc.exists) {
        throw const StudyPreferencesException(
          AppStrings.studyPreferencesNotAvailable,
        );
      }

      final data = doc.data() ?? const {};
      return StudyPreferences.fromFirestore(data);
    } on StudyPreferencesException {
      rethrow;
    } catch (e) {
      throw const StudyPreferencesException(
        AppStrings.studyPreferencesLoadError,
      );
    }
  }

  Future<void> savePreferences(StudyPreferences preferences) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const StudyPreferencesException(AppStrings.authenticationRequired);
    }

    if (preferences.studyDays.isEmpty) {
      throw const StudyPreferencesException(
        AppStrings.selectAtLeastOneStudyDay,
      );
    }

    if (preferences.preferredSessionDuration < 5 ||
        preferences.preferredSessionDuration > 180) {
      throw const StudyPreferencesException(AppStrings.invalidCustomDuration);
    }

    try {
      final userDocRef = _firestore.collection('users').doc(currentUser.uid);
      final doc = await userDocRef.get();

      if (!doc.exists) {
        throw const StudyPreferencesException(
          AppStrings.studyPreferencesNotAvailable,
        );
      }

      // Sort study days using shared weekday order
      final sortedStudyDays = List<String>.from(preferences.studyDays);
      sortedStudyDays.sort((a, b) {
        final indexA = StudyDayConstants.orderedDays.indexOf(a);
        final indexB = StudyDayConstants.orderedDays.indexOf(b);
        return indexA.compareTo(indexB);
      });

      await userDocRef.set({
        'studyDays': sortedStudyDays,
        'preferredSessionDuration': preferences.preferredSessionDuration,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on StudyPreferencesException {
      rethrow;
    } catch (e) {
      throw const StudyPreferencesException(
        AppStrings.studyPreferencesSaveError,
      );
    }
  }
}
