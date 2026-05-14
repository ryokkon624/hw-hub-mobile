import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/shopping_item_history_suggestion_dto.dart';

/// 過去履歴から選ぶボトムシート。
/// キーワード・storeType・期間フィルタを保持し、フィルタ結果を表示する。
class HistoryPickerBottomSheet extends StatefulWidget {
  const HistoryPickerBottomSheet({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  final List<ShoppingItemHistorySuggestionDto> suggestions;
  final ValueChanged<ShoppingItemHistorySuggestionDto> onSelected;

  @override
  State<HistoryPickerBottomSheet> createState() =>
      _HistoryPickerBottomSheetState();
}

class _HistoryPickerBottomSheetState extends State<HistoryPickerBottomSheet> {
  String _keyword = '';
  String? _storeType;
  _Period _period = _Period.all;

  List<ShoppingItemHistorySuggestionDto> get _filtered {
    return widget.suggestions.where((s) {
      // キーワードフィルタ
      if (_keyword.isNotEmpty &&
          !s.name.toLowerCase().contains(_keyword.toLowerCase())) {
        return false;
      }
      // 購入場所フィルタ
      if (_storeType != null && s.storeType != _storeType) {
        return false;
      }
      // 期間フィルタ（ローカルフィルタ）
      if (_period != _Period.all && s.lastPurchasedDate != null) {
        final dt = DateTime.tryParse(s.lastPurchasedDate!);
        if (dt == null) return false;
        final cutoff = DateTime.now().subtract(_period.duration);
        if (dt.isBefore(cutoff)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
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
                  l10n.shoppingHistoryModalTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.shoppingHistoryModalDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                // キーワード検索
                TextField(
                  onChanged: (v) => setState(() => _keyword = v),
                  decoration: InputDecoration(
                    hintText: l10n.shoppingHistoryModalKeywordPlaceholder,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                // 期間フィルタチップ
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _Period.values.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(_periodLabel(l10n, p)),
                          selected: _period == p,
                          onSelected: (_) => setState(() => _period = p),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // アイテムリスト
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      l10n.shoppingHistoryModalEmpty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final s = filtered[i];
                      return ListTile(
                        title: Text(s.name),
                        subtitle: s.storeType != null
                            ? Text(_storeTypeLabel(l10n, s.storeType!))
                            : null,
                        trailing: s.purchaseCount > 0
                            ? Text(
                                '${s.purchaseCount}回',
                                style: Theme.of(context).textTheme.bodySmall,
                              )
                            : null,
                        onTap: () => widget.onSelected(s),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _periodLabel(AppLocalizations l10n, _Period period) {
    switch (period) {
      case _Period.all:
        return l10n.shoppingHistoryModalPeriodAll;
      case _Period.last30d:
        return l10n.shoppingHistoryModalPeriod30d;
      case _Period.last90d:
        return l10n.shoppingHistoryModalPeriod90d;
      case _Period.last365d:
        return l10n.shoppingHistoryModalPeriod365d;
    }
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

enum _Period {
  all,
  last30d,
  last90d,
  last365d;

  Duration get duration {
    switch (this) {
      case _Period.all:
        return Duration.zero;
      case _Period.last30d:
        return const Duration(days: 30);
      case _Period.last90d:
        return const Duration(days: 90);
      case _Period.last365d:
        return const Duration(days: 365);
    }
  }
}
