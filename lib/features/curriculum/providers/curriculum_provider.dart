import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../models/curriculum_course_model.dart';
import '../services/curriculum_service.dart';

/// الخطة الدراسية لتخصص واحد.
///
/// الخطة تُقرأ دائمًا لتخصص محدد، لذلك يحمل المزوّد majorId الحالي ويعيد
/// الاشتراك عند تغييره بدل الاحتفاظ بخطط متعددة في الذاكرة.
class CurriculumProvider extends ChangeNotifier {
  final CurriculumService _service;

  CurriculumProvider(this._service);

  List<CurriculumCourseModel> _entries = [];
  Map<int, List<CurriculumCourseModel>> _byLevel = {};

  String? _majorId;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  StreamSubscription<List<CurriculumCourseModel>>? _subscription;

  List<CurriculumCourseModel> get entries => _entries;

  /// صفوف الخطة مجمّعة حسب المستوى الأكاديمي (1..8).
  Map<int, List<CurriculumCourseModel>> get byLevel => _byLevel;

  String? get majorId => _majorId;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  bool get hasCurriculum => _entries.isNotEmpty;

  bool _isAdminSession = false;

  /// يتبع حالة المصادقة. يُستدعى من ProxyProvider في app_providers.
  ///
  /// شاشة الخطة الدراسية إدارية؛ الطالب يقرأ خطته عبر StudentCoursesProvider
  /// لا عبر هذا المزوّد.
  void syncWithAuth({required bool isActiveAdmin}) {
    if (isActiveAdmin) {
      _isAdminSession = true;
      return;
    }

    final hadAdminState =
        _isAdminSession || _subscription != null || _entries.isNotEmpty;
    _isAdminSession = false;
    if (!hadAdminState) return;

    stopListening();
    _entries = [];
    _byLevel = {};
    _majorId = null;
    _isLoading = false;
    _errorMessage = null;

    scheduleMicrotask(notifyListeners);
  }

  /// المستويات التي تحتوي فعلًا على صفوف، مرتبة تصاعديًا.
  List<int> get levels {
    final list = _byLevel.keys.toList()..sort();
    return list;
  }

  List<CurriculumCourseModel> entriesForLevel(int level) =>
      _byLevel[level] ?? const <CurriculumCourseModel>[];

  /// صفوف الخطة التي تشير إلى مساقات محددة فقط، دون خانات المتطلبات.
  List<CurriculumCourseModel> get courseEntries =>
      _entries.where((entry) => entry.isCourseEntry).toList();

  /// خانات المتطلبات التي لم يُختَر لها مساق بعد.
  List<CurriculumCourseModel> get slotEntries =>
      _entries.where((entry) => entry.isSlotEntry).toList();

  /// معرّفات المساقات المطلوبة في الخطة، لجلب بياناتها من الكتالوج.
  List<String> get curriculumCourseIds => _entries
      .where((entry) => entry.isCourseEntry && entry.courseId != null)
      .map((entry) => entry.courseId!)
      .toList();

  void _applyData(List<CurriculumCourseModel> data) {
    _entries = data;

    final grouped = <int, List<CurriculumCourseModel>>{};
    for (final entry in data) {
      grouped.putIfAbsent(entry.academicLevel, () => []).add(entry);
    }
    _byLevel = grouped;
  }

  void listenToCurriculum(String majorId) {
    stopListening();

    _majorId = majorId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _service.watchCurriculum(majorId).listen(
      (data) {
        _applyData(data);
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = AppStrings.curriculumLoadError;
        notifyListeners();
      },
    );
  }

  Future<void> loadCurriculum(String majorId) async {
    _majorId = majorId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _applyData(await _service.getCurriculum(majorId));
    } on CurriculumException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = AppStrings.curriculumLoadError;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void clearCurriculum() {
    stopListening();
    _majorId = null;
    _applyData(const <CurriculumCourseModel>[]);
    notifyListeners();
  }

  Future<bool> addCourseEntry(CurriculumCourseModel entry) {
    return _runWrite(() => _service.addCourseEntry(entry));
  }

  Future<bool> addSlotEntry(CurriculumCourseModel entry) {
    return _runWrite(() => _service.addSlotEntry(entry));
  }

  Future<bool> updateEntry(CurriculumCourseModel entry) {
    return _runWrite(() => _service.updateEntry(entry));
  }

  Future<bool> removeEntry(String entryId) {
    return _runWrite(() => _service.removeEntry(entryId));
  }

  /// نقل صف إلى معرّف مستند جديد.
  ///
  /// معرّفات صفوف الخطة توليدية، فتغيير المساق (أو مستوى الخانة وترتيبها)
  /// يغيّر المعرّف نفسه، والمستند لا يمكن أن ينتقل. لذلك يُنشأ الصف الجديد
  /// أولًا ثم يُحذف القديم: لو فشلت العملية في منتصفها يبقى صف مكرر ظاهر
  /// للمشرف، وهو أهون من اختفاء الصف من الخطة.
  Future<bool> replaceEntry({
    required String oldEntryId,
    required CurriculumCourseModel entry,
  }) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (entry.isCourseEntry) {
        await _service.addCourseEntry(entry);
      } else {
        await _service.addSlotEntry(entry);
      }
      await _service.removeEntry(oldEntryId);
      return true;
    } on CurriculumException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.curriculumSaveError;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> _runWrite(Future<void> Function() action) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on CurriculumException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.curriculumSaveError;
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
