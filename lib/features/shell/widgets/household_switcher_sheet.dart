import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../core/household/household_state.dart';
import '../../../core/models/household.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';

class HouseholdSwitcherSheet extends ConsumerWidget {
  const HouseholdSwitcherSheet({super.key, required this.state});

  final HouseholdState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              '世帯を選択',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: colors.textHeading),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          ...state.households.map(
            (h) => _HouseholdTile(
              household: h,
              isSelected: h.id == state.selectedHousehold?.id,
              onTap: () {
                ref.read(householdNotifierProvider.notifier).select(h);
                Navigator.of(context).pop();
              },
            ),
          ),
          const Divider(height: 1),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'キャンセル',
              style: TextStyle(color: colors.textMuted),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _HouseholdTile extends StatelessWidget {
  const _HouseholdTile({
    required this.household,
    required this.isSelected,
    required this.onTap,
  });

  final Household household;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return ListTile(
      title: Text(
        household.name,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(
              color: colors.textBody,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
      ),
      subtitle: household.description != null
          ? Text(
              household.description!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.textMuted),
            )
          : null,
      trailing: isSelected
          ? Icon(Icons.check_circle, color: colors.primary)
          : null,
      onTap: onTap,
    );
  }
}
