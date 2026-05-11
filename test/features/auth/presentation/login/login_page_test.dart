import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/auth/presentation/login/login_notifier.dart';
import 'package:hw_hub_mobile/features/auth/presentation/login/login_page.dart';
import 'package:hw_hub_mobile/features/auth/presentation/login/login_state.dart';

import '../../../../helpers/widget_test_helpers.dart';

class _ErrorLoginNotifier extends LoginNotifier {
  @override
  LoginState build() => const LoginState(
        errorMessage: 'メールアドレスまたはパスワードが正しくありません。',
      );
}

void main() {
  group('LoginPage', () {
    testWidgets('初期状態: アプリ名が表示されログインボタンが無効', (tester) async {
      await tester.pumpWidget(buildTestPage(const LoginPage()));
      await tester.pump();

      expect(find.text('Housework Hub'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('メールとパスワードを入力するとログインボタンが有効になる', (tester) async {
      await tester.pumpWidget(buildTestPage(const LoginPage()));
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('errorMessageが設定されているとエラー文言が表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const LoginPage(),
        overrides: [
          loginNotifierProvider.overrideWith(() => _ErrorLoginNotifier()),
        ],
      ));
      await tester.pump();

      expect(find.text('メールアドレスまたはパスワードが正しくありません。'), findsOneWidget);
    });
  });
}
