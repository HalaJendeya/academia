import 'package:cloud_firestore/cloud_firestore.dart';

/// عرض مبسّط لمستند المعلّم داخل شاشات المشرف (قراءة فقط).
///
/// مستند المعلّم أفقر عمدًا من مستند الطالب: لا رقم جامعي ولا تخصص ولا
/// مستوى أكاديمي ولا تفضيلات دراسة. تلك حقول تصف مسارًا دراسيًا، والمعلّم
/// لا يدرس. كل ما تحتاجه شاشات المشرف هو الهوية وحالة الحساب.
class AdminTeacherModel {
  final String uid;
  final String fullName;
  final String email;
  final String status;
  final DateTime? createdAt;

  const AdminTeacherModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.status,
    this.createdAt,
  });

  static const String statusActive = 'active';
  static const String statusDisabled = 'disabled';

  bool get isActive => status == statusActive;

  /// اسم للعرض لا يكون فارغًا أبدًا.
  ///
  /// الحساب المُنشأ خارج التطبيق قد يصل بلا اسم؛ عرض سطر فارغ في القائمة
  /// يجعل الصف غير قابل للتمييز، فيحلّ البريد محلّه.
  String get displayName =>
      fullName.trim().isNotEmpty ? fullName.trim() : email;

  factory AdminTeacherModel.fromFirestore(
    Map<String, dynamic> data,
    String uid,
  ) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return AdminTeacherModel(
      uid: uid,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      status: data['status'] as String? ?? statusActive,
      createdAt: parseDateTime(data['createdAt']),
    );
  }
}
