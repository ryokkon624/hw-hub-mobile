import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/housework_assign/presentation/widgets/bulk_skip_dialog.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  group('showBulkSkipDialog', () {
    testWidgets('ダイアログが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Builder(
            builder: (context) => ElevatedButton(
              key: const Key('openDialog'),
              onPressed: () => showBulkSkipDialog(context, count: 3),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('openDialog')));
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('キャンセルと実行ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Builder(
            builder: (context) => ElevatedButton(
              key: const Key('openDialog'),
              onPressed: () => showBulkSkipDialog(context, count: 3),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('openDialog')));
      await tester.pump();

      expect(find.byType(TextButton), findsNWidgets(2));
    });
  });
}
