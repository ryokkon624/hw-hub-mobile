import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../models/shopping_item.dart';

class ShoppingCard extends StatelessWidget {
  const ShoppingCard({super.key, required this.items, required this.onOpen});

  final List<ShoppingItem> items;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    final openItems = items.where((i) => i.status == '0').toList();

    final superCount = openItems.where((i) => i.storeType == '1').length;
    final drugCount = openItems.where((i) => i.storeType == '3').length;
    final onlineCount = openItems.where((i) => i.storeType == '2').length;

    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    final recentCount = items.where((i) {
      try {
        final created = DateTime.parse(i.createdAt);
        return created.isAfter(twoDaysAgo);
      } catch (_) {
        return false;
      }
    }).length;

    return Card(
      color: colors.surfaceCard,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  color: colors.info,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  l10n.homeShoppingTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textHeading,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.homeShoppingSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _StoreCountItem(
                    label: l10n.homeShoppingStoreSupermarket,
                    count: superCount,
                    bgColor: colors.storeSuperSoft,
                    borderColor: colors.storeSuperBorder,
                    textColor: colors.storeSuperText,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _StoreCountItem(
                    label: l10n.homeShoppingStoreDrugStore,
                    count: drugCount,
                    bgColor: colors.storeDrugSoft,
                    borderColor: colors.storeDrugBorder,
                    textColor: colors.storeDrugText,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _StoreCountItem(
                    label: l10n.homeShoppingStoreOnline,
                    count: onlineCount,
                    bgColor: colors.storeOnlineSoft,
                    borderColor: colors.storeOnlineBorder,
                    textColor: colors.storeOnlineText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primary50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.homeShoppingRecentlyAdded,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.primary),
                  ),
                  Text(
                    l10n.homeShoppingCountFormat(recentCount),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(l10n.homeShoppingOpenButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreCountItem extends StatelessWidget {
  const _StoreCountItem({
    required this.label,
    required this.count,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  final String label;
  final int count;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
