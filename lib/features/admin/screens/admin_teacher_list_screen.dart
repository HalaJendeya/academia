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
import '../models/admin_teacher_model.dart';
import '../providers/admin_teacher_provider.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';

/// قائمة حسابات المعلّمين.
///
/// لا زرّ إضافة هنا عمدًا: إنشاء الحساب يحتاج صلاحيات لا يملكها عميل الجوال
/// ولا يجوز أن يملكها. الشاشة تشرح ذلك مرة واحدة أعلى القائمة بدل أن تعرض
/// زرًّا معطَّلًا لا يُفسِّر نفسه.
class AdminTeacherListScreen extends StatefulWidget {
  const AdminTeacherListScreen({super.key});

  @override
  State<AdminTeacherListScreen> createState() => _AdminTeacherListScreenState();
}

class _AdminTeacherListScreenState extends State<AdminTeacherListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminTeacherProvider>().listenToTeachers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminTeacherModel> _filter(List<AdminTeacherModel> teachers) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return teachers;
    return teachers.where((teacher) {
      return teacher.fullName.toLowerCase().contains(query) ||
          teacher.email.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminTeacherProvider>();
    final filtered = _filter(provider.teachers);

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.teachersManagementTitle),
          centerTitle: true,
          leading: const AdminBackButton(),
        ),
        body: Column(
          children: [
            _buildProvisioningNote(),
            _buildSearchField(),
            Expanded(child: _buildBody(provider, filtered)),
          ],
        ),
      ),
    );
  }

  Widget _buildProvisioningNote() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.medium,
        0,
      ),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.teacherProvisioningNoteTitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.teacherProvisioningNoteDesc,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: AppStrings.teacherSearchHint,
          prefixIcon: Icon(Icons.search_rounded),
        ),
        onChanged: (value) => setState(() => _query = value),
      ),
    );
  }

  Widget _buildBody(
    AdminTeacherProvider provider,
    List<AdminTeacherModel> filtered,
  ) {
    if (provider.isLoading && provider.teachers.isEmpty) {
      return const AppLoadingState();
    }

    if (provider.teachers.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.teachersEmptyTitle,
        description: AppStrings.teachersEmptyDesc,
        icon: Icons.co_present_outlined,
      );
    }

    if (filtered.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.teachersSearchEmptyTitle,
        description: AppStrings.teachersSearchEmptyDesc,
        icon: Icons.search_off_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        0,
        AppSpacing.medium,
        AppSpacing.huge,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildTeacherCard(filtered[index]),
    );
  }

  Widget _buildTeacherCard(AdminTeacherModel teacher) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      onTap: () {
        context.read<AdminTeacherProvider>().selectTeacher(teacher);
        Navigator.of(context).pushNamed(AppRoutes.adminTeacherDetails);
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(
              Icons.co_present_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher.displayName,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (teacher.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    teacher.email,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          AppStatusBadge(
            label: teacher.isActive
                ? AppStrings.activeStatus
                : AppStrings.disabledStatus,
            backgroundColor:
                (teacher.isActive ? AppColors.secondary : AppColors.danger)
                    .withValues(alpha: 0.08),
            foregroundColor: teacher.isActive
                ? AppColors.secondary
                : AppColors.danger,
          ),
        ],
      ),
    );
  }
}
