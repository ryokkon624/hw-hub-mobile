import 'package:flutter/material.dart';
import 'package:hw_hub_mobile/core/theme/app_color_scheme.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';
import '../../data/housework_assign_repository.dart';

class SwipeModeCard extends StatelessWidget {
  const SwipeModeCard({
    super.key,
    required this.task,
    required this.onAssignToMe,
    required this.onNext,
  });

  final HouseworkTaskDto task;
  final VoidCallback onAssignToMe;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).extension<AppColorScheme>();

    return Dismissible(
      key: ValueKey('swipe_${task.houseworkTaskId}'),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.3,
        DismissDirection.endToStart: 0.3,
      },
      background: Container(
        color: colorScheme?.swipeSelf ?? const Color(0xFF0EA5E9),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              l10n.houseworkAssignSwipeMakeMineLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: colorScheme?.swipeDisabled ?? const Color(0xFFCBD5E1),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.houseworkAssignSwipeNextLabel,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onAssignToMe();
        } else {
          onNext();
        }
        return false; // Notifier が state 更新して次のカードを差し替えるため dismiss しない
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.houseworkName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.houseworkAssignTargetDateLabel(task.targetDate),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.houseworkAssignCurrentAssigneeLabel(
                task.assigneeUserId == null
                    ? l10n.houseworkAssignAssigneeUnassigned
                    : (task.assigneeNickname ?? task.assigneeUserId.toString()),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
