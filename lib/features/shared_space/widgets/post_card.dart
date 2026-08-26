// lib/features/shared_space/widgets/post_card.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../models/post_model.dart';
import 'post_attachment_preview.dart';

/// بطاقة منشور واحد بساحة مشاركة المساق، مطابقة لتصميم الفيجما: كاتب
/// ودوره، قائمة خيارات (⋮)، النص، مرفق اختياري، وصف إعجاب/تعليق بالأسفل.
///
/// قائمة الخيارات ديناميكية حسب الملكية: "تعديل المنشور" لصاحبه فقط،
/// "الإبلاغ عن المنشور" لغيره — طالب لا يُبلِغ عن نفسه، ولا يعدّل منشور
/// زميله؛ نفس الشرط الذي تفرضه قاعدة posts.update بـ Firestore، معروضًا
/// هنا كواجهة لا كتحقق أمني بديل عنها.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLikeTap,
    this.onReportTap,
    this.onEditTap,
  });

  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onReportTap;
  final VoidCallback? onEditTap;

  bool get _isOwnPost => post.authorId == FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
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
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          icon: const Icon(
            Icons.more_vert_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          onSelected: (value) {
            if (value == 'report') onReportTap?.call();
            if (value == 'edit') onEditTap?.call();
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
                post.authorRole,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        _buildAvatar(),
      ],
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      child: Text(
        post.authorName.isNotEmpty ? post.authorName[0] : '؟',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _sharePost() async {
    final buffer = StringBuffer(post.content);
    if (post.attachment != null) {
      buffer
        ..writeln()
        ..writeln()
        ..write(post.attachment!.fileUrl);
    }
    await Share.share(buffer.toString(), subject: 'منشور من ${post.authorName}');
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        InkWell(
          onTap: onLikeTap,
          borderRadius: BorderRadius.circular(AppRadius.small),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Row(
              children: [
                Text(
                  'إعجاب (${post.likesCount})',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: post.isLikedByMe
                        ? AppColors.primary
                        : AppColors.textMuted,
                    fontWeight: post.isLikedByMe
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  post.isLikedByMe
                      ? Icons.thumb_up_rounded
                      : Icons.thumb_up_outlined,
                  size: 16,
                  color: post.isLikedByMe
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Text(
          'تعليق (${post.commentsCount})',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.chat_bubble_outline_rounded,
          size: 16,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.medium),
        InkWell(
          onTap: _sharePost,
          borderRadius: BorderRadius.circular(AppRadius.small),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
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
        ),
      ],
    );
  }
}