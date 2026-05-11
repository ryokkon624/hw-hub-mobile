import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_reset_sent/password_reset_sent_page.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  group('PasswordResetSentPage', () {
    testWidgets('タイトルとメールアドレスが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const PasswordResetSentPage(email: 'test@example.com'),
      ));
      await tester.pump();

      expect(find.text('メールを確認してください'), findsOneWidget);
      expect(find.text('(test@example.com)'), findsOneWidget);
    });

    testWidgets('初期状態: 再送ボタンが有効', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const PasswordResetSentPage(email: 'test@example.com'),
      ));
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
      expect(find.text('メールを再送'), findsOneWidget);
    });
  });
}
