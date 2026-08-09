import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../academics/models/major_model.dart';
import '../../academics/services/major_service.dart';
import '../../auth/models/app_user_model.dart';
import '../../curriculum/models/curriculum_course_model.dart';
import '../../curriculum/services/curriculum_service.dart';
import '../../enrollments/models/enrollment_model.dart';
import '../../enrollments/services/enrollment_service.dart';
import '../../semesters/models/semester_model.dart';
import '../../semesters/services/semester_service.dart';
import '../models/course_model.dart';
import '../models/course_offering_model.dart';
import '../models/student_course_view.dart';
import '../services/course_offering_service.dart';
import '../services/course_service.dart';

/// المرحلة التي فشل عندها التحميل، لتشخيص الخطأ بدل رسالة عامة واحدة.
enum StudentCoursesStage {
  idle,
  semester,
  major,
  curriculum,
  courses,
  offerings,
  ready,
}

/// كل ما تحتاجه واجهة الطالب عن مساقاته، مشتقًا من استعلامات مساواة فقط.
///
/// المزوّد يستمد هويته من [AppUserModel] للطالب المسجَّل: لا شاشة تعرف
/// majorId ولا academicLevel ولا تمرّرهما. هذا يمنع أن تعرض شاشة خطة تخصص
/// لا ينتمي إليه الطالب.
class StudentCoursesProvider extends ChangeNotifier {
  final SemesterService _semesterService;
  final CurriculumService _curriculumService;
  final CourseService _courseService;
  final CourseOfferingService _offeringService;
  final EnrollmentService _enrollmentService;
  final MajorService _majorService;

  StudentCoursesProvider(
    this._semesterService,
    this._curriculumService,
    this._courseService,
    this._offeringService,
    this._enrollmentService,
    this._majorService,
  );

  // ---- identity of the student this data belongs to ----
  String? _userId;
  String? _majorId;
  int? _academicLevel;

  // ---- loaded data ----
  SemesterModel? _currentSemester;
  MajorModel? _major;
  Map<String, SemesterModel> _semestersById = {};
  List<CurriculumCourseModel> _curriculum = [];
  Map<String, CourseModel> _coursesById = {};
  List<CourseOfferingModel> _currentSemesterOfferings = [];
  Map<String, CourseOfferingModel> _offeringsById = {};
  List<EnrollmentModel> _enrollments = [];

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  StudentCoursesStage _failedStage = StudentCoursesStage.idle;

  StreamSubscription<List<EnrollmentModel>>? _enrollmentsSubscription;

  /// يمنع سباق التحميل: نتيجة تحميل قديم لمستخدم سابق تُهمَل.
  int _loadToken = 0;

  // ------------------------------------------------------------- accessors

  String? get userId => _userId;
  String? get majorId => _majorId;
  int? get academicLevel => _academicLevel;

  SemesterModel? get currentSemester => _currentSemester;

  /// مستند التخصص نفسه، لعرض اسمه الحقيقي بدل النص الحر القديم في users.
  MajorModel? get major => _major;

  /// اسم البرنامج الأكاديمي للعرض، أو نص بديل واضح إن تعذّر حلّه.
  String get majorName => _major?.name ?? AppStrings.unknownMajor;

  List<CurriculumCourseModel> get curriculum => _curriculum;
  List<EnrollmentModel> get enrollments => _enrollments;

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  StudentCoursesStage get failedStage => _failedStage;

  /// الطالب غير مرتبط ببرنامج أكاديمي: حالة فارغة صريحة لا خطأ.
  bool get hasMajor => _majorId != null && _majorId!.trim().isNotEmpty;
  bool get hasCurrentSemester => _currentSemester != null;

  CourseModel? courseById(String? courseId) {
    if (courseId == null || courseId.trim().isEmpty) return null;
    return _coursesById[courseId];
  }

  /// يحلّ الطروح الحالية والتاريخية معًا، لأن طروح السجل تُجلب بمعرّفاتها.
  CourseOfferingModel? offeringById(String? offeringId) {
    if (offeringId == null || offeringId.trim().isEmpty) return null;
    return _offeringsById[offeringId];
  }

  SemesterModel? semesterById(String? semesterId) {
    if (semesterId == null || semesterId.trim().isEmpty) return null;
    return _semestersById[semesterId];
  }

  CurriculumCourseModel? curriculumEntryForCourse(String? courseId) {
    if (courseId == null) return null;
    for (final entry in _curriculum) {
      if (entry.isCourseEntry && entry.courseId == courseId) return entry;
    }
    return null;
  }

  // --------------------------------------------------------------- program

  /// خطة التخصص كاملة مجمّعة حسب المستوى، بالمساقات والخانات معًا.
  ///
  /// مشتقة من majorId وحده، لذلك تظهر كاملة حتى لو لم يُسجَّل الطالب في أي
  /// مساق بعد. طالب بلا تسجيلات يجب أن يرى خطته لا شاشة فارغة.
  Map<int, List<StudentProgramEntryView>> get programByLevel {
    final grouped = <int, List<StudentProgramEntryView>>{};

    for (final entry in _curriculum) {
      grouped
          .putIfAbsent(entry.academicLevel, () => [])
          .add(
            StudentProgramEntryView(
              entry: entry,
              course: entry.isCourseEntry ? _coursesById[entry.courseId] : null,
            ),
          );
    }

    for (final rows in grouped.values) {
      rows.sort((a, b) => a.sequence.compareTo(b.sequence));
    }
    return grouped;
  }

  /// المستويات الموجودة فعلًا في الخطة، مرتبة.
  List<int> get programLevels {
    final levels = _curriculum.map((e) => e.academicLevel).toSet().toList()
      ..sort();
    return levels;
  }

  int get programTotalCreditHours {
    var total = 0;
    for (final rows in programByLevel.values) {
      for (final row in rows) {
        total += row.creditHours;
      }
    }
    return total;
  }

  List<StudentProgramEntryView> programForLevel(int academicLevel) =>
      programByLevel[academicLevel] ?? const <StudentProgramEntryView>[];

  /// صفوف الخطة لمستوى الطالب نفسه.
  ///
  /// يعتمد على academicLevel المخزَّن في مستند المستخدم؛ إن كان غير محدد
  /// تُعاد قائمة فارغة بدل افتراض مستوى.
  List<StudentProgramEntryView> get recommendedForMyLevel {
    final level = _academicLevel;
    if (level == null) return const <StudentProgramEntryView>[];
    return programForLevel(level);
  }

  int get recommendedCreditHours => recommendedForMyLevel.fold<int>(
    0,
    (sum, row) => sum + row.creditHours,
  );

  // --------------------------------------------------------- available now

  /// تقاطع خطة الطالب مع ما هو مطروح فعلًا هذا الفصل.
  ///
  /// الاستثناء الوحيد هو الطروح التي للطالب فيها تسجيل نشط بالفعل.
  ///
  /// لا تُستبعد المساقات التي أنهاها الطالب سابقًا: إعادة الدراسة جزء معتمد
  /// من النظام، وإخفاؤها تلقائيًا يمنع إعادة مساق راسب فيه. كذلك لا تُطبَّق
  /// المتطلبات السابقة هنا؛ فهي نص للعرض فقط.
  List<StudentAvailableCourseView> get availableNow {
    final semesterId = _currentSemester?.id;
    if (semesterId == null) return const <StudentAvailableCourseView>[];

    final planCourseIds = <String>{
      for (final entry in _curriculum)
        if (entry.isCourseEntry && entry.courseId != null) entry.courseId!,
    };

    final activeOfferingIds = <String>{
      for (final enrollment in _enrollments)
        if (enrollment.isActive) enrollment.offeringId,
    };

    final available = _currentSemesterOfferings
        .where(
          (offering) =>
              offering.isActive &&
              offering.semesterId == semesterId &&
              planCourseIds.contains(offering.courseId) &&
              !activeOfferingIds.contains(offering.id),
        )
        .map(
          (offering) => StudentAvailableCourseView(
            offering: offering,
            course: _coursesById[offering.courseId],
            curriculumEntry: curriculumEntryForCourse(offering.courseId),
          ),
        )
        .toList();

    available.sort((a, b) {
      final byLevel = (a.academicLevel ?? 0).compareTo(b.academicLevel ?? 0);
      if (byLevel != 0) return byLevel;
      return a.courseCode.compareTo(b.courseCode);
    });
    return available;
  }

  // -------------------------------------------------------- current & past

  /// التسجيلات النشطة في الفصل الحالي وحده.
  ///
  /// التسجيلات المُزالة مستبعدة: الإزالة الناعمة سجل تدقيق للمشرف ولا تُعرض
  /// للطالب.
  List<StudentCourseView> get currentCourses {
    final semesterId = _currentSemester?.id;
    if (semesterId == null) return const <StudentCourseView>[];

    final rows =
        _enrollments
            .where(
              (enrollment) =>
                  enrollment.semesterId == semesterId && enrollment.isActive,
            )
            .map(_toCourseView)
            .toList()
          ..sort((a, b) => a.courseCode.compareTo(b.courseCode));

    return rows;
  }

  /// المحاولات السابقة مجمّعة حسب المساق الدائم ومرتبة برقم المحاولة.
  ///
  /// السجل هو ما ليس ضمن [currentCourses]: التسجيل النشط في الفصل الحالي لا
  /// يظهر في القسمين معًا. المحاولات المُزالة مستبعدة كما في الحالية.
  ///
  /// إعادة دراسة المساق نفسه تبقى محاولة منفصلة برقمها الخاص، لأن كل محاولة
  /// مستند مستقل يشير إلى طرح مختلف.
  Map<String, List<StudentCourseView>> get historyByCourse {
    final currentSemesterId = _currentSemester?.id;

    final historical = _enrollments.where((enrollment) {
      if (enrollment.isRemoved) return false;
      final isCurrent =
          enrollment.semesterId == currentSemesterId && enrollment.isActive;
      return !isCurrent;
    });

    final grouped = <String, List<StudentCourseView>>{};
    for (final enrollment in historical) {
      grouped.putIfAbsent(enrollment.courseId, () => []).add(
        _toCourseView(enrollment),
      );
    }

    for (final attempts in grouped.values) {
      attempts.sort((a, b) => a.attemptNumber.compareTo(b.attemptNumber));
    }
    return grouped;
  }

  /// السجل مسطَّحًا، مرتبًا بالمساق ثم برقم المحاولة.
  List<StudentCourseView> get history {
    final grouped = historyByCourse;
    final keys = grouped.keys.toList()
      ..sort((a, b) {
        final aCode = _coursesById[a]?.courseCode ?? '';
        final bCode = _coursesById[b]?.courseCode ?? '';
        return aCode.compareTo(bCode);
      });
    return [for (final key in keys) ...grouped[key]!];
  }

  StudentCourseView _toCourseView(EnrollmentModel enrollment) {
    return StudentCourseView(
      enrollment: enrollment,
      offering: _offeringsById[enrollment.offeringId],
      course: _coursesById[enrollment.courseId],
      semester: _semestersById[enrollment.semesterId],
      curriculumEntry: curriculumEntryForCourse(enrollment.courseId),
    );
  }

  // ------------------------------------------------------------- lifecycle

  /// يربط المزوّد بالمستخدم المسجَّل حاليًا.
  ///
  /// يُستدعى من ChangeNotifierProxyProvider أثناء البناء، لذلك لا يُشعر
  /// المستمعين مباشرة بل يؤجّل العمل إلى microtask.
  void syncWithUser(AppUserModel? user, {required bool isLoggedIn}) {
    final isStudent = isLoggedIn && user != null && user.isStudent;

    if (!isStudent) {
      // تسجيل خروج أو حساب مشرف: لا تُترك بيانات طالب سابق في الذاكرة.
      if (_userId != null || _hasLoaded || _enrollments.isNotEmpty) {
        scheduleMicrotask(clear);
      }
      return;
    }

    final sameStudent = user.uid == _userId;
    final identityUnchanged =
        sameStudent &&
        user.majorId == _majorId &&
        user.academicLevel == _academicLevel;

    if (identityUnchanged && (_hasLoaded || _isLoading)) return;

    scheduleMicrotask(() => load(user: user));
  }

  /// تحميل كل ما تعرضه واجهة الطالب، مرحلةً بمرحلة.
  ///
  /// الاستماع إلى التسجيلات يبدأ فقط بعد نجاح المراحل السابقة: بث تسجيلات
  /// بلا فصل دراسي ولا كتالوج ينتج شاشة تعرض صفوفًا بلا أسماء.
  Future<void> load({required AppUserModel user}) async {
    final token = ++_loadToken;

    // تبديل الطالب يمسح بيانات السابق قبل أي قراءة.
    if (_userId != null && _userId != user.uid) {
      _resetData();
    }

    _userId = user.uid;
    _majorId = user.majorId;
    _academicLevel = user.academicLevel;

    _isLoading = true;
    _errorMessage = null;
    _failedStage = StudentCoursesStage.idle;
    notifyListeners();

    var stage = StudentCoursesStage.semester;

    try {
      // 1. الفصول الدراسية: مجموعة صغيرة محدودة، وتلزم لتسمية فصول السجل.
      final semesters = await _semesterService.getSemesters();
      if (token != _loadToken) return;
      _semestersById = {for (final s in semesters) s.id: s};
      SemesterModel? current;
      for (final semester in semesters) {
        if (semester.isCurrent) {
          current = semester;
          break;
        }
      }
      _currentSemester = current;

      // 2. مستند التخصص: قراءة مستند واحد بمعرّفه، لا بثًّا لكل التخصصات.
      stage = StudentCoursesStage.major;
      _major = hasMajor ? await _majorService.getMajorById(_majorId!) : null;
      if (token != _loadToken) return;

      // 3. خطة التخصص.
      stage = StudentCoursesStage.curriculum;
      _curriculum = hasMajor
          ? await _curriculumService.getCurriculum(_majorId!)
          : const <CurriculumCourseModel>[];
      if (token != _loadToken) return;

      // 3. طروحات الفصل الحالي.
      stage = StudentCoursesStage.offerings;
      final semesterId = _currentSemester?.id;
      _currentSemesterOfferings = semesterId == null
          ? const <CourseOfferingModel>[]
          : await _offeringService.getOfferingsBySemester(semesterId);
      if (token != _loadToken) return;
      _indexOfferings(_currentSemesterOfferings);

      // 4. مساقات الكتالوج المذكورة في الخطة.
      stage = StudentCoursesStage.courses;
      final planCourseIds = <String>{
        for (final entry in _curriculum)
          if (entry.isCourseEntry && entry.courseId != null) entry.courseId!,
      };
      await _loadCourses(planCourseIds);
      if (token != _loadToken) return;

      _failedStage = StudentCoursesStage.ready;
      _hasLoaded = true;
    } catch (e) {
      if (token != _loadToken) return;
      _failedStage = stage;
      _errorMessage = _messageForStage(stage);
      _isLoading = false;
      notifyListeners();
      // لا يبدأ بث التسجيلات بعد فشل التحميل الأساسي.
      return;
    }

    _isLoading = false;
    notifyListeners();

    listenToMyEnrollments();
  }

  String _messageForStage(StudentCoursesStage stage) {
    switch (stage) {
      case StudentCoursesStage.semester:
        return AppStrings.semesterLoadError;
      case StudentCoursesStage.major:
        return AppStrings.majorLoadError;
      case StudentCoursesStage.curriculum:
        return AppStrings.curriculumLoadError;
      case StudentCoursesStage.offerings:
        return AppStrings.offeringLoadError;
      case StudentCoursesStage.courses:
      case StudentCoursesStage.idle:
      case StudentCoursesStage.ready:
        return AppStrings.courseLoadError;
    }
  }

  void _indexOfferings(List<CourseOfferingModel> offerings) {
    for (final offering in offerings) {
      _offeringsById[offering.id] = offering;
    }
  }

  Future<void> _loadCourses(Set<String> courseIds) async {
    if (courseIds.isEmpty) return;
    final courses = await _courseService.getCoursesByIds(courseIds.toList());
    for (final course in courses) {
      _coursesById[course.id] = course;
    }
  }

  /// سجلات الطالب الحالي مباشرة، حتى يظهر أي تسجيل يضيفه المشرف فورًا.
  void listenToMyEnrollments() {
    stopListening();
    final token = _loadToken;

    _enrollmentsSubscription = _enrollmentService.watchMyEnrollments().listen(
      (data) {
        if (token != _loadToken) return;
        _enrollments = data;
        _errorMessage = null;
        notifyListeners();
        // التسجيل قد يشير إلى طرح أو مساق خارج الخطة والفصل الحالي.
        unawaited(_resolveEnrollmentReferences(data, token));
      },
      onError: (error) {
        if (token != _loadToken) return;
        _errorMessage = AppStrings.courseLoadError;
        notifyListeners();
      },
    );
  }

  /// جلب الطروح والمساقات التي تشير إليها التسجيلات وليست محمَّلة بعد.
  ///
  /// هذا ما يجعل السجل قابلًا للعرض: طرح فصل سابق ليس ضمن طروحات الفصل
  /// الحالي، ومساق مثل MIS202 قد لا يكون ضمن خطة التخصص إطلاقًا. يُجلب
  /// المفقود بمعرّفاته فقط، لا بتحميل المجموعات كاملة.
  Future<void> _resolveEnrollmentReferences(
    List<EnrollmentModel> enrollments,
    int token,
  ) async {
    final missingOfferingIds = <String>{
      for (final enrollment in enrollments)
        if (enrollment.hasOffering &&
            !_offeringsById.containsKey(enrollment.offeringId))
          enrollment.offeringId,
    };

    final missingCourseIds = <String>{
      for (final enrollment in enrollments)
        if (enrollment.courseId.trim().isNotEmpty &&
            !_coursesById.containsKey(enrollment.courseId))
          enrollment.courseId,
    };

    if (missingOfferingIds.isEmpty && missingCourseIds.isEmpty) return;

    try {
      if (missingOfferingIds.isNotEmpty) {
        final offerings = await _offeringService.getOfferingsByIds(
          missingOfferingIds.toList(),
        );
        if (token != _loadToken) return;
        _indexOfferings(offerings);
      }

      if (missingCourseIds.isNotEmpty) {
        await _loadCourses(missingCourseIds);
        if (token != _loadToken) return;
      }

      notifyListeners();
    } catch (e) {
      if (token != _loadToken) return;
      // فشل إثراء السجل لا يُفقد التسجيلات نفسها؛ تُعرض بحقولها المنسوخة.
      _errorMessage = AppStrings.courseLoadError;
      notifyListeners();
    }
  }

  void stopListening() {
    _enrollmentsSubscription?.cancel();
    _enrollmentsSubscription = null;
  }

  void _resetData() {
    _currentSemester = null;
    _major = null;
    _semestersById = {};
    _curriculum = const <CurriculumCourseModel>[];
    _coursesById = {};
    _currentSemesterOfferings = const <CourseOfferingModel>[];
    _offeringsById = {};
    _enrollments = const <EnrollmentModel>[];
    _hasLoaded = false;
    _errorMessage = null;
    _failedStage = StudentCoursesStage.idle;
  }

  /// مسح كامل لبيانات الطالب. يُستدعى عند تسجيل الخروج أو تبديل الحساب.
  void clear() {
    stopListening();
    // إبطال أي تحميل أو بث معلَّق يخص الطالب السابق.
    _loadToken++;
    _userId = null;
    _majorId = null;
    _academicLevel = null;
    _isLoading = false;
    _resetData();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
