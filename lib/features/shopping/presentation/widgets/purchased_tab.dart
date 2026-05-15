import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/shopping_repository.dart';
import 'purchased_item_tile.dart';

class PurchasedTab extends StatelessWidget {
  const PurchasedTab({
    super.key,
    required this.itemsByDate,
    required this.onCardTap,
  });

  final Map<String, List<ShoppingItemDto>> itemsByDate;
  final ValueChanged<int> onCardTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    if (itemsByDate.isEmpty) {
      return Center(
        child: Text(
          l10n.shoppingEmptyPurchased,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
      );
    }

    final sortedDates = itemsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final items = itemsByDate[dateKey]!;
        final dateLabel = _formatDateLabel(l10n, dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日付グループヘッダー
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Text(
                    dateLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.shoppingPurchasedGroupCount(items.length),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
            // アイテム一覧
            ...items.map(
              (item) => PurchasedItemTile(
                item: item,
                onTap: () => onCardTap(item.shoppingItemId),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDateLabel(AppLocalizations l10n, String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) return dateKey;
    final date = DateTime.tryParse(dateKey);
    if (date == null) return dateKey;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return l10n.shoppingPurchasedDateGroupToday;
    if (target == today.subtract(const Duration(days: 1))) {
      return l10n.shoppingPurchasedDateGroupYesterday;
    }
    return l10n.shoppingPurchasedDateGroupOther(date.month, date.day);
  }
}
