/// عرض مبسّط لمستند الطالب داخل شاشات المشرف (قراءة فقط).
class AdminStudentModel {
  final String uid;
  final String fullName;
  final String email;
  final String studentId;

  /// اسم التخصص كما أدخله الطالب، نص حر.
  final String major;

  /// مرجع إلى مستند التخصص، وهو ما تُبنى عليه الخطة الدراسية.
  /// null يعني أن الطالب لم يُربط ببرنامج أكاديمي بعد.
  final String? majorId;

  /// المستوى الأكاديمي للطالب كرقم صحيح.
  ///
  /// حلّ محل الحقل القديم الغامض semester الذي لم يكن مخزَّنًا في أي مستند.
  /// النص العربي يُبنى عند العرض عبر AppStrings.academicLevelDisplay.
  final int? academicLevel;

  final String status;
  final bool onboardingCompleted;

  const AdminStudentModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.studentId,
    required this.major,
    this.majorId,
    this.academicLevel,
    required this.status,
    required this.onboardingCompleted,
  });

  bool get isActive => status == 'active';

  factory AdminStudentModel.fromFirestore(
    Map<String, dynamic> data,
    String uid,
  ) {
    /*
     * قراءة متسامحة: تقبل الرقم الصحيح (الشكل المعتمد) وكذلك النصوص القديمة
     * سواء بأرقام إنجليزية "4" أو عربية-هندية "المستوى ٤"، حتى لا تفشل شاشات
     * المشرف بسبب مستند لم يُحدَّث بعد.
     */
    int? parseAcademicLevel(dynamic value) {
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

    return AdminStudentModel(
      uid: uid,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      major: data['major'] as String? ?? '',
      majorId: (data['majorId'] as String?)?.trim().isNotEmpty == true
          ? (data['majorId'] as String).trim()
          : null,
      academicLevel: parseAcademicLevel(data['academicLevel']),
      status: data['status'] as String? ?? 'active',
      onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
    );
  }
}
