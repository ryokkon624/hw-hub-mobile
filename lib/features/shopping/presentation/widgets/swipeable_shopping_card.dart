import 'package:flutter/material.dart';
import '../../../../core/models/purchase_location_type.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/shopping_repository.dart';
import '../shopping_list_state.dart';

/// 未購入・かご・購入済みタブのアイテムカード。
/// [variant] により背景・スワイプアクションが変わる。
/// [enableSwipe] が false のときはスワイプなしでカード本体のみ表示する（購入済みタブ用）。
class SwipeableShoppingCard extends StatelessWidget {
  const SwipeableShoppingCard({
    super.key,
    required this.item,
    required this.variant,
    required this.onPrimarySwipe,
    required this.onSecondarySwipe,
    required this.onTap,
    required this.onFavoriteTap,
    this.enableSwipe = true,
  });

  final ShoppingItemDto item;
  final ShoppingTab variant; // unpurchased or basket

  /// 右スワイプ（startToEnd）のアクション
  final Future<bool> Function() onPrimarySwipe;

  /// 左スワイプ（endToStart）のアクション
  final Future<bool> Function() onSecondarySwipe;

  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  /// false のときはスワイプなしでカード本体（_CardBody）のみを表示する（購入済みタブ用）
  final bool enableSwipe;

  @override
  Widget build(BuildContext context) {
    final cardBody = _CardBody(
      item: item,
      onTap: onTap,
      onFavoriteTap: onFavoriteTap,
    );

    if (!enableSwipe) return cardBody;

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
      child: cardBody,
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
    final bgColor = _storeBackgroundColor(colors, item.storeType);

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // コンテンツ
              Expanded(
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // アイコンエリア
              Row(
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
            ],
          ),
        ),
      ),
    );
  }

  /// 購入場所に対応したカード背景色を返す（AC1）
  Color _storeBackgroundColor(AppColorScheme colors, String? storeType) {
    final type = PurchaseLocationType.fromCode(storeType);
    switch (type) {
      case PurchaseLocationType.supermarket:
        return colors.paletteEmeraldSoft;
      case PurchaseLocationType.online:
        return colors.paletteBlueSoft;
      case PurchaseLocationType.drugstore:
        return colors.paletteRoseSoft;
      case null:
        return colors.surfaceCard;
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
