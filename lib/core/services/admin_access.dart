import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// تحقق مشترك من صلاحية المشرف داخل التطبيق.
///
/// يُستخدم في جميع خدمات الكتابة الإدارية حتى تبقى قاعدة الحالة الانتقالية
/// معرَّفة في مكان واحد بدل تكرارها في كل خدمة.
///
/// هذا التحقق للراحة ووضوح الرسائل فقط؛ التطبيق الفعلي للصلاحيات يتم في
/// قواعد أمان Firestore.
class AdminAccess {
  const AdminAccess._();

  /// يعيد معرّف المشرف النشط، أو null إذا لم يكن المستخدم مشرفًا نشطًا.
  static Future<String?> activeAdminUid(
    FirebaseAuth auth,
    FirebaseFirestore firestore,
  ) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return null;

    final userDoc = await firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    if (!userDoc.exists) return null;

    final data = userDoc.data();
    if (data == null || data['role'] != 'admin') return null;

    /*
     * توافق انتقالي: غياب الحقل status يُعامل كحساب نشط، تمامًا كما في
     * AppUserModel وقواعد Firestore الحالية.
     */
    final status = data['status'] as String? ?? 'active';
    if (status != 'active') return null;

    return currentUser.uid;
  }

  static bool isSignedIn(FirebaseAuth auth) => auth.currentUser != null;
}
