import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../models/course_assignment_model.dart';
import '../services/course_assignment_service.dart';

/// الواجبات الأكاديمية عبر الأدوار الثلاثة.
///
/// يتبع النمط الذي أرساه CourseFileProvider: مستمع لكل طرح مصرَّح به، ودمج
/// في الذاكرة. لا يوجد استعلام عالمي واحد يُصفّى محليًا — القواعد تقيّد
/// القراءة بالطرح، فاستعلام غير مقيَّد يُرفض من الخادم أصلًا. الاستثناء
/// الوحيد هو إشراف المشرف، وهو مصرَّح له عالميًا بنص القاعدة.
///
/// [activeAssignmentCount] استثناء مقصود ومحدود: لوحة المشرف تحتاج رقمًا
/// واحدًا، ويُقرأ بتجميع من الخادم لا باشتراك.
class CourseAssignmentProvider extends ChangeNotifier {
  final CourseAssignmentService _service;

  CourseAssignmentProvider(this._service);

  List<CourseAssignmentModel> _assignments = const <CourseAssignmentModel>[];
  bool _isLoading = false;
  String? _errorMessage;

  /// مستمع واحد لكل طرح، مفتاحه معرّف الطرح.
  final Map<String, StreamSubscription<List<CourseAssignmentModel>>>
  _subscriptions = {};
  final Map<String, List<CourseAssignmentModel>> _byOffering = {};

  StreamSubscription<List<CourseAssignmentModel>>? _globalSubscription;

  int? _activeAssignmentCount;
  bool _isLoadingActiveAssignmentCount = false;

  List<CourseAssignmentModel> get assignments => _assignments;

  /// النشطة وحدها. الاستعلامات الإنتاجية تُصفّي على الخادم، لكن الإشراف
  /// العالمي وحالات التخبئة قد تحمل غير ذلك.
  List<CourseAssignmentModel> get activeAssignments =>
      _assignments.where((assignment) => assignment.isActive).toList();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
      /*
       * لا تُكتب رسالة في errorMessage: تلك تخص قائمة الواجبات، وفشل عدّاد
       * إحصائي يجب ألا يُظهر لوحة المشرف كأنها فشلت.
       */
      _activeAssignmentCount = null;
    } finally {
      _isLoadingActiveAssignmentCount = false;
      notifyListeners();
    }
  }

  /// واجبات طرح واحد: تفاصيل المساق للطالب، وتفاصيل الطرح للمعلّم.
  void listenToOfferingAssignments(String offeringId) {
    if (offeringId.trim().isEmpty) {
      stopListening();
      _assignments = const <CourseAssignmentModel>[];
      _isLoading = false;
      notifyListeners();
      return;
    }

    // المستمع نفسه قائم بالفعل: لا نعيد الاشتراك ولا نُظهر تحميلًا جديدًا.
    if (_subscriptions.length == 1 &&
        _subscriptions.containsKey(offeringId.trim()) &&
        _globalSubscription == null) {
      return;
    }

    listenToOfferingsAssignments([offeringId]);
  }

  /// واجبات عدة طروح، بمستمع لكل طرح ودمج في الذاكرة.
  void listenToOfferingsAssignments(List<String> offeringIds) {
    final unique = offeringIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    // المجموعة نفسها مشتركة بالفعل: إعادة الاشتراك تُومض القائمة بلا سبب.
    if (_globalSubscription == null &&
        _subscriptions.isNotEmpty &&
        _subscriptions.length == unique.length &&
        unique.every(_subscriptions.containsKey)) {
      return;
    }

    stopListening();

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
              _errorMessage = AppStrings.courseAssignmentsLoadError;
              _rebuildMerged();
              notifyListeners();
            },
          );
    }
  }

  /// كل الواجبات النشطة — إشراف المشرف وحده.
  void listenToAllActiveAssignments() {
    if (_globalSubscription != null) return;

    stopListening();
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
        _errorMessage = AppStrings.courseAssignmentsLoadError;
        notifyListeners();
      },
    );
  }

  /// دمج نتائج المستمعين مع إزالة التكرار بالمعرّف.
  ///
  /// التكرار ممكن نظريًا لو اشترك المزوّد بالطرح نفسه مرتين؛ المفتاح يمنع
  /// ذلك، لكن الدمج بالمعرّف يجعل القائمة صحيحة مهما كان مصدرها.
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
      // ترتيب ثابت عند تساوي الموعد، وإلا اهتزّ ترتيب القائمة بين البثّات.
      return byDue != 0 ? byDue : a.id.compareTo(b.id);
    });
    _assignments = merged;
  }

  void stopListening() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _byOffering.clear();

    _globalSubscription?.cancel();
    _globalSubscription = null;
  }

  void clearAssignments() {
    stopListening();
    _assignments = const <CourseAssignmentModel>[];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
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
        stopListening();
        _assignments = const <CourseAssignmentModel>[];
        _activeAssignmentCount = null;
        _isLoading = false;
        _errorMessage = null;
      }
      _hadSession = true;
      _lastRole = role;
      return;
    }

    final hadState =
        _hadSession || _subscriptions.isNotEmpty || _assignments.isNotEmpty;
    _hadSession = false;
    _lastRole = null;
    if (!hadState) return;

    stopListening();
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
