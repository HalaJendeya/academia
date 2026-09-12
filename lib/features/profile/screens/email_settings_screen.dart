// lib/features/profile/screens/email_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_section.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../providers/email_settings_provider.dart';

/// إدارة بريد الحساب: الأساسي (بريد الدخول) والاحتياطي.
///
/// الشاشة تعرض الحالة كما هي فعلًا، لا كما نتمنّاها: عنوان احتياطي غير
/// موثَّق يُقال عنه ذلك صراحةً، وطلب التغيير يظهر "بانتظار التأكيد" ما دام
/// الرابط لم يُفتح بعد. لا يوجد زر "تحقق" مستقل لأن Firebase من جهة
/// العميل لا تستطيع توثيق عنوان دون جعله بريد الدخول — انظر التوثيق في
/// [EmailSettingsProvider].
class EmailSettingsScreen extends StatefulWidget {
  const EmailSettingsScreen({super.key});

  @override
  State<EmailSettingsScreen> createState() => _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends State<EmailSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<EmailSettingsProvider>().load();
    });
  }

  Future<void> _showMessage(String message, {bool isError = false}) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _openSecondaryEmailSheet(EmailSettingsProvider provider) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SecondaryEmailSheet(provider: provider),
    );

    if (saved == true && mounted) {
      await _showMessage(AppStrings.secondaryEmailSaved);
    }
  }

  Future<void> _confirmRemove(EmailSettingsProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(
          AppStrings.secondaryEmailRemove,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          textAlign: TextAlign.right,
        ),
        content: Text(
          provider.secondaryEmail ?? '',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              AppStrings.secondaryEmailRemove,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final ok = await provider.removeSecondaryEmail();
    if (!mounted) return;
    await _showMessage(
      ok ? AppStrings.secondaryEmailRemoved : (provider.errorMessage ?? ''),
      isError: !ok,
    );
  }

  /*
   * تعيين الاحتياطي أساسيًا.
   *
   * الترتيب هنا يتبع ما تفرضه Firebase فعلًا: تُجرَّب العملية أولًا، فإن
   * طلبت إعادة تأكيد الهوية (requires-recent-login) تُطلب كلمة المرور
   * وتُعاد المحاولة. لا نطلب كلمة المرور مقدّمًا بلا داعٍ.
   */
  Future<void> _promote(EmailSettingsProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(
          AppStrings.secondaryEmailPromote,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          textAlign: TextAlign.right,
        ),
        content: Text(
          AppStrings.secondaryEmailPromoteExplanation,
          style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    var result = await provider.promoteSecondaryToPrimary();

    if (result == PrimaryEmailChangeResult.reauthenticationRequired) {
      if (!mounted) return;
      final password = await showDialog<String>(
        context: context,
        builder: (_) => const _ReauthDialog(),
      );
      if (password == null || password.isEmpty) return;
      result = await provider.promoteSecondaryToPrimary(password: password);
    }

    if (!mounted) return;
    if (result == PrimaryEmailChangeResult.verificationSent) {
      await _showMessage(AppStrings.primaryEmailChangeSent);
    } else if (result == PrimaryEmailChangeResult.failed) {
      await _showMessage(
        provider.errorMessage ?? AppStrings.emailChangeErrorGeneric,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmailSettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AcademiaSubAppBar(title: AppStrings.emailSettingsTitle),
      body: SafeArea(child: _buildBody(provider)),
    );
  }

  Widget _buildBody(EmailSettingsProvider provider) {
    if (provider.isLoading && provider.profile == null) {
      return const AppLoadingState();
    }

    if (provider.errorMessage != null && provider.profile == null) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: provider.load,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        _buildPrimaryCard(provider),
        const SizedBox(height: AppSpacing.medium),
        if (provider.hasPendingChange) ...[
          _buildPendingCard(provider),
          const SizedBox(height: AppSpacing.medium),
        ],
        _buildSecondaryCard(provider),
        const SizedBox(height: AppSpacing.medium),
        _buildLimitationNote(),
      ],
    );
  }

  Widget _buildPrimaryCard(EmailSettingsProvider provider) {
    final email = provider.primaryEmail ?? provider.profile?.email ?? '';

    return AppSection(
      title: AppStrings.primaryEmailLabel,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    email.isEmpty ? AppStrings.profileEmailUnavailable : email,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                _Badge(
                  label: AppStrings.primaryEmailBadge,
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.extraSmall),
            Text(
              AppStrings.primaryEmailHint,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  /// الحالة الصادقة: أُرسل الرابط ولم يتغيّر البريد بعد.
  Widget _buildPendingCard(EmailSettingsProvider provider) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.primaryEmailChangePendingTitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              const Icon(
                Icons.schedule_rounded,
                size: 18,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.extraSmall),
          Text(
            AppStrings.primaryEmailChangePendingBody,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: AppSpacing.extraSmall),
          Text(
            provider.pendingPrimaryEmail ?? '',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: AppSpacing.small),
          AppSecondaryButton(
            label: AppStrings.primaryEmailRefresh,
            onPressed: provider.isSubmitting ? null : provider.load,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryCard(EmailSettingsProvider provider) {
    final secondary = provider.secondaryEmail;
    final hasSecondary = (secondary ?? '').trim().isNotEmpty;

    return AppSection(
      title: AppStrings.secondaryEmailLabel,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    hasSecondary ? secondary! : AppStrings.secondaryEmailEmpty,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight:
                          hasSecondary ? FontWeight.bold : FontWeight.normal,
                      color: hasSecondary
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasSecondary) ...[
                  const SizedBox(width: AppSpacing.small),
                  _Badge(
                    label: provider.isSecondaryVerified
                        ? AppStrings.secondaryEmailVerifiedBadge
                        : AppStrings.secondaryEmailUnverifiedBadge,
                    color: provider.isSecondaryVerified
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              AppStrings.secondaryEmailVerificationNote,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: AppSpacing.medium),
            AppPrimaryButton(
              label: hasSecondary
                  ? AppStrings.secondaryEmailChange
                  : AppStrings.secondaryEmailAdd,
              onPressed: provider.isSubmitting
                  ? null
                  : () => _openSecondaryEmailSheet(provider),
            ),
            if (hasSecondary && !provider.hasPendingChange) ...[
              const SizedBox(height: AppSpacing.small),
              AppSecondaryButton(
                label: AppStrings.secondaryEmailPromote,
                onPressed:
                    provider.isSubmitting ? null : () => _promote(provider),
              ),
            ],
            if (hasSecondary) ...[
              const SizedBox(height: AppSpacing.small),
              TextButton(
                onPressed:
                    provider.isSubmitting ? null : () => _confirmRemove(provider),
                child: Text(
                  AppStrings.secondaryEmailRemove,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// حدّ معروف يُذكر للطالبة بدل أن يُكتشف وقت الحاجة.
  Widget _buildLimitationNote() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              AppStrings.secondaryEmailRecoveryLimitation,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// نافذة إدخال البريد الاحتياطي.
///
/// تملك مُتحكّم النص بنفسها وتتخلص منه في dispose الخاص بها — لا في
/// then() لمسار الحوار، وهو الخطأ الذي سبق أن سبّب استعمال مُتحكّم بعد
/// التخلص منه في هذا المشروع.
class _SecondaryEmailSheet extends StatefulWidget {
  const _SecondaryEmailSheet({required this.provider});

  final EmailSettingsProvider provider;

  @override
  State<_SecondaryEmailSheet> createState() => _SecondaryEmailSheetState();
}

class _SecondaryEmailSheetState extends State<_SecondaryEmailSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.provider.secondaryEmail ?? '');
  String? _error;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _controller.text;
    final validationError = widget.provider.validateSecondaryEmail(value);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final ok = await widget.provider.saveSecondaryEmail(value);
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSaving = false;
        _error = widget.provider.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.secondaryEmailFieldLabel,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: AppSpacing.small),
            TextField(
              controller: _controller,
              textAlign: TextAlign.left,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: AppStrings.secondaryEmailFieldHint,
                errorText: _error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            AppPrimaryButton(
              label: AppStrings.saveChanges,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
            const SizedBox(height: AppSpacing.small),
            AppSecondaryButton(
              label: AppStrings.cancel,
              onPressed:
                  _isSaving ? null : () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// طلب كلمة المرور الحالية عند اشتراط Firebase تسجيل دخول حديث.
///
/// كلمة المرور تعود إلى المستدعي وتُستعمل لحظيًا ثم تُهمل — لا تُخزَّن ولا
/// تُكتب في أي سجل.
class _ReauthDialog extends StatefulWidget {
  const _ReauthDialog();

  @override
  State<_ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends State<_ReauthDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.isEmpty) {
      setState(() => _error = AppStrings.currentPasswordRequired);
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Text(
        AppStrings.reauthRequiredTitle,
        style: AppTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
        textAlign: TextAlign.right,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.reauthRequiredBody,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: AppSpacing.small),
          TextField(
            controller: _controller,
            obscureText: true,
            autofocus: true,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              labelText: AppStrings.currentPasswordLabel,
              hintText: AppStrings.currentPasswordHint,
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(onPressed: _submit, child: const Text(AppStrings.confirm)),
      ],
    );
  }
}
