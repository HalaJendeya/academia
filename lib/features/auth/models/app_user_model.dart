import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, admin }

class AppUserModel {
  const AppUserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    required this.emailVerified,
    required this.onboardingCompleted,
    required this.onboardingStatus,
    this.studentId,
    this.major,
    this.majorId,
    this.academicLevel,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final UserRole role;
  final String status;
  final bool emailVerified;
  final bool onboardingCompleted;
  final String onboardingStatus;

  final String? studentId;

  /// اسم التخصص كما أدخله الطالب في التسجيل، نص حر بلا ارتباط بمجموعة.
  final String? major;

  /// مرجع إلى مستند التخصص، وهو ما تُبنى عليه الخطة الدراسية.
  ///
  /// null يعني أن المشرف لم يربط الطالب ببرنامج أكاديمي بعد، وتعرض واجهة
  /// الطالب حالة فارغة واضحة بدل خطة فارغة.
  final String? majorId;

  /// المستوى الأكاديمي كرقم صحيح (1..8).
  ///
  /// يُخزَّن رقمًا في Firestore ويُبنى نصه العربي في طبقة العرض فقط. مستند
  /// المستخدم هو مصدر الحقيقة للمستوى، ومنه تشتق واجهة المساقات "الموصى
  /// لمستواي" بدل أن تسأل الشاشة عن المستوى أو تفترضه.
  final int? academicLevel;

  /// رابط الصورة الشخصية في Cloudinary.
  ///
  /// المستند يحمل الرابط فقط؛ الصورة نفسها في Cloudinary. null يعني ألا
  /// صورة، وتعرض الواجهة الأيقونة الافتراضية.
  final String? photoUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isStudent => role == UserRole.student;

  bool get isAdmin => role == UserRole.admin;

  bool get isActive => status == 'active';

  factory AppUserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('User document ${document.id} does not contain data.');
    }

    return AppUserModel(
      uid: document.id,
      fullName: _readString(data['fullName']),
      email: _readString(data['email']),
      role: _roleFromString(data['role']),
      status: _readString(data['status'], fallback: 'active'),
      emailVerified: _readBool(data['emailVerified']),
      onboardingCompleted: _readBool(data['onboardingCompleted']),
      onboardingStatus: _readString(
        data['onboardingStatus'],
        fallback: 'pending',
      ),
      studentId: _readNullableString(data['studentId']),
      major: _readNullableString(data['major']),
      majorId: _readNullableString(data['majorId']),
      academicLevel: _readAcademicLevel(data['academicLevel']),
      photoUrl: _readNullableString(data['photoUrl']),
      createdAt: _readDateTime(data['createdAt']),
      updatedAt: _readDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role.name,
      'status': status,
      'emailVerified': emailVerified,
      'onboardingCompleted': onboardingCompleted,
      'onboardingStatus': onboardingStatus,
      if (studentId != null) 'studentId': studentId,
      if (major != null) 'major': major,
      if (majorId != null) 'majorId': majorId,
      if (academicLevel != null) 'academicLevel': academicLevel,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  AppUserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    UserRole? role,
    String? status,
    bool? emailVerified,
    bool? onboardingCompleted,
    String? onboardingStatus,
    String? studentId,
    String? major,
    String? majorId,
    int? academicLevel,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      emailVerified: emailVerified ?? this.emailVerified,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      studentId: studentId ?? this.studentId,
      major: major ?? this.major,
      majorId: majorId ?? this.majorId,
      academicLevel: academicLevel ?? this.academicLevel,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// قراءة متسامحة للمستوى الأكاديمي، مطابقة لما في StudentProfile و
  /// AdminStudentModel: تقبل الرقم الصحيح (الشكل المعتمد) والنصوص القديمة
  /// بأرقام إنجليزية "4" أو عربية-هندية "المستوى ٤"، ولا ترمي استثناءً.
  static int? _readAcademicLevel(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    if (value is String) {
      final digits = StringBuffer();
      for (final rune in value.runes) {
        if (rune >= 0x30 && rune <= 0x39) {
          digits.writeCharCode(rune);
        } else if (rune >= 0x0660 && rune <= 0x0669) {
          digits.writeCharCode(rune - 0x0660 + 0x30);
        }
      }
      return int.tryParse(digits.toString());
    }

    return null;
  }

  static UserRole _roleFromString(dynamic value) {
    final roleValue = value?.toString().trim().toLowerCase();

    switch (roleValue) {
      case 'admin':
        return UserRole.admin;

      case 'student':
      default:
        return UserRole.student;
    }
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final result = value.toString().trim();

    if (result.isEmpty) {
      return fallback;
    }

    return result;
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    return false;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}
