import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/shopping_repository.dart';
import '../../shopping_providers.dart';
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
                  AppSnackBar.showSuccess(l10n.shoppingToastBulkPurchased);
                }
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(l10n.shoppingBulkPurchaseButton),
            ),
          ),
        // アイテム一覧
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(shoppingListNotifierProvider),
            child: items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            l10n.shoppingEmptyBasket,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        key: ValueKey(item.shoppingItemId),
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
                              AppSnackBar.showSuccess(
                                l10n.shoppingToastMarkedPurchased,
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
                              AppSnackBar.showSuccess(
                                l10n.shoppingToastMovedBack,
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
        ),
      ],
    );
  }
}
