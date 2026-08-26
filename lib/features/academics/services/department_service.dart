import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/admin_access.dart';
import '../models/department_model.dart';

class DepartmentException implements Exception {
  final String message;
  const DepartmentException(this.message);

  @override
  String toString() => message;
}

class DepartmentService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DepartmentService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _departments =>
      _firestore.collection('departments');

  Future<String> _requireAdmin() async {
    if (!AdminAccess.isSignedIn(_auth)) {
      throw const DepartmentException(AppStrings.authenticationRequired);
    }
    final uid = await AdminAccess.activeAdminUid(_auth, _firestore);
    if (uid == null) {
      throw const DepartmentException(AppStrings.unauthorizedAccess);
    }
    return uid;
  }

  List<DepartmentModel> _map(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final list = snapshot.docs
        .map((doc) => DepartmentModel.fromFirestore(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Stream<List<DepartmentModel>> watchDepartments() =>
      _departments.snapshots().map(_map);

  Future<List<DepartmentModel>> getDepartments() async {
    try {
      return _map(await _departments.get());
    } catch (e) {
      throw const DepartmentException(AppStrings.departmentLoadError);
    }
  }

  Future<DepartmentModel?> getDepartmentById(String id) async {
    try {
      final doc = await _departments.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return DepartmentModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw const DepartmentException(AppStrings.departmentLoadError);
    }
  }

  void _validate(DepartmentModel department) {
    if (department.name.trim().isEmpty) {
      throw const DepartmentException(AppStrings.departmentNameRequired);
    }
    if (!DepartmentModel.allowedStatuses.contains(department.status)) {
      throw const DepartmentException(AppStrings.departmentStatusInvalid);
    }
  }

  Future<String> createDepartment(DepartmentModel department) async {
    await _requireAdmin();
    _validate(department);

    try {
      final docRef = _departments.doc();
      await docRef.set({
        ...department.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } on DepartmentException {
      rethrow;
    } catch (e) {
      throw const DepartmentException(AppStrings.departmentSaveError);
    }
  }

  Future<void> updateDepartment(DepartmentModel department) async {
    await _requireAdmin();
    _validate(department);

    if (department.id.trim().isEmpty) {
      throw const DepartmentException(AppStrings.departmentNotFound);
    }

    try {
      await _departments.doc(department.id).update({
        ...department.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on DepartmentException {
      rethrow;
    } catch (e) {
      throw const DepartmentException(AppStrings.departmentSaveError);
    }
  }
}
