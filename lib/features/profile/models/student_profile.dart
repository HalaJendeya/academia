class StudentProfile {
  final String uid;
  final String fullName;
  final String studentId;
  final String email;
  final String? major;

  /// المستوى الأكاديمي للطالب كرقم صحيح (1..8).
  ///
  /// كان يُخزَّن سابقًا كنص عربي معروض مثل "المستوى ٤"؛ بعد توحيد المخطط
  /// أصبح رقمًا صحيحًا في Firestore، ويُبنى النص العربي في طبقة العرض عبر
  /// AppStrings.academicLevelDisplay.
  final int? academicLevel;

  final String? photoUrl;

  /// عنوان بديل يحفظه الطالب للتواصل/الاسترجاع مستقبلًا.
  ///
  /// ليس بريد دخول: Firebase Authentication لا تعرفه إطلاقًا، وتخزينه هنا
  /// لا يجعله صالحًا لتسجيل الدخول.
  final String? secondaryEmail;

  /// هل أُثبتت ملكية العنوان الاحتياطي فعلًا؟
  ///
  /// 🔴 لا يصير true إلا بطريق واحد: أن يكون هذا العنوان بريدَ دخولٍ سابقًا
  /// لهذا الحساب نزل احتياطيًا بعد تغيير ناجح. لا زر في التطبيق يرفعها،
  /// وقاعدة Firestore ترفض رفعها من العميل.
  final bool secondaryEmailVerified;

  /// عنوان طُلب جعله أساسيًا وما زال بانتظار نقر الرابط المُرسَل إليه.
  ///
  /// حالة حقيقية لا تجميلية: Firebase لم تغيّر البريد بعد.
  final String? pendingPrimaryEmail;

  const StudentProfile({
    required this.uid,
    required this.fullName,
    required this.studentId,
    required this.email,
    this.major,
    this.academicLevel,
    this.photoUrl,
    this.secondaryEmail,
    this.secondaryEmailVerified = false,
    this.pendingPrimaryEmail,
  });

  /// قراءة متسامحة للمستوى الأكاديمي.
  ///
  /// تقبل الرقم الصحيح (الشكل المعتمد) وأيضًا النصوص القديمة سواء بأرقام
  /// إنجليزية "4" أو عربية-هندية "المستوى ٤"، حتى لا يفشل تحميل الملف
  /// الشخصي بسبب مستند لم يُحدَّث بعد.
  static int? parseAcademicLevel(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    if (value is String) {
      final digits = StringBuffer();
      for (final rune in value.runes) {
        if (rune >= 0x30 && rune <= 0x39) {
          digits.writeCharCode(rune); // 0-9
        } else if (rune >= 0x0660 && rune <= 0x0669) {
          digits.writeCharCode(rune - 0x0660 + 0x30); // ٠-٩
        }
      }
      return int.tryParse(digits.toString());
    }

    return null;
  }

  factory StudentProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return StudentProfile(
      uid: uid,
      fullName: data['fullName'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      email: data['email'] as String? ?? '',
      major: data['major'] as String?,
      academicLevel: parseAcademicLevel(data['academicLevel']),
      photoUrl: data['photoUrl'] as String?,
      secondaryEmail: data['secondaryEmail'] as String?,
      secondaryEmailVerified: data['secondaryEmailVerified'] as bool? ?? false,
      pendingPrimaryEmail: data['pendingPrimaryEmail'] as String?,
    );
  }

  Map<String, dynamic> toEditableFirestore() {
    return {
      'fullName': fullName,
      'major': major,
      'academicLevel': academicLevel,
      'photoUrl': photoUrl,
    };
  }

  StudentProfile copyWith({
    String? fullName,
    String? major,
    int? academicLevel,
    String? photoUrl,
  }) {
    return StudentProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      studentId: studentId,
      email: email,
      major: major ?? this.major,
      academicLevel: academicLevel ?? this.academicLevel,
      photoUrl: photoUrl ?? this.photoUrl,
      secondaryEmail: secondaryEmail,
      secondaryEmailVerified: secondaryEmailVerified,
      pendingPrimaryEmail: pendingPrimaryEmail,
    );
  }
}
