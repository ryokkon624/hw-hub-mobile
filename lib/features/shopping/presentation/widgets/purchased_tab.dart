import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/shopping_repository.dart';
import '../shopping_list_notifier.dart';
import '../shopping_list_state.dart';
import 'swipeable_shopping_card.dart';

/// 購入済みタブのカードで左スワイプしたときに表示するSnackBar
void _showPurchasedSwipeHint(BuildContext context, AppLocalizations l10n) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n.shoppingSwipePurchasedHint),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
}

class PurchasedTab extends ConsumerWidget {
  const PurchasedTab({
    super.key,
    required this.itemsByDate,
    required this.onCardTap,
  });

  final Map<String, List<ShoppingItemDto>> itemsByDate;
  final ValueChanged<int> onCardTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    Widget listContent;
    if (itemsByDate.isEmpty) {
      listContent = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                l10n.shoppingEmptyPurchased,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
              ),
            ),
          ),
        ],
      );
    } else {
      final sortedDates = itemsByDate.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      listContent = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
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
              // アイテム一覧（左スワイプのみ有効）
              ...items.map(
                (item) => Padding(
                  key: ValueKey(item.shoppingItemId),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: SwipeableShoppingCard(
                    item: item,
                    variant: ShoppingTab.purchased,
                    enableSwipe: true,
                    direction: DismissDirection.endToStart,
                    onTap: () => onCardTap(item.shoppingItemId),
                    onFavoriteTap: () {},
                    onPrimarySwipe: () async => false,
                    onSecondarySwipe: () async {
                      _showPurchasedSwipeHint(context, l10n);
                      return false;
                    },
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(shoppingListNotifierProvider),
      child: listContent,
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
