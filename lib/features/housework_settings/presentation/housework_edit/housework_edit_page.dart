import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app_router.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../housework_settings_providers.dart';
import '../widgets/housework_form.dart';

/// 家事編集画面（#22）。
class HouseworkEditPage extends ConsumerStatefulWidget {
  const HouseworkEditPage({super.key, required this.houseworkId});

  final int houseworkId;

  @override
  ConsumerState<HouseworkEditPage> createState() => _HouseworkEditPageState();
}

class _HouseworkEditPageState extends ConsumerState<HouseworkEditPage> {
  HouseworkFormErrors _errors = HouseworkFormErrors.empty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final asyncState = ref.watch(
      houseworkEditNotifierProvider(widget.houseworkId),
    );
    final notifier = ref.read(
      houseworkEditNotifierProvider(widget.houseworkId).notifier,
    );

    ref.listen(houseworkEditNotifierProvider(widget.houseworkId), (_, next) {
      if (!next.hasValue) return;
      final val = next.value!;

      // 取得失敗時は一覧へリダイレクト
      if (val.fetchError && val.form.name.isEmpty) {
        if (mounted) context.go(AppRoutes.settingsHousework);
        return;
      }

      if (val.successMessage != null) {
        AppSnackBar.showSuccess(l10n.houseworkEditSaveSuccess);
        ref.invalidate(houseworkListNotifierProvider);
        if (mounted) context.go(AppRoutes.settingsHousework);
      }
      if (val.errorMessage != null) {
        AppSnackBar.showError(val.errorMessage!);
      }
    });

    return Scaffold(
      key: const Key('houseworkEditPage'),
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surfaceCard,
        elevation: 0,
        title: Text(
          l10n.houseworkEditTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colors.textHeading,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (state) {
          if (state.fetchError) {
            return const Center(child: CircularProgressIndicator());
          }
          return _HouseworkEditBody(
            state: state,
            errors: _errors,
            notifier: notifier,
            onSubmit: () => _onSubmit(state, notifier),
            onCancel: () => context.go(AppRoutes.settingsHousework),
          );
        },
      ),
    );
  }

  void _onSubmit(HouseworkEditState state, HouseworkEditNotifier notifier) {
    final errors = notifier.validate();
    setState(() => _errors = errors);
    if (errors.hasError) return;
    notifier.save();
  }
}

class _HouseworkEditBody extends ConsumerWidget {
  const _HouseworkEditBody({
    required this.state,
    required this.errors,
    required this.notifier,
    required this.onSubmit,
    required this.onCancel,
  });

  final HouseworkEditState state;
  final HouseworkFormErrors errors;
  final HouseworkEditNotifier notifier;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 共通フォーム（テンプレート選択ボタンなし - AC3）
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
                  key: const Key('houseworkEditCancelButton'),
                  onPressed: onCancel,
                  child: Text(l10n.commonCancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  key: const Key('houseworkEditSaveButton'),
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
