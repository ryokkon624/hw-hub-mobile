import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../l10n/app_localizations.dart';
import '../shopping_item_list/shopping_list_state.dart';

class ShoppingTabBar extends StatelessWidget {
  const ShoppingTabBar({
    super.key,
    required this.activeTab,
    required this.unpurchasedCount,
    required this.basketCount,
    required this.purchasedCount,
    required this.onTabChanged,
  });

  final ShoppingTab activeTab;
  final int unpurchasedCount;
  final int basketCount;
  final int purchasedCount;
  final ValueChanged<ShoppingTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Container(
      color: colors.surfaceCard,
      child: Row(
        children: [
          _TabItem(
            label: l10n.shoppingTabUnpurchased,
            count: unpurchasedCount,
            isActive: activeTab == ShoppingTab.unpurchased,
            showCount: true,
            onTap: () => onTabChanged(ShoppingTab.unpurchased),
          ),
          _TabItem(
            label: l10n.shoppingTabBasket,
            count: basketCount,
            isActive: activeTab == ShoppingTab.basket,
            showCount: true,
            onTap: () => onTabChanged(ShoppingTab.basket),
          ),
          _TabItem(
            label: l10n.shoppingTabPurchased,
            count: purchasedCount,
            isActive: activeTab == ShoppingTab.purchased,
            showCount: false, // #92: 購入済みタブは件数バッジを非表示
            onTap: () => onTabChanged(ShoppingTab.purchased),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
    this.showCount = true,
  });

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  /// false のとき件数バッジを非表示にする（購入済みタブ用）
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final activeColor = colors.primary;
    final inactiveColor = colors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? activeColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isActive ? activeColor : inactiveColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (showCount && count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : colors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isActive ? Colors.white : inactiveColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
