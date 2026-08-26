import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_strings.dart';
import '../models/assignment_progress_model.dart';

class AssignmentProgressException implements Exception {
  final String message;
  const AssignmentProgressException(this.message);

  @override
  String toString() => message;
}

/// علامات الإنجاز الشخصية للطالب على الواجبات الأكاديمية.
///
/// مجموعة `/assignmentProgress` منفصلة تمامًا عن `/assignments`: تلك يملكها
/// المعلّم ويشترك فيها الطرح كله، وهذه خاصة بطالب واحد. لا كتابة هنا تمسّ
/// عنوان الواجب ولا موعده ولا أولويته ولا حالته.
///
/// الكتابة تتبع نمط المهام الشخصية حرفيًا ([TaskService.completeTask] و
/// [TaskService.reopenTask]): طابع زمني من الخادم عند الإنجاز، وحذف الحقل
/// عند التراجع — لا `null` تُقرأ لاحقًا كتاريخ.
class AssignmentProgressService {
  final FirebaseFirestore _firestore;

  AssignmentProgressService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _progress =>
      _firestore.collection('assignmentProgress');

  /// كل علامات الإنجاز التي يملكها هذا الطالب.
  ///
  /// استعلام مساواة واحد على `studentId`، وهو ما تسمح به القاعدة: التقييم
  /// يتم لكل مستند، فاستعلام مقيَّد بمعرّف الطالب ينجح بينما أي استعلام
  /// غير مقيَّد يُرفض عند أول مستند لا يملكه.
  Stream<List<AssignmentProgressModel>> watchStudentProgress(String studentId) {
    if (studentId.trim().isEmpty) {
      return Stream<List<AssignmentProgressModel>>.value(
        const <AssignmentProgressModel>[],
      );
    }

    return _progress
        .where('studentId', isEqualTo: studentId.trim())
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    AssignmentProgressModel.fromFirestore(doc.data(), doc.id),
              )
              .toList(),
        );
  }

  /// يضع علامة الإنجاز أو يزيلها.
  ///
  /// `set` بدمج لا `update`: المستند قد لا يكون موجودًا أصلًا في أول مرة،
  /// و`update` كان سيفشل حينها. المعرّف حتمي فلا ينتج عن ذلك تكرار.
  ///
  /// [studentId] يُكتب في المستند لأن القاعدة تقارنه بـ `request.auth.uid`
  /// وتشترط أن يطابق نصف المعرّف — فلا يستطيع طالب تسجيل إنجاز باسم غيره.
  Future<void> setCompleted({
    required String studentId,
    required String assignmentId,
    required bool completed,
  }) async {
    final student = studentId.trim();
    final assignment = assignmentId.trim();

    if (student.isEmpty || assignment.isEmpty) {
      throw const AssignmentProgressException(
        AppStrings.assignmentProgressSaveError,
      );
    }

    final docRef = _progress.doc(
      AssignmentProgressModel.documentId(student, assignment),
    );

    try {
      await docRef.set({
        'studentId': student,
        'assignmentId': assignment,
        'isCompleted': completed,
        // عند التراجع يُحذف التاريخ بدل كتابة null، كما في reopenTask.
        'completedAt': completed
            ? FieldValue.serverTimestamp()
            : FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw const AssignmentProgressException(
        AppStrings.assignmentProgressSaveError,
      );
    }
  }
}
