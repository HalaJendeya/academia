import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_strings.dart';
import '../constants/onboarding_statuses.dart';
import '../models/onboarding_preferences.dart';

class OnboardingException implements Exception {
  final String message;
  const OnboardingException(this.message);

  @override
  String toString() => message;
}

class OnboardingService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  OnboardingService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  String _completedKey(String uid) => 'onboarding_completed_$uid';
  String _statusKey(String uid) => 'onboarding_status_$uid';

  Future<void> _cacheStatus({
    required String uid,
    required bool completed,
    required String status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey(uid), completed);
    await prefs.setString(_statusKey(uid), status);
  }

  Future<void> clearCachedStatusForUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey(uid));
    await prefs.remove(_statusKey(uid));
  }

  Future<bool> isOnboardingCompleted() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    final uid = user.uid;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedValue = prefs.getBool(_completedKey(uid));

      if (cachedValue != null) {
        return cachedValue;
      }

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return false;
      }

      final data = doc.data();
      final completed = data?['onboardingCompleted'] as bool? ?? false;
      final status = data?['onboardingStatus'] as String?;

      final resolvedCompleted =
          completed ||
          status == OnboardingStatuses.completed ||
          status == OnboardingStatuses.skipped;

      await prefs.setBool(_completedKey(uid), resolvedCompleted);
      if (status != null) {
        await prefs.setString(_statusKey(uid), status);
      }

      return resolvedCompleted;
    } catch (_) {
      return false; // Safely return false to prevent boot loop crashes in Splash
    }
  }

  Future<void> _validateVerifiedUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const OnboardingException(AppStrings.authenticationRequired);
    }

    try {
      await user.reload();
    } catch (_) {
      // If offline, reload might fail. Fallback on existing currentUser verification flag.
    }

    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null || !refreshedUser.emailVerified) {
      throw const OnboardingException(AppStrings.authenticationRequired);
    }
  }

  Future<void> completeOnboarding(OnboardingPreferences preferences) async {
    await _validateVerifiedUser();
    final uid = _auth.currentUser!.uid;

    if (preferences.studyDays.isEmpty) {
      throw const OnboardingException(AppStrings.selectAtLeastOneStudyDay);
    }
    if (preferences.preferredSessionDuration < 5 ||
        preferences.preferredSessionDuration > 180) {
      throw const OnboardingException(AppStrings.invalidCustomDuration);
    }

    // Firestore Merge write
    await _firestore.collection('users').doc(uid).set({
      ...preferences.toFirestore(),
      'onboardingCompleted': true,
      'onboardingStatus': OnboardingStatuses.completed,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Update local cache ONLY after Firestore write Future succeeds
    await _cacheStatus(
      uid: uid,
      completed: true,
      status: OnboardingStatuses.completed,
    );
  }

  Future<void> skipOnboarding() async {
    await _validateVerifiedUser();
    final uid = _auth.currentUser!.uid;

    // Use default values so later features don't get missing properties
    final defaults = OnboardingPreferences.defaults();

    // Firestore Merge write
    await _firestore.collection('users').doc(uid).set({
      ...defaults.toFirestore(),
      'onboardingCompleted': true,
      'onboardingStatus': OnboardingStatuses.skipped,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Update local cache ONLY after Firestore write Future succeeds
    await _cacheStatus(
      uid: uid,
      completed: true,
      status: OnboardingStatuses.skipped,
    );
  }
}
