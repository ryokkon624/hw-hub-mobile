import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/shopping_repository.dart';
import '../shopping_list_notifier.dart';
import '../shopping_list_state.dart';
import 'shopping_location_filter.dart';
import 'swipeable_shopping_card.dart';
import 'bulk_purchase_dialog.dart';

class UnpurchasedTab extends ConsumerWidget {
  const UnpurchasedTab({
    super.key,
    required this.items,
    required this.locationFilter,
    required this.onCardTap,
  });

  final List<ShoppingItemDto> items;
  final String? locationFilter;
  final ValueChanged<int> onCardTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Column(
      children: [
        ShoppingLocationFilter(
          selectedFilter: locationFilter,
          onFilterChanged: (filter) => ref
              .read(shoppingListNotifierProvider.notifier)
              .setLocationFilter(filter),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    l10n.shoppingEmptyUnpurchased,
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
                        variant: ShoppingTab.unpurchased,
                        onPrimarySwipe: () async {
                          // 右スワイプ: かごへ
                          await ref
                              .read(shoppingListNotifierProvider.notifier)
                              .moveToBasket(item.shoppingItemId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.shoppingToastMovedToBasket),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                          return true;
                        },
                        onSecondarySwipe: () async {
                          // 左スワイプ: 削除確認ダイアログ
                          if (!context.mounted) return false;
                          final confirmed = await showDeleteConfirmDialog(
                            context,
                          );
                          if (!confirmed) return false;
                          await ref
                              .read(shoppingListNotifierProvider.notifier)
                              .deleteItem(item.shoppingItemId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.shoppingToastDeleted),
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
