import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_strings.dart';
import '../models/study_session_model.dart';

class StudySessionException implements Exception {
  final String message;
  const StudySessionException(this.message);

  @override
  String toString() => message;
}

/// جلسات مذاكرة الطالب في Firestore.
///
/// عدد الكتابات مقصود وقليل: كتابة عند البدء، وكتابة واحدة عند الإغلاق
/// (اكتمال أو إنهاء مبكر أو إلغاء). العدّ التنازلي نفسه حالة محلية في
/// [StudySessionProvider] ولا يمسّ قاعدة البيانات إطلاقًا — الكتابة كل
/// ثانية كانت ستضاعف كلفة المجموعة بلا أي فائدة للطالب.
class StudySessionService {
  final FirebaseFirestore _firestore;

  StudySessionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('studySessions');

  /// كل جلسات هذا الطالب.
  ///
  /// استعلام مساواة واحد على `userId`، وهو ما تسمح به القاعدة: التقييم يتم
  /// لكل مستند، فاستعلام مقيَّد بالمالك ينجح بينما أي استعلام غير مقيَّد
  /// يُرفض عند أول مستند لا يملكه. والترتيب في الذاكرة لا في الخادم حتى
  /// يبقى `firestore.indexes.json` فارغًا.
  Stream<List<StudySessionModel>> watchUserSessions(String userId) {
    final owner = userId.trim();
    if (owner.isEmpty) {
      return Stream<List<StudySessionModel>>.value(
        const <StudySessionModel>[],
      );
    }

    return _sessions.where('userId', isEqualTo: owner).snapshots().map((
      snapshot,
    ) {
      final list = snapshot.docs
          .map((doc) => StudySessionModel.fromFirestore(doc.data(), doc.id))
          .toList();
      // الأحدث أولًا.
      list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return list;
    });
  }

  /// ينشئ جلسة جارية ويعيد معرّفها.
  ///
  /// [offeringId] و[courseId] يُكتبان معًا أو لا يُكتبان: القاعدة ترفض
  /// نصف ارتباط، ومستند يحمل طرحًا بلا مساق لا يمكن عرضه لاحقًا.
  Future<String> startSession({
    required String userId,
    required int plannedMinutes,
    String? offeringId,
    String? courseId,
    String? sessionName,
    String? goal,
  }) async {
    final owner = userId.trim();
    if (owner.isEmpty) {
      throw const StudySessionException(AppStrings.authenticationRequired);
    }
    if (!StudySessionModel.isValidDuration(plannedMinutes)) {
      throw const StudySessionException(AppStrings.studySessionInvalidDuration);
    }

    final offering = offeringId?.trim();
    final course = courseId?.trim();
    final hasCourse = (offering?.isNotEmpty ?? false);
    if (hasCourse && (course == null || course.isEmpty)) {
      throw const StudySessionException(AppStrings.studySessionInvalidCourse);
    }

    // نصوص اختيارية: تُكتب فقط إن كتبها الطالب، فلا يحمل المستند حقولًا
    // فارغة، وتبقى الجلسات القديمة بلا هذه الحقول صالحة كما هي.
    final name = _trimToNull(sessionName, StudySessionModel.maxSessionNameLength);
    final sessionGoal = _trimToNull(goal, StudySessionModel.maxGoalLength);

    try {
      final doc = await _sessions.add({
        'userId': owner,
        if (hasCourse) 'offeringId': offering,
        if (hasCourse) 'courseId': course,
        'sessionName': ?name,
        'goal': ?sessionGoal,
        'plannedMinutes': plannedMinutes,
        'actualMinutes': 0,
        'status': StudySessionModel.statusToString(StudySessionStatus.active),
        'startedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (e) {
      throw const StudySessionException(AppStrings.studySessionStartError);
    }
  }

  /// يغلق الجلسة: اكتمال أو إنهاء مبكر أو إلغاء.
  ///
  /// كتابة واحدة تحمل الحالة النهائية والمدة الفعلية ووقت الانتهاء معًا،
  /// فلا تمرّ الجلسة بحالة وسيطة نصف مغلقة لو انقطع الاتصال في المنتصف.
  Future<void> closeSession({
    required String sessionId,
    required StudySessionStatus status,
    required int actualMinutes,
  }) async {
    final id = sessionId.trim();
    if (id.isEmpty) {
      throw const StudySessionException(AppStrings.studySessionNotFound);
    }
    if (status == StudySessionStatus.active) {
      throw const StudySessionException(AppStrings.studySessionCloseError);
    }

    try {
      await _sessions.doc(id).update({
        'status': StudySessionModel.statusToString(status),
        'actualMinutes': actualMinutes < 0 ? 0 : actualMinutes,
        'endedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw const StudySessionException(AppStrings.studySessionCloseError);
    }
  }

  /// يحفظ ما كتبه الطالب في «ماذا أنجزت؟» بعد انتهاء الجلسة.
  ///
  /// كتابة ثالثة اختيارية، ولا تحدث إلا إذا كتب الطالب شيئًا فعلًا: تخطّي
  /// الحقل لا يكلّف قراءةً ولا كتابة. ولا تمسّ هذه الكتابة الحالة ولا
  /// المدة — القواعد تقصرها على `reflection` وحدها.
  Future<void> saveReflection({
    required String sessionId,
    required String reflection,
  }) async {
    final id = sessionId.trim();
    if (id.isEmpty) {
      throw const StudySessionException(AppStrings.studySessionNotFound);
    }

    final text = _trimToNull(
      reflection,
      StudySessionModel.maxReflectionLength,
    );
    if (text == null) return;

    try {
      await _sessions.doc(id).update({
        'reflection': text,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw const StudySessionException(AppStrings.studySessionCloseError);
    }
  }

  /// يقصّ الفراغات ويحدّ الطول، ويعيد null للنص الفارغ.
  ///
  /// القصّ هنا وليس في الشاشة: الحدّ نفسه مفروض في القواعد، فمن الأفضل ألا
  /// تصل كتابة مرفوضة إلى الخادم أصلًا.
  static String? _trimToNull(String? value, int maxLength) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text.length <= maxLength ? text : text.substring(0, maxLength);
  }
}
