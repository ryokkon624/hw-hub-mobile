import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/housework_task_dto.dart';

class SwipeableTaskCard extends StatelessWidget {
  const SwipeableTaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onSkip,
    this.isPast = false,
    this.isToday = false,
  });

  final HouseworkTaskDto task;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  /// 過去タスク（今日より前）: rose 系スタイル
  final bool isPast;

  /// 今日のタスク: emerald 系スタイル
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final l10n = AppLocalizations.of(context);

    // カードの背景色・ボーダー色・タイトル色をバリアントに応じて切り替える
    final Color cardBg;
    final Color cardBorder;
    final Color titleColor;

    if (isPast) {
      cardBg = colors.paletteRoseSoft;
      cardBorder = colors.paletteRoseBorder;
      titleColor = colors.paletteRoseText;
    } else if (isToday) {
      cardBg = colors.paletteEmeraldSoft;
      cardBorder = colors.paletteEmeraldBorder;
      titleColor = colors.paletteEmeraldText;
    } else {
      cardBg = colors.surfaceCard;
      cardBorder = colors.border;
      titleColor = colors.textHeading;
    }

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
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(color: cardBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            task.houseworkName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w600,
            ),
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
