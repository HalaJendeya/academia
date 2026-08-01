class SupportRequest {
  final String uid;
  final String fullName;
  final String email;
  final String subject;
  final String message;
  final String status;
  final String source;

  const SupportRequest({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.subject,
    required this.message,
    required this.status,
    this.source = 'mobile_app',
  });

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
}
