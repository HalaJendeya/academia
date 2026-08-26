import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/admin_access.dart';
import '../models/major_model.dart';

class MajorException implements Exception {
  final String message;
  const MajorException(this.message);

  @override
  String toString() => message;
}

class MajorService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  MajorService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _majors =>
      _firestore.collection('majors');

  Future<String> _requireAdmin() async {
    if (!AdminAccess.isSignedIn(_auth)) {
      throw const MajorException(AppStrings.authenticationRequired);
    }
    final uid = await AdminAccess.activeAdminUid(_auth, _firestore);
    if (uid == null) {
      throw const MajorException(AppStrings.unauthorizedAccess);
    }
    return uid;
  }

  List<MajorModel> _map(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final list = snapshot.docs
        .map((doc) => MajorModel.fromFirestore(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Stream<List<MajorModel>> watchMajors() => _majors.snapshots().map(_map);

  Future<List<MajorModel>> getMajors() async {
    try {
      return _map(await _majors.get());
    } catch (e) {
      throw const MajorException(AppStrings.majorLoadError);
    }
  }

  Future<MajorModel?> getMajorById(String id) async {
    if (id.trim().isEmpty) return null;
    try {
      final doc = await _majors.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return MajorModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw const MajorException(AppStrings.majorLoadError);
    }
  }

  Stream<List<MajorModel>> watchMajorsByDepartment(String departmentId) {
    return _majors
        .where('departmentId', isEqualTo: departmentId)
        .snapshots()
        .map(_map);
  }

  Future<void> _verifyDepartmentExists(String departmentId) async {
    final doc = await _firestore
        .collection('departments')
        .doc(departmentId)
        .get();
    if (!doc.exists) {
      throw const MajorException(AppStrings.departmentNotFound);
    }
  }

  void _validate(MajorModel major) {
    if (major.name.trim().isEmpty) {
      throw const MajorException(AppStrings.majorNameRequired);
    }
    if (major.code.trim().isEmpty) {
      throw const MajorException(AppStrings.majorCodeRequired);
    }
    if (major.departmentId.trim().isEmpty) {
      throw const MajorException(AppStrings.courseDepartmentRequired);
    }
    if (major.totalLevels <= 0) {
      throw const MajorException(AppStrings.majorTotalLevelsInvalid);
    }
    if (!MajorModel.allowedStatuses.contains(major.status)) {
      throw const MajorException(AppStrings.majorStatusInvalid);
    }
  }

  Future<String> createMajor(MajorModel major) async {
    await _requireAdmin();
    _validate(major);
    await _verifyDepartmentExists(major.departmentId);

    try {
      final docRef = _majors.doc();
      await docRef.set({
        ...major.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } on MajorException {
      rethrow;
    } catch (e) {
      throw const MajorException(AppStrings.majorSaveError);
    }
  }

  Future<void> updateMajor(MajorModel major) async {
    await _requireAdmin();
    _validate(major);
    await _verifyDepartmentExists(major.departmentId);

    if (major.id.trim().isEmpty) {
      throw const MajorException(AppStrings.majorNotFound);
    }

    try {
      await _majors.doc(major.id).update({
        ...major.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on MajorException {
      rethrow;
    } catch (e) {
      throw const MajorException(AppStrings.majorSaveError);
    }
  }
}
