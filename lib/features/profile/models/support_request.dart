import 'package:cloud_firestore/cloud_firestore.dart';

/// طلب دعم أرسله مستخدم من شاشة المساعدة.
///
/// الكتابة من جهة الطالب والقراءة من جهة المشرف يتشاركان هذا النموذج نفسه؛
/// لا نموذج ثانٍ للوحة المشرف.
///
/// [toFirestore] يبقى كما هو: هو ما تكتبه شاشة الطالب، وتغييره يغيّر شكل
/// المستند وقواعد إنشائه.
class SupportRequest {
  /// معرّف المستند. فارغ قبل الحفظ: المعرّف يولّده Firestore.
  final String id;

  final String uid;
  final String fullName;
  final String email;
  final String subject;
  final String message;
  final String status;
  final String source;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupportRequest({
    this.id = '',
    required this.uid,
    required this.fullName,
    required this.email,
    required this.subject,
    required this.message,
    required this.status,
    this.source = 'mobile_app',
    this.createdAt,
    this.updatedAt,
  });

  // ---- status ----
  //
  // دورة حياة مقصودة الصِّغَر: الطلب مفتوح حتى يعلن المشرف أنه عولج، ويمكن
  // إعادة فتحه. لا إسناد لموظف ولا أولويات ولا ردود — تلك أنظمة تذاكر، وهذا
  // صندوق وارد.
  static const String statusOpen = 'open';
  static const String statusResolved = 'resolved';

  static const List<String> allowedStatuses = <String>[
    statusOpen,
    statusResolved,
  ];

  bool get isOpen => status == statusOpen;
  bool get isResolved => status == statusResolved;

  /// قراءة متسامحة: المستندات القديمة قد تنقصها حقول أُضيفت لاحقًا، وفشل
  /// التحويل يعني صندوق وارد فارغًا بدل طلب ناقص.
  factory SupportRequest.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    String readString(dynamic value) => value is String ? value.trim() : '';

    final status = readString(data['status']);

    return SupportRequest(
      id: id,
      uid: readString(data['uid']),
      fullName: readString(data['fullName']),
      email: readString(data['email']),
      subject: readString(data['subject']),
      message: readString(data['message']),
      // حالة غير معروفة أو غائبة تُقرأ كمفتوحة: طلب لا نعرف حاله يجب أن
      // يبقى مرئيًا للمشرف لا أن يختفي في تبويب "محلولة".
      status: allowedStatuses.contains(status) ? status : statusOpen,
      source: readString(data['source']),
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'subject': subject,
      'message': message,
      'status': status,
      'source': source,
    };
  }

  SupportRequest copyWith({String? status}) {
    return SupportRequest(
      id: id,
      uid: uid,
      fullName: fullName,
      email: email,
      subject: subject,
      message: message,
      status: status ?? this.status,
      source: source,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
