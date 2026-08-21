// lib/features/shared_space/providers/post_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/comment_model.dart';
import '../models/post_attachment.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

/// حالة منشورات مساق واحد، وتعليقات المنشور المفتوح حاليًا (إن وجد) —
/// Firestore حقيقي بالكامل عبر Streams.
///
/// نفس مبدأ CourseFileProvider.listenToOfferingFiles: اشتراك (Stream)
/// يُلغى ويُستبدل عند تبديل المساق، لا استعلام لمرة واحدة.
class PostProvider extends ChangeNotifier {
  final PostService _service;

  PostProvider(this._service);

  // ---------------------------------------------------------------------
  // Posts
  // ---------------------------------------------------------------------

  List<PostModel> _posts = [];
  StreamSubscription<List<PostModel>>? _postsSubscription;
  String? _courseId;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // ---- Pagination ("تحميل المزيد") ----
  // منشورات أقدم مُحمَّلة يدويًا، تُضاف بعد الصفحة الحيّة الأولى؛ لا تتحدّث
  // لحظيًا (انظر توثيق PostService.getOlderPosts).
  final List<PostModel> _olderPosts = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;

  /// الصفحة الحيّة أولًا، ثم المنشورات الأقدم المحمَّلة يدويًا — مصدر
  /// واحد للقائمة الكاملة يعرض على الشاشة، بدل دمج القائمتين بكل مكان.
  List<PostModel> get posts => [..._posts, ..._olderPosts];
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  void listenToCoursePosts(String courseId) {
    _postsSubscription?.cancel();
    _courseId = courseId;
    _olderPosts.clear();
    _hasMore = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _postsSubscription = _service.watchPostsForCourse(courseId).listen(
          (posts) async {
        // حالة الإعجاب لكل مستخدم غير مخزَّنة داخل مستند المنشور، فتُجلب
        // لكل منشور على حدة بعد وصول القائمة نفسها.
        final withLikeStatus = await Future.wait(
          posts.map((p) async {
            final liked = await _service.isPostLikedByMe(p.id);
            return p.copyWith(isLikedByMe: liked);
          }),
        );
        _posts = withLikeStatus;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object e) {
        _errorMessage = e is PostException
            ? e.message
            : 'تعذر تحميل منشورات المساحة، حاول مرة أخرى.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// يحمّل الدفعة التالية من المنشورات الأقدم من آخر منشور معروض حاليًا.
  /// لا شيء يُطلب إن كانت الصفحة الأولى لم تصل بعد، أو لم يتبقَّ شيء، أو
  /// طلب سابق ما زال جاريًا — يمنع طلبات مكرّرة من تمرير سريع بالقائمة.
  Future<void> loadMorePosts() async {
    if (_isLoadingMore || !_hasMore || _courseId == null) return;

    final currentList = posts;
    if (currentList.isEmpty) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final page = await _service.getOlderPosts(
        courseId: _courseId!,
        before: currentList.last.createdAt,
      );

      final existingIds = currentList.map((p) => p.id).toSet();
      final withLikeStatus = await Future.wait(
        page.posts
            .where((p) => !existingIds.contains(p.id))
            .map((p) async {
          final liked = await _service.isPostLikedByMe(p.id);
          return p.copyWith(isLikedByMe: liked);
        }),
      );

      _olderPosts.addAll(withLikeStatus);
      _hasMore = page.hasMore;
    } catch (e) {
      // فشل "تحميل المزيد" لا يمسح ما هو معروض أصلًا — القائمة الحالية
      // تبقى كما هي، والمستخدم يقدر يعيد المحاولة بنفس الزر.
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void clearPosts() {
    _postsSubscription?.cancel();
    _postsSubscription = null;
    _posts = [];
    _olderPosts.clear();
    _hasMore = true;
    _courseId = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> toggleLike(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    // تحديث متفائل فوري؛ القيمة الحقيقية من المعاملة (Transaction) ستصل
    // عبر الـ Stream نفسه بعد لحظات وتستبدلها تلقائيًا.
    final previous = _posts[index];
    _posts[index] = previous.copyWith(
      isLikedByMe: !previous.isLikedByMe,
      likesCount: previous.isLikedByMe
          ? previous.likesCount - 1
          : previous.likesCount + 1,
    );
    notifyListeners();

    try {
      await _service.toggleLike(postId);
    } catch (e) {
      final currentIndex = _posts.indexWhere((p) => p.id == postId);
      if (currentIndex != -1) _posts[currentIndex] = previous;
      notifyListeners();
    }
  }

  Future<bool> createPost({
    required String courseId,
    required String authorName,
    String authorRole = '',
    required String content,
    PostAttachment? attachment,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createPost(
        courseId: courseId,
        authorName: authorName,
        authorRole: authorRole,
        content: content,
        attachment: attachment,
      );
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

  Future<bool> updatePost({
    required String postId,
    required String content,
    PostAttachment? attachment,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updatePost(postId: postId, content: content, attachment: attachment);
      return true;
    } on PostException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'تعذر حفظ التعديلات، حاول مرة أخرى.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> archivePost(String postId) async {
    try {
      await _service.archivePost(postId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> reportPost({
    required String postId,
    required String courseId,
    required String reporterName,
    required String reason,
    String notes = '',
  }) async {
    try {
      await _service.reportPost(
        postId: postId,
        courseId: courseId,
        reporterName: reporterName,
        reason: reason,
        notes: notes,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Comments — خاصة بمنشور واحد مفتوح حاليًا (شاشة التفاصيل).
  // ---------------------------------------------------------------------

  List<CommentModel> _comments = [];
  StreamSubscription<List<CommentModel>>? _commentsSubscription;

  bool _isLoadingComments = false;
  bool _isSendingComment = false;
  String? _commentsError;

  List<CommentModel> get comments => _comments;
  bool get isLoadingComments => _isLoadingComments;
  bool get isSendingComment => _isSendingComment;
  String? get commentsError => _commentsError;

  void listenToComments(String postId) {
    _commentsSubscription?.cancel();
    _isLoadingComments = true;
    _commentsError = null;
    notifyListeners();

    _commentsSubscription = _service.watchComments(postId).listen(
          (comments) {
        _comments = comments;
        _isLoadingComments = false;
        _commentsError = null;
        notifyListeners();
      },
      onError: (Object e) {
        _commentsError = e is PostException
            ? e.message
            : 'تعذر تحميل التعليقات، حاول مرة أخرى.';
        _isLoadingComments = false;
        notifyListeners();
      },
    );
  }

  void clearComments() {
    _commentsSubscription?.cancel();
    _commentsSubscription = null;
    _comments = [];
    _commentsError = null;
    notifyListeners();
  }

  Future<bool> addComment({
    required String postId,
    required String authorName,
    required String content,
  }) async {
    if (_isSendingComment || content.trim().isEmpty) return false;

    _isSendingComment = true;
    notifyListeners();

    try {
      await _service.addComment(
        postId: postId,
        authorName: authorName,
        content: content,
      );
      return true;
    } catch (e) {
      return false;
    } finally {
      _isSendingComment = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _commentsSubscription?.cancel();
    super.dispose();
  }
}