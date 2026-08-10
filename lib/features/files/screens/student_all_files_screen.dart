// lib/features/files/screens/student_all_files_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../../core/widgets/error_state.dart';
import '../models/student_app_file.dart';
import '../providers/student_file_provider.dart';
import '../widgets/student_all_file_card.dart';
import '../widgets/student_download_progress_card.dart';
import '../widgets/student_download_progress_sheet.dart';
import '../widgets/student_file_filter_tabs.dart';

class AllFilesScreen extends StatefulWidget {
  const AllFilesScreen({super.key});

  @override
  State<AllFilesScreen> createState() => _AllFilesScreenState();
}

class _AllFilesScreenState extends State<AllFilesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = FileFilterTabs.filterAll;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentFileProvider>().loadAllFiles();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleNavigation(int index) {
    handleMainNavigation(context, index, currentIndex: 1);
  }

  void _openOfflineFiles() {
    Navigator.pushNamed(context, AppRoutes.offlineFiles);
  }

  void _openFilePreview(String fileId) {
    Navigator.pushNamed(context, AppRoutes.filePreview, arguments: fileId);
  }

  void _showDownloadProgress(StudentAppFile file) {
    DownloadProgressSheet.show(
      context,
      file: file,
      downloadProgress: 0.65,
      downloadedSizeLabel: '12MB',
      totalSizeLabel: '18MB',
      remainingTimeLabel: AppStrings.downloadRemainingTimeLabel,
    );
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

  List<StudentAppFile> _filterFiles(List<StudentAppFile> files) {
    var result = files;

    if (_selectedFilter == FileFilterTabs.filterPdf) {
      result = result.where((f) => f.type == StudentAppFile.typePdf).toList();
    } else if (_selectedFilter == FileFilterTabs.filterPresentations) {
      result = result.where((f) => f.type == StudentAppFile.typePpt).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((f) => f.title.toLowerCase().contains(query))
          .toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final fileProvider = context.watch<StudentFileProvider>();

    if (fileProvider.isLoadingAllFiles && fileProvider.allFiles.isEmpty) {
      return _buildScaffold(
        body: const AppLoadingState(message: AppStrings.filesLoadError),
      );
    }

    if (fileProvider.allFilesErrorMessage != null &&
        fileProvider.allFiles.isEmpty) {
      return _buildScaffold(
        body: AppErrorState(
          message: fileProvider.allFilesErrorMessage!,
          onRetry: () {
            context.read<StudentFileProvider>().loadAllFiles(
              forceRefresh: true,
            );
          },
        ),
      );
    }

    final filteredFiles = _filterFiles(fileProvider.allFiles);

    return _buildScaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.screenVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.allFilesTitle,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppSpacing.medium),
              _buildSearchField(),
              const SizedBox(height: AppSpacing.medium),
              FileFilterTabs(
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) {
                  setState(() => _selectedFilter = filter);
                },
                onOfflineTap: _openOfflineFiles,
              ),
              const SizedBox(height: AppSpacing.medium),
              if (filteredFiles.isEmpty)
                _buildEmptyState()
              else
                ...filteredFiles.map(
                      (file) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: file.isDownloading
                        ? DownloadProgressCard(file: file)
                        : AllFileCard(
                      file: file,
                      onTap: () => _openFilePreview(file.id),
                      onDownloadTap: () => _showDownloadProgress(file),
                      onDeleteTap: _showDeleteUnderDevelopment,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.large),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold({required Widget body}) {
    return AuthenticatedPageScaffold(
      currentIndex: 1,
      onNavigationTap: _handleNavigation,
      appBar: const AcademiaMainAppBar(
        title: AppStrings.appName,
        showBackButton: true,
        showProfile: true,
        showSearch: false,
        showNotifications: true,
      ),
      body: body,
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textAlign: TextAlign.right,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: AppStrings.allFilesSearchHint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textDisabled,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.extraLarge),
      child: Center(
        child: Text(
          AppStrings.noFilesFoundMessage,
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }
}