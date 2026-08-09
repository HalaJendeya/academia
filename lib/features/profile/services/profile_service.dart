import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../models/student_profile.dart';

class ProfileException implements Exception {
  final String message;
  const ProfileException(this.message);

  @override
  String toString() => message;
}

class ProfileService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ProfileService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Future<StudentProfile> getCurrentProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const ProfileException(AppStrings.authenticationRequired);
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!doc.exists) {
        throw const ProfileException(AppStrings.profileNotFound);
      }

      final data = doc.data();
      if (data == null) {
        throw const ProfileException(AppStrings.profileNotFound);
      }

      return StudentProfile.fromFirestore(currentUser.uid, data);
    } on ProfileException {
      rethrow;
    } catch (e) {
      throw const ProfileException(AppStrings.profileLoadError);
    }
  }

  Future<void> updateProfile({
    required String fullName,
    String? major,
    int? academicLevel,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const ProfileException(AppStrings.authenticationRequired);
    }

    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) {
      throw const ProfileException(AppStrings.fullNameRequired);
    }
    if (trimmedName.length < 2) {
      throw const ProfileException(AppStrings.fullNameTooShort);
    }

    try {
      final Map<String, dynamic> updateData = {
        'fullName': trimmedName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (major != null && major.trim().isNotEmpty) {
        updateData['major'] = major.trim();
      }
      // يُكتب كرقم صحيح؛ لا تُخزَّن النصوص المعروضة في قاعدة البيانات.
      if (academicLevel != null && academicLevel > 0) {
        updateData['academicLevel'] = academicLevel;
      }

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      throw const ProfileException(AppStrings.profileUpdateError);
    }
  }
}
