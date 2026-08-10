// lib/features/files/screens/student_file_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/error_state.dart';
import '../models/student_app_file.dart';
import '../providers/student_file_provider.dart';
import '../widgets/student_file_info_card.dart';
import '../widgets/student_file_type_icon.dart';

class FilePreviewScreen extends StatefulWidget {
  const FilePreviewScreen({super.key});

  @override
  State<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> {
  String? _fileId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fileId = ModalRoute.of(context)?.settings.arguments as String?;
    if (fileId != null && fileId != _fileId) {
      _fileId = fileId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<StudentFileProvider>().loadFileById(fileId);
      });
    }
  }

  @override
  void dispose() {
    context.read<StudentFileProvider>().clearSelectedFile();
    super.dispose();
  }

  void _showUnderDevelopment() {
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
    final file = fileProvider.selectedFile;

    if (fileProvider.isLoadingSelectedFile && file == null) {
      return _buildScaffold(
        title: '',
        body: const AppLoadingState(message: AppStrings.fileDetailLoadError),
      );
    }

    if (fileProvider.selectedFileErrorMessage != null && file == null) {
      return _buildScaffold(
        title: '',
        body: AppErrorState(
          message: fileProvider.selectedFileErrorMessage!,
          onRetry: () {
            if (_fileId != null) {
              context.read<StudentFileProvider>().loadFileById(
                _fileId!,
                forceRefresh: true,
              );
            }
          },
        ),
      );
    }

    if (file == null) {
      return _buildScaffold(title: '', body: const SizedBox.shrink());
    }

    return _buildScaffold(
      title: file.title,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPreviewArea(file),
            const SizedBox(height: AppSpacing.large),
            _buildActionButtons(),
            const SizedBox(height: AppSpacing.large),
            FileInfoCard(file: file),
          ],
        ),
      ),
    );
  }

  Widget _buildScaffold({required String title, required Widget body}) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AcademiaSubAppBar(title: title),
      body: SafeArea(child: body),
    );
  }

  Widget _buildPreviewArea(StudentAppFile file) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Center(
        child: FileTypeIcon(type: file.type, size: 72),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.open_in_new_rounded,
          label: AppStrings.fileOpenExternalAction,
        ),
        _buildActionButton(
          icon: Icons.share_rounded,
          label: AppStrings.fileShareAction,
        ),
        _buildActionButton(
          icon: Icons.download_rounded,
          label: AppStrings.fileDownloadAction,
        ),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String label}) {
    return Column(
      children: [
        InkWell(
          onTap: _showUnderDevelopment,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.extraSmall),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}