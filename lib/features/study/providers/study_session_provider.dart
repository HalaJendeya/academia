import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../models/study_session_model.dart';
import '../services/study_session_service.dart';

/// جلسات المذاكرة: السجل المخزَّن، والمؤقّت الحيّ.
///
/// الفصل بين الاثنين مقصود. السجل يأتي من Firestore عبر مستمع، أما العدّ
/// التنازلي فحالة محلية بحتة لا تُكتب: تُخزَّن الجلسة مرتين فقط طوال
/// عمرها — عند البدء وعند الإغلاق.
///
/// 🔴 الوقت المتبقي يُشتقّ من [_endsAt] لا من عدّاد يُنقَص كل ثانية.
/// المؤقّت الدوري لا يعمل بدقة والتطبيق في الخلفية، فعدّاد يُنقَص ثانيةً
/// كل تكّة يتأخّر بمقدار مدة الغياب. حساب الفرق من [DateTime.now] يعطي
/// الوقت الصحيح فور العودة مهما طال الغياب، والتكّة مجرّد محفّز لإعادة
/// الرسم لا مصدر للحقيقة.
class StudySessionProvider extends ChangeNotifier {
  final StudySessionService _service;

  StudySessionProvider(this._service);

  // ----------------------------------------------------------- سجل مخزَّن
  List<StudySessionModel> _sessions = const [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<StudySessionModel>>? _subscription;

  String? _studentId;

  List<StudySessionModel> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// الجلسات المغلقة، الأحدث أولًا — وهي وحدها ما يُعرض في «آخر الجلسات».
  List<StudySessionModel> get finishedSessions =>
      _sessions.where((s) => !s.isActive).toList();

  List<StudySessionModel> recentSessions({int limit = 5}) {
    final finished = finishedSessions;
    return finished.length <= limit ? finished : finished.sublist(0, limit);
  }

  // ----------------------------------------------------------- مؤقّت محلي
  String? _activeSessionId;
  String? _activeOfferingId;
  String? _activeCourseId;
  int _plannedMinutes = 0;
  DateTime? _startedAt;

  /// لحظة الانتهاء المتوقَّعة. null أثناء الإيقاف المؤقت.
  DateTime? _endsAt;

  /// المتبقي المجمَّد أثناء الإيقاف المؤقت.
  Duration? _pausedRemaining;

  bool _isStarting = false;
  bool _isClosing = false;
  Timer? _ticker;

  /// ساعة قابلة للحقن حتى تختبر الاختبارات مرور الوقت دون انتظاره.
  DateTime Function() _clock = DateTime.now;

  @visibleForTesting
  void debugSetClock(DateTime Function() clock) {
    _clock = clock;
    notifyListeners();
  }

  bool get hasActiveSession => _activeSessionId != null;
  bool get isPaused => hasActiveSession && _endsAt == null;
  bool get isRunning => hasActiveSession && _endsAt != null;
  bool get isStarting => _isStarting;
  bool get isClosing => _isClosing;
  String? get activeSessionId => _activeSessionId;
  String? get activeOfferingId => _activeOfferingId;
  int get plannedMinutes => _plannedMinutes;

  /// الوقت المتبقي، محسوبًا من الساعة لا من عدّاد داخلي.
  Duration get remaining {
    if (!hasActiveSession) return Duration.zero;
    if (_pausedRemaining != null) return _pausedRemaining!;
    final endsAt = _endsAt;
    if (endsAt == null) return Duration.zero;
    final left = endsAt.difference(_clock());
    return left.isNegative ? Duration.zero : left;
  }

  /// بلغت الجلسة نهايتها الطبيعية.
  bool get hasReachedZero => hasActiveSession && remaining == Duration.zero;

  /// ما مضى فعلًا من الجلسة، بالدقائق، مقرَّبًا لأقرب دقيقة كاملة.
  int get elapsedMinutes {
    if (!hasActiveSession) return 0;
    final total = Duration(minutes: _plannedMinutes);
    final left = remaining;
    final elapsed = total - left;
    return elapsed.isNegative ? 0 : elapsed.inMinutes;
  }

  // ------------------------------------------------------- دورة حياة المصادقة
  /// يتبع حالة المصادقة. يُستدعى من ProxyProvider في app_providers.
  ///
  /// المستمع هنا مقيَّد بـ `userId == uid`، وقراءته مسموحة لصاحبها وحده.
  /// بقاؤه حيًّا بعد الخروج أو بعد تبديل الحساب ينتج PERMISSION_DENIED
  /// متكررة، والعلاج إيقاف المستمع لا إضعاف القاعدة — نفس ما فُعل في
  /// AssignmentProgressProvider وبقية المزوّدات المقيَّدة بالمالك.
  ///
  /// [studentId] يكون null لغير الطالب النشط: المعلّم والمشرف لا يملكان
  /// جلسات مذاكرة، وفتح مستمع لهما استعلام ترفضه القاعدة بحق.
  void syncWithUser({required String? studentId}) {
    final next = studentId?.trim().isEmpty ?? true ? null : studentId!.trim();
    if (next == _studentId) return;

    _studentId = next;
    stopListening();

    // تبديل الحساب يُسقط كل شيء: سجلّ الحساب السابق ومؤقّته معًا.
    _sessions = const [];
    _errorMessage = null;
    _isLoading = false;
    _discardTimer();

    if (next != null) {
      _listen(next);
    } else {
      scheduleMicrotask(notifyListeners);
    }
  }

  void _listen(String studentId) {
    _isLoading = true;
    _errorMessage = null;
    scheduleMicrotask(notifyListeners);

    _subscription = _service.watchUserSessions(studentId).listen(
      (data) {
        _sessions = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _sessions = const [];
        _isLoading = false;
        _errorMessage = AppStrings.studySessionsLoadError;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  // ------------------------------------------------------------- الإجراءات
  /// يبدأ جلسة جديدة. يعيد false إذا تعذّر البدء.
  ///
  /// جلسة واحدة في كل مرة: البدء مرفوض ما دامت هناك جلسة جارية، فلا
  /// ينتهي الطالب بمؤقّتين يتنافسان على الشاشة نفسها.
  Future<bool> startSession({
    required int plannedMinutes,
    String? offeringId,
    String? courseId,
  }) async {
    if (_isStarting || hasActiveSession) return false;

    final studentId = _studentId;
    if (studentId == null) {
      _errorMessage = AppStrings.authenticationRequired;
      notifyListeners();
      return false;
    }

    if (!StudySessionModel.isValidDuration(plannedMinutes)) {
      _errorMessage = AppStrings.studySessionInvalidDuration;
      notifyListeners();
      return false;
    }

    _isStarting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = await _service.startSession(
        userId: studentId,
        plannedMinutes: plannedMinutes,
        offeringId: offeringId,
        courseId: courseId,
      );

      _activeSessionId = id;
      _activeOfferingId = offeringId;
      _activeCourseId = courseId;
      _plannedMinutes = plannedMinutes;
      _startedAt = _clock();
      _endsAt = _startedAt!.add(Duration(minutes: plannedMinutes));
      _pausedRemaining = null;
      _startTicker();
      return true;
    } on StudySessionException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.studySessionStartError;
      return false;
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  void pause() {
    if (!isRunning) return;
    _pausedRemaining = remaining;
    _endsAt = null;
    _stopTicker();
    notifyListeners();
  }

  void resume() {
    if (!isPaused) return;
    final left = _pausedRemaining ?? Duration.zero;
    _pausedRemaining = null;
    _endsAt = _clock().add(left);
    _startTicker();
    notifyListeners();
  }

  /// إنهاء مبكر: تُحتسب الجلسة مكتملة بما ذاكره الطالب فعلًا لا بالمخطَّط.
  Future<bool> finishEarly() => _close(StudySessionStatus.completed);

  /// اكتمال طبيعي عند بلوغ الصفر: تُحتسب المدة المخطَّطة كاملة.
  Future<bool> complete() => _close(
    StudySessionStatus.completed,
    overrideMinutes: _plannedMinutes,
  );

  /// إلغاء: لا تُحتسب مدة، والجلسة تبقى في السجل بحالتها الصريحة.
  Future<bool> cancel() =>
      _close(StudySessionStatus.cancelled, overrideMinutes: 0);

  Future<bool> _close(
    StudySessionStatus status, {
    int? overrideMinutes,
  }) async {
    final id = _activeSessionId;
    if (id == null || _isClosing) return false;

    _isClosing = true;
    _errorMessage = null;
    notifyListeners();

    final minutes = overrideMinutes ?? elapsedMinutes;

    try {
      await _service.closeSession(
        sessionId: id,
        status: status,
        actualMinutes: minutes,
      );
      _discardTimer();
      return true;
    } on StudySessionException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.studySessionCloseError;
      return false;
    } finally {
      _isClosing = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------- التكّة
  /// التكّة تعيد الرسم فقط؛ الوقت يُقرأ من الساعة في [remaining].
  void _startTicker() {
    _stopTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!hasActiveSession) {
        _stopTicker();
        return;
      }
      notifyListeners();
      // عند بلوغ الصفر يتوقف العدّ، ويبقى الإغلاق قرارًا صريحًا تتخذه
      // الشاشة حتى لا تُكتب Firestore من مؤقّت خلفي بلا واجهة.
      if (remaining == Duration.zero) _stopTicker();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _discardTimer() {
    _stopTicker();
    _activeSessionId = null;
    _activeOfferingId = null;
    _activeCourseId = null;
    _plannedMinutes = 0;
    _startedAt = null;
    _endsAt = null;
    _pausedRemaining = null;
  }

  @visibleForTesting
  String? get debugActiveCourseId => _activeCourseId;

  @visibleForTesting
  DateTime? get debugStartedAt => _startedAt;

  @override
  void dispose() {
    _stopTicker();
    stopListening();
    super.dispose();
  }
}
