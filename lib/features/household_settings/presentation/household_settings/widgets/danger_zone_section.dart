import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/ui/app_dialog.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../household_settings_providers.dart';

/// 危険ゾーンセクション（AC10）。OWNERかつ自分以外のACTIVEメンバーがいない場合のみ表示。
class DangerZoneSection extends ConsumerWidget {
  const DangerZoneSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifierState = ref.watch(householdSettingsNotifierProvider);

    return notifierState.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (state) {
        // isCurrentUserOwner / hasOtherActiveMembers は Notifier 側で事前計算済み（O(1)参照）
        if (!state.isCurrentUserOwner) return const SizedBox.shrink();

        return Card(
          key: const Key('dangerZoneSection'),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.red, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.householdSettingsDangerZoneSection,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                if (state.hasOtherActiveMembers)
                  Text(
                    l10n.householdSettingsDeleteHouseholdDisabledNote,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      key: const Key('deleteHouseholdButton'),
                      onPressed: state.isLoadingDeleteCounts
                          ? null
                          : () => _onDeletePressed(
                              context,
                              ref,
                              l10n,
                              state.houseworkCount,
                              state.shoppingCount,
                            ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: Text(l10n.householdSettingsDeleteHouseholdButton),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onDeletePressed(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    int? houseworkCount,
    int? shoppingCount,
  ) async {
    // 件数がまだ取得されていない場合はAPIで取得してから再表示
    if (houseworkCount == null || shoppingCount == null) {
      await ref
          .read(householdSettingsNotifierProvider.notifier)
          .fetchDeleteCounts();
      // build が再実行されて最新件数が表示される
      return;
    }

    if (!context.mounted) return;

    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.householdSettingsDeleteHouseholdConfirmTitle,
      message: l10n.householdSettingsDeleteHouseholdConfirmBody(
        houseworkCount,
        shoppingCount,
      ),
      confirmLabel: l10n.householdSettingsDeleteHouseholdButton,
      cancelLabel: l10n.commonCancel,
      isDanger: true,
    );
    if (confirmed) {
      await ref
          .read(householdSettingsNotifierProvider.notifier)
          .deleteHousehold();
    }
  }
}
