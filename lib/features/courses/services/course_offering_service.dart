import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/admin_access.dart';
import '../models/course_offering_model.dart';

class CourseOfferingException implements Exception {
  final String message;
  const CourseOfferingException(this.message);

  @override
  String toString() => message;
}

/// خدمة طروحات المساقات: مساق واحد × فصل دراسي واحد × شعبة واحدة.
///
/// كل منطق الفصول الدراسية الخاص بالمساقات انتقل إلى هنا من CourseService.
class CourseOfferingService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CourseOfferingService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _offerings =>
      _firestore.collection('courseOfferings');

  Future<String> _requireAdmin() async {
    if (!AdminAccess.isSignedIn(_auth)) {
      throw const CourseOfferingException(AppStrings.authenticationRequired);
    }
    final uid = await AdminAccess.activeAdminUid(_auth, _firestore);
    if (uid == null) {
      throw const CourseOfferingException(AppStrings.unauthorizedAccess);
    }
    return uid;
  }

  List<CourseOfferingModel> _map(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final list = snapshot.docs
        .map((doc) => CourseOfferingModel.fromFirestore(doc.data(), doc.id))
        .toList();
    list.sort((a, b) {
      final bySemester = b.semesterId.compareTo(a.semesterId);
      if (bySemester != 0) return bySemester;
      return a.section.compareTo(b.section);
    });
    return list;
  }

  Stream<List<CourseOfferingModel>> watchOfferingsBySemester(
    String semesterId,
  ) {
    return _offerings
        .where('semesterId', isEqualTo: semesterId)
        .snapshots()
        .map(_map);
  }

  /// طروحات فصل دراسي محدد وحالتها نشطة — استعلام مساواة فقط.
  Stream<List<CourseOfferingModel>> watchActiveOfferingsBySemester(
    String semesterId,
  ) {
    return _offerings
        .where('semesterId', isEqualTo: semesterId)
        .where('status', isEqualTo: CourseOfferingModel.statusActive)
        .snapshots()
        .map(_map);
  }

  Future<List<CourseOfferingModel>> getOfferingsBySemester(
    String semesterId,
  ) async {
    try {
      return _map(
        await _offerings.where('semesterId', isEqualTo: semesterId).get(),
      );
    } catch (e) {
      throw const CourseOfferingException(AppStrings.offeringLoadError);
    }
  }

  /// طروحات معلّم واحد عبر كل الفصول — استعلام مساواة فقط.
  ///
  /// هذا هو الاستعلام الوحيد الذي تبني عليه واجهة المعلّم: الملكية تُقرأ من
  /// teacherId المخزَّن لا من اسم المدرّس، فالاسم نص حر لا يُطابق حسابًا.
  Stream<List<CourseOfferingModel>> watchOfferingsByTeacher(String teacherId) {
    if (teacherId.trim().isEmpty) {
      return Stream<List<CourseOfferingModel>>.value(
        const <CourseOfferingModel>[],
      );
    }
    return _offerings
        .where('teacherId', isEqualTo: teacherId.trim())
        .snapshots()
        .map(_map);
  }

  /// كل طروحات مساق دائم عبر الفصول — "متى طُرح هذا المساق؟"
  Stream<List<CourseOfferingModel>> watchOfferingsByCourse(String courseId) {
    return _offerings
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map(_map);
  }

  /// جلب طروحات بعينها بمعرّفاتها على دفعات (حد whereIn هو 30).
  ///
  /// هذه هي الطريقة التي يحلّ بها سجل الطالب طروحه القديمة: التسجيل يحمل
  /// offeringId، فنطلب تلك الطروحات وحدها بدل تحميل كل طروحات كل الفصول.
  Future<List<CourseOfferingModel>> getOfferingsByIds(
    List<String> offeringIds,
  ) async {
    final unique = offeringIds
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();
    if (unique.isEmpty) return <CourseOfferingModel>[];

    try {
      final result = <CourseOfferingModel>[];
      for (var i = 0; i < unique.length; i += 30) {
        final chunk = unique.sublist(
          i,
          i + 30 > unique.length ? unique.length : i + 30,
        );
        final snapshot = await _offerings
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        result.addAll(
          snapshot.docs.map(
            (doc) => CourseOfferingModel.fromFirestore(doc.data(), doc.id),
          ),
        );
      }
      return result;
    } catch (e) {
      throw const CourseOfferingException(AppStrings.offeringLoadError);
    }
  }

  Future<CourseOfferingModel?> getOfferingById(String offeringId) async {
    if (offeringId.trim().isEmpty) return null;
    try {
      final doc = await _offerings.doc(offeringId).get();
      if (!doc.exists || doc.data() == null) return null;
      return CourseOfferingModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw const CourseOfferingException(AppStrings.offeringLoadError);
    }
  }

  Future<void> _verifyCourseExists(String courseId) async {
    final doc = await _firestore.collection('courses').doc(courseId).get();
    if (!doc.exists) {
      throw const CourseOfferingException(AppStrings.courseNotFound);
    }
  }

  Future<void> _verifySemesterExists(String semesterId) async {
    final doc = await _firestore.collection('semesters').doc(semesterId).get();
    if (!doc.exists) {
      throw const CourseOfferingException(AppStrings.semesterNotFound);
    }
  }

  void _validate(CourseOfferingModel offering) {
    if (offering.courseId.trim().isEmpty) {
      throw const CourseOfferingException(AppStrings.offeringCourseRequired);
    }
    if (offering.semesterId.trim().isEmpty) {
      throw const CourseOfferingException(AppStrings.offeringSemesterRequired);
    }
    if (offering.instructorName.trim().isEmpty) {
      throw const CourseOfferingException(
        AppStrings.offeringInstructorRequired,
      );
    }
    if (!CourseOfferingModel.allowedStatuses.contains(offering.status)) {
      throw const CourseOfferingException(AppStrings.offeringStatusInvalid);
    }
  }

  Future<String> createOffering(CourseOfferingModel offering) async {
    final adminUid = await _requireAdmin();
    _validate(offering);
    await _verifyCourseExists(offering.courseId);
    await _verifySemesterExists(offering.semesterId);

    final docId = CourseOfferingModel.buildId(
      offering.courseId,
      offering.semesterId,
      offering.section,
    );

    try {
      final docRef = _offerings.doc(docId);
      final existing = await docRef.get();
      if (existing.exists) {
        throw const CourseOfferingException(AppStrings.offeringAlreadyExists);
      }

      await docRef.set({
        ...offering.toMap(),
        'createdBy': adminUid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docId;
    } on CourseOfferingException {
      rethrow;
    } catch (e) {
      throw const CourseOfferingException(AppStrings.offeringSaveError);
    }
  }

  /// تحديث الحقول القابلة للتعديل فقط.
  ///
  /// courseId و semesterId و section تشكّل معرّف المستند، لذلك لا تُعدَّل؛
  /// لتغييرها يجب إنشاء طرح جديد.
  Future<void> updateOffering(CourseOfferingModel offering) async {
    await _requireAdmin();
    _validate(offering);

    if (offering.id.trim().isEmpty) {
      throw const CourseOfferingException(AppStrings.offeringNotFound);
    }

    try {
      await _offerings.doc(offering.id).update({
        /*
         * إلغاء الإسناد يحذف الحقل ولا يكتبه فارغًا: القواعد تشترط لأي
         * teacherId موجود أن يشير إلى حساب معلّم فعلي، والطرح غير المملوك
         * يُمثَّل بغياب الحقل تمامًا كما في الطروحات القديمة.
         */
        'teacherId': offering.hasTeacher
            ? offering.teacherId
            : FieldValue.delete(),
        'instructorName': offering.instructorName,
        'status': offering.status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on CourseOfferingException {
      rethrow;
    } catch (e) {
      throw const CourseOfferingException(AppStrings.offeringSaveError);
    }
  }

  Future<void> archiveOffering(String offeringId) async {
    await _requireAdmin();

    final offering = await getOfferingById(offeringId);
    if (offering == null) {
      throw const CourseOfferingException(AppStrings.offeringNotFound);
    }

    try {
      await _offerings.doc(offeringId).update({
        'status': CourseOfferingModel.statusArchived,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw const CourseOfferingException(AppStrings.offeringSaveError);
    }
  }

  /// نسخ طروحات فصل دراسي إلى فصل آخر.
  ///
  /// يحافظ على المساق والشعبة واسم المدرّس كقيم افتراضية قابلة للتعديل.
  /// العملية مُتسقة عند التكرار (idempotent) لأن معرّفات المستندات توليدية،
  /// فإعادة التشغيل تستبدل ولا تُنشئ نسخًا مكررة.
  ///
  /// يعيد عدد الطروحات المكتوبة.
  Future<int> duplicateSemesterOfferings({
    required String fromSemesterId,
    required String toSemesterId,
  }) async {
    final adminUid = await _requireAdmin();

    if (fromSemesterId.trim().isEmpty || toSemesterId.trim().isEmpty) {
      throw const CourseOfferingException(AppStrings.offeringSemesterRequired);
    }
    if (fromSemesterId == toSemesterId) {
      throw const CourseOfferingException(AppStrings.offeringAlreadyExists);
    }
    await _verifySemesterExists(toSemesterId);

    final source = await getOfferingsBySemester(fromSemesterId);
    if (source.isEmpty) return 0;

    try {
      final batch = _firestore.batch();
      var count = 0;

      for (final offering in source) {
        // لا نستنسخ الطروحات الملغاة.
        if (offering.isCancelled) continue;

        final newId = CourseOfferingModel.buildId(
          offering.courseId,
          toSemesterId,
          offering.section,
        );

        batch.set(_offerings.doc(newId), {
          'courseId': offering.courseId,
          'semesterId': toSemesterId,
          // المعلّم يُنسخ مع الطرح كقيمة افتراضية قابلة للتعديل، تمامًا كما
          // يُنسخ اسم المدرّس: الفصل الجديد يبدأ من توزيع الفصل السابق.
          if (offering.hasTeacher) 'teacherId': offering.teacherId,
          'instructorName': offering.instructorName,
          'section': offering.section,
          'status': CourseOfferingModel.statusActive,
          'source': CourseOfferingModel.sourceManual,
          'createdBy': adminUid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        count++;
      }

      if (count > 0) await batch.commit();
      return count;
    } on CourseOfferingException {
      rethrow;
    } catch (e) {
      throw const CourseOfferingException(AppStrings.offeringSaveError);
    }
  }
}
