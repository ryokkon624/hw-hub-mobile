import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_reset/password_reset_notifier.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_reset/password_reset_page.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_reset/password_reset_state.dart';

import '../../../../helpers/widget_test_helpers.dart';

class _MismatchPasswordResetNotifier extends PasswordResetNotifier {
  @override
  PasswordResetState build() => const PasswordResetState(
        password: 'password123',
        passwordConfirm: 'different456',
      );
}

void main() {
  group('PasswordResetPage', () {
    testWidgets('初期状態: タイトルが表示され送信ボタンが無効', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const PasswordResetPage(token: 'valid-token'),
      ));
      await tester.pump();

      expect(find.text('パスワード再設定'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('パスワードが一致しない場合にエラーが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const PasswordResetPage(token: 'valid-token'),
        overrides: [
          passwordResetNotifierProvider
              .overrideWith(() => _MismatchPasswordResetNotifier()),
        ],
      ));
      await tester.pump();

      expect(find.text('パスワードが一致しません。'), findsOneWidget);
    });
  });
}
