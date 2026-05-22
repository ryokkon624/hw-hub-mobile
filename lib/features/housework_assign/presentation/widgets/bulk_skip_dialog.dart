import 'package:flutter/material.dart';
import '../../../../core/ui/app_dialog.dart';
import '../../../../l10n/app_localizations.dart';

Future<bool> showBulkSkipDialog(
  BuildContext context, {
  required int count,
}) async {
  final l10n = AppLocalizations.of(context);
  return AppDialog.confirm(
    context,
    title: l10n.houseworkAssignBulkSkipDialogTitle,
    message: l10n.houseworkAssignBulkSkipDialogBody(count),
    confirmLabel: l10n.houseworkAssignBulkSkipButton,
    cancelLabel: l10n.commonCancel,
  );
}
