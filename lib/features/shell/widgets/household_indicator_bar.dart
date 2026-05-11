import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../core/household/household_state.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import 'household_switcher_sheet.dart';

class HouseholdIndicatorBar extends ConsumerWidget {
  const HouseholdIndicatorBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(householdNotifierProvider);

    return householdAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (state) {
        if (!state.isMultiple) return const SizedBox.shrink();
        return _Bar(state: state);
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.state});

  final HouseholdState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    return Material(
      color: colors.surfaceCard,
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => HouseholdSwitcherSheet(state: state),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colors.border),
              bottom: BorderSide(color: colors.border),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.home_outlined, size: 16, color: colors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Text(
                state.selectedHousehold?.name ?? '',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textBody),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.arrow_drop_down, size: 16, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
