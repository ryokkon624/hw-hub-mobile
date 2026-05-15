import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/shopping_repository.dart';
import '../shopping_list_notifier.dart';
import '../shopping_list_state.dart';
import 'swipeable_shopping_card.dart';
import 'bulk_purchase_dialog.dart';

class BasketTab extends ConsumerWidget {
  const BasketTab({super.key, required this.items, required this.onCardTap});

  final List<ShoppingItemDto> items;
  final ValueChanged<int> onCardTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Column(
      children: [
        // 一括購入済みボタン（AC6）
        if (items.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            color: colors.surfaceCard,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showBulkPurchaseDialog(context);
                if (!confirmed) return;
                await ref
                    .read(shoppingListNotifierProvider.notifier)
                    .bulkPurchase();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.shoppingToastBulkPurchased),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(l10n.shoppingBulkPurchaseButton),
            ),
          ),
        // アイテム一覧
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    l10n.shoppingEmptyBasket,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: SwipeableShoppingCard(
                        item: item,
                        variant: ShoppingTab.basket,
                        onPrimarySwipe: () async {
                          // 右スワイプ: 購入済みに
                          await ref
                              .read(shoppingListNotifierProvider.notifier)
                              .markPurchased(item.shoppingItemId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.shoppingToastMarkedPurchased,
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                          return true;
                        },
                        onSecondarySwipe: () async {
                          // 左スワイプ: 未購入に戻す
                          await ref
                              .read(shoppingListNotifierProvider.notifier)
                              .moveBackToUnpurchased(item.shoppingItemId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.shoppingToastMovedBack),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                          return true;
                        },
                        onTap: () => onCardTap(item.shoppingItemId),
                        onFavoriteTap: () => ref
                            .read(shoppingListNotifierProvider.notifier)
                            .toggleFavorite(item.shoppingItemId),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
