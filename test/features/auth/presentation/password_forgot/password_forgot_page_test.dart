import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_forgot/password_forgot_page.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  group('PasswordForgotPage', () {
    testWidgets('初期状態: タイトルが表示され送信ボタンが無効', (tester) async {
      await tester.pumpWidget(buildTestPage(const PasswordForgotPage()));
      await tester.pump();

      expect(find.text('パスワードをお忘れですか？'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('メールアドレスを入力すると送信ボタンが有効になる', (tester) async {
      await tester.pumpWidget(buildTestPage(const PasswordForgotPage()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('initialEmailが渡されるとフィールドに設定される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const PasswordForgotPage(initialEmail: 'preset@example.com'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('preset@example.com'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });
  });
}
