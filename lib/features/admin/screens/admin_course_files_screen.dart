import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../files/services/course_file_opener.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../courses/models/course_offering_model.dart';
import '../../files/models/course_file_model.dart';
import '../../files/providers/course_file_provider.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';
import '../widgets/edit_course_file_dialog.dart';
import 'admin_upload_file_screen.dart';

/// وسيطات الشاشة: الملفات دائمًا تخص طرحًا بعينه.
class OfferingFilesArgs {
  const OfferingFilesArgs({required this.offering, required this.courseTitle});

  final CourseOfferingModel offering;
  final String courseTitle;
}

/// ملفات طرح مساق، للمشرف.
///
/// الشاشة مقيَّدة بطرح مُمرَّر إليها، ولا تسأل المشرف عن المساق أو الفصل:
/// هذه الحقول تُشتق من الطرح داخل المزوّد، فلا يمكن أن يُنسب ملف إلى فصل
/// لا ينتمي إليه.
class AdminCourseFilesScreen extends StatefulWidget {
  const AdminCourseFilesScreen({super.key});

  @override
  State<AdminCourseFilesScreen> createState() => _AdminCourseFilesScreenState();
}

class _AdminCourseFilesScreenState extends State<AdminCourseFilesScreen> {
  OfferingFilesArgs? _args;
  bool _initialized = false;

  /// مرجع محفوظ: لا يمكن قراءة المزوّد من context أثناء dispose.
  CourseFileProvider? _fileProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fileProvider = context.read<CourseFileProvider>();

    if (_initialized) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is OfferingFilesArgs) _args = arguments;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final offeringId = _args?.offering.id;
      if (offeringId == null) return;
      context.read<CourseFileProvider>().listenToOfferingFiles(offeringId);
    });

    _initialized = true;
  }

  @override
  void dispose() {
    _fileProvider?.clearFiles();
    super.dispose();
  }

  void _openUpload() {
    final args = _args;
    if (args == null) return;

    Navigator.of(context).pushNamed(
      AppRoutes.adminUploadFile,
      arguments: UploadFileArgs(
        offering: args.offering,
        courseTitle: args.courseTitle,
      ),
    );
  }

  Future<void> _openFile(CourseFileModel file) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await openCourseFileUrl(file.cloudinaryUrl);
    if (!mounted || result == CourseFileOpenResult.opened) return;

    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.fileOpenError)),
    );
  }

  Future<void> _editFile(CourseFileModel file) async {
    final provider = context.read<CourseFileProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final updated = await showEditCourseFileDialog(context: context, file: file);
    if (updated == null || !mounted) return;

    final success = await provider.updateFileMetadata(updated);
    if (!mounted) return;

    scaffoldMessenger.showSnackBar(
      success
          ? const SnackBar(content: Text(AppStrings.fileUpdatedSuccess))
          : SnackBar(
              content: Text(provider.errorMessage ?? AppStrings.fileSaveError),
              backgroundColor: AppColors.error,
            ),
    );
  }

  void _confirmArchive(CourseFileModel file) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          AppStrings.archiveFileTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: Text(
          '${AppStrings.archiveFileConfirm}\n(${file.title})',
          textAlign: TextAlign.right,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                final provider = context.read<CourseFileProvider>();
                final success = await provider.archiveFile(file.id);

                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  success
                      ? const SnackBar(
                          content: Text(AppStrings.fileArchivedSuccess),
                        )
                      : SnackBar(
                          content: Text(
                            provider.errorMessage ?? AppStrings.fileSaveError,
                          ),
                          backgroundColor: AppColors.error,
                        ),
                );
              },
              child: const Text(AppStrings.confirmAction),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.cancelAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseFileProvider>();
    final args = _args;

    if (args == null) {
      return const AdminAccessGuard(
        child: Scaffold(body: Center(child: Text(AppStrings.offeringNotFound))),
      );
    }

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.offeringFilesTitle),
          centerTitle: true,
          leading: const AdminBackButton(),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openUpload,
          label: const Text(AppStrings.uploadFileTitle),
          icon: const Icon(Icons.upload_rounded),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            _buildOfferingHeader(args, provider.files.length),
            Expanded(child: _buildBody(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferingHeader(OfferingFilesArgs args, int count) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              args.courseTitle,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppStatusBadge(
                  label:
                      '${AppStrings.offeringSectionLabel} '
                      '${args.offering.section}',
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.textSecondary,
                ),
                AppStatusBadge(
                  label: args.offering.instructorName,
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.textSecondary,
                  icon: Icons.person_rounded,
                ),
                AppStatusBadge(
                  label: '${AppStrings.offeringFilesCountLabel}: $count',
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  foregroundColor: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CourseFileProvider provider) {
    if (provider.isLoading && provider.files.isEmpty) {
      return const AppLoadingState();
    }

    if (provider.errorMessage != null && provider.files.isEmpty) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: () {
          final offeringId = _args?.offering.id;
          if (offeringId != null) provider.listenToOfferingFiles(offeringId);
        },
      );
    }

    if (provider.files.isEmpty) {
      return AppEmptyState(
        title: AppStrings.noOfferingFilesTitle,
        description: AppStrings.noOfferingFilesDesc,
        icon: Icons.folder_open_rounded,
        actionLabel: AppStrings.uploadFileTitle,
        onAction: _openUpload,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        0,
        AppSpacing.medium,
        AppSpacing.huge,
      ),
      itemCount: provider.files.length,
      itemBuilder: (context, index) => _buildFileCard(provider.files[index]),
    );
  }

  Widget _buildFileCard(CourseFileModel file) {
    final statusColor = file.isActive
        ? AppColors.activeStatus
        : AppColors.textMuted;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  file.title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              AppStatusBadge(
                label: file.isActive
                    ? AppStrings.fileStatusActive
                    : AppStrings.fileStatusArchived,
                backgroundColor: statusColor.withValues(alpha: 0.08),
                foregroundColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            file.fileName,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppStatusBadge(
                label: AppStrings.fileCategoryDisplay(file.category),
                backgroundColor: AppColors.secondary.withValues(alpha: 0.08),
                foregroundColor: AppColors.secondary,
              ),
              if (file.fileExtension.isNotEmpty)
                AppStatusBadge(
                  label: file.fileExtension.toUpperCase(),
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.textSecondary,
                ),
              if (file.readableSize.isNotEmpty)
                AppStatusBadge(
                  label: file.readableSize,
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.textSecondary,
                ),
              if (file.createdAt != null)
                AppStatusBadge(
                  label: _formatDate(file.createdAt!),
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.textSecondary,
                  icon: Icons.event_rounded,
                ),
            ],
          ),
          if (file.description.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              file.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Divider(height: 24, color: AppColors.divider),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _openFile(file),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text(AppStrings.openFileAction),
              ),
              const Spacer(),
              IconButton(
                tooltip: AppStrings.editAction,
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                onPressed: () => _editFile(file),
              ),
              // لا حذف نهائي: الرفع غير موقَّع فلا يمكن حذف الملف من التخزين،
              // وحذف بياناته وحده يترك ملفًا يتيمًا.
              IconButton(
                tooltip: AppStrings.archiveAction,
                icon: Icon(
                  Icons.archive_rounded,
                  color: file.isActive
                      ? AppColors.secondary
                      : AppColors.textDisabled,
                ),
                onPressed: file.isActive ? () => _confirmArchive(file) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
