import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/housework_assign/presentation/widgets/bulk_skip_dialog.dart';

import '../../../../helpers/widget_test_helpers.dart';

Widget _buildDialog({int count = 3}) {
  return buildTestPage(Scaffold(body: BulkSkipDialog(count: count)));
}

void main() {
  group('BulkSkipDialog', () {
    testWidgets('AlertDialogが表示される', (tester) async {
      await tester.pumpWidget(_buildDialog());
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('キャンセルと実行ボタンが表示される', (tester) async {
      await tester.pumpWidget(_buildDialog());
      await tester.pump();

      expect(find.byType(TextButton), findsNWidgets(2));
    });
  });
}
