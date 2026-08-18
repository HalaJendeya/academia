// lib/features/shared_space/screens/shared_space_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../providers/post_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/report_post_sheet.dart';
import 'create_post_screen.dart';

/// محتوى تبويب "المساحة" داخل تفاصيل المساق.
///
/// مقيَّد بمساق واحد فقط ([courseId])، بنفس مبدأ تبويب "الملفات": ساحة
/// مشاركة عابرة للمساقات لا معنى لها هنا. الشاشة العامة (إن أُضيفت لاحقًا)
/// موضوع منفصل تمامًا عن هذا التبويب.
///
/// Mock بالكامل حاليًا — الإعجاب والنشر يُحدَّثان محليًا فقط عبر
/// [PostProvider]، ولا يُخزَّنان بعد.
class SharedSpaceScreen extends StatefulWidget {
  const SharedSpaceScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  final String courseId;
  final String courseTitle;

  @override
  State<SharedSpaceScreen> createState() => _SharedSpaceScreenState();
}

class _SharedSpaceScreenState extends State<SharedSpaceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().loadPosts(widget.courseId);
    });
  }

  void _showUnderDevelopment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('هذه الميزة قيد التطوير'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openCreatePost() {
    Navigator.of(context).push(
      CreatePostScreen.route(
        courseId: widget.courseId,
        courseTitle: widget.courseTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostProvider>();

    return Stack(
      children: [
        _buildBody(provider),
        Positioned(
          bottom: AppSpacing.medium,
          left: AppSpacing.medium,
          child: FloatingActionButton(
            heroTag: 'shared_space_create_post',
            backgroundColor: AppColors.primary,
            onPressed: _openCreatePost,
            child: const Icon(Icons.add_rounded, color: AppColors.textOnPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(PostProvider provider) {
    if (provider.isLoading && provider.posts.isEmpty) {
      return const AppLoadingState();
    }

    if (provider.errorMessage != null && provider.posts.isEmpty) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: () =>
            context.read<PostProvider>().loadPosts(widget.courseId, forceRefresh: true),
      );
    }

    if (provider.posts.isEmpty) {
      return const AppEmptyState(
        title: 'لا توجد منشورات بعد',
        description: 'كوني أول من يشارك سؤالًا أو ملاحظة مع زملائك في المساق.',
        icon: Icons.forum_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.medium,
        AppSpacing.screenHorizontal,
        AppSpacing.huge,
      ),
      children: [
        Text(
          'المساحة المشتركة',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.right,
        ),

        const SizedBox(height: 2),
        Text(
          'شارك أفكارك وأسئلتك مع زملائك في المساق',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: AppSpacing.medium),
        ...provider.posts.map(
              (post) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.medium),
            child: PostCard(
              post: post,

              onLikeTap: () => context.read<PostProvider>().toggleLike(post.id),
              onReportTap: _showUnderDevelopment,
            ),
          ),
        ),
      ],
    );
  }
}