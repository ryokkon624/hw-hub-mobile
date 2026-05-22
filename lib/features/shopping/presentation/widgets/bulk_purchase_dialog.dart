import 'package:flutter/material.dart';
import '../../../../core/ui/app_dialog.dart';
import '../../../../l10n/app_localizations.dart';

/// かごタブの一括購入済み確認ダイアログ
Future<bool> showBulkPurchaseDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return AppDialog.confirm(
    context,
    title: l10n.shoppingBulkPurchaseConfirmTitle,
    message: l10n.shoppingBulkPurchaseConfirmMessage,
    confirmLabel: l10n.shoppingBulkPurchaseButton,
    cancelLabel: l10n.commonCancel,
  );
}

/// 削除確認ダイアログ
Future<bool> showDeleteConfirmDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return AppDialog.confirm(
    context,
    title: l10n.shoppingDeleteConfirmTitle,
    message: l10n.shoppingDeleteConfirmMessage,
    confirmLabel: l10n.commonDelete,
    cancelLabel: l10n.commonCancel,
    isDanger: true,
  );
}
