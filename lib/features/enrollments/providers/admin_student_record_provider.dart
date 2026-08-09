import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../academics/models/major_model.dart';
import '../../academics/services/major_service.dart';
import '../../courses/models/course_model.dart';
import '../../courses/models/course_offering_model.dart';
import '../../courses/models/student_course_view.dart';
import '../../courses/services/course_offering_service.dart';
import '../../courses/services/course_service.dart';
import '../../semesters/models/semester_model.dart';
import '../../semesters/services/semester_service.dart';
import '../models/enrollment_model.dart';
import '../services/enrollment_service.dart';

/// السجل الأكاديمي لطالب واحد كما يراه المشرف.
///
/// منفصل عن [EnrollmentProvider] عمدًا: ذاك يخلط حالة القراءة بحالة الكتابة
/// في errorMessage واحد، فيكفي أن يفشل إسناد مساق حتى تعرض قائمة السجل
/// رسالة خطأ رغم أن التحميل نجح. هنا القراءة وحدها.
///
/// كما أنه يحلّ ما لا تحلّه شاشة التفاصيل القديمة: التسجيل يشير إلى طرح،
/// والطرح وحده يحمل المدرّس والشعبة والفصل. بدون هذا الحلّ تبقى البطاقات
/// بلا اسم مدرّس ولا فصل مهما كانت البيانات صحيحة.
class AdminStudentRecordProvider extends ChangeNotifier {
  final EnrollmentService _enrollmentService;
  final CourseOfferingService _offeringService;
  final CourseService _courseService;
  final SemesterService _semesterService;
  final MajorService _majorService;

  AdminStudentRecordProvider(
    this._enrollmentService,
    this._offeringService,
    this._courseService,
    this._semesterService,
    this._majorService,
  );

  String? _studentUid;
  MajorModel? _major;

  Map<String, SemesterModel> _semestersById = {};
  Map<String, CourseOfferingModel> _offeringsById = {};
  Map<String, CourseModel> _coursesById = {};
  List<EnrollmentModel> _enrollments = const [];

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  StreamSubscription<List<EnrollmentModel>>? _subscription;

  /// يبطل نتائج أي تحميل يخص طالبًا سابقًا.
  int _token = 0;

  String? get studentUid => _studentUid;
  MajorModel? get major => _major;
  String? get majorName => _major?.name;

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;

  List<EnrollmentModel> get enrollments => _enrollments;

  /// المحاولات الجارية: تسجيلات نشطة.
  List<StudentCourseView> get currentAttempts =>
      _viewsWhere((enrollment) => enrollment.isActive);

  /// السجل: المحاولات المنتهية.
  ///
  /// المُزالة مستبعدة من الاثنين — الإزالة الناعمة سجل تدقيق لا محاولة
  /// أكاديمية، وعرضها بين المحاولات يجعل الرقم يبدو مكررًا.
  List<StudentCourseView> get history =>
      _viewsWhere((enrollment) => enrollment.isCompleted);

  List<StudentCourseView> _viewsWhere(bool Function(EnrollmentModel) test) {
    final views = _enrollments.where(test).map(_toView).toList();
    views.sort((a, b) {
      final byCourse = a.courseCode.compareTo(b.courseCode);
      if (byCourse != 0) return byCourse;
      return a.attemptNumber.compareTo(b.attemptNumber);
    });
    return views;
  }

  StudentCourseView _toView(EnrollmentModel enrollment) {
    return StudentCourseView(
      enrollment: enrollment,
      offering: _offeringsById[enrollment.offeringId],
      course: _coursesById[enrollment.courseId],
      semester: _semestersById[enrollment.semesterId],
    );
  }

  /// تحميل سجل طالب محدَّد.
  ///
  /// [majorId] اختياري: يُقرأ من مستند الطالب في شاشة القائمة، ونحلّه هنا
  /// إلى اسم التخصص الحقيقي بدل الاعتماد على النص الحر القديم.
  Future<void> loadForStudent({
    required String uid,
    String? majorId,
  }) async {
    final token = ++_token;

    if (_studentUid != uid) _resetData();
    _studentUid = uid;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final semesters = await _semesterService.getSemesters();
      if (token != _token) return;
      _semestersById = {for (final semester in semesters) semester.id: semester};

      if (majorId != null && majorId.trim().isNotEmpty) {
        _major = await _majorService.getMajorById(majorId);
        if (token != _token) return;
      }
    } catch (e) {
      if (token != _token) return;
      // فشل السياق لا يمنع عرض التسجيلات نفسها؛ تُعرض بحقولها المنسوخة.
      _errorMessage = AppStrings.courseLoadError;
    }

    if (token != _token) return;
    _isLoading = false;
    _hasLoaded = true;
    notifyListeners();

    _listenToEnrollments(uid, token);
  }

  void _listenToEnrollments(String uid, int token) {
    _subscription?.cancel();
    _subscription = _enrollmentService
        .watchStudentEnrollments(uid)
        .listen(
          (data) {
            if (token != _token) return;
            _enrollments = data;
            _errorMessage = null;
            notifyListeners();
            unawaited(_resolveReferences(data, token));
          },
          onError: (error) {
            if (token != _token) return;
            _errorMessage = AppStrings.courseLoadError;
            notifyListeners();
          },
        );
  }

  /// جلب الطروح والمساقات التي تشير إليها التسجيلات بمعرّفاتها فقط.
  ///
  /// الطروح تمتد عبر فصول متعددة، فلا يمكن الاكتفاء بطروحات فصل واحد؛
  /// وتحميل كل الطروح لقراءة اثنين منها هدر.
  Future<void> _resolveReferences(
    List<EnrollmentModel> enrollments,
    int token,
  ) async {
    final missingOfferings = <String>{
      for (final enrollment in enrollments)
        if (enrollment.hasOffering &&
            !_offeringsById.containsKey(enrollment.offeringId))
          enrollment.offeringId,
    };

    final missingCourses = <String>{
      for (final enrollment in enrollments)
        if (enrollment.courseId.trim().isNotEmpty &&
            !_coursesById.containsKey(enrollment.courseId))
          enrollment.courseId,
    };

    if (missingOfferings.isEmpty && missingCourses.isEmpty) return;

    try {
      if (missingOfferings.isNotEmpty) {
        final offerings = await _offeringService.getOfferingsByIds(
          missingOfferings.toList(),
        );
        if (token != _token) return;
        for (final offering in offerings) {
          _offeringsById[offering.id] = offering;
        }
      }

      if (missingCourses.isNotEmpty) {
        final courses = await _courseService.getCoursesByIds(
          missingCourses.toList(),
        );
        if (token != _token) return;
        for (final course in courses) {
          _coursesById[course.id] = course;
        }
      }

      notifyListeners();
    } catch (e) {
      if (token != _token) return;
      _errorMessage = AppStrings.courseLoadError;
      notifyListeners();
    }
  }

  void _resetData() {
    _major = null;
    _semestersById = {};
    _offeringsById = {};
    _coursesById = {};
    _enrollments = const [];
    _hasLoaded = false;
    _errorMessage = null;
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _token++;
    _studentUid = null;
    _isLoading = false;
    _resetData();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
