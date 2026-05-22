import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class BulkCompleteDialog extends StatelessWidget {
  const BulkCompleteDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const BulkCompleteDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.myTasksBulkCompleteTitle),
      content: Text(l10n.myTasksBulkCompleteContent),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.myTasksBulkCompleteConfirm),
        ),
      ],
    );
  }
}
