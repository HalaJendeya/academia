class StudentProfile {
  final String uid;
  final String fullName;
  final String studentId;
  final String email;
  final String? major;
  final String? academicLevel;
  final String? photoUrl;

  const StudentProfile({
    required this.uid,
    required this.fullName,
    required this.studentId,
    required this.email,
    this.major,
    this.academicLevel,
    this.photoUrl,
  });

  factory StudentProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return StudentProfile(
      uid: uid,
      fullName: data['fullName'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      email: data['email'] as String? ?? '',
      major: data['major'] as String?,
      academicLevel: data['academicLevel'] as String?,
      photoUrl: data['photoUrl'] as String?,
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
    String? academicLevel,
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
    );
  }
}
