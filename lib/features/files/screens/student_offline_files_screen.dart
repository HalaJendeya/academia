// lib/features/files/screens/student_offline_files_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/error_state.dart';
import '../providers/student_file_provider.dart';
import '../widgets/student_all_file_card.dart';
import '../widgets/student_storage_usage_card.dart';

class OfflineFilesScreen extends StatefulWidget {
  const OfflineFilesScreen({super.key});

  @override
  State<OfflineFilesScreen> createState() => _OfflineFilesScreenState();
}

class _OfflineFilesScreenState extends State<OfflineFilesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentFileProvider>().loadDownloadedFiles();
    });
  }

  void _openFilePreview(String fileId) {
    Navigator.pushNamed(context, AppRoutes.filePreview, arguments: fileId);
  }

  void _showDeleteUnderDevelopment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.screenUnderDevelopment),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileProvider = context.watch<StudentFileProvider>();

    if (fileProvider.isLoadingDownloadedFiles &&
        fileProvider.downloadedFiles.isEmpty) {
      return _buildScaffold(
        body: const AppLoadingState(message: AppStrings.filesLoadError),
      );
    }

    if (fileProvider.downloadedFilesErrorMessage != null &&
        fileProvider.downloadedFiles.isEmpty) {
      return _buildScaffold(
        body: AppErrorState(
          message: fileProvider.downloadedFilesErrorMessage!,
          onRetry: () {
            context.read<StudentFileProvider>().loadDownloadedFiles(
              forceRefresh: true,
            );
          },
        ),
      );
    }

    final files = fileProvider.downloadedFiles;

    return _buildScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StorageUsageCard(files: files),
            const SizedBox(height: AppSpacing.medium),
            if (files.isEmpty)
              _buildEmptyState()
            else
              ...files.map(
                    (file) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                  child: AllFileCard(
                    file: file,
                    onTap: () => _openFilePreview(file.id),
                    onDeleteTap: _showDeleteUnderDevelopment,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaffold({required Widget body}) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AcademiaSubAppBar(title: AppStrings.offlineFilesTitle),
      body: SafeArea(child: body),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.extraLarge),
      child: Center(
        child: Text(
          AppStrings.noOfflineFilesMessage,
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }
}