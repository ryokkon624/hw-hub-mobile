import 'package:flutter/material.dart';
import 'package:hw_hub_mobile/core/theme/app_color_scheme.dart';
import 'package:hw_hub_mobile/core/ui/user_avatar.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';
import '../../data/housework_assign_repository.dart';

class AssignableTaskCard extends StatelessWidget {
  const AssignableTaskCard({
    super.key,
    required this.task,
    required this.onAssignToMe,
    required this.onPickMember,
  });

  final HouseworkTaskDto task;
  final Future<bool> Function() onAssignToMe;
  final VoidCallback onPickMember;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).extension<AppColorScheme>();

    return Dismissible(
      key: ValueKey(task.houseworkTaskId),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.3,
        DismissDirection.endToStart: 0.3,
      },
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: colorScheme?.swipeMembers ?? const Color(0xFFF59E0B),
        label: l10n.houseworkAssignSwipePickMemberLabel,
        icon: Icons.group,
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: colorScheme?.swipeSelf ?? const Color(0xFF0EA5E9),
        label: l10n.houseworkAssignSwipeMakeMineLabel,
        icon: Icons.person,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await onAssignToMe();
        } else {
          onPickMember();
          return false; // モーダルで選択するため dismiss はしない
        }
      },
      child: _CardContent(task: task),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.label,
    required this.icon,
  });

  final Alignment alignment;
  final Color color;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({required this.task});

  final HouseworkTaskDto task;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isUnassigned = task.assigneeUserId == null;
    final assigneeLabel = isUnassigned
        ? l10n.houseworkAssignAssigneeUnassigned
        : (task.assigneeNickname ?? task.assigneeUserId.toString());

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          UserAvatar(
            iconUrl: null,
            label: assigneeLabel,
            isUnassigned: isUnassigned,
            size: UserAvatarSize.md,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.houseworkName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.houseworkAssignTargetDateLabel(task.targetDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
