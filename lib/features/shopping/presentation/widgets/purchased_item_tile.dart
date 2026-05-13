import 'package:flutter/material.dart';
import '../../../../core/models/purchase_location_type.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/shopping_repository.dart';

/// 購入済みタブのアイテム行（スワイプなし）
class PurchasedItemTile extends StatelessWidget {
  const PurchasedItemTile({super.key, required this.item, required this.onTap});

  final ShoppingItemDto item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final storeType = PurchaseLocationType.fromCode(item.storeType);

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.textBody),
              ),
            ),
            if (storeType != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _StoreBadge(type: storeType),
            ],
          ],
        ),
      ),
    );
  }
}

class _StoreBadge extends StatelessWidget {
  const _StoreBadge({required this.type});

  final PurchaseLocationType type;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final l10n = AppLocalizations.of(context);

    final Color bg;
    final Color text;
    final String label;

    switch (type) {
      case PurchaseLocationType.supermarket:
        bg = colors.storeSuperSoft;
        text = colors.storeSuperText;
        label = l10n.shoppingFilterSupermarket;
      case PurchaseLocationType.drugstore:
        bg = colors.storeDrugSoft;
        text = colors.storeDrugText;
        label = l10n.shoppingFilterDrugstore;
      case PurchaseLocationType.online:
        bg = colors.storeOnlineSoft;
        text = colors.storeOnlineText;
        label = l10n.shoppingFilterOnline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: text),
      ),
    );
  }
}
