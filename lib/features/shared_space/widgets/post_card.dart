// lib/features/shared_space/widgets/post_card.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../models/post_attachment.dart';
import '../models/post_model.dart';

/// بطاقة منشور واحد بساحة مشاركة المساق، مطابقة لتصميم الفيجما: كاتب
/// ودوره، قائمة خيارات (⋮)، النص، مرفق اختياري، وصف إعجاب/تعليق بالأسفل.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLikeTap,
    this.onReportTap,
  });

  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onReportTap;

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
            _buildAttachment(post.attachment!),
          ],
          const SizedBox(height: AppSpacing.small),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.small),
          _buildFooter(),
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
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'report',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'الإبلاغ عن المنشور',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  const Icon(
                    Icons.flag_outlined,
                    color: AppColors.error,
                    size: 18,
                  ),
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
      backgroundImage: post.authorAvatarUrl != null
          ? NetworkImage(post.authorAvatarUrl!)
          : null,
      child: post.authorAvatarUrl == null
          ? Text(
        post.authorName.isNotEmpty ? post.authorName[0] : '؟',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      )
          : null,
    );
  }

  Widget _buildAttachment(PostAttachment attachment) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  attachment.fileName,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  attachment.sizeLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
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
      ],
    );
  }
}