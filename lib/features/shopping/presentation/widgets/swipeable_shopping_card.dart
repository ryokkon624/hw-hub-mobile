import 'package:flutter/material.dart';
import '../../../../core/models/purchase_location_type.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/shopping_repository.dart';
import '../shopping_list_state.dart';

/// 未購入・かごタブのスワイプ可能なアイテムカード。
/// [variant] により背景・スワイプアクションが変わる。
class SwipeableShoppingCard extends StatelessWidget {
  const SwipeableShoppingCard({
    super.key,
    required this.item,
    required this.variant,
    required this.onPrimarySwipe,
    required this.onSecondarySwipe,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final ShoppingItemDto item;
  final ShoppingTab variant; // unpurchased or basket

  /// 右スワイプ（startToEnd）のアクション
  final Future<bool> Function() onPrimarySwipe;

  /// 左スワイプ（endToStart）のアクション
  final Future<bool> Function() onSecondarySwipe;

  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    final primaryLabel = variant == ShoppingTab.unpurchased
        ? l10n.shoppingSwipeMoveToBasket
        : l10n.shoppingSwipeMarkPurchased;
    final secondaryLabel = variant == ShoppingTab.unpurchased
        ? l10n.shoppingSwipeDelete
        : l10n.shoppingSwipeMoveBack;
    final secondaryColor = variant == ShoppingTab.unpurchased
        ? colors.swipeDelete
        : colors.swipeDisabled;

    return Dismissible(
      key: ValueKey('${variant.name}_${item.shoppingItemId}'),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.3,
        DismissDirection.endToStart: 0.3,
      },
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: colors.swipeAction,
        icon: variant == ShoppingTab.unpurchased
            ? Icons.shopping_basket_outlined
            : Icons.check_circle_outline,
        label: primaryLabel,
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: secondaryColor,
        icon: variant == ShoppingTab.unpurchased
            ? Icons.delete_outline
            : Icons.undo,
        label: secondaryLabel,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return onPrimarySwipe();
        } else {
          return onSecondarySwipe();
        }
      },
      child: _CardBody(item: item, onTap: onTap, onFavoriteTap: onFavoriteTap),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.item,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final ShoppingItemDto item;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final storeColor = _storeColor(colors, item.storeType);

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 購入場所カラーバー
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: storeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
              ),
              // コンテンツ
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textHeading,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.memo != null && item.memo!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.memo!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // アイコンエリア
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // お気に入りアイコン（AC10）
                    GestureDetector(
                      onTap: onFavoriteTap,
                      child: Icon(
                        item.favorite == '1' ? Icons.star : Icons.star_border,
                        color: item.favorite == '1'
                            ? Colors.amber
                            : colors.textMuted,
                        size: 20,
                      ),
                    ),
                    // 画像アイコン（AC3: 画像がある場合のみ）
                    if (item.hasImage) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.photo_camera_outlined,
                        color: colors.textMuted,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _storeColor(AppColorScheme colors, String? storeType) {
    final type = PurchaseLocationType.fromCode(storeType);
    switch (type) {
      case PurchaseLocationType.supermarket:
        return colors.storeSuper;
      case PurchaseLocationType.drugstore:
        return colors.storeDrug;
      case PurchaseLocationType.online:
        return colors.storeOnline;
      case null:
        return colors.border;
    }
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final AlignmentGeometry alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
