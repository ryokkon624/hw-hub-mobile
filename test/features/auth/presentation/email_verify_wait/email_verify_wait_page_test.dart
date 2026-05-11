import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/auth/presentation/email_verify_wait/email_verify_wait_page.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  group('EmailVerifyWaitPage', () {
    testWidgets('メールアドレスが渡されると確認メール送信済みタイトルが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const EmailVerifyWaitPage(email: 'test@example.com'),
      ));
      await tester.pump();

      expect(find.text('確認メールを送信しました'), findsOneWidget);
      expect(find.textContaining('test@example.com'), findsOneWidget);
    });

    testWidgets('初期状態: 再送ボタンが有効（クールダウンなし）', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const EmailVerifyWaitPage(email: 'test@example.com'),
      ));
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
      expect(find.text('確認メールを再送'), findsOneWidget);
    });
  });
}
