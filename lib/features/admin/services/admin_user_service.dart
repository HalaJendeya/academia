import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/admin_access.dart';

class AdminUserException implements Exception {
  final String message;
  const AdminUserException(this.message);

  @override
  String toString() => message;
}

/// إدارة حالة حسابات المستخدمين من جهة المشرف.
///
/// خدمة مستقلة عن EnrollmentService عن قصد: تلك تدير التسجيلات الأكاديمية،
/// وحالة الحساب إدارةُ مستخدمين لا شأن لها بالمساقات. خلطهما يجعل خدمة
/// التسجيلات تملك مستند المستخدم أيضًا.
///
/// لا تلمس الدور: القواعد تمنع أي عميل — بما فيه المشرف — من تغيير role،
/// وتغييره يتم خارج التطبيق.
class AdminUserService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AdminUserService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  /// القيم المسموح بها لحالة الحساب، مطابقة لما تفرضه قواعد Firestore.
  static const String statusActive = 'active';
  static const String statusDisabled = 'disabled';

  static const List<String> allowedStatuses = <String>[
    statusActive,
    statusDisabled,
  ];

  Future<String> _requireAdmin() async {
    if (!AdminAccess.isSignedIn(_auth)) {
      throw const AdminUserException(AppStrings.authenticationRequired);
    }
    final uid = await AdminAccess.activeAdminUid(_auth, _firestore);
    if (uid == null) {
      throw const AdminUserException(AppStrings.unauthorizedAccess);
    }
    return uid;
  }

  /// تعطيل حساب طالب أو إعادة تفعيله.
  ///
  /// الحساب لا يُحذف ولا تُمس بياناته: التعطيل يغيّر حقلًا واحدًا، وكل
  /// فحوص "الحساب نشط" في التطبيق وفي القواعد تقرأه.
  ///
  /// الحقلان المكتوبان status و updatedAt وحدهما — تحديث موجَّه لا set()
  /// بمستند كامل، فلا يمكن أن تُمسح حقول لم تكن الشاشة تقصدها.
  Future<void> setStudentAccountStatus({
    required String userId,
    required String status,
  }) async {
    await _requireAdmin();

    if (userId.trim().isEmpty) {
      throw const AdminUserException(AppStrings.studentNotFound);
    }
    if (!allowedStatuses.contains(status)) {
      throw const AdminUserException(AppStrings.accountStatusInvalid);
    }

    final docRef = _firestore.collection('users').doc(userId.trim());

    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw const AdminUserException(AppStrings.studentNotFound);
    }

    try {
      await docRef.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw const AdminUserException(AppStrings.accountStatusUpdateError);
    }
  }
}
