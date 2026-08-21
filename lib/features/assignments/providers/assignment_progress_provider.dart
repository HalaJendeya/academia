import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../models/assignment_progress_model.dart';
import '../services/assignment_progress_service.dart';

/// علامات الإنجاز الشخصية للطالب الحالي.
///
/// مزوّد مستقل عن [CourseAssignmentProvider] عمدًا. ذاك يخدم الأدوار
/// الثلاثة بنطاقَي اشتراك، وهذا يخصّ الطالب وحده — تمامًا مثل
/// [TaskProvider]. دمجهما كان سيضيف نطاقًا ثالثًا إلى مزوّد سبق أن انكسر
/// من تشارك النطاقات.
///
/// الحالة تُقرأ من بثّ حيّ لا من كتابة متفائلة: الطالب قد يضع العلامة من
/// شاشة التفاصيل ويراها فورًا في شاشة المهام دون أن تتراسل الشاشتان.
class AssignmentProgressProvider extends ChangeNotifier {
  final AssignmentProgressService _service;

  AssignmentProgressProvider(this._service);

  String? _studentId;
  bool _isLoading = false;
  String? _errorMessage;

  /// معرّفات الواجبات المنجَزة. مجموعة لا قائمة: السؤال الوحيد المطروح
  /// عليها هو «هل هذا الواجب منجَز؟» ويُطرح لكل عنصر في كل بناء.
  Set<String> _completedIds = const <String>{};
  Map<String, DateTime?> _completedAt = const <String, DateTime?>{};

  /// الواجبات التي تُحفظ حالتها الآن، لمنع النقر المزدوج لكل واجب على حدة.
  ///
  /// مجموعة لا راية واحدة: قائمة الواجبات قد تعرض عدة أزرار، وقفل الجميع
  /// لأن أحدها يُحفظ سلوك خاطئ.
  final Set<String> _saving = <String>{};

  StreamSubscription<List<AssignmentProgressModel>>? _subscription;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get studentId => _studentId;

  Set<String> get completedAssignmentIds => _completedIds;

  bool isCompleted(String assignmentId) => _completedIds.contains(assignmentId);

  DateTime? completedAt(String assignmentId) => _completedAt[assignmentId];

  /// لحظات الإنجاز بمعرّف الواجب، لترتيب تبويب «مكتملة».
  ///
  /// قد تكون القيمة null لواجب منجَز فعلًا: الطابع الزمني يأتي من الخادم،
  /// فيصل فارغًا في النسخة المحلية حتى تتم المزامنة.
  Map<String, DateTime?> get completionTimes => _completedAt;

  bool isSaving(String assignmentId) => _saving.contains(assignmentId);

  /// يتبع حالة المصادقة. يُستدعى من ProxyProvider في app_providers.
  ///
  /// [studentId] يساوي null لأي جلسة ليست طالبًا نشطًا. المعلّم والمشرف
  /// ليس لهما تقدّم شخصي، وفتح المستمع لهما استعلام ترفضه القاعدة بحق.
  void syncWithUser({required String? studentId}) {
    final id = studentId?.trim();

    if (id == null || id.isEmpty) {
      final hadState =
          _studentId != null || _completedIds.isNotEmpty || _subscription != null;
      _studentId = null;
      stopListening();
      _completedIds = const <String>{};
      _completedAt = const <String, DateTime?>{};
      _saving.clear();
      _isLoading = false;
      _errorMessage = null;
      if (hadState) scheduleMicrotask(notifyListeners);
      return;
    }

    if (_studentId == id && _subscription != null) return;

    _studentId = id;
    _completedIds = const <String>{};
    _completedAt = const <String, DateTime?>{};
    _saving.clear();
    _isLoading = true;
    _errorMessage = null;

    scheduleMicrotask(() => _listen(id));
  }

  void _listen(String studentId) {
    _subscription?.cancel();

    _subscription = _service.watchStudentProgress(studentId).listen(
      (records) {
        final completed = <String>{};
        final times = <String, DateTime?>{};
        for (final record in records) {
          if (!record.isCompleted) continue;
          completed.add(record.assignmentId);
          times[record.assignmentId] = record.completedAt;
        }
        _completedIds = completed;
        _completedAt = times;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        /*
         * فشل قراءة التقدّم لا يُسقط الواجبات نفسها.
         *
         * الواجبات تأتي من مزوّد آخر وتبقى معروضة؛ كل ما يضيع هنا هو علامة
         * الإنجاز، فتُعرض العناصر كغير منجزة مع رسالة. عرض شاشة خطأ كاملة
         * كان سيحجب محتوى صالحًا بسبب حقل ثانوي.
         */
        _completedIds = const <String>{};
        _completedAt = const <String, DateTime?>{};
        _isLoading = false;
        _errorMessage = AppStrings.assignmentProgressLoadError;
        notifyListeners();
      },
    );
  }

  /// يضع العلامة أو يزيلها. يعيد true عند النجاح.
  ///
  /// لا تحديث متفائل للقائمة: البثّ الحيّ يصل خلال جزء من الثانية ومن
  /// الذاكرة المحلية فورًا حين يكون الجهاز دون اتصال، فكتابة الحالة يدويًا
  /// كانت ستضيف مصدر حقيقة ثانيًا يمكن أن يتناقض معه.
  Future<bool> setCompleted(String assignmentId, bool completed) async {
    final id = assignmentId.trim();
    final student = _studentId;

    if (id.isEmpty || student == null) {
      _errorMessage = AppStrings.assignmentProgressSaveError;
      notifyListeners();
      return false;
    }

    // حارس النقر المزدوج: الطلب الثاني على الواجب نفسه يُتجاهل.
    if (_saving.contains(id)) return false;

    _saving.add(id);
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.setCompleted(
        studentId: student,
        assignmentId: id,
        completed: completed,
      );
      return true;
    } on AssignmentProgressException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.assignmentProgressSaveError;
      return false;
    } finally {
      _saving.remove(id);
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
