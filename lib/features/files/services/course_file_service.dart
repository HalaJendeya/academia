import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
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

  /// عدد الملفات النشطة في كل الطروحات، لبطاقة إحصاء لوحة المشرف.
  ///
  /// استعلام تجميعي لا قراءة مستندات: العدد وحده مطلوب، وتحميل كل مستندات
  /// البيانات الوصفية لعدّها هدر. ولا استماع مستمر: الرقم يُقرأ مرة عند
  /// فتح اللوحة.
  ///
  /// المؤرشف مستثنى عمدًا. الأرشفة هي الإزالة المعتمدة في المشروع، وعدّ
  /// المؤرشف يجعل الرقم يعدّ ما أُزيل.
  Future<int> getActiveFileCount() async {
    try {
      final snapshot = await _files
          .where('status', isEqualTo: CourseFileModel.statusActive)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw const CourseFileException(AppStrings.fileLoadError);
    }
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
  /// التحقق من صلاحية الكتابة: مشرف نشط، أو معلم نشط يملك الطرح.
  /// يعيد معرّف المستخدم الحالي ونوع دوره (كحالة) إذا كان مصرّحًا له.
  Future<({String uid, bool isAdmin})> _requireWriteAccess(String offeringId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const CourseFileException(AppStrings.authenticationRequired);
    }
    final uid = currentUser.uid;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      throw const CourseFileException(AppStrings.unauthorizedAccess);
    }

    final data = userDoc.data();
    if (data == null) {
      throw const CourseFileException(AppStrings.unauthorizedAccess);
    }

    final role = data['role'] as String?;
    final status = data['status'] as String? ?? 'active';
    if (status != 'active') {
      throw const CourseFileException(AppStrings.unauthorizedAccess);
    }

    if (role == 'admin') {
      return (uid: uid, isAdmin: true);
    } else if (role == 'teacher') {
      // قراءة الطرح للتحقق من أن المعلم هو مالك الطرح
      final offeringDoc = await _firestore
          .collection('courseOfferings')
          .doc(offeringId)
          .get();
      if (!offeringDoc.exists || offeringDoc.data() == null) {
        throw const CourseFileException(AppStrings.offeringNotFound);
      }
      final offeringData = offeringDoc.data()!;
      if (offeringData['teacherId'] != uid) {
        throw const CourseFileException(AppStrings.unauthorizedAccess);
      }
      return (uid: uid, isAdmin: false);
    }

    throw const CourseFileException(AppStrings.unauthorizedAccess);
  }

  /// إنشاء البيانات الوصفية بعد نجاح الرفع إلى Cloudinary.
  ///
  /// تُستدعى بعد الرفع لا قبله: مستند يشير إلى ملف غير موجود أسوأ من عدم
  /// وجود المستند أصلًا.
  Future<String> createFileMetadata(CourseFileModel file) async {
    final authResult = await _requireWriteAccess(file.offeringId);
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
        'uploadedBy': authResult.uid,
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
    if (file.id.trim().isEmpty) {
      throw const CourseFileException(AppStrings.fileNotFound);
    }

    // Read the existing file metadata from Firestore to prevent tampering with offeringId or other fields
    final existingDoc = await _files.doc(file.id).get();
    if (!existingDoc.exists || existingDoc.data() == null) {
      throw const CourseFileException(AppStrings.fileNotFound);
    }
    final existingData = existingDoc.data()!;
    final trueOfferingId = existingData['offeringId'] as String? ?? '';

    await _requireWriteAccess(trueOfferingId);
    _validate(file);

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
    if (fileId.trim().isEmpty) {
      throw const CourseFileException(AppStrings.fileNotFound);
    }

    // Read the existing file to get its true offeringId for authorization
    final existingDoc = await _files.doc(fileId).get();
    if (!existingDoc.exists || existingDoc.data() == null) {
      throw const CourseFileException(AppStrings.fileNotFound);
    }
    final existingData = existingDoc.data()!;
    final trueOfferingId = existingData['offeringId'] as String? ?? '';

    await _requireWriteAccess(trueOfferingId);

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
