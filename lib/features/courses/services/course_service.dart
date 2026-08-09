import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/admin_access.dart';
import '../models/course_model.dart';

class CourseException implements Exception {
  final String message;
  const CourseException(this.message);

  @override
  String toString() => message;
}

/// خدمة دليل المساقات الدائمة (الكتالوج).
///
/// لا تحتوي على أي منطق خاص بالفصول الدراسية؛ انتقل ذلك بالكامل إلى
/// CourseOfferingService.
class CourseService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CourseService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _courses =>
      _firestore.collection('courses');

  Future<String> _requireAdmin() async {
    if (!AdminAccess.isSignedIn(_auth)) {
      throw const CourseException(AppStrings.authenticationRequired);
    }
    final uid = await AdminAccess.activeAdminUid(_auth, _firestore);
    if (uid == null) {
      throw const CourseException(AppStrings.unauthorizedAccess);
    }
    return uid;
  }

  List<CourseModel> _map(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final list = snapshot.docs
        .map((doc) => CourseModel.fromFirestore(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => a.courseCode.compareTo(b.courseCode));
    return list;
  }

  Stream<List<CourseModel>> watchCourses() => _courses.snapshots().map(_map);

  Future<List<CourseModel>> getCourses() async {
    try {
      return _map(await _courses.get());
    } catch (e) {
      throw const CourseException(AppStrings.courseLoadError);
    }
  }

  Future<CourseModel?> getCourseById(String courseId) async {
    if (courseId.trim().isEmpty) return null;
    try {
      final doc = await _courses.doc(courseId).get();
      if (!doc.exists || doc.data() == null) return null;
      return CourseModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw const CourseException(AppStrings.courseLoadError);
    }
  }

  /// جلب مجموعة مساقات بمعرّفاتها على دفعات (حد whereIn هو 30).
  Future<List<CourseModel>> getCoursesByIds(List<String> courseIds) async {
    final unique = courseIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (unique.isEmpty) return <CourseModel>[];

    try {
      final result = <CourseModel>[];
      for (var i = 0; i < unique.length; i += 30) {
        final chunk = unique.sublist(
          i,
          i + 30 > unique.length ? unique.length : i + 30,
        );
        final snapshot = await _courses
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        result.addAll(
          snapshot.docs.map(
            (doc) => CourseModel.fromFirestore(doc.data(), doc.id),
          ),
        );
      }
      result.sort((a, b) => a.courseCode.compareTo(b.courseCode));
      return result;
    } catch (e) {
      throw const CourseException(AppStrings.courseLoadError);
    }
  }

  Stream<List<CourseModel>> watchCoursesByDepartment(String departmentId) {
    return _courses
        .where('departmentId', isEqualTo: departmentId)
        .snapshots()
        .map(_map);
  }

  /// رمز المساق حقل عمل فريد.
  ///
  /// لا يمكن فرض التفرّد في قواعد Firestore لأنها لا تنفّذ استعلامات، لذلك
  /// يُفحص هنا. الفحص إرشادي وليس ذريًا، وهو كافٍ لمشرف واحد.
  Future<void> _verifyCourseCodeUnique(
    String courseCode, {
    String? excludeCourseId,
  }) async {
    final normalized = CourseModel.normalizeCode(courseCode);
    final snapshot = await _courses
        .where('courseCode', isEqualTo: normalized)
        .get();

    final clash = snapshot.docs.any((doc) => doc.id != excludeCourseId);
    if (clash) {
      throw const CourseException(AppStrings.courseCodeAlreadyExists);
    }
  }

  Future<void> _verifyDepartmentExists(String departmentId) async {
    final doc = await _firestore
        .collection('departments')
        .doc(departmentId)
        .get();
    if (!doc.exists) {
      throw const CourseException(AppStrings.departmentNotFound);
    }
  }

  void _validate(CourseModel course) {
    if (course.title.trim().isEmpty) {
      throw const CourseException(AppStrings.courseTitleRequired);
    }
    if (course.courseCode.trim().isEmpty) {
      throw const CourseException(AppStrings.courseCodeRequired);
    }
    if (course.creditHours <= 0) {
      throw const CourseException(AppStrings.creditHoursInvalid);
    }
    if (course.departmentId.trim().isEmpty) {
      throw const CourseException(AppStrings.courseDepartmentRequired);
    }
    if (!CourseModel.allowedStatuses.contains(course.status)) {
      throw const CourseException(AppStrings.courseStatusInvalid);
    }
  }

  Future<String> createCourse(CourseModel course) async {
    final adminUid = await _requireAdmin();
    _validate(course);
    await _verifyDepartmentExists(course.departmentId);
    await _verifyCourseCodeUnique(course.courseCode);

    try {
      final docRef = _courses.doc();
      await docRef.set({
        ...course.toMap(),
        'courseCode': CourseModel.normalizeCode(course.courseCode),
        'createdBy': adminUid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } on CourseException {
      rethrow;
    } catch (e) {
      throw const CourseException(AppStrings.courseSaveError);
    }
  }

  Future<void> updateCourse(CourseModel course) async {
    await _requireAdmin();
    _validate(course);
    await _verifyDepartmentExists(course.departmentId);
    await _verifyCourseCodeUnique(
      course.courseCode,
      excludeCourseId: course.id,
    );

    try {
      final data = {...course.toMap()};
      // createdBy غير قابل للتعديل، وقواعد Firestore تفرض ذلك أيضًا.
      data.remove('createdBy');
      data['courseCode'] = CourseModel.normalizeCode(course.courseCode);

      await _courses.doc(course.id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on CourseException {
      rethrow;
    } catch (e) {
      throw const CourseException(AppStrings.courseSaveError);
    }
  }

  /// أرشفة المساق الدائم. لا يوجد حذف نهائي.
  Future<void> archiveCourse(String courseId) async {
    await _requireAdmin();

    final course = await getCourseById(courseId);
    if (course == null) {
      throw const CourseException(AppStrings.courseNotFound);
    }

    try {
      await _courses.doc(courseId).update({
        'status': CourseModel.statusArchived,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw const CourseException(AppStrings.courseSaveError);
    }
  }

  /*
   * ملاحظة: لا توجد دالة deleteCourse — الأرشفة هي السلوك المعتمد،
   * وقواعد Firestore تمنع الحذف النهائي.
   */
}
