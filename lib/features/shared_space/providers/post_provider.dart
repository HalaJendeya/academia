// lib/features/shared_space/providers/post_provider.dart

import 'package:flutter/material.dart';

import '../models/comment_model.dart';
import '../models/post_attachment.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

/// حالة منشورات مساق واحد، وتعليقات المنشور المفتوح حاليًا (إن وجد).
///
/// مقيَّد بمساق واحد في كل مرة — نفس مبدأ CourseFileProvider مع
/// offeringId: لا معنى لقائمة منشورات عابرة للمساقات ضمن تبويب "المساحة"
/// الخاص بمساق محدد.
class PostProvider extends ChangeNotifier {
  final PostService _service;

  PostProvider(this._service);

  List<PostModel> _posts = [];
  String? _courseId;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> loadPosts(String courseId, {bool forceRefresh = false}) async {
    if (_courseId == courseId && _posts.isNotEmpty && !forceRefresh) return;
    if (_isLoading) return;

    _courseId = courseId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await _service.getPostsForCourse(courseId);
    } on PostException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'تعذر تحميل منشورات المساحة، حاول مرة أخرى.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearPosts() {
    _posts = [];
    _courseId = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> toggleLike(String postId) async {
    // تحديث متفائل: يعكس الحالة فورًا بالواجهة، ويصحّحها إن فشل الطلب.
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final previous = _posts[index];
    _posts[index] = previous.copyWith(
      isLikedByMe: !previous.isLikedByMe,
      likesCount: previous.isLikedByMe
          ? previous.likesCount - 1
          : previous.likesCount + 1,
    );
    notifyListeners();

    try {
      final updated = await _service.toggleLike(postId);
      final currentIndex = _posts.indexWhere((p) => p.id == postId);
      if (currentIndex != -1) _posts[currentIndex] = updated;
    } catch (e) {
      final currentIndex = _posts.indexWhere((p) => p.id == postId);
      if (currentIndex != -1) _posts[currentIndex] = previous;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> createPost({
    required String courseId,
    required String content,
    PostAttachment? attachment,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final post = await _service.createPost(
        courseId: courseId,
        content: content,
        attachment: attachment,
      );
      _posts.insert(0, post);
      return true;
    } on PostException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'تعذر نشر المنشور، حاول مرة أخرى.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> reportPost({
    required String postId,
    required String reason,
    String notes = '',
  }) async {
    try {
      await _service.reportPost(postId: postId, reason: reason, notes: notes);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Comments — خاصة بمنشور واحد مفتوح حاليًا (شاشة التفاصيل).
  // ---------------------------------------------------------------------

  List<CommentModel> _comments = [];
  String? _commentsPostId;
  bool _isLoadingComments = false;
  bool _isSendingComment = false;
  String? _commentsError;

  List<CommentModel> get comments => _comments;
  bool get isLoadingComments => _isLoadingComments;
  bool get isSendingComment => _isSendingComment;
  String? get commentsError => _commentsError;

  Future<void> loadComments(String postId, {bool forceRefresh = false}) async {
    if (_commentsPostId == postId && _comments.isNotEmpty && !forceRefresh) {
      return;
    }
    if (_isLoadingComments) return;

    _commentsPostId = postId;
    _isLoadingComments = true;
    _commentsError = null;
    notifyListeners();

    try {
      _comments = await _service.getCommentsForPost(postId);
    } on PostException catch (e) {
      _commentsError = e.message;
    } catch (e) {
      _commentsError = 'تعذر تحميل التعليقات، حاول مرة أخرى.';
    } finally {
      _isLoadingComments = false;
      notifyListeners();
    }
  }

  void clearComments() {
    _comments = [];
    _commentsPostId = null;
    _commentsError = null;
    notifyListeners();
  }

  Future<bool> addComment({
    required String postId,
    required String content,
  }) async {
    if (_isSendingComment || content.trim().isEmpty) return false;

    _isSendingComment = true;
    notifyListeners();

    try {
      final comment = await _service.addComment(postId: postId, content: content);
      _comments.add(comment);

      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _posts[postIndex] = _posts[postIndex].copyWith(
          commentsCount: _posts[postIndex].commentsCount + 1,
        );
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      _isSendingComment = false;
      notifyListeners();
    }
  }
}