import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/shopping_repository.dart';

/// お気に入りから選ぶボトムシート。
class FavoritePickerBottomSheet extends StatelessWidget {
  const FavoritePickerBottomSheet({
    super.key,
    required this.favorites,
    required this.onSelected,
  });

  final List<ShoppingItemDto> favorites;
  final ValueChanged<ShoppingItemDto> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // ヘッダー
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.shoppingFavoriteModalTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.shoppingFavoriteModalDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // アイテムリスト
          Expanded(
            child: favorites.isEmpty
                ? Center(
                    child: Text(
                      l10n.shoppingFavoriteModalEmpty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    itemCount: favorites.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final item = favorites[i];
                      return ListTile(
                        leading: const Icon(Icons.star, color: Colors.amber),
                        title: Text(item.name),
                        subtitle: item.storeType != null
                            ? Text(_storeTypeLabel(l10n, item.storeType!))
                            : null,
                        onTap: () => onSelected(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _storeTypeLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case '1':
        return l10n.shoppingFilterSupermarket;
      case '2':
        return l10n.shoppingFilterOnline;
      case '3':
        return l10n.shoppingFilterDrugstore;
      default:
        return code;
    }
  }
}
