import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../models/course_model.dart';

class CourseException implements Exception {
  final String message;
  const CourseException(this.message);

  @override
  String toString() => message;
}

class CourseService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CourseService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<CourseModel>> watchCourses() {
    return _firestore
        .collection('courses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CourseModel.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<List<CourseModel>> getCourses() async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => CourseModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw const CourseException(AppStrings.courseLoadError);
    }
  }

  Future<CourseModel?> getCourseById(String courseId) async {
    try {
      final doc = await _firestore.collection('courses').doc(courseId).get();
      if (!doc.exists || doc.data() == null) return null;
      return CourseModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw const CourseException(AppStrings.courseLoadError);
    }
  }

  Future<String> createCourse(CourseModel course) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const CourseException(AppStrings.authenticationRequired);
    }

    if (course.title.trim().isEmpty) {
      throw const CourseException(AppStrings.courseTitleRequired);
    }
    if (course.courseCode.trim().isEmpty) {
      throw const CourseException(AppStrings.courseCodeRequired);
    }
    if (course.instructorName.trim().isEmpty) {
      throw const CourseException(AppStrings.instructorRequired);
    }
    if (course.department.trim().isEmpty) {
      throw const CourseException(AppStrings.departmentRequired);
    }
    if (course.semester <= 0) {
      throw const CourseException(AppStrings.semesterInvalid);
    }
    if (course.creditHours <= 0) {
      throw const CourseException(AppStrings.creditHoursInvalid);
    }
    if (course.academicYear.trim().isEmpty) {
      throw const CourseException(AppStrings.academicYearRequired);
    }

    try {
      final docRef = _firestore.collection('courses').doc();
      await docRef.set({
        ...course.toMap(),
        'createdBy': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw const CourseException(AppStrings.courseSaveError);
    }
  }

  Future<void> updateCourse(CourseModel course) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const CourseException(AppStrings.authenticationRequired);
    }

    if (course.title.trim().isEmpty) {
      throw const CourseException(AppStrings.courseTitleRequired);
    }
    if (course.courseCode.trim().isEmpty) {
      throw const CourseException(AppStrings.courseCodeRequired);
    }
    if (course.instructorName.trim().isEmpty) {
      throw const CourseException(AppStrings.instructorRequired);
    }
    if (course.department.trim().isEmpty) {
      throw const CourseException(AppStrings.departmentRequired);
    }
    if (course.semester <= 0) {
      throw const CourseException(AppStrings.semesterInvalid);
    }
    if (course.creditHours <= 0) {
      throw const CourseException(AppStrings.creditHoursInvalid);
    }
    if (course.academicYear.trim().isEmpty) {
      throw const CourseException(AppStrings.academicYearRequired);
    }

    try {
      await _firestore.collection('courses').doc(course.id).update({
        ...course.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw const CourseException(AppStrings.courseSaveError);
    }
  }

  Future<void> archiveCourse(String courseId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const CourseException(AppStrings.authenticationRequired);
    }

    try {
      await _firestore.collection('courses').doc(courseId).update({
        'status': 'archived',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw const CourseException(AppStrings.courseSaveError);
    }
  }

  Future<void> deleteCourse(String courseId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const CourseException(AppStrings.authenticationRequired);
    }

    try {
      await _firestore.collection('courses').doc(courseId).delete();
    } catch (e) {
      throw const CourseException(AppStrings.courseSaveError);
    }
  }
}
