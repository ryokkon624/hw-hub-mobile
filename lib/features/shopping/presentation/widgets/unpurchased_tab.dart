import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/shopping_repository.dart';
import '../../shopping_providers.dart';
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
                            l10n.shoppingEmptyUnpurchased,
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
                          variant: ShoppingTab.unpurchased,
                          onPrimarySwipe: () async {
                            // 右スワイプ: かごへ
                            await ref
                                .read(shoppingListNotifierProvider.notifier)
                                .moveToBasket(item.shoppingItemId);
                            if (context.mounted) {
                              AppSnackBar.showSuccess(
                                l10n.shoppingToastMovedToBasket,
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
                              AppSnackBar.showSuccess(
                                l10n.shoppingToastDeleted,
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
