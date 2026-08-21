// lib/features/shared_space/screens/post_details_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../providers/post_provider.dart';
import '../widgets/post_attachment_preview.dart';
import '../widgets/report_post_sheet.dart';
import 'create_post_screen.dart';

/// تفاصيل منشور واحد + تعليقاته — Firestore حقيقي (Stream حي للتعليقات).
class PostDetailsScreen extends StatefulWidget {
  const PostDetailsScreen({
    super.key,
    required this.post,
    required this.courseTitle,
  });

  final PostModel post;
  final String courseTitle;

  static Route<void> route({
    required PostModel post,
    required String courseTitle,
  }) {
    return MaterialPageRoute(
      builder: (_) => PostDetailsScreen(post: post, courseTitle: courseTitle),
    );
  }

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final TextEditingController _replyController = TextEditingController();

  bool get _isOwnPost =>
      widget.post.authorId == FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().listenToComments(widget.post.id);
    });
  }

  @override
  void dispose() {
    context.read<PostProvider>().clearComments();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    final provider = context.read<PostProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // اسم الكاتب الحقيقي من بروفايل الطالب — يُقرأ قبل أي await حتى لا
    // يُستخدم context بعد فجوة غير متزامنة (lint use_build_context_synchronously).
    final authorName = context.read<ProfileProvider>().profile?.fullName;
    if (authorName == null || authorName.trim().isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('تعذر التعرف على بيانات حسابك، أعيدي تسجيل الدخول'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _replyController.clear();
    FocusScope.of(context).unfocus();

    final success = await provider.addComment(
      postId: widget.post.id,
      authorName: authorName,
      content: content,
    );
    if (!mounted || success) return;

    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('تعذر إرسال الرد، حاول مرة أخرى'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showReportSheet() {
    ReportPostSheet.show(context, post: widget.post);
  }

  void _openEditPost(PostModel post) {
    Navigator.of(context).push(
      CreatePostScreen.editRoute(post: post, courseTitle: widget.courseTitle),
    );
  }

  /// مشاركة المنشور نفسه (نصًا)، لا رابطًا — لا نسخة ويب للتطبيق بعد.
  Future<void> _sharePost(PostModel post) async {
    final buffer = StringBuffer(post.content);
    if (post.attachment != null) {
      buffer
        ..writeln()
        ..writeln()
        ..write(post.attachment!.fileUrl);
    }
    await Share.share(buffer.toString(), subject: 'منشور من ${post.authorName}');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostProvider>();
    final post = _currentPost(provider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'تفاصيل المنشور',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            onSelected: (value) {
              if (value == 'report') _showReportSheet();
              if (value == 'edit') _openEditPost(post);
            },
            itemBuilder: (context) => [
              if (_isOwnPost)
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'تعديل المنشور',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'report',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'الإبلاغ عن المنشور',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    const Icon(Icons.flag_outlined, color: AppColors.error, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                children: [
                  _buildPostCard(post),
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    'التعليقات',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  _buildCommentsList(provider),
                ],
              ),
            ),
            _buildReplyBar(provider),
          ],
        ),
      ),
    );
  }

  /// يعكس تحديثات الإعجاب/عدد التعليقات اللحظية من القائمة الأصلية إن كان
  /// المنشور نفسه لا يزال محمَّلًا فيها (الـ Stream حدَّثه بالخلفية)؛ وإلا
  /// يعرض النسخة الأصلية التي فُتحت بها الشاشة.
  PostModel _currentPost(PostProvider provider) {
    final match = provider.posts.where((p) => p.id == widget.post.id);
    return match.isNotEmpty ? match.first : widget.post;
  }

  Widget _buildPostCard(PostModel post) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      post.authorName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeAgo(post.createdAt),
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.extraSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        widget.courseTitle,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              _buildAvatar(post.authorName),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            post.content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.6,
            ),
            textAlign: TextAlign.right,
          ),
          if (post.attachment != null) ...[
            const SizedBox(height: AppSpacing.small),
            PostAttachmentPreview(attachment: post.attachment!),
          ],
          const SizedBox(height: AppSpacing.small),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () => context.read<PostProvider>().toggleLike(post.id),
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: Row(
                  children: [
                    Text(
                      'إعجاب',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: post.isLikedByMe ? AppColors.primary : AppColors.textMuted,
                        fontWeight: post.isLikedByMe ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      post.isLikedByMe ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                      size: 16,
                      color: post.isLikedByMe ? AppColors.primary : AppColors.textMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Text(
                '${post.commentsCount} رد',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.medium),
              InkWell(
                onTap: () => _sharePost(post),
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: Row(
                  children: [
                    Text(
                      'مشاركة',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.share_rounded, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(PostProvider provider) {
    if (provider.isLoadingComments && provider.comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.large),
        child: AppLoadingState(),
      );
    }

    if (provider.commentsError != null && provider.comments.isEmpty) {
      return AppErrorState(
        message: provider.commentsError!,
        onRetry: () => context.read<PostProvider>().listenToComments(widget.post.id),
      );
    }

    if (provider.comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
        child: Center(
          child: Text(
            'لا توجد تعليقات بعد، كوني أول من يرد.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Column(
      children: provider.comments
          .map((c) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.small),
        child: _buildCommentCard(c),
      ))
          .toList(),
    );
  }

  Widget _buildCommentCard(CommentModel comment) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      comment.authorName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeAgo(comment.createdAt),
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              _buildAvatar(comment.authorName, size: 16),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            comment.content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBar(PostProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.small,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            InkWell(
              onTap: provider.isSendingComment ? null : _sendReply,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: provider.isSendingComment
                    ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnPrimary,
                  ),
                )
                    : const Icon(Icons.send_rounded, color: AppColors.textOnPrimary, size: 18),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: TextField(
                controller: _replyController,
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'اكتب ردًا...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                    vertical: AppSpacing.small,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _sendReply(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, {double size = 18}) {
    return CircleAvatar(
      radius: size,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      child: Text(
        name.isNotEmpty ? name[0] : '؟',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static const List<String> _arabicMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
    return '${date.day} ${_arabicMonths[date.month - 1]} ${date.year}';
  }
}