import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: const Text('過去の家事をすべて完了にしますか？'),
      content: const Text('過去の未対応タスクをすべて完了に更新します。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('完了にする'),
        ),
      ],
    );
  }
}
