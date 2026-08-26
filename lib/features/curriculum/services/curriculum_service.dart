import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/admin_access.dart';
import '../models/curriculum_course_model.dart';

class CurriculumException implements Exception {
  final String message;
  const CurriculumException(this.message);

  @override
  String toString() => message;
}

/// خدمة الخطة الدراسية: أي المساقات تنتمي إلى تخصص معيّن وفي أي مستوى.
class CurriculumService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CurriculumService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _curriculum =>
      _firestore.collection('curriculumCourses');

  Future<String> _requireAdmin() async {
    if (!AdminAccess.isSignedIn(_auth)) {
      throw const CurriculumException(AppStrings.authenticationRequired);
    }
    final uid = await AdminAccess.activeAdminUid(_auth, _firestore);
    if (uid == null) {
      throw const CurriculumException(AppStrings.unauthorizedAccess);
    }
    return uid;
  }

  List<CurriculumCourseModel> _map(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final list = snapshot.docs
        .map((doc) => CurriculumCourseModel.fromFirestore(doc.data(), doc.id))
        .toList();
    // ترتيب الخطة: المستوى ثم ترتيب الصف داخل المستوى.
    list.sort((a, b) {
      final byLevel = a.academicLevel.compareTo(b.academicLevel);
      if (byLevel != 0) return byLevel;
      return a.sequence.compareTo(b.sequence);
    });
    return list;
  }

  /// كل صفوف الخطة لتخصص — استعلام حقل واحد، لا يحتاج فهرسًا مركبًا.
  Stream<List<CurriculumCourseModel>> watchCurriculum(String majorId) {
    return _curriculum
        .where('majorId', isEqualTo: majorId)
        .snapshots()
        .map(_map);
  }

  Future<List<CurriculumCourseModel>> getCurriculum(String majorId) async {
    if (majorId.trim().isEmpty) return <CurriculumCourseModel>[];
    try {
      return _map(await _curriculum.where('majorId', isEqualTo: majorId).get());
    } catch (e) {
      throw const CurriculumException(AppStrings.curriculumLoadError);
    }
  }

  Future<void> _verifyMajorExists(String majorId) async {
    final doc = await _firestore.collection('majors').doc(majorId).get();
    if (!doc.exists) {
      throw const CurriculumException(AppStrings.majorNotFound);
    }
  }

  Future<void> _verifyCourseExists(String courseId) async {
    final doc = await _firestore.collection('courses').doc(courseId).get();
    if (!doc.exists) {
      throw const CurriculumException(AppStrings.courseNotFound);
    }
  }

  void _validate(CurriculumCourseModel entry) {
    if (entry.majorId.trim().isEmpty) {
      throw const CurriculumException(AppStrings.majorNotFound);
    }
    if (!CurriculumCourseModel.allowedEntryTypes.contains(entry.entryType)) {
      throw const CurriculumException(AppStrings.curriculumEntryTypeInvalid);
    }
    if (!CurriculumCourseModel.allowedRequirementTypes.contains(
      entry.requirementType,
    )) {
      throw const CurriculumException(AppStrings.requirementTypeInvalid);
    }
    if (entry.academicLevel < CurriculumCourseModel.minAcademicLevel ||
        entry.academicLevel > CurriculumCourseModel.maxAcademicLevel) {
      throw const CurriculumException(AppStrings.academicLevelInvalid);
    }

    if (entry.isCourseEntry) {
      if (entry.courseId == null || entry.courseId!.trim().isEmpty) {
        throw const CurriculumException(AppStrings.curriculumCourseRequired);
      }
    } else {
      if (entry.slotLabel == null || entry.slotLabel!.trim().isEmpty) {
        throw const CurriculumException(AppStrings.curriculumSlotLabelRequired);
      }
      if (entry.creditHours == null || entry.creditHours! <= 0) {
        throw const CurriculumException(AppStrings.curriculumSlotHoursRequired);
      }
    }
  }

  /// إضافة مساق محدد إلى الخطة الدراسية.
  ///
  /// المتطلبات السابقة تُخزَّن ولا تُطبَّق في هذه المرحلة.
  Future<String> addCourseEntry(CurriculumCourseModel entry) async {
    await _requireAdmin();
    _validate(entry);
    await _verifyMajorExists(entry.majorId);
    await _verifyCourseExists(entry.courseId!);

    final docId = CurriculumCourseModel.buildId(entry.majorId, entry.courseId!);

    try {
      final docRef = _curriculum.doc(docId);
      final existing = await docRef.get();
      if (existing.exists) {
        throw const CurriculumException(
          AppStrings.curriculumEntryAlreadyExists,
        );
      }

      await docRef.set({
        ...entry.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docId;
    } on CurriculumException {
      rethrow;
    } catch (e) {
      throw const CurriculumException(AppStrings.curriculumSaveError);
    }
  }

  /// إضافة خانة متطلب لم يُختَر لها مساق بعد.
  ///
  /// لا يُنشأ أي مستند في مجموعة courses لهذه الخانات.
  Future<String> addSlotEntry(CurriculumCourseModel entry) async {
    await _requireAdmin();
    _validate(entry);
    await _verifyMajorExists(entry.majorId);

    final docId = CurriculumCourseModel.buildSlotId(
      entry.majorId,
      entry.academicLevel,
      entry.sequence,
    );

    try {
      await _curriculum.doc(docId).set({
        ...entry.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docId;
    } on CurriculumException {
      rethrow;
    } catch (e) {
      throw const CurriculumException(AppStrings.curriculumSaveError);
    }
  }

  Future<void> updateEntry(CurriculumCourseModel entry) async {
    await _requireAdmin();
    _validate(entry);

    if (entry.id.trim().isEmpty) {
      throw const CurriculumException(AppStrings.curriculumEntryNotFound);
    }

    try {
      await _curriculum.doc(entry.id).update({
        'academicLevel': entry.academicLevel,
        'requirementType': entry.requirementType,
        if (entry.creditHours != null) 'creditHours': entry.creditHours,
        if (entry.slotLabel != null) 'slotLabel': entry.slotLabel,
        'prerequisiteCourseIds': entry.prerequisiteCourseIds,
        /*
         * يُكتب دائمًا: حذف الحقل عند التفريغ لا مجرد تخطّيه. تخطّي القيمة
         * الفارغة كان يُبقي النص القديم في المستند، فلا يستطيع المشرف إزالة
         * متطلب سابق أُدخل بالخطأ.
         */
        'prerequisiteText': entry.prerequisiteText ?? FieldValue.delete(),
        'sequence': entry.sequence,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on CurriculumException {
      rethrow;
    } catch (e) {
      throw const CurriculumException(AppStrings.curriculumSaveError);
    }
  }

  Future<void> removeEntry(String entryId) async {
    await _requireAdmin();

    if (entryId.trim().isEmpty) {
      throw const CurriculumException(AppStrings.curriculumEntryNotFound);
    }

    try {
      await _curriculum.doc(entryId).delete();
    } catch (e) {
      throw const CurriculumException(AppStrings.curriculumSaveError);
    }
  }
}
