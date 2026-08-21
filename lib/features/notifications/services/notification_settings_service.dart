import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../models/notification_settings.dart';

class NotificationSettingsException implements Exception {
  final String message;
  const NotificationSettingsException(this.message);

  @override
  String toString() => message;
}

class NotificationSettingsService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  NotificationSettingsService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<NotificationSettings> getCurrentSettings() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const NotificationSettingsException(
        AppStrings.authenticationRequired,
      );
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!doc.exists) {
        throw const NotificationSettingsException(
          AppStrings.notificationSettingsNotAvailable,
        );
      }

      final data = doc.data() ?? const {};
      return NotificationSettings.fromFirestore(data);
    } on NotificationSettingsException {
      rethrow;
    } catch (e) {
      throw const NotificationSettingsException(
        AppStrings.notificationSettingsLoadError,
      );
    }
  }

  Future<void> saveSettings(NotificationSettings settings) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const NotificationSettingsException(
        AppStrings.authenticationRequired,
      );
    }

    try {
      final userDocRef = _firestore.collection('users').doc(currentUser.uid);
      final doc = await userDocRef.get();

      if (!doc.exists) {
        throw const NotificationSettingsException(
          AppStrings.notificationSettingsNotAvailable,
        );
      }

      final data = doc.data() ?? const {};
      final existingPreferences =
          data['notificationPreferences'] as Map? ?? const {};

      // Copy existing preference map and merge visible settings
      final Map<String, dynamic> mergedPreferences = Map<String, dynamic>.from(
        existingPreferences,
      );

      // Merge visible keys
      final visiblePrefs = settings.toVisiblePreferenceMap();
      mergedPreferences.addAll(visiblePrefs);

      // Save using set merge options
      await userDocRef.set({
        'notificationPreferences': mergedPreferences,
        'quietHours': settings.toQuietHoursMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on NotificationSettingsException {
      rethrow;
    } catch (e) {
      throw const NotificationSettingsException(
        AppStrings.notificationSettingsSaveError,
      );
    }
  }
}
