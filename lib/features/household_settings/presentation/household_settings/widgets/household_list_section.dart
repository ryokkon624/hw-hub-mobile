import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/di/providers.dart';
import '../../../../../core/models/household.dart';
import '../../../../../core/theme/app_color_scheme.dart';
import '../../../../../l10n/app_localizations.dart';

/// 所属世帯一覧セクション（AC1・AC2）。
class HouseholdListSection extends ConsumerWidget {
  const HouseholdListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final householdState = ref.watch(householdNotifierProvider);

    return householdState.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (hs) {
        return Card(
          key: const Key('householdsSection'),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.householdSettingsHouseholdsSection,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...hs.households.map(
                  (h) => _HouseholdRow(
                    household: h,
                    isCurrent: hs.selectedHousehold?.id == h.id,
                  ),
                ),
                const Divider(),
                TextButton.icon(
                  key: const Key('addHouseholdButton'),
                  onPressed: () => _showCreateDialog(context, ref, l10n),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.householdSettingsAddHousehold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.householdSettingsCreateHouseholdTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.householdSettingsCreateHouseholdNameHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(dialogContext);
              await ref
                  .read(householdNotifierProvider.notifier)
                  .addHousehold(name: name);
            },
            child: Text(l10n.householdSettingsCreateHouseholdButton),
          ),
        ],
      ),
    );
  }
}

class _HouseholdRow extends ConsumerWidget {
  const _HouseholdRow({required this.household, required this.isCurrent});

  final Household household;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(household.name, overflow: TextOverflow.ellipsis),
      trailing: isCurrent
          ? Chip(
              label: Text(
                l10n.householdSettingsCurrentBadge,
                style: TextStyle(color: colors.statusActiveText),
              ),
              backgroundColor: colors.statusActiveBg,
            )
          : TextButton(
              onPressed: () {
                ref.read(householdNotifierProvider.notifier).select(household);
              },
              child: Text(l10n.householdSettingsSwitchBadge),
            ),
    );
  }
}
