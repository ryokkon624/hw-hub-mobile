import 'package:flutter/material.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';

class BulkSkipDialog extends StatelessWidget {
  const BulkSkipDialog({super.key, required this.count});

  final int count;

  static Future<bool> show(BuildContext context, {required int count}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => BulkSkipDialog(count: count),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.houseworkAssignBulkSkipDialogTitle),
      content: Text(l10n.houseworkAssignBulkSkipDialogBody(count)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.houseworkAssignBulkSkipButton),
        ),
      ],
    );
  }
}
