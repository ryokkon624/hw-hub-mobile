import 'package:flutter/material.dart';
import '../../../../core/models/shopping_item_status.dart';
import '../../../../l10n/app_localizations.dart';

/// 買い物アイテムステータスを 3 ステップで表示・選択するウィジェット。
/// 「未購入 → かご → 購入済み」の横並びステップ UI。
class StatusStepSelector extends StatelessWidget {
  const StatusStepSelector({
    super.key,
    required this.currentStatus,
    required this.onChanged,
    this.enabled = true,
  });

  final String currentStatus;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [
      _StepInfo(
        status: ShoppingItemStatus.notPurchased.code,
        label: l10n.shoppingTabUnpurchased,
        helpText: l10n.shoppingDetailStatusHelpNotPurchased,
      ),
      _StepInfo(
        status: ShoppingItemStatus.inBasket.code,
        label: l10n.shoppingTabBasket,
        helpText: l10n.shoppingDetailStatusHelpInBasket,
      ),
      _StepInfo(
        status: ShoppingItemStatus.purchased.code,
        label: l10n.shoppingTabPurchased,
        helpText: l10n.shoppingDetailStatusHelpPurchased,
      ),
    ];

    final currentIndex = steps.indexWhere((s) => s.status == currentStatus);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              // コネクターライン
              final lineIndex = i ~/ 2;
              final isCompleted = lineIndex < currentIndex;
              return Expanded(
                child: Container(
                  height: 2,
                  color: isCompleted ? primary : theme.dividerColor,
                ),
              );
            } else {
              // ステップ丸アイコン
              final stepIndex = i ~/ 2;
              final isCompleted = stepIndex < currentIndex;
              final isCurrent = stepIndex == currentIndex;
              final step = steps[stepIndex];

              return GestureDetector(
                onTap: enabled ? () => onChanged(step.status) : null,
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted || isCurrent
                            ? primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isCompleted || isCurrent
                              ? primary
                              : theme.dividerColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(Icons.check, size: 16, color: onPrimary)
                            : Text(
                                '${stepIndex + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent
                                      ? onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrent
                            ? primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }
          }),
        ),
        if (currentIndex >= 0) ...[
          const SizedBox(height: 8),
          Text(
            steps[currentIndex].helpText,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _StepInfo {
  const _StepInfo({
    required this.status,
    required this.label,
    required this.helpText,
  });

  final String status;
  final String label;
  final String helpText;
}
