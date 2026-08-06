class AdminStudentModel {
  final String uid;
  final String fullName;
  final String email;
  final String studentId;
  final String major;
  final int? semester;
  final String status;
  final bool onboardingCompleted;

  const AdminStudentModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.studentId,
    required this.major,
    this.semester,
    required this.status,
    required this.onboardingCompleted,
  });

  factory AdminStudentModel.fromFirestore(
    Map<String, dynamic> data,
    String uid,
  ) {
    int? parseSemester(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    return AdminStudentModel(
      uid: uid,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      major: data['major'] as String? ?? '',
      semester: parseSemester(data['semester']),
      status: data['status'] as String? ?? 'active',
      onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
    );
  }
}
