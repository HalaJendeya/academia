import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/admin_access.dart';
import '../models/course_file_model.dart';

class CourseFileException implements Exception {
  final String message;
  const CourseFileException(this.message);

  @override
  String toString() => message;
}

/// البيانات الوصفية لملفات المساقات في Firestore.
///
/// الملف الثنائي في Cloudinary؛ هنا ما يجعله قابلًا للاستعلام والعرض
/// والتحكم في صلاحيته. لا يوجد حذف نهائي: الرفع غير الموقَّع لا يسمح بحذف
/// النسخة في Cloudinary، فحذف البيانات الوصفية وحده يترك ملفًا يتيمًا لا
/// يعرف عنه التطبيق شيئًا. الأرشفة هي الإزالة المعتمدة.
class CourseFileService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CourseFileService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _files =>
      _firestore.collection('courseFiles');

  Future<String> _requireAdmin() async {
    if (!AdminAccess.isSignedIn(_auth)) {
      throw const CourseFileException(AppStrings.authenticationRequired);
    }
    final uid = await AdminAccess.activeAdminUid(_auth, _firestore);
    if (uid == null) {
      throw const CourseFileException(AppStrings.unauthorizedAccess);
    }
    return uid;
  }

  List<CourseFileModel> _map(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final list = snapshot.docs
        .map((doc) => CourseFileModel.fromFirestore(doc.data(), doc.id))
        .toList();

    // الأحدث أولًا. الترتيب محليًا: الاستعلام مساواة فقط ولا يحتاج فهرسًا.
    list.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    return list;
  }

  /// ملفات طرح واحد — استعلام مساواة على offeringId.
  Stream<List<CourseFileModel>> watchOfferingFiles(String offeringId) {
    return _files
        .where('offeringId', isEqualTo: offeringId)
        .snapshots()
        .map(_map);
  }

  Future<List<CourseFileModel>> getOfferingFiles(String offeringId) async {
    if (offeringId.trim().isEmpty) return <CourseFileModel>[];
    try {
      return _map(await _files.where('offeringId', isEqualTo: offeringId).get());
    } catch (e) {
      throw const CourseFileException(AppStrings.fileLoadError);
    }
  }

  void _validate(CourseFileModel file) {
    if (file.title.trim().isEmpty) {
      throw const CourseFileException(AppStrings.courseFileTitleRequired);
    }
    if (!CourseFileModel.allowedCategories.contains(file.category)) {
      throw const CourseFileException(AppStrings.fileCategoryInvalid);
    }
    if (!CourseFileModel.allowedStatuses.contains(file.status)) {
      throw const CourseFileException(AppStrings.fileStatusInvalid);
    }
  }

  /// قراءة الطرح والتحقق من أن المساق والفصل مأخوذان منه فعلًا.
  ///
  /// الواجهة تمرّر الطرح كاملًا، لكن التحقق يتم هنا أيضًا: البيانات
  /// المنسوخة التي لا تُقارن بمصدرها تنحرف عنه بصمت.
  Future<void> _verifyOfferingMatches(CourseFileModel file) async {
    final doc = await _firestore
        .collection('courseOfferings')
        .doc(file.offeringId)
        .get();

    if (!doc.exists || doc.data() == null) {
      throw const CourseFileException(AppStrings.offeringNotFound);
    }

    final data = doc.data()!;
    if (data['courseId'] != file.courseId ||
        data['semesterId'] != file.semesterId) {
      throw const CourseFileException(AppStrings.fileSaveError);
    }
  }

  /// إنشاء البيانات الوصفية بعد نجاح الرفع إلى Cloudinary.
  ///
  /// تُستدعى بعد الرفع لا قبله: مستند يشير إلى ملف غير موجود أسوأ من عدم
  /// وجود المستند أصلًا.
  Future<String> createFileMetadata(CourseFileModel file) async {
    final adminUid = await _requireAdmin();
    _validate(file);

    if (file.cloudinaryUrl.trim().isEmpty ||
        file.cloudinaryPublicId.trim().isEmpty) {
      throw const CourseFileException(AppStrings.fileSaveError);
    }

    await _verifyOfferingMatches(file);

    try {
      final docRef = _files.doc();
      await docRef.set({
        ...file.toMap(),
        'uploadedBy': adminUid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } on CourseFileException {
      rethrow;
    } catch (e) {
      throw const CourseFileException(AppStrings.fileSaveError);
    }
  }

  /// تعديل الحقول الوصفية القابلة للتغيير فقط.
  ///
  /// الطرح والمساق والفصل ومراجع Cloudinary ورافع الملف غير قابلة للتعديل:
  /// تغييرها يعني ملفًا آخر، وهو ما يُنشأ برفع جديد.
  Future<void> updateFileMetadata(CourseFileModel file) async {
    await _requireAdmin();
    _validate(file);

    if (file.id.trim().isEmpty) {
      throw const CourseFileException(AppStrings.fileNotFound);
    }

    try {
      await _files.doc(file.id).update({
        'title': file.title.trim(),
        'description': file.description.trim(),
        'category': file.category,
        'status': file.status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on CourseFileException {
      rethrow;
    } catch (e) {
      throw const CourseFileException(AppStrings.fileSaveError);
    }
  }

  Future<void> archiveFile(String fileId) async {
    await _requireAdmin();

    if (fileId.trim().isEmpty) {
      throw const CourseFileException(AppStrings.fileNotFound);
    }

    try {
      await _files.doc(fileId).update({
        'status': CourseFileModel.statusArchived,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw const CourseFileException(AppStrings.fileSaveError);
    }
  }
}
