import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// かごタブの一括購入済み確認ダイアログ
Future<bool> showBulkPurchaseDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.shoppingBulkPurchaseConfirmTitle),
      content: Text(l10n.shoppingBulkPurchaseConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.shoppingBulkPurchaseButton),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 削除確認ダイアログ
Future<bool> showDeleteConfirmDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.shoppingDeleteConfirmTitle),
      content: Text(l10n.shoppingDeleteConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.commonDelete),
        ),
      ],
    ),
  );
  return result ?? false;
}
