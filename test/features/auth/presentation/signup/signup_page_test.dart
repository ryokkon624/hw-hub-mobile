import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/auth/presentation/signup/signup_notifier.dart';
import 'package:hw_hub_mobile/features/auth/presentation/signup/signup_page.dart';
import 'package:hw_hub_mobile/features/auth/presentation/signup/signup_state.dart';

import '../../../../helpers/widget_test_helpers.dart';

class _ErrorSignupNotifier extends SignupNotifier {
  @override
  SignupState build() => const SignupState(errorMessage: 'アカウントの作成に失敗しました。時間をおいて再度お試しください。');
}

void main() {
  group('SignupPage', () {
    testWidgets('初期状態: アカウント作成タイトルが表示されボタンが無効', (tester) async {
      await tester.pumpWidget(buildTestPage(const SignupPage()));
      await tester.pump();

      expect(find.text('アカウント作成'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('必須フィールドを入力するとボタンが有効になる', (tester) async {
      await tester.pumpWidget(buildTestPage(const SignupPage()));
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'テストユーザー');
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      await tester.enterText(find.byType(TextField).at(3), 'password123');
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('errorMessageが設定されているとエラー文言が表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const SignupPage(),
        overrides: [
          signupNotifierProvider.overrideWith(() => _ErrorSignupNotifier()),
        ],
      ));
      await tester.pump();

      expect(find.text('アカウントの作成に失敗しました。時間をおいて再度お試しください。'), findsOneWidget);
    });
  });
}
