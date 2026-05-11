import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/auth/presentation/auth_result/auth_result_page.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  group('AuthResultPage', () {
    testWidgets('emailVerify/success: 成功アイコンとタイトルが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const AuthResultPage(type: 'emailVerify', status: 'success'),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('メール認証が完了しました'), findsOneWidget);
      expect(find.text('ログインへ'), findsOneWidget);
    });

    testWidgets('emailVerify/expired: エラーアイコンと期限切れタイトルが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const AuthResultPage(type: 'emailVerify', status: 'expired'),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('リンクの有効期限が切れています'), findsOneWidget);
      expect(find.text('サインアップへ'), findsOneWidget);
    });

    testWidgets('passwordReset/success: 成功アイコンとタイトルが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const AuthResultPage(type: 'passwordReset', status: 'success'),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('パスワードを変更しました'), findsOneWidget);
      expect(find.text('ログインへ'), findsOneWidget);
    });

    testWidgets('passwordReset/expired: エラーアイコンと再発行ボタンが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const AuthResultPage(type: 'passwordReset', status: 'expired'),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('パスワード再設定をやり直す'), findsOneWidget);
    });
  });
}
