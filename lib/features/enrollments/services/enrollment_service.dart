import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../../admin/models/admin_student_model.dart';
import '../models/enrollment_model.dart';

class EnrollmentException implements Exception {
  final String message;
  const EnrollmentException(this.message);

  @override
  String toString() => message;
}

class EnrollmentService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  EnrollmentService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> _verifyAdminAccess() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const EnrollmentException(AppStrings.authenticationRequired);
    }

    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    if (!userDoc.exists) {
      throw const EnrollmentException(AppStrings.unauthorizedAccess);
    }

    final data = userDoc.data();
    if (data == null || data['role'] != 'admin' || data['status'] != 'active') {
      throw const EnrollmentException(AppStrings.unauthorizedAccess);
    }
  }

  Stream<List<AdminStudentModel>> watchStudents() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AdminStudentModel.fromFirestore(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => a.fullName.compareTo(b.fullName));
          return list;
        });
  }

  Future<List<AdminStudentModel>> getStudents() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      final list = snapshot.docs
          .map((doc) => AdminStudentModel.fromFirestore(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
      return list;
    } catch (e) {
      throw const EnrollmentException(AppStrings.courseLoadError);
    }
  }

  Stream<List<EnrollmentModel>> watchStudentEnrollments(String userId) {
    return _firestore
        .collection('enrollments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => EnrollmentModel.fromFirestore(doc.data(), doc.id))
              .toList();
          list.sort((a, b) {
            if (a.assignedAt == null && b.assignedAt == null) return 0;
            if (a.assignedAt == null) return 1;
            if (b.assignedAt == null) return -1;
            return b.assignedAt!.compareTo(a.assignedAt!);
          });
          return list;
        });
  }

  Future<List<EnrollmentModel>> getStudentEnrollments(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: userId)
          .get();
      final list = snapshot.docs
          .map((doc) => EnrollmentModel.fromFirestore(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        if (a.assignedAt == null && b.assignedAt == null) return 0;
        if (a.assignedAt == null) return 1;
        if (b.assignedAt == null) return -1;
        return b.assignedAt!.compareTo(a.assignedAt!);
      });
      return list;
    } catch (e) {
      throw const EnrollmentException(AppStrings.courseLoadError);
    }
  }

  Future<void> assignCourse({
    required String userId,
    required String courseId,
  }) async {
    await _verifyAdminAccess();
    final currentUser = _auth.currentUser!;
    final docId = '${userId}_$courseId';
    final docRef = _firestore.collection('enrollments').doc(docId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['status'] == 'removed') {
          transaction.update(docRef, {
            'status': 'active',
            'assignedBy': currentUser.uid,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        transaction.set(docRef, {
          'userId': userId,
          'courseId': courseId,
          'status': 'active',
          'assignedBy': currentUser.uid,
          'assignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> removeCourse({
    required String userId,
    required String courseId,
  }) async {
    await _verifyAdminAccess();
    final currentUser = _auth.currentUser!;
    final docId = '${userId}_$courseId';
    final docRef = _firestore.collection('enrollments').doc(docId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (doc.exists) {
        transaction.update(docRef, {
          'status': 'removed',
          'assignedBy': currentUser.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> restoreCourse({
    required String userId,
    required String courseId,
  }) async {
    await _verifyAdminAccess();
    final currentUser = _auth.currentUser!;
    final docId = '${userId}_$courseId';
    final docRef = _firestore.collection('enrollments').doc(docId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (doc.exists) {
        transaction.update(docRef, {
          'status': 'active',
          'assignedBy': currentUser.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(docRef, {
          'userId': userId,
          'courseId': courseId,
          'status': 'active',
          'assignedBy': currentUser.uid,
          'assignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<bool> isStudentEnrolled({
    required String userId,
    required String courseId,
  }) async {
    final docId = '${userId}_$courseId';
    final doc = await _firestore.collection('enrollments').doc(docId).get();
    if (!doc.exists) return false;
    final data = doc.data();
    return data != null && data['status'] == 'active';
  }
}
