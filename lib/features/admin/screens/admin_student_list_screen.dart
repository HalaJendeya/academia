import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import '../../enrollments/providers/enrollment_provider.dart';
import '../models/admin_student_model.dart';

class AdminStudentListScreen extends StatefulWidget {
  const AdminStudentListScreen({super.key});

  @override
  State<AdminStudentListScreen> createState() => _AdminStudentListScreenState();
}

class _AdminStudentListScreenState extends State<AdminStudentListScreen> {
  String _searchQuery = '';
  String _statusFilter =
      'all'; // 'all', 'active', 'disabled', 'onboarded', 'pending_onboard'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<EnrollmentProvider>().listenToStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnrollmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminStudentsTitle),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: AppStrings.searchStudentHint,
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.medium),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildFilterChip('all', AppStrings.filterAll),
                      const SizedBox(width: 8),
                      _buildFilterChip('active', AppStrings.filterActive),
                      const SizedBox(width: 8),
                      _buildFilterChip('disabled', AppStrings.filterDisabled),
                      const SizedBox(width: 8),
                      _buildFilterChip('onboarded', AppStrings.filterOnboarded),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'pending_onboard',
                        AppStrings.filterPendingOnboard,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterVal, String label) {
    final isSelected = _statusFilter == filterVal;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _statusFilter = filterVal;
          });
        }
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildBody(EnrollmentProvider provider) {
    if (provider.isLoadingStudents) {
      return const AppLoadingState();
    }

    if (provider.errorMessage != null) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: () => provider.listenToStudents(),
      );
    }

    final filtered = provider.students.where((student) {
      final matchesSearch =
          student.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.studentId.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _statusFilter == 'all' ||
          (_statusFilter == 'active' && student.status == 'active') ||
          (_statusFilter == 'disabled' && student.status != 'active') ||
          (_statusFilter == 'onboarded' && student.onboardingCompleted) ||
          (_statusFilter == 'pending_onboard' && !student.onboardingCompleted);
      return matchesSearch && matchesStatus;
    }).toList();

    if (filtered.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.noStudentsFound,
        icon: Icons.people_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final student = filtered[index];
        return _buildStudentCard(student, provider);
      },
    );
  }

  Widget _buildStudentCard(
    AdminStudentModel student,
    EnrollmentProvider provider,
  ) {
    final statusColor = student.status == 'active'
        ? AppColors.activeStatus
        : AppColors.textMuted;
    final statusBgColor = statusColor.withValues(alpha: 0.08);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      onTap: () {
        provider.selectStudent(student);
        Navigator.of(
          context,
        ).pushNamed(AppRoutes.adminStudentDetails, arguments: student);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  student.fullName,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: student.status == 'active'
                    ? AppStrings.activeStatus
                    : AppStrings.archivedStatus,
                backgroundColor: statusBgColor,
                foregroundColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              const Icon(
                Icons.badge_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${AppStrings.studentIdLabel}: ${student.studentId}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              const Icon(
                Icons.email_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                student.email,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (student.major.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Row(
              children: [
                const Icon(
                  Icons.school_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${AppStrings.majorLabel}: ${student.major}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          if (student.semester != null) ...[
            const SizedBox(height: AppSpacing.small),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${AppStrings.semesterLabel}: ${student.semester}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
