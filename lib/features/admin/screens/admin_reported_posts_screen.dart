// lib/features/admin/screens/admin_reported_posts_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../shared_space/models/post_report_model.dart';
import '../providers/admin_post_reports_provider.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';

/// قائمة البلاغات المعلَّقة لمراجعة الأدمن — M-10 Reported Posts Queue.
///
/// عرض فقط، بلا حذف فعلي: "أرشفة المنشور" حذف منطقي (status: archived)
/// نفس مبدأ archivePost في كل مكان آخر بالمشروع؛ "تجاهل البلاغ" يحسم
/// البلاغ دون المساس بالمنشور — كلاهما إجراء نهائي لا رجوع عنه من هذه
/// الشاشة، فيُطلب تأكيد قبل التنفيذ.
class AdminReportedPostsScreen extends StatefulWidget {
  const AdminReportedPostsScreen({super.key});

  @override
  State<AdminReportedPostsScreen> createState() =>
      _AdminReportedPostsScreenState();
}

class _AdminReportedPostsScreenState extends State<AdminReportedPostsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminPostReportsProvider>().listenToReports();
    });
  }

  @override
  void dispose() {
    context.read<AdminPostReportsProvider>().stopListening();
    super.dispose();
  }

  Future<void> _confirmDismiss(PostReportModel report) async {
    final confirmed = await _showConfirmDialog(
      title: 'تجاهل البلاغ',
      message: 'سيبقى المنشور ظاهرًا للطلاب دون أي تغيير. هل تريدين المتابعة؟',
      confirmLabel: 'تجاهل البلاغ',
    );
    if (confirmed != true || !mounted) return;

    final success = await context.read<AdminPostReportsProvider>().dismissReport(report.id);
    if (!mounted) return;
    _showResultSnackBar(success, 'تم تجاهل البلاغ');
  }

  Future<void> _confirmArchive(PostReportModel report) async {
    final confirmed = await _showConfirmDialog(
      title: 'أرشفة المنشور',
      message: 'سيختفي المنشور من ساحة المشاركة نهائيًا للطلاب. هل تريدين المتابعة؟',
      confirmLabel: 'أرشفة المنشور',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    final success = await context.read<AdminPostReportsProvider>().archiveReportedPost(
      postId: report.postId,
      reportId: report.id,
    );
    if (!mounted) return;
    _showResultSnackBar(success, 'تم أرشفة المنشور');
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, textAlign: TextAlign.right),
        content: Text(message, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmLabel,
              style: TextStyle(color: isDestructive ? AppColors.error : AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showResultSnackBar(bool success, String successMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? successMessage : 'تعذر تنفيذ الإجراء، حاول مرة أخرى'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminPostReportsProvider>();

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بلاغات المنشورات'),
          centerTitle: true,
          leading: const AdminBackButton(),
        ),
        body: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(AdminPostReportsProvider provider) {
    if (provider.isLoading && provider.reports.isEmpty) {
      return const AppLoadingState();
    }

    if (provider.errorMessage != null && provider.reports.isEmpty) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: () => context.read<AdminPostReportsProvider>().listenToReports(),
      );
    }

    if (provider.reports.isEmpty) {
      return const AppEmptyState(
        title: 'لا توجد بلاغات معلَّقة',
        description: 'كل البلاغات تمت مراجعتها. سيظهر أي بلاغ جديد هنا فورًا.',
        icon: Icons.verified_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      itemCount: provider.reports.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.medium),
        child: _buildReportCard(provider, provider.reports[index]),
      ),
    );
  }

  Widget _buildReportCard(AdminPostReportsProvider provider, PostReportModel report) {
    final post = provider.postFor(report.postId);
    final isActing = provider.isActing;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  report.reasonDisplay,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(report.createdAt),
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.extraSmall),
          Text(
            'بواسطة: ${report.reporterName.isNotEmpty ? report.reporterName : 'غير معروف'}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
          if (report.notes.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              report.notes,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.right,
            ),
          ],
          const SizedBox(height: AppSpacing.small),
          const Divider(color: AppColors.divider),
          const SizedBox(height: AppSpacing.small),
          if (post == null)
            Text(
              'تعذر العثور على المنشور — قد يكون محذوفًا مسبقًا.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.right,
            )
          else ...[
            Text(
              post.authorName,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 4),
            Text(
              post.content,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.right,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isActing ? null : () => _confirmDismiss(report),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('تجاهل البلاغ'),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: ElevatedButton(
                  onPressed: (isActing || post == null) ? null : () => _confirmArchive(report),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  child: const Text('أرشفة المنشور'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const List<String> _arabicMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  String _formatDate(DateTime date) {
    return '${date.day} ${_arabicMonths[date.month - 1]} ${date.year}';
  }
}