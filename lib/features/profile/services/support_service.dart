import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../models/support_request.dart';

class SupportException implements Exception {
  final String message;
  const SupportException(this.message);

  @override
  String toString() => message;
}

class SupportService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  SupportService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('supportRequests');

  /// كل طلبات الدعم، للمشرف.
  ///
  /// بلا شرط ولا ترتيب في الاستعلام: القواعد تسمح بالقراءة للمشرف وحده،
  /// والترتيب محليًا فلا يحتاج فهرسًا. التصفية حسب الحالة تتم في الواجهة
  /// لأن الشاشة تعرض عدّاد كل تبويب في الوقت نفسه.
  Stream<List<SupportRequest>> watchSupportRequests() {
    return _requests.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => SupportRequest.fromFirestore(doc.data(), doc.id))
          .toList();

      // الأحدث أولًا. المستندات القديمة بلا createdAt تنزل إلى الآخر بدل
      // أن تتصدّر القائمة بترتيب عشوائي.
      list.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return list;
    });
  }

  /// تغيير حالة الطلب. لا يمس ما كتبه الطالب.
  ///
  /// الحقلان المكتوبان status و updatedAt وحدهما، وهو بالضبط ما تسمح به
  /// القاعدة: أي حقل إضافي هنا يجعل الكتابة كلها مرفوضة.
  Future<void> setRequestStatus({
    required String requestId,
    required String status,
  }) async {
    if (_auth.currentUser == null) {
      throw const SupportException(AppStrings.authenticationRequired);
    }
    if (requestId.trim().isEmpty) {
      throw const SupportException(AppStrings.supportRequestNotFound);
    }
    if (!SupportRequest.allowedStatuses.contains(status)) {
      throw const SupportException(AppStrings.supportRequestStatusInvalid);
    }

    try {
      await _requests.doc(requestId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw const SupportException(AppStrings.supportRequestStatusError);
    }
  }

  Future<void> submitSupportRequest({
    required String subject,
    required String message,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const SupportException(AppStrings.authenticationRequired);
    }

    final normalizedSubject = subject.trim();
    final normalizedMessage = message.trim();

    // Service-side validations
    if (normalizedSubject.isEmpty) {
      throw const SupportException(AppStrings.supportRequestSubjectRequired);
    }
    if (normalizedSubject.length < 3) {
      throw const SupportException(AppStrings.supportRequestSubjectTooShort);
    }
    if (normalizedSubject.length > 120) {
      throw const SupportException(AppStrings.supportRequestSubjectTooLong);
    }

    if (normalizedMessage.isEmpty) {
      throw const SupportException(AppStrings.supportRequestMessageRequired);
    }
    if (normalizedMessage.length < 10) {
      throw const SupportException(AppStrings.supportRequestMessageTooShort);
    }
    if (normalizedMessage.length > 2000) {
      throw const SupportException(AppStrings.supportRequestMessageTooLong);
    }

    try {
      String resolvedName = '';
      String resolvedEmail = '';

      // Try to read profile document from users/{uid}
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          resolvedName = data['fullName'] as String? ?? '';
          resolvedEmail = data['email'] as String? ?? '';
        }
      }

      // Fallbacks
      if (resolvedEmail.isEmpty) {
        resolvedEmail = currentUser.email ?? '';
      }

      final supportRequest = SupportRequest(
        uid: currentUser.uid,
        fullName: resolvedName,
        email: resolvedEmail,
        subject: normalizedSubject,
        message: normalizedMessage,
        status: SupportRequest.statusOpen,
      );

      await _requests.add({
        ...supportRequest.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on SupportException {
      rethrow;
    } catch (e) {
      throw const SupportException(AppStrings.supportRequestError);
    }
  }
}
