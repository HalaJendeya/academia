// lib/features/admin/providers/admin_post_reports_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared_space/models/post_model.dart';
import '../../shared_space/models/post_report_model.dart';
import '../../shared_space/services/post_service.dart';

/// حالة قائمة البلاغات لدى الأدمن.
///
/// كل بلاغ مقرون بملخّص المنشور المُبلَّغ عنه (اسم الكاتب ومحتواه)، يُجلب
/// مرة واحدة عند وصول البلاغ لا عند كل بناء واجهة — لا داعٍ لاستعلام
/// متكرر لمنشور لا يتغيّر أثناء مراجعة قائمة البلاغات.
class AdminPostReportsProvider extends ChangeNotifier {
  final PostService _service;

  AdminPostReportsProvider(this._service);

  StreamSubscription<List<PostReportModel>>? _subscription;

  List<PostReportModel> _reports = [];
  final Map<String, PostModel?> _postsById = {};

  bool _isLoading = false;
  bool _isActing = false;
  String? _errorMessage;

  List<PostReportModel> get reports => _reports;
  bool get isLoading => _isLoading;
  bool get isActing => _isActing;
  String? get errorMessage => _errorMessage;

  PostModel? postFor(String postId) => _postsById[postId];

  void listenToReports() {
    _subscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _service.watchPendingReports().listen(
          (reports) async {
        _reports = reports;

        final missingIds = reports
            .map((r) => r.postId)
            .where((id) => !_postsById.containsKey(id))
            .toSet();
        for (final postId in missingIds) {
          _postsById[postId] = await _service.getPostById(postId);
        }

        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object e) {
        _errorMessage = e is PostException
            ? e.message
            : 'تعذر تحميل البلاغات، حاول مرة أخرى.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _reports = [];
    _postsById.clear();
    notifyListeners();
  }

  Future<bool> dismissReport(String reportId) async {
    if (_isActing) return false;
    _isActing = true;
    notifyListeners();
    try {
      await _service.dismissReport(reportId);
      return true;
    } catch (e) {
      return false;
    } finally {
      _isActing = false;
      notifyListeners();
    }
  }

  Future<bool> archiveReportedPost({
    required String postId,
    required String reportId,
  }) async {
    if (_isActing) return false;
    _isActing = true;
    notifyListeners();
    try {
      await _service.archiveReportedPost(postId: postId, reportId: reportId);
      return true;
    } catch (e) {
      return false;
    } finally {
      _isActing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}