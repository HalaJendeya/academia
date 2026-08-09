import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../models/semester_model.dart';

class SemesterException implements Exception {
  final String message;
  const SemesterException(this.message);

  @override
  String toString() => message;
}

class SemesterService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  SemesterService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'semesters';

  CollectionReference<Map<String, dynamic>> get _semesters =>
      _firestore.collection(_collection);

  Future<void> _verifyAdminAccess() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const SemesterException(AppStrings.authenticationRequired);
    }

    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    if (!userDoc.exists) {
      throw const SemesterException(AppStrings.unauthorizedAccess);
    }

    final data = userDoc.data();
    if (data == null || data['role'] != 'admin') {
      throw const SemesterException(AppStrings.unauthorizedAccess);
    }

    /*
     * توافق انتقالي: بعض مستندات المستخدمين القديمة لا تحتوي على الحقل status.
     * نتعامل مع غيابه على أنه "نشط"، تمامًا كما يفعل AppUserModel وقواعد
     * Firestore في المرحلة 6A. يُشدَّد هذا الشرط بعد إكمال ترحيل البيانات.
     */
    final status = data['status'] as String? ?? 'active';
    if (status != 'active') {
      throw const SemesterException(AppStrings.unauthorizedAccess);
    }
  }

  List<SemesterModel> _mapSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs
        .map((doc) => SemesterModel.fromFirestore(doc.data(), doc.id))
        .toList();

    // الأحدث أولًا: السنة الأكاديمية ثم رقم الفصل.
    list.sort((a, b) {
      final yearCompare = b.academicYear.compareTo(a.academicYear);
      if (yearCompare != 0) return yearCompare;
      return b.semesterNumber.compareTo(a.semesterNumber);
    });

    return list;
  }

  Stream<List<SemesterModel>> watchSemesters() {
    return _semesters.snapshots().map(_mapSnapshot);
  }

  Future<List<SemesterModel>> getSemesters() async {
    try {
      final snapshot = await _semesters.get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      throw const SemesterException(AppStrings.semesterLoadError);
    }
  }

  /// الفصل الدراسي الحالي يُحدَّد بالحقل status فقط، وليس بالتواريخ.
  Stream<SemesterModel?> watchCurrentSemester() {
    return _semesters
        .where('status', isEqualTo: SemesterModel.statusCurrent)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final doc = snapshot.docs.first;
          return SemesterModel.fromFirestore(doc.data(), doc.id);
        });
  }

  Future<SemesterModel?> getCurrentSemester() async {
    try {
      final snapshot = await _semesters
          .where('status', isEqualTo: SemesterModel.statusCurrent)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return SemesterModel.fromFirestore(doc.data(), doc.id);
    } catch (e) {
      throw const SemesterException(AppStrings.semesterLoadError);
    }
  }

  void _validate(SemesterModel semester) {
    if (semester.academicYear.trim().isEmpty) {
      throw const SemesterException(AppStrings.academicYearRequired);
    }
    if (semester.semesterNumber <= 0) {
      throw const SemesterException(AppStrings.semesterNumberInvalid);
    }
    if (semester.semesterName.trim().isEmpty) {
      throw const SemesterException(AppStrings.semesterNameRequired);
    }
    if (!SemesterModel.allowedStatuses.contains(semester.status)) {
      throw const SemesterException(AppStrings.semesterStatusInvalid);
    }
  }

  /// إنشاء فصل دراسي بمعرّف توليدي ثابت مع منع التكرار.
  Future<String> createSemester(SemesterModel semester) async {
    await _verifyAdminAccess();
    _validate(semester);

    final docId = SemesterModel.buildId(
      semester.academicYear,
      semester.semesterNumber,
    );

    try {
      final docRef = _semesters.doc(docId);
      final existing = await docRef.get();

      if (existing.exists) {
        throw const SemesterException(AppStrings.semesterAlreadyExists);
      }

      await docRef.set({
        ...semester.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docId;
    } on SemesterException {
      rethrow;
    } catch (e) {
      throw const SemesterException(AppStrings.semesterSaveError);
    }
  }

  /// تحديث الحقول القابلة للتعديل فقط.
  ///
  /// academicYear و semesterNumber يشكّلان معرّف المستند، لذلك لا يمكن
  /// تعديلهما؛ لتغييرهما يجب إنشاء فصل دراسي جديد.
  Future<void> updateSemester(SemesterModel semester) async {
    await _verifyAdminAccess();
    _validate(semester);

    if (semester.id.trim().isEmpty) {
      throw const SemesterException(AppStrings.semesterNotFound);
    }

    try {
      await _semesters.doc(semester.id).update({
        'semesterName': semester.semesterName,
        'status': semester.status,
        'startDate': semester.startDate == null
            ? null
            : Timestamp.fromDate(semester.startDate!),
        'endDate': semester.endDate == null
            ? null
            : Timestamp.fromDate(semester.endDate!),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw const SemesterException(AppStrings.semesterSaveError);
    }
  }

  /// تعيين الفصل الدراسي الحالي.
  ///
  /// تتم العملية داخل دفعة واحدة (batch) حتى لا يوجد أكثر من فصل دراسي
  /// بحالة current في أي لحظة: الفصل الحالي السابق يتحول إلى completed
  /// والفصل المستهدف يتحول إلى current.
  Future<void> setCurrentSemester(String semesterId) async {
    await _verifyAdminAccess();

    if (semesterId.trim().isEmpty) {
      throw const SemesterException(AppStrings.semesterNotFound);
    }

    try {
      final targetRef = _semesters.doc(semesterId);
      final target = await targetRef.get();

      if (!target.exists) {
        throw const SemesterException(AppStrings.semesterNotFound);
      }

      // قد يوجد أكثر من مستند بحالة current نتيجة بيانات قديمة، لذلك
      // نتعامل مع النتيجة كقائمة وليس كمستند واحد.
      final currentSnapshot = await _semesters
          .where('status', isEqualTo: SemesterModel.statusCurrent)
          .get();

      final batch = _firestore.batch();

      for (final doc in currentSnapshot.docs) {
        if (doc.id == semesterId) continue;
        batch.update(doc.reference, {
          'status': SemesterModel.statusCompleted,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      batch.update(targetRef, {
        'status': SemesterModel.statusCurrent,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } on SemesterException {
      rethrow;
    } catch (e) {
      throw const SemesterException(AppStrings.semesterSaveError);
    }
  }
}
