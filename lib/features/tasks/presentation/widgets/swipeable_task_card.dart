import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/my_tasks_repository.dart';

class SwipeableTaskCard extends StatelessWidget {
  const SwipeableTaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onSkip,
  });

  final HouseworkTaskDto task;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final l10n = AppLocalizations.of(context);

    return Dismissible(
      key: ValueKey(task.houseworkTaskId),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.3,
        DismissDirection.endToStart: 0.3,
      },
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: colors.swipeAction,
        icon: Icons.check_circle_outline,
        label: l10n.myTasksSwipeCompleteLabel,
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: colors.swipeDisabled,
        icon: Icons.skip_next_outlined,
        label: l10n.myTasksSwipeSkipLabel,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onComplete();
        } else {
          onSkip();
        }
        return true;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            task.houseworkName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final AlignmentGeometry alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
