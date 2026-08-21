// lib/features/shared_space/screens/shared_space_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../models/post_model.dart';
import '../providers/post_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/report_post_sheet.dart';
import 'create_post_screen.dart';
import 'post_details_screen.dart';

/// محتوى تبويب "المساحة" داخل تفاصيل المساق — Firestore حقيقي.
///
/// الاشتراك بالمنشورات (Stream) يبدأ عند فتح التبويب، ويُلغى صراحة عند
/// إغلاقه ([dispose]) — نفس مبدأ CourseFileProvider.clearFiles: تسريب
/// اشتراك لم يُلغَ يعني استماعًا لبيانات مساق لم يعد المستخدم يراه.
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().listenToCoursePosts(widget.courseId);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    context.read<PostProvider>().clearPosts();
    super.dispose();
  }

  /// يطلب الصفحة التالية عند الاقتراب من آخر القائمة (200 بكسل)، لا عند
  /// الوصول الحرفي لآخرها — يمنع "ارتطامًا" محسوسًا بنهاية القائمة قبل
  /// ظهور المزيد.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<PostProvider>().loadMorePosts();
    }
  }

  void _openCreatePost() {
    Navigator.of(context).push(
      CreatePostScreen.route(
        courseId: widget.courseId,
        courseTitle: widget.courseTitle,
      ),
    );
  }

  void _openPostDetails(PostModel post) {
    Navigator.of(context).push(
      PostDetailsScreen.route(post: post, courseTitle: widget.courseTitle),
    );
  }

  void _showReportSheet(PostModel post) {
    ReportPostSheet.show(context, post: post);
  }

  void _openEditPost(PostModel post) {
    Navigator.of(context).push(
      CreatePostScreen.editRoute(post: post, courseTitle: widget.courseTitle),
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
        onRetry: () => context.read<PostProvider>().listenToCoursePosts(widget.courseId),
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
      controller: _scrollController,
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
              onTap: () => _openPostDetails(post),
              onLikeTap: () => context.read<PostProvider>().toggleLike(post.id),
              onReportTap: () => _showReportSheet(post),
              onEditTap: () => _openEditPost(post),
            ),
          ),
        ),
        if (provider.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }
}