import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../admin/models/admin_student_model.dart';
import '../../courses/models/course_model.dart';
import '../../courses/models/course_offering_model.dart';
import '../../courses/services/course_offering_service.dart';
import '../../courses/services/course_service.dart';
import '../../enrollments/models/enrollment_model.dart';
import '../../enrollments/services/enrollment_service.dart';
import '../../semesters/models/semester_model.dart';
import '../../semesters/services/semester_service.dart';
import '../models/teacher_offering_view.dart';

/// الطروحات المسندة إلى المعلّم الحالي، وقوائم طلابها.
///
/// الملكية تُقرأ من courseOfferings.teacherId وحده. اسم المدرّس النصي لا
/// يُستعمل في أي استعلام: هو نص حر لا يُطابق حسابًا، واستعماله للملكية كان
/// سيجعل تشابه الأسماء صلاحية.
///
/// كل مستمع هنا مربوط بجلسة معلّم نشط ويتوقف عند الخروج أو تبديل الحساب،
/// كما في المزوّدات الإدارية: المزوّدات مركَّبة فوق MaterialApp فلا يُستدعى
/// dispose أثناء الجلسة.
class TeacherOfferingsProvider extends ChangeNotifier {
  final CourseOfferingService _offeringService;
  final CourseService _courseService;
  final SemesterService _semesterService;
  final EnrollmentService _enrollmentService;

  TeacherOfferingsProvider(
    this._offeringService,
    this._courseService,
    this._semesterService,
    this._enrollmentService,
  );

  String? _teacherUid;

  List<CourseOfferingModel> _offerings = [];
  Map<String, CourseModel> _coursesById = {};
  Map<String, SemesterModel> _semestersById = {};

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<CourseOfferingModel>>? _offeringsSubscription;
  StreamSubscription<List<SemesterModel>>? _semestersSubscription;

  // ---- roster of one selected offering ----
  String? _selectedOfferingId;
  List<TeacherRosterEntry> _roster = [];
  bool _isLoadingRoster = false;
  String? _rosterErrorMessage;
  StreamSubscription<List<EnrollmentModel>>? _rosterSubscription;

  /// أسماء الطلاب المقروءة، مخبَّأة عبر الطروحات.
  ///
  /// الطالب نفسه قد يظهر في أكثر من طرح للمعلّم نفسه؛ التخبئة تمنع إعادة
  /// قراءة مستنده في كل مرة تُفتح فيها قائمة.
  final Map<String, AdminStudentModel> _studentCache = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isLoadingRoster => _isLoadingRoster;
  String? get rosterErrorMessage => _rosterErrorMessage;
  List<TeacherRosterEntry> get roster => _roster;
  String? get selectedOfferingId => _selectedOfferingId;

  /// كل الطروحات المسندة، مرتَّبة بالأحدث فصلًا ثم بالشعبة.
  List<TeacherOfferingView> get offerings =>
      _offerings.map(_toView).toList(growable: false);

  /// الطروحات النشطة وحدها — ما يُدرَّس فعلًا الآن.
  List<TeacherOfferingView> get activeOfferings => _offerings
      .where((offering) => offering.isActive)
      .map(_toView)
      .toList(growable: false);

  TeacherOfferingView _toView(CourseOfferingModel offering) {
    return TeacherOfferingView(
      offering: offering,
      course: _coursesById[offering.courseId],
      semester: _semestersById[offering.semesterId],
    );
  }

  /// الطرح المفتوح حاليًا، أو null إن لم يعد ضمن المسندة إلى المعلّم.
  ///
  /// إعادة القراءة من القائمة الحيّة لا من نسخة محفوظة: سحب الإسناد يجب أن
  /// يُفرغ الشاشة لا أن تبقى تعرض طرحًا لم يعد يملكه.
  TeacherOfferingView? get selectedOffering {
    final offeringId = _selectedOfferingId;
    if (offeringId == null) return null;
    for (final offering in _offerings) {
      if (offering.id == offeringId) return _toView(offering);
    }
    return null;
  }

  /// يتبع حالة المصادقة. يُستدعى من ProxyProvider في app_providers.
  ///
  /// [teacherUid] غير null فقط لحساب معلّم نشط. أي شيء آخر — خروج، أو دور
  /// آخر، أو حساب معطَّل — يوقف كل استماع ويمسح الحالة.
  void syncWithAuth({required String? teacherUid}) {
    if (teacherUid != null && teacherUid == _teacherUid) return;

    if (teacherUid == null) {
      final hadState = _teacherUid != null ||
          _offeringsSubscription != null ||
          _semestersSubscription != null ||
          _rosterSubscription != null ||
          _offerings.isNotEmpty;

      _teacherUid = null;
      if (!hadState) return;

      _stopAll();
      _offerings = [];
      _coursesById = {};
      _semestersById = {};
      _roster = [];
      _selectedOfferingId = null;
      _studentCache.clear();
      _isLoading = false;
      _isLoadingRoster = false;
      _errorMessage = null;
      _rosterErrorMessage = null;

      scheduleMicrotask(notifyListeners);
      return;
    }

    // تبديل الحساب إلى معلّم آخر: لا تُورَّث أي بيانات من السابق.
    _stopAll();
    _offerings = [];
    _roster = [];
    _selectedOfferingId = null;
    _studentCache.clear();
    _teacherUid = teacherUid;

    _listenToSemesters();
    _listenToOfferings(teacherUid);
  }

  void _stopAll() {
    _offeringsSubscription?.cancel();
    _offeringsSubscription = null;
    _semestersSubscription?.cancel();
    _semestersSubscription = null;
    stopListeningToRoster();
  }

  void _listenToSemesters() {
    _semestersSubscription = _semesterService.watchSemesters().listen(
      (data) {
        _semestersById = {for (final semester in data) semester.id: semester};
        notifyListeners();
      },
      // أسماء الفصول تحسين عرض لا شرط صحة: فشلها لا يُفرغ قائمة الطروحات.
      onError: (error) {},
    );
  }

  void _listenToOfferings(String teacherUid) {
    _isLoading = true;
    _errorMessage = null;
    scheduleMicrotask(notifyListeners);

    _offeringsSubscription = _offeringService
        .watchOfferingsByTeacher(teacherUid)
        .listen(
          (data) async {
            _offerings = data;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
            await _loadCoursesFor(data);
          },
          onError: (error) {
            _offerings = [];
            _isLoading = false;
            _errorMessage = AppStrings.teacherOfferingsLoadError;
            notifyListeners();
          },
        );
  }

  Future<void> _loadCoursesFor(List<CourseOfferingModel> offerings) async {
    final missing = offerings
        .map((offering) => offering.courseId)
        .where((id) => id.isNotEmpty && !_coursesById.containsKey(id))
        .toSet()
        .toList();
    if (missing.isEmpty) return;

    try {
      final courses = await _courseService.getCoursesByIds(missing);
      _coursesById = {
        ..._coursesById,
        for (final course in courses) course.id: course,
      };
      notifyListeners();
    } catch (e) {
      // بيانات المساق تفصيل عرض؛ الطرح يبقى معروضًا بمعرّفه.
    }
  }

  // ----------------------------------------------------------------- roster

  /// قائمة طلاب طرح واحد.
  ///
  /// القراءة مسموحة لأن القواعد تربطها بـ teacherId المخزَّن في الطرح؛ طلب
  /// قائمة طرح لا يملكه المعلّم يُرفض من الخادم لا من الواجهة.
  void listenToOfferingRoster(String offeringId) {
    stopListeningToRoster();

    _selectedOfferingId = offeringId;
    _isLoadingRoster = true;
    _rosterErrorMessage = null;
    notifyListeners();

    _rosterSubscription = _enrollmentService
        .watchOfferingRoster(offeringId)
        .listen(
          (enrollments) async {
            _roster = enrollments
                .map(
                  (enrollment) => TeacherRosterEntry(
                    enrollment: enrollment,
                    student: _studentCache[enrollment.userId],
                  ),
                )
                .toList();
            _isLoadingRoster = false;
            _rosterErrorMessage = null;
            notifyListeners();
            await _loadStudentNames(enrollments);
          },
          onError: (error) {
            _roster = [];
            _isLoadingRoster = false;
            _rosterErrorMessage = AppStrings.teacherRosterLoadError;
            notifyListeners();
          },
        );
  }

  Future<void> _loadStudentNames(List<EnrollmentModel> enrollments) async {
    final missing = enrollments
        .map((enrollment) => enrollment.userId)
        .where((uid) => uid.isNotEmpty && !_studentCache.containsKey(uid))
        .toSet()
        .toList();
    if (missing.isEmpty) return;

    final students = await _enrollmentService.getStudentsByIds(missing);
    if (students.isEmpty) return;

    for (final student in students) {
      _studentCache[student.uid] = student;
    }

    _roster = _roster
        .map(
          (entry) => TeacherRosterEntry(
            enrollment: entry.enrollment,
            student: _studentCache[entry.userId],
          ),
        )
        .toList();
    notifyListeners();
  }

  void stopListeningToRoster() {
    _rosterSubscription?.cancel();
    _rosterSubscription = null;
    _roster = [];
    _isLoadingRoster = false;
    _rosterErrorMessage = null;
    _selectedOfferingId = null;
  }

  @override
  void dispose() {
    _stopAll();
    super.dispose();
  }
}
