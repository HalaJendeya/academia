import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/admin_access.dart';
import '../models/admin_teacher_model.dart';

class AdminTeacherException implements Exception {
  final String message;
  const AdminTeacherException(this.message);

  @override
  String toString() => message;
}

/// إدارة حسابات المعلّمين من واجهة المشرف.
///
/// النطاق هنا هو ما يستطيع عميل الجوال فعله فعلًا: القراءة، وتفعيل الحساب
/// أو تعطيله. الإنشاء ليس منه — لا يمكن للتطبيق أن يكتب حقل role (القواعد
/// تمنع كل عميل من ذلك)، ولا أن ينشئ حساب مصادقة دون أن يُخرج المشرف من
/// جلسته. الإنشاء يتم عبر tool/provision_teacher بصلاحيات Admin SDK.
class AdminTeacherService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AdminTeacherService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<String> _requireAdmin() async {
    if (!AdminAccess.isSignedIn(_auth)) {
      throw const AdminTeacherException(AppStrings.authenticationRequired);
    }
    final uid = await AdminAccess.activeAdminUid(_auth, _firestore);
    if (uid == null) {
      throw const AdminTeacherException(AppStrings.unauthorizedAccess);
    }
    return uid;
  }

  List<AdminTeacherModel> _map(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final list = snapshot.docs
        .map((doc) => AdminTeacherModel.fromFirestore(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => a.displayName.compareTo(b.displayName));
    return list;
  }

  /// كل حسابات المعلّمين — استعلام مساواة واحد، والترتيب في الذاكرة.
  ///
  /// القراءة مسموحة للمشرف وحده (users.list في القواعد)، لذلك يجب إيقاف
  /// هذا المستمع عند الخروج أو تبديل الحساب.
  Stream<List<AdminTeacherModel>> watchTeachers() {
    return _users.where('role', isEqualTo: 'teacher').snapshots().map(_map);
  }

  /*
   * لا يوجد استعلام منفصل للمعلّمين النشطين.
   *
   * قائمة المعلّمين قصيرة بطبيعتها، والمزوّد يشتقّ النشطين منها في الذاكرة:
   * استعلام ثانٍ يعني اشتراكًا ثانيًا يجب إيقافه عند الخروج، مقابل تصفية
   * سطر واحد.
   */

  /// تفعيل حساب معلّم أو تعطيله.
  ///
  /// تُكتب status وحدها: القواعد تشترط أن يبقى role كما هو، وأي محاولة
  /// لتغييره من العميل مرفوضة — وهذا مقصود، فترقية الأدوار قرار خارج
  /// التطبيق.
  Future<void> setTeacherStatus({
    required String uid,
    required String status,
  }) async {
    await _requireAdmin();

    if (status != AdminTeacherModel.statusActive &&
        status != AdminTeacherModel.statusDisabled) {
      throw const AdminTeacherException(AppStrings.teacherStatusInvalid);
    }

    final docRef = _users.doc(uid);
    final doc = await docRef.get();
    final data = doc.data();

    if (!doc.exists || data == null) {
      throw const AdminTeacherException(AppStrings.teacherNotFound);
    }
    // حارس ضد تعديل حساب ليس معلّمًا عبر شاشة المعلّمين.
    if (data['role'] != 'teacher') {
      throw const AdminTeacherException(AppStrings.teacherNotFound);
    }

    try {
      await docRef.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw const AdminTeacherException(AppStrings.teacherSaveError);
    }
  }
}
