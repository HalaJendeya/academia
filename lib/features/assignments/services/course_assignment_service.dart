import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/admin_access.dart';
import '../../courses/models/course_offering_model.dart';
import '../models/course_assignment_model.dart';

class CourseAssignmentException implements Exception {
  final String message;
  const CourseAssignmentException(this.message);

  @override
  String toString() => message;
}

/// خدمة الواجبات الأكاديمية.
///
/// مجموعة واحدة `/assignments` تخدم الأدوار الثلاثة: المعلّم يؤلّف داخل
/// طروحه، والطالب يقرأ واجبات ما سُجِّل فيه، والمشرف يشرف عالميًا. لا نماذج
/// خلفية منفصلة لكل دور.
///
/// كل كتابة تعيد قراءة مستند الطرح الحقيقي من Firestore. ما ترسله الواجهة
/// ليس مصدر حقيقة: لو اكتفينا بالتحقق مما أرسلته الشاشة لأمكن لطلب مُعدّ
/// يدويًا أن ينسب واجبًا إلى طرح معلّم آخر.
class CourseAssignmentService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CourseAssignmentService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _assignments =>
      _firestore.collection('assignments');

  List<CourseAssignmentModel> _map(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final list = snapshot.docs
        .map((doc) => CourseAssignmentModel.fromFirestore(doc.data(), doc.id))
        .toList();
    // الأقرب موعدًا أولًا، فيظهر المتأخر والمستحق قريبًا في الأعلى.
    list.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return list;
  }

  // ------------------------------------------------------------------ reads

  /// واجبات طرح واحد النشطة.
  ///
  /// التصفية في الاستعلام لا في الواجهة: تحميل المؤرشف ثم إخفاؤه يعني نقل
  /// بيانات لا يُفترض عرضها. استعلام مساواة مزدوج لا يحتاج فهرسًا مركّبًا.
  Stream<List<CourseAssignmentModel>> watchOfferingAssignments(
    String offeringId,
  ) {
    if (offeringId.trim().isEmpty) {
      return Stream<List<CourseAssignmentModel>>.value(
        const <CourseAssignmentModel>[],
      );
    }
    return _assignments
        .where('offeringId', isEqualTo: offeringId.trim())
        .where('status', isEqualTo: CourseAssignmentModel.statusActive)
        .snapshots()
        .map(_map);
  }

  /// كل الواجبات النشطة في النظام — إشراف المشرف وحده.
  ///
  /// القواعد تسمح بهذا الاستعلام للمشرف النشط فقط؛ أي دور آخر يُرفض عند
  /// أول مستند، لذلك يجب ألا يُفتح هذا المستمع لغير المشرف.
  Stream<List<CourseAssignmentModel>> watchAllActiveAssignments() {
    return _assignments
        .where('status', isEqualTo: CourseAssignmentModel.statusActive)
        .snapshots()
        .map(_map);
  }

  Future<List<CourseAssignmentModel>> getOfferingAssignments(
    String offeringId,
  ) async {
    if (offeringId.trim().isEmpty) return <CourseAssignmentModel>[];
    try {
      return _map(
        await _assignments
            .where('offeringId', isEqualTo: offeringId.trim())
            .where('status', isEqualTo: CourseAssignmentModel.statusActive)
            .get(),
      );
    } catch (e) {
      throw const CourseAssignmentException(
        AppStrings.courseAssignmentsLoadError,
      );
    }
  }

  /// عدد الواجبات النشطة، بتجميع من الخادم لا بتنزيل المجموعة.
  ///
  /// النمط نفسه المستخدم في عدّاد ملفات لوحة المشرف.
  Future<int> getActiveAssignmentCount() async {
    try {
      final snapshot = await _assignments
          .where('status', isEqualTo: CourseAssignmentModel.statusActive)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw const CourseAssignmentException(
        AppStrings.courseAssignmentsLoadError,
      );
    }
  }

  Future<CourseAssignmentModel?> getAssignmentById(String assignmentId) async {
    if (assignmentId.trim().isEmpty) return null;
    try {
      final doc = await _assignments.doc(assignmentId.trim()).get();
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return CourseAssignmentModel.fromFirestore(data, doc.id);
    } catch (e) {
      throw const CourseAssignmentException(
        AppStrings.courseAssignmentsLoadError,
      );
    }
  }

  // ---------------------------------------------------------- authorization

  /// يقرأ الطرح الحقيقي ويتحقق أن المستخدم معلّم نشط يملكه.
  ///
  /// الملكية تُقرأ من `courseOfferings/{id}.teacherId` وحده — لا من اسم
  /// المدرّس ولا من حالة الواجهة. يعيد الطرح نفسه حتى تُنسخ منه الحقول
  /// المرجعية بدل الوثوق بما أرسلته الشاشة.
  ///
  /// هذا تحقق راحة ورسائل واضحة؛ التطبيق الفعلي في قواعد Firestore.
  Future<({String uid, CourseOfferingModel offering})>
  _requireTeacherWriteAccess(String offeringId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const CourseAssignmentException(AppStrings.authenticationRequired);
    }
    if (offeringId.trim().isEmpty) {
      throw const CourseAssignmentException(AppStrings.offeringNotFound);
    }

    final uid = currentUser.uid;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userData = userDoc.data();
    if (!userDoc.exists || userData == null) {
      throw const CourseAssignmentException(AppStrings.unauthorizedAccess);
    }
    if (userData['role'] != 'teacher' ||
        (userData['status'] as String? ?? 'active') != 'active') {
      throw const CourseAssignmentException(AppStrings.unauthorizedAccess);
    }

    final offeringDoc = await _firestore
        .collection('courseOfferings')
        .doc(offeringId.trim())
        .get();
    final offeringData = offeringDoc.data();
    if (!offeringDoc.exists || offeringData == null) {
      throw const CourseAssignmentException(AppStrings.offeringNotFound);
    }

    final offering = CourseOfferingModel.fromFirestore(
      offeringData,
      offeringDoc.id,
    );
    if (offering.teacherId != uid) {
      throw const CourseAssignmentException(AppStrings.unauthorizedAccess);
    }

    return (uid: uid, offering: offering);
  }

  void _validateAuthoredFields({
    required String title,
    required String priority,
  }) {
    if (title.trim().isEmpty) {
      throw const CourseAssignmentException(AppStrings.assignmentTitleRequired);
    }
    if (!CourseAssignmentModel.allowedPriorities.contains(priority)) {
      throw const CourseAssignmentException(
        AppStrings.assignmentPriorityInvalid,
      );
    }
  }

  // ----------------------------------------------------------------- writes

  /// إنشاء واجب داخل طرح يملكه المعلّم.
  ///
  /// لا يقبل نموذجًا جاهزًا عمدًا: الحقول المرجعية (offeringId و courseId و
  /// semesterId و createdBy) تُشتقّ هنا من الطرح المقروء ومن هوية المستخدم،
  /// فلا تملك الواجهة طريقة لتلفيقها أصلًا.
  Future<String> createAssignment({
    required String offeringId,
    required String title,
    required String description,
    required DateTime dueAt,
    required String priority,
  }) async {
    final access = await _requireTeacherWriteAccess(offeringId);
    _validateAuthoredFields(title: title, priority: priority);

    final offering = access.offering;
    if (offering.courseId.trim().isEmpty ||
        offering.semesterId.trim().isEmpty) {
      throw const CourseAssignmentException(AppStrings.offeringNotFound);
    }

    try {
      final docRef = await _assignments.add({
        'offeringId': offering.id,
        'courseId': offering.courseId,
        'semesterId': offering.semesterId,
        'title': title.trim(),
        'description': description.trim(),
        'dueAt': Timestamp.fromDate(dueAt),
        'priority': priority,
        'status': CourseAssignmentModel.statusActive,
        'createdBy': access.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw const CourseAssignmentException(AppStrings.assignmentSaveError);
    }
  }

  /// تعديل الحقول التي يملك المعلّم تأليفها.
  ///
  /// الملكية تُقاس بـ offeringId المخزَّن في المستند الأصلي لا بأي قيمة
  /// واردة: لولا ذلك لأمكن نقل واجب إلى طرح معلّم آخر بإرسال معرّف مختلف.
  Future<void> updateAssignment({
    required String assignmentId,
    required String title,
    required String description,
    required DateTime dueAt,
    required String priority,
  }) async {
    if (assignmentId.trim().isEmpty) {
      throw const CourseAssignmentException(AppStrings.assignmentNotFound);
    }

    final docRef = _assignments.doc(assignmentId.trim());
    final doc = await docRef.get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      throw const CourseAssignmentException(AppStrings.assignmentNotFound);
    }

    final originalOfferingId = data['offeringId'] as String? ?? '';
    await _requireTeacherWriteAccess(originalOfferingId);
    _validateAuthoredFields(title: title, priority: priority);

    try {
      // الحقول المرجعية غائبة عن هذا التحديث تمامًا، لا مُعادة بقيمها.
      await docRef.update({
        'title': title.trim(),
        'description': description.trim(),
        'dueAt': Timestamp.fromDate(dueAt),
        'priority': priority,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw const CourseAssignmentException(AppStrings.assignmentUpdateError);
    }
  }

  /// أرشفة واجب من قِبل معلّمه.
  ///
  /// أرشفة لا حذف: الحذف النهائي مرفوض للجميع في القواعد.
  Future<void> archiveAssignment(String assignmentId) async {
    if (assignmentId.trim().isEmpty) {
      throw const CourseAssignmentException(AppStrings.assignmentNotFound);
    }

    final docRef = _assignments.doc(assignmentId.trim());
    final doc = await docRef.get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      throw const CourseAssignmentException(AppStrings.assignmentNotFound);
    }

    await _requireTeacherWriteAccess(data['offeringId'] as String? ?? '');

    try {
      await docRef.update({
        'status': CourseAssignmentModel.statusArchived,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw const CourseAssignmentException(AppStrings.assignmentUpdateError);
    }
  }

  /// أرشفة إشرافية من المشرف.
  ///
  /// مسار منفصل عن أرشفة المعلّم عمدًا: المشرف ليس مؤلّف المحتوى الأكاديمي.
  /// لا يملك إنشاءً ولا تعديل عنوان أو تعليمات أو موعد أو أولوية — فقط
  /// إخفاء واجب مخالف. القواعد تفرض الشيء نفسه بقصر الحقول المتغيّرة على
  /// status و updatedAt واشتراط أن تصبح الحالة 'archived'.
  Future<void> moderateArchiveAssignment(String assignmentId) async {
    if (!AdminAccess.isSignedIn(_auth)) {
      throw const CourseAssignmentException(AppStrings.authenticationRequired);
    }
    final adminUid = await AdminAccess.activeAdminUid(_auth, _firestore);
    if (adminUid == null) {
      throw const CourseAssignmentException(AppStrings.unauthorizedAccess);
    }
    if (assignmentId.trim().isEmpty) {
      throw const CourseAssignmentException(AppStrings.assignmentNotFound);
    }

    final docRef = _assignments.doc(assignmentId.trim());
    final doc = await docRef.get();
    if (!doc.exists || doc.data() == null) {
      throw const CourseAssignmentException(AppStrings.assignmentNotFound);
    }

    try {
      await docRef.update({
        'status': CourseAssignmentModel.statusArchived,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw const CourseAssignmentException(AppStrings.assignmentUpdateError);
    }
  }
}
