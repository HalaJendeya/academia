import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/admin_access.dart';
import '../../admin/models/admin_student_model.dart';
import '../../courses/models/course_offering_model.dart';
import '../models/enrollment_model.dart';

class EnrollmentException implements Exception {
  final String message;
  const EnrollmentException(this.message);

  @override
  String toString() => message;
}

/// خدمة تسجيل الطلاب في طروحات المساقات.
///
/// التسجيل يشير إلى طرح (offering) لا إلى مساق دائم، لأن المدرّس والفصل
/// الدراسي خاصان بالطرح. courseId و semesterId يُنسخان من الطرح عند الكتابة
/// حتى يمكن تجميع المحاولات حسب المساق والفصل باستعلام واحد.
class EnrollmentService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  EnrollmentService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _enrollments =>
      _firestore.collection('enrollments');

  Future<String> _requireAdmin() async {
    if (!AdminAccess.isSignedIn(_auth)) {
      throw const EnrollmentException(AppStrings.authenticationRequired);
    }
    final uid = await AdminAccess.activeAdminUid(_auth, _firestore);
    if (uid == null) {
      throw const EnrollmentException(AppStrings.unauthorizedAccess);
    }
    return uid;
  }

  List<EnrollmentModel> _mapSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs
        .map((doc) => EnrollmentModel.fromFirestore(doc.data(), doc.id))
        .toList();

    list.sort((a, b) {
      if (a.assignedAt == null && b.assignedAt == null) return 0;
      if (a.assignedAt == null) return 1;
      if (b.assignedAt == null) return -1;
      return b.assignedAt!.compareTo(a.assignedAt!);
    });

    return list;
  }

  /// قراءة الطرح والتحقق من صلاحيته للتسجيل.
  ///
  /// courseId و semesterId يُقرآن من الطرح ولا يُمرَّران من الواجهة، حتى لا
  /// يمكن أن يختلف التسجيل عن الطرح الذي يشير إليه.
  Future<CourseOfferingModel> _loadOfferingForEnrollment(
    String offeringId,
  ) async {
    if (offeringId.trim().isEmpty) {
      throw const EnrollmentException(AppStrings.offeringNotFound);
    }

    final doc = await _firestore
        .collection('courseOfferings')
        .doc(offeringId)
        .get();

    if (!doc.exists || doc.data() == null) {
      throw const EnrollmentException(AppStrings.offeringNotFound);
    }

    final offering = CourseOfferingModel.fromFirestore(doc.data()!, doc.id);

    if (offering.isCancelled) {
      throw const EnrollmentException(AppStrings.offeringCancelledCannotEnroll);
    }
    if (offering.courseId.trim().isEmpty ||
        offering.semesterId.trim().isEmpty) {
      throw const EnrollmentException(AppStrings.offeringNotFound);
    }

    return offering;
  }

  /// رقم المحاولة التالية لهذا الطالب في هذا المساق الدائم.
  ///
  /// يعتمد على أكبر رقم محاولة موجود وليس على عدد السجلات، وتُحتسب ضمنه
  /// السجلات المُزالة أيضًا: إزالة تسجيل لا تلغي أن المحاولة حدثت.
  Future<int> _nextAttemptNumber(String userId, String courseId) async {
    final snapshot = await _enrollments
        .where('userId', isEqualTo: userId)
        .where('courseId', isEqualTo: courseId)
        .get();

    var maxAttempt = 0;
    for (final doc in snapshot.docs) {
      final attempt = (doc.data()['attemptNumber'] as num?)?.toInt() ?? 1;
      if (attempt > maxAttempt) maxAttempt = attempt;
    }

    return maxAttempt + 1;
  }

  // ---------------------------------------------------------------- students

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

  // ------------------------------------------------------------- enrollments

  Stream<List<EnrollmentModel>> watchStudentEnrollments(String userId) {
    return _enrollments
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(_mapSnapshot);
  }

  Future<List<EnrollmentModel>> getStudentEnrollments(String userId) async {
    try {
      final snapshot = await _enrollments
          .where('userId', isEqualTo: userId)
          .get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      throw const EnrollmentException(AppStrings.courseLoadError);
    }
  }

  /// سجلات الطالب الحالي (واجهة الطالب). لا تتطلب صلاحية مشرف.
  ///
  /// استعلام واحد يخدم المساقات الحالية والسجل السابق معًا، لأن semesterId
  /// منسوخ في كل سجل.
  Stream<List<EnrollmentModel>> watchMyEnrollments() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream<List<EnrollmentModel>>.error(
        const EnrollmentException(AppStrings.authenticationRequired),
      );
    }

    return _enrollments
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .map(_mapSnapshot);
  }

  /// قائمة الطلاب المسجلين في طرح معيّن — استعلام مساواة فقط.
  Stream<List<EnrollmentModel>> watchOfferingRoster(String offeringId) {
    return _enrollments
        .where('offeringId', isEqualTo: offeringId)
        .where('status', isEqualTo: EnrollmentModel.statusActive)
        .snapshots()
        .map(_mapSnapshot);
  }

  /// تسجيل طالب في طرح مساق.
  ///
  /// إعادة تسجيل الطالب في الطرح نفسه بعد إزالته ليست محاولة جديدة، لذلك
  /// يُحتفظ برقم المحاولة الأصلي؛ المحاولة الجديدة تنشأ فقط بطرح مختلف
  /// (أي فصل دراسي آخر) ومن ثم بمستند مختلف.
  Future<void> assignToOffering({
    required String userId,
    required String offeringId,
  }) async {
    final adminUid = await _requireAdmin();
    final offering = await _loadOfferingForEnrollment(offeringId);

    final docRef = _enrollments.doc(
      EnrollmentModel.buildId(userId, offeringId),
    );
    final existing = await docRef.get();

    if (existing.exists) {
      final data = existing.data() ?? const <String, dynamic>{};
      final currentStatus =
          data['status'] as String? ?? EnrollmentModel.statusActive;

      if (currentStatus == EnrollmentModel.statusActive) {
        throw const EnrollmentException(AppStrings.alreadyEnrolledError);
      }

      await docRef.update({
        'status': EnrollmentModel.statusActive,
        // تراجع عن الإزالة: النتيجة الأكاديمية السابقة لم تعد صالحة.
        'completionStatus': FieldValue.delete(),
        'grade': FieldValue.delete(),
        // استكمال السجلات القديمة التي أُنشئت قبل فصل الطروحات.
        'offeringId': offeringId,
        'courseId': offering.courseId,
        'semesterId': offering.semesterId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final attemptNumber = await _nextAttemptNumber(userId, offering.courseId);

    await docRef.set({
      'userId': userId,
      'offeringId': offeringId,
      'courseId': offering.courseId,
      'semesterId': offering.semesterId,
      'attemptNumber': attemptNumber,
      'status': EnrollmentModel.statusActive,
      'assignedBy': adminUid,
      'assignedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// تسجيل نتيجة المحاولة الأكاديمية وإنهاؤها.
  ///
  /// التقدير نص للعرض فقط؛ لا يوجد نظام تقديرات أو حساب معدل في هذه المرحلة.
  Future<void> setCompletionStatus({
    required String userId,
    required String offeringId,
    required String completionStatus,
    String? grade,
  }) async {
    await _requireAdmin();

    if (!EnrollmentModel.allowedCompletionStatuses.contains(completionStatus)) {
      throw const EnrollmentException(AppStrings.completionStatusInvalid);
    }

    final docRef = _enrollments.doc(
      EnrollmentModel.buildId(userId, offeringId),
    );
    final doc = await docRef.get();

    if (!doc.exists) {
      throw const EnrollmentException(AppStrings.enrollmentNotFoundError);
    }

    final trimmedGrade = grade?.trim();

    await docRef.update({
      'status': EnrollmentModel.statusCompleted,
      'completionStatus': completionStatus,
      if (trimmedGrade != null && trimmedGrade.isNotEmpty)
        'grade': trimmedGrade,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// إزالة ناعمة: يبقى السجل متاحًا للمشرف كسجل تدقيق ويُخفى عن الطالب.
  Future<void> removeEnrollment({
    required String userId,
    required String offeringId,
  }) async {
    await _requireAdmin();

    final docRef = _enrollments.doc(
      EnrollmentModel.buildId(userId, offeringId),
    );
    final doc = await docRef.get();

    if (!doc.exists) {
      throw const EnrollmentException(AppStrings.enrollmentNotFoundError);
    }

    await docRef.update({
      'status': EnrollmentModel.statusRemoved,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// إعادة تسجيل بعد إزالة.
  ///
  /// لا تُنشئ سجلًا مفقودًا: غياب المستند يعني أن ما يُعاد ليس موجودًا أصلًا،
  /// وإنشاؤه هنا يتجاوز احتساب رقم المحاولة. الإنشاء يمر عبر
  /// [assignToOffering] وحده.
  Future<void> restoreEnrollment({
    required String userId,
    required String offeringId,
  }) async {
    await _requireAdmin();
    final offering = await _loadOfferingForEnrollment(offeringId);

    final docRef = _enrollments.doc(
      EnrollmentModel.buildId(userId, offeringId),
    );
    final doc = await docRef.get();

    if (!doc.exists) {
      throw const EnrollmentException(AppStrings.enrollmentNotFoundError);
    }

    await docRef.update({
      'status': EnrollmentModel.statusActive,
      'completionStatus': FieldValue.delete(),
      'grade': FieldValue.delete(),
      'offeringId': offeringId,
      'courseId': offering.courseId,
      'semesterId': offering.semesterId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// تغيير حالة دورة حياة التسجيل ضمن القيم المسموح بها فقط.
  ///
  /// النتيجة الأكاديمية تُسجَّل عبر [setCompletionStatus]؛ هذه الدالة تغيّر
  /// الحالة الإدارية فقط.
  Future<void> setEnrollmentStatus({
    required String userId,
    required String offeringId,
    required String status,
  }) async {
    await _requireAdmin();

    if (!EnrollmentModel.allowedStatuses.contains(status)) {
      throw const EnrollmentException(AppStrings.enrollmentStatusInvalid);
    }

    final docRef = _enrollments.doc(
      EnrollmentModel.buildId(userId, offeringId),
    );
    final doc = await docRef.get();

    if (!doc.exists) {
      throw const EnrollmentException(AppStrings.enrollmentNotFoundError);
    }

    await docRef.update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isStudentEnrolledInOffering({
    required String userId,
    required String offeringId,
  }) async {
    final doc = await _enrollments
        .doc(EnrollmentModel.buildId(userId, offeringId))
        .get();
    if (!doc.exists) return false;
    return doc.data()?['status'] == EnrollmentModel.statusActive;
  }
}
