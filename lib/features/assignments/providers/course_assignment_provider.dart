import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../models/course_assignment_model.dart';
import '../services/course_assignment_service.dart';

/// الواجبات الأكاديمية عبر الأدوار الثلاثة.
///
/// مجموعة Firestore واحدة `/assignments` وخدمة واحدة، لكن **نطاقَي اشتراك
/// مستقلين** داخل المزوّد:
///
///   [aggregate] — عدة طروح دفعةً واحدة: طروح الطالب المسجَّل فيها، أو
///                 طروح المعلّم المسندة إليه، أو الإشراف العالمي للمشرف.
///                 لا يملك أي دور أكثر من واحد من هذه في وقت واحد.
///
///   [selected]  — طرح واحد بعينه: تبويب الواجبات في تفاصيل المساق.
///                 قد يكون طرحًا من السجل خارج المجموعة الكلية.
///
/// 🔴 الفصل بينهما هو إصلاح انحدار المرحلة 8.4: كان النطاقان يتشاركان قائمة
/// وقائمة اشتراكات واحدة، فكانت شاشة تفاصيل المساق تستولي عليها لطرح واحد
/// ثم توقفها عند المغادرة، فتفقد شاشة «المهام والواجبات» ولوحة اليوم
/// واجباتهما. الترقيع السابق كان دالة استعادة تُستدعى من dispose؛ الآن لا
/// يوجد ما يُستعاد لأن الشاشتين لا تتشاركان حالة أصلًا.
class CourseAssignmentProvider extends ChangeNotifier {
  final CourseAssignmentService _service;

  CourseAssignmentProvider(this._service);

  // ---------------------------------------------------------- aggregate

  List<CourseAssignmentModel> _assignments = const <CourseAssignmentModel>[];
  bool _isLoading = false;
  String? _errorMessage;

  /// مستمع لكل طرح، مفتاحه معرّف الطرح. لا استعلام عالمي غير مقيَّد إلا
  /// للمشرف، وهو مصرَّح له بنص القاعدة.
  final Map<String, StreamSubscription<List<CourseAssignmentModel>>>
  _subscriptions = {};
  final Map<String, List<CourseAssignmentModel>> _byOffering = {};

  StreamSubscription<List<CourseAssignmentModel>>? _globalSubscription;

  List<CourseAssignmentModel> get assignments => _assignments;

  List<CourseAssignmentModel> get activeAssignments =>
      _assignments.where((assignment) => assignment.isActive).toList();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ----------------------------------------------------------- selected

  List<CourseAssignmentModel> _selected = const <CourseAssignmentModel>[];
  bool _isLoadingSelected = false;
  String? _selectedErrorMessage;
  String? _selectedOfferingId;
  StreamSubscription<List<CourseAssignmentModel>>? _selectedSubscription;

  List<CourseAssignmentModel> get selectedAssignments => _selected;

  List<CourseAssignmentModel> get activeSelectedAssignments =>
      _selected.where((assignment) => assignment.isActive).toList();

  bool get isLoadingSelected => _isLoadingSelected;
  String? get selectedErrorMessage => _selectedErrorMessage;
  String? get selectedOfferingId => _selectedOfferingId;

  // -------------------------------------------------------------- count

  int? _activeAssignmentCount;
  bool _isLoadingActiveAssignmentCount = false;

  /// عدد الواجبات النشطة، أو null إن لم يُقرأ بعد أو فشلت قراءته.
  ///
  /// null ليس صفرًا: الصفر يعني «لا واجبات»، وعرضه قبل القراءة أو بعد
  /// فشلها رقم مختلق. الواجهة تعرض شرطة مكانه.
  int? get activeAssignmentCount => _activeAssignmentCount;

  bool get isLoadingActiveAssignmentCount => _isLoadingActiveAssignmentCount;

  /// قراءة واحدة محدودة للعدّاد. تُستدعى عند فتح لوحة المشرف.
  Future<void> loadActiveAssignmentCount() async {
    if (_isLoadingActiveAssignmentCount) return;

    _isLoadingActiveAssignmentCount = true;
    notifyListeners();

    try {
      _activeAssignmentCount = await _service.getActiveAssignmentCount();
    } catch (e) {
      // فشل عدّاد إحصائي لا يجب أن يُظهر لوحة المشرف كأنها فشلت.
      _activeAssignmentCount = null;
    } finally {
      _isLoadingActiveAssignmentCount = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------- selected-scope reads

  /// واجبات طرح واحد — تبويب الواجبات في تفاصيل المساق.
  ///
  /// نطاق مستقل تمامًا: لا يمسّ اشتراك [aggregate] ولا قائمته، فزيارة
  /// تفاصيل مساق لم تعد تُفرغ شاشة «المهام والواجبات».
  void listenToOfferingAssignments(String offeringId) {
    final id = offeringId.trim();

    if (id.isEmpty) {
      stopListeningToSelected();
      return;
    }

    if (_selectedOfferingId == id && _selectedSubscription != null) return;

    _selectedSubscription?.cancel();
    _selectedOfferingId = id;
    _selected = const <CourseAssignmentModel>[];
    _isLoadingSelected = true;
    _selectedErrorMessage = null;
    notifyListeners();

    _selectedSubscription = _service.watchOfferingAssignments(id).listen(
      (data) {
        _selected = data;
        _isLoadingSelected = false;
        _selectedErrorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _selected = const <CourseAssignmentModel>[];
        _isLoadingSelected = false;
        _selectedErrorMessage = _messageFor(error);
        notifyListeners();
      },
    );
  }

  void stopListeningToSelected() {
    _selectedSubscription?.cancel();
    _selectedSubscription = null;
    _selectedOfferingId = null;
    _selected = const <CourseAssignmentModel>[];
    _isLoadingSelected = false;
    _selectedErrorMessage = null;
  }

  // ------------------------------------------------ aggregate-scope reads

  /// واجبات عدة طروح، بمستمع لكل طرح ودمج في الذاكرة.
  void listenToOfferingsAssignments(List<String> offeringIds) {
    final unique = offeringIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    if (_globalSubscription == null &&
        _subscriptions.isNotEmpty &&
        _subscriptions.length == unique.length &&
        unique.every(_subscriptions.containsKey)) {
      return;
    }

    _stopAggregate();

    if (unique.isEmpty) {
      _assignments = const <CourseAssignmentModel>[];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    for (final offeringId in unique) {
      _subscriptions[offeringId] = _service
          .watchOfferingAssignments(offeringId)
          .listen(
            (data) {
              _byOffering[offeringId] = data;
              _isLoading = false;
              _errorMessage = null;
              _rebuildMerged();
              notifyListeners();
            },
            onError: (error) {
              /*
               * فشل طرح واحد لا يمسح الباقي: القائمة المدمجة تبقى صحيحة
               * لما نجح، والخطأ يُعرض إلى جانبها.
               */
              _byOffering.remove(offeringId);
              _isLoading = false;
              _errorMessage = _messageFor(error);
              _rebuildMerged();
              notifyListeners();
            },
          );
    }
  }

  /// كل الواجبات النشطة — إشراف المشرف وحده.
  void listenToAllActiveAssignments() {
    if (_globalSubscription != null) return;

    _stopAggregate();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _globalSubscription = _service.watchAllActiveAssignments().listen(
      (data) {
        _assignments = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _assignments = const <CourseAssignmentModel>[];
        _isLoading = false;
        _errorMessage = _messageFor(error);
        notifyListeners();
      },
    );
  }

  /// دمج نتائج المستمعين مع إزالة التكرار بالمعرّف وترتيب حتمي.
  void _rebuildMerged() {
    final byId = <String, CourseAssignmentModel>{};
    for (final list in _byOffering.values) {
      for (final assignment in list) {
        byId[assignment.id] = assignment;
      }
    }

    final merged = byId.values.toList();
    merged.sort((a, b) {
      final byDue = a.dueAt.compareTo(b.dueAt);
      return byDue != 0 ? byDue : a.id.compareTo(b.id);
    });
    _assignments = merged;
  }

  void _stopAggregate() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _byOffering.clear();

    _globalSubscription?.cancel();
    _globalSubscription = null;
  }

  /// يوقف نطاق التجميع. لا يمسّ نطاق الطرح المختار.
  void stopListening() {
    _stopAggregate();
  }

  void clearAssignments() {
    _stopAggregate();
    _assignments = const <CourseAssignmentModel>[];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /*
   * ترجمة آمنة لأخطاء Firestore.
   *
   * لا يُعرض نص الاستثناء الخام للمستخدم أبدًا، لكن التمييز بين «مرفوض»
   * و«تعذر الاتصال» يغيّر ما يفعله الطالب: الأول يراجع حسابه، والثاني
   * يعيد المحاولة. الرسالة العامة السابقة لم تكن تفرّق.
   */
  static String _messageFor(Object? error) {
    final code = _firebaseCode(error);
    switch (code) {
      case 'permission-denied':
        return AppStrings.assignmentsPermissionDenied;
      case 'unavailable':
      case 'deadline-exceeded':
        return AppStrings.assignmentsUnavailableOffline;
      default:
        return AppStrings.courseAssignmentsLoadError;
    }
  }

  /// يقرأ `code` من FirebaseException دون استيراد الحزمة في المزوّد.
  static String? _firebaseCode(Object? error) {
    try {
      final dynamic candidate = error;
      final code = candidate?.code;
      return code is String ? code : null;
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------ lifecycle

  /// مجموعة الطروح المشترَك بها نيابةً عن الطالب، أو null إن لم تُضبط بعد.
  List<String>? _studentOfferingIds;

  /// يتبع طروح الطالب المصرَّح له بها، من StudentCoursesProvider.
  ///
  /// يُستدعى من ProxyProvider حتى تكون واجبات الطالب متاحة في التطبيق كله —
  /// شاشة المهام ولوحة اليوم معًا — دون أن تدير كل شاشة اشتراكها بنفسها.
  ///
  /// [offeringIds] تساوي null لأي جلسة ليست طالبًا نشطًا. حينها لا يفعل
  /// شيئًا ما لم يسبق للمزوّد أن اشترك كطالب: المعلّم والمشرف يقودان
  /// اشتراكاتهما من شاشاتهما.
  void syncStudentOfferings(List<String>? offeringIds) {
    if (offeringIds == null) {
      if (_studentOfferingIds == null) return;
      _studentOfferingIds = null;
      _stopAggregate();
      _assignments = const <CourseAssignmentModel>[];
      scheduleMicrotask(notifyListeners);
      return;
    }

    final normalized = offeringIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final current = _studentOfferingIds;
    final sameSet =
        current != null &&
        current.length == normalized.length &&
        List.generate(
          current.length,
          (i) => current[i] == normalized[i],
        ).every((same) => same);

    // لا حاجة لمقارنة الاشتراكات الحيّة: نطاق الطرح المختار لم يعد يمسّها.
    if (sameSet) return;

    _studentOfferingIds = normalized;
    listenToOfferingsAssignments(normalized);
  }

  bool _hadSession = false;
  String? _lastRole;

  /// يتبع حالة المصادقة. يُستدعى من ProxyProvider في app_providers.
  ///
  /// الشرط «مستخدم نشط» لا «معلّم»: المزوّد يخدم الطالب والمشرف أيضًا.
  /// تبديل الدور مع بقاء الجلسة يوقف الاستماع كذلك — استعلام فتحه معلّم
  /// على طروحه لا يجوز أن يبقى حيًّا بعد أن صار الحساب طالبًا.
  void syncWithAuth({required bool isActiveUser, String? role}) {
    if (isActiveUser) {
      if (_hadSession && _lastRole != null && _lastRole != role) {
        _stopAggregate();
        stopListeningToSelected();
        _assignments = const <CourseAssignmentModel>[];
        _activeAssignmentCount = null;
        _isLoading = false;
        _errorMessage = null;
        _studentOfferingIds = null;
      }
      _hadSession = true;
      _lastRole = role;
      return;
    }

    final hadState =
        _hadSession || _subscriptions.isNotEmpty || _assignments.isNotEmpty;
    _hadSession = false;
    _lastRole = null;
    _studentOfferingIds = null;
    if (!hadState) return;

    _stopAggregate();
    stopListeningToSelected();
    _assignments = const <CourseAssignmentModel>[];
    _activeAssignmentCount = null;
    _isLoading = false;
    _errorMessage = null;

    // update يعمل أثناء البناء؛ الإشعار يؤجَّل إلى ما بعده.
    scheduleMicrotask(notifyListeners);
  }

  // ----------------------------------------------------------------- writes

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<bool> createAssignment({
    required String offeringId,
    required String title,
    required String description,
    required DateTime dueAt,
    required String priority,
  }) {
    return _runWrite(
      () => _service.createAssignment(
        offeringId: offeringId,
        title: title,
        description: description,
        dueAt: dueAt,
        priority: priority,
      ),
    );
  }

  Future<bool> updateAssignment({
    required String assignmentId,
    required String title,
    required String description,
    required DateTime dueAt,
    required String priority,
  }) {
    return _runWrite(
      () => _service.updateAssignment(
        assignmentId: assignmentId,
        title: title,
        description: description,
        dueAt: dueAt,
        priority: priority,
      ),
    );
  }

  Future<bool> archiveAssignment(String assignmentId) {
    return _runWrite(() => _service.archiveAssignment(assignmentId));
  }

  /// أرشفة إشرافية من المشرف — مسار منفصل عن أرشفة المعلّم.
  Future<bool> moderateArchiveAssignment(String assignmentId) {
    return _runWrite(() => _service.moderateArchiveAssignment(assignmentId));
  }

  Future<bool> _runWrite(Future<void> Function() action) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on CourseAssignmentException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.assignmentSaveError;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
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
