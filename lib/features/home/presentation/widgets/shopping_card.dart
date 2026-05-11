import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/shopping_item_dto.dart';

class ShoppingCard extends StatelessWidget {
  const ShoppingCard({super.key, required this.items, required this.onOpen});

  final List<ShoppingItemDto> items;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    // 未購入アイテムのみ
    final openItems = items.where((i) => i.status == '0').toList();

    // 購入場所別件数
    final Map<String, int> storeCountMap = {};
    for (final item in openItems) {
      final store = item.storeType ?? 'other';
      storeCountMap[store] = (storeCountMap[store] ?? 0) + 1;
    }

    // 直近2日以内追加件数
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
      color: colors.infoSoft,
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
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.homeShoppingSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (storeCountMap.isEmpty)
              Text(
                '0件',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
              )
            else
              ...storeCountMap.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _storeLabel(e.key),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textBody,
                        ),
                      ),
                      Text(
                        '${e.value}件',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.homeShoppingRecentlyAdded}: $recentCount件',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onOpen,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.info,
                  side: BorderSide(color: colors.info.withValues(alpha: 0.5)),
                ),
                child: Text(l10n.homeShoppingOpenButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _storeLabel(String storeType) {
    switch (storeType) {
      case 'supermarket':
        return 'スーパー';
      case 'online':
        return 'ネット';
      case 'drug_store':
        return 'ドラッグストア';
      default:
        return storeType;
    }
  }
}
