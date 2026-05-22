import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../housework_settings_providers.dart';
import '../widgets/housework_form.dart';
import 'widgets/template_picker_modal.dart';

/// 家事新規作成画面（#21）。
class HouseworkCreatePage extends ConsumerStatefulWidget {
  const HouseworkCreatePage({super.key});

  @override
  ConsumerState<HouseworkCreatePage> createState() =>
      _HouseworkCreatePageState();
}

class _HouseworkCreatePageState extends ConsumerState<HouseworkCreatePage> {
  HouseworkFormErrors _errors = HouseworkFormErrors.empty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final asyncState = ref.watch(houseworkCreateNotifierProvider);
    final notifier = ref.read(houseworkCreateNotifierProvider.notifier);

    ref.listen(houseworkCreateNotifierProvider, (_, next) {
      if (!next.hasValue) return;
      final val = next.value!;
      if (val.successMessage != null) {
        AppSnackBar.showSuccess(l10n.houseworkCreateSaveSuccess);
        // 一覧Providerをinvalidateして最新状態を反映
        ref.invalidate(houseworkListNotifierProvider);
        if (mounted) Navigator.of(context).pop();
      }
      if (val.errorMessage != null) {
        AppSnackBar.showError(val.errorMessage!);
      }
    });

    return Scaffold(
      key: const Key('houseworkCreatePage'),
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surfaceCard,
        elevation: 0,
        title: Text(
          l10n.houseworkCreateTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colors.textHeading,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (state) => _HouseworkCreateBody(
          state: state,
          errors: _errors,
          notifier: notifier,
          onSubmit: () => _onSubmit(state, notifier),
          onCancel: () => Navigator.of(context).pop(),
          onShowTemplates: () => _showTemplatePicker(context, state, notifier),
        ),
      ),
    );
  }

  void _onSubmit(HouseworkCreateState state, HouseworkCreateNotifier notifier) {
    final errors = notifier.validate();
    setState(() => _errors = errors);
    if (errors.hasError) return;
    notifier.save();
  }

  void _showTemplatePicker(
    BuildContext context,
    HouseworkCreateState state,
    HouseworkCreateNotifier notifier,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => TemplatePickerModal(
        templates: state.templates,
        onSelected: (t) => notifier.applyTemplate(t, locale),
      ),
    );
  }
}

class _HouseworkCreateBody extends ConsumerWidget {
  const _HouseworkCreateBody({
    required this.state,
    required this.errors,
    required this.notifier,
    required this.onSubmit,
    required this.onCancel,
    required this.onShowTemplates,
  });

  final HouseworkCreateState state;
  final HouseworkFormErrors errors;
  final HouseworkCreateNotifier notifier;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final VoidCallback onShowTemplates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // テンプレートから選択ボタン
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('houseworkTemplateButton'),
              onPressed: onShowTemplates,
              icon: const Icon(Icons.list_alt),
              label: Text(l10n.houseworkCreateTemplateButton),
            ),
          ),
          const SizedBox(height: 16),

          // 推薦メモバナー
          if (state.recommendationText != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.accentSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.accentBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: colors.accentBadgeText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.recommendationText!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.textBody),
                    ),
                  ),
                  IconButton(
                    key: const Key('dismissRecommendation'),
                    onPressed: () => notifier.dismissRecommendation(),
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 共通フォーム
          HouseworkForm(
            form: state.form,
            members: state.members,
            errors: errors,
            onNameChanged: notifier.updateName,
            onDescriptionChanged: notifier.updateDescription,
            onCategoryChanged: notifier.updateCategory,
            onRecurrenceTypeChanged: notifier.updateRecurrenceType,
            onWeeklyDayToggled: notifier.toggleWeeklyDay,
            onDayOfMonthChanged: notifier.updateDayOfMonth,
            onNthWeekChanged: notifier.updateNthWeek,
            onWeekdayChanged: notifier.updateWeekday,
            onStartDateChanged: notifier.updateStartDate,
            onEndDateChanged: notifier.updateEndDate,
            onAssigneeChanged: notifier.updateDefaultAssigneeUserId,
          ),
          const SizedBox(height: 24),

          // キャンセル・保存ボタン
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('houseworkCancelButton'),
                  onPressed: onCancel,
                  child: Text(l10n.commonCancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  key: const Key('houseworkSaveButton'),
                  onPressed: state.isSaving ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                  ),
                  child: state.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.commonSave),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
