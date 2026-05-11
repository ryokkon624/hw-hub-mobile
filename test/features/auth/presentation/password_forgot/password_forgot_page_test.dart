import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_forgot/password_forgot_notifier.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_forgot/password_forgot_page.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_forgot/password_forgot_state.dart';

import '../../../../helpers/widget_test_helpers.dart';

class _ErrorPasswordForgotNotifier extends PasswordForgotNotifier {
  @override
  PasswordForgotState build() => const PasswordForgotState(
    email: 'test@example.com',
    errorMessage: 'ネットワークエラーが発生しました。',
  );
}

class _LoadingPasswordForgotNotifier extends PasswordForgotNotifier {
  @override
  PasswordForgotState build() =>
      const PasswordForgotState(email: 'test@example.com', isLoading: true);
}

class _SentEmailPasswordForgotNotifier extends PasswordForgotNotifier {
  @override
  PasswordForgotState build() {
    // Transition to sentEmail state after build
    Future.microtask(
      () => state = state.copyWith(sentEmail: 'test@example.com'),
    );
    return const PasswordForgotState();
  }
}

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
      await tester.pumpWidget(
        buildTestPage(
          const PasswordForgotPage(initialEmail: 'preset@example.com'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('preset@example.com'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('errorMessageが設定されているとエラー文言が表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const PasswordForgotPage(),
          overrides: [
            passwordForgotNotifierProvider.overrideWith(
              () => _ErrorPasswordForgotNotifier(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ネットワークエラーが発生しました。'), findsOneWidget);
    });

    testWidgets('送信中: ボタンが無効でローディングインジケーターが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const PasswordForgotPage(),
          overrides: [
            passwordForgotNotifierProvider.overrideWith(
              () => _LoadingPasswordForgotNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('sentEmail設定後: /forgot-password/sentに遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/forgot-password',
              builder: (_, _) => const PasswordForgotPage(),
            ),
            GoRoute(
              path: '/forgot-password/sent',
              builder: (_, _) => const Scaffold(body: Text('sent-page')),
            ),
          ],
          overrides: [
            passwordForgotNotifierProvider.overrideWith(
              () => _SentEmailPasswordForgotNotifier(),
            ),
          ],
          initialLocation: '/forgot-password',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('sent-page'), findsOneWidget);
    });

    testWidgets('ログインへ戻るボタンタップで/loginに遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/forgot-password',
              builder: (_, _) => const PasswordForgotPage(),
            ),
            GoRoute(
              path: '/login',
              builder: (_, _) => const Scaffold(body: Text('login-page')),
            ),
          ],
          initialLocation: '/forgot-password',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ログインへ戻る'));
      await tester.pumpAndSettle();

      expect(find.text('login-page'), findsOneWidget);
    });
  });
}
