import 'package:cloud_firestore/cloud_firestore.dart';

/// تقدّم طالب واحد في واجب واحد — علامة إنجاز شخصية.
///
/// 🔴 مجموعة منفصلة عن `/assignments` عمدًا وليست حقلًا فيها.
///
/// مستند الواجب يملكه المعلّم ويشترك فيه كل طلاب الطرح؛ كتابة إنجاز طالب
/// فيه تجعل الواجب منجزًا للجميع. لذلك الإنجاز يُخزَّن هنا، مستندًا لكل
/// (طالب × واجب)، ولا يقرؤه أحد سوى صاحبه.
///
/// وهذا **ليس تسليمًا**: لا ملف ولا نص ولا درجة ولا مراجعة. الغرض الوحيد
/// أن يتذكّر الطالب ما أنهاه، تمامًا كما يفعل مع مهمته الشخصية.
class AssignmentProgressModel {
  final String id;
  final String studentId;
  final String assignmentId;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  const AssignmentProgressModel({
    required this.id,
    required this.studentId,
    required this.assignmentId,
    this.isCompleted = false,
    this.completedAt,
    this.updatedAt,
  });

  /// معرّف حتمي: `{studentId}_{assignmentId}`.
  ///
  /// النمط نفسه المستعمل في `enrollments/{userId}_{offeringId}`، وللسبب
  /// نفسه: مستند واحد لا يمكن أن يتكرّر للعلاقة الواحدة. معرّف عشوائي كان
  /// سيسمح بسجلَّي إنجاز متناقضين للواجب الواحد دون أن يمنع ذلك شيء.
  static String documentId(String studentId, String assignmentId) =>
      '${studentId}_$assignmentId';

  factory AssignmentProgressModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return AssignmentProgressModel(
      id: id,
      studentId: data['studentId'] as String? ?? '',
      assignmentId: data['assignmentId'] as String? ?? '',
      // غياب الحقل يعني «غير منجز»، لا حالة مجهولة: المستند قد يوجد
      // بعد تراجع الطالب عن الإنجاز.
      isCompleted: data['isCompleted'] as bool? ?? false,
      completedAt: parseDateTime(data['completedAt']),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }
}
