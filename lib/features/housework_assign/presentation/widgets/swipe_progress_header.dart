import 'package:flutter/material.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';

/// スワイプモードの進捗を画面上部中央に大きめに表示するウィジェット（AC1）。
class SwipeProgressHeader extends StatelessWidget {
  const SwipeProgressHeader({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          l10n.houseworkAssignSwipeProgressLabel(current, total),
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
