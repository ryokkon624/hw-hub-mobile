import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/features/auth/auth_providers.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_reset/password_reset_page.dart';

import '../../../../helpers/widget_test_helpers.dart';

class _MismatchPasswordResetNotifier extends PasswordResetNotifier {
  @override
  PasswordResetState build() => const PasswordResetState(
    password: 'password123',
    passwordConfirm: 'different456',
  );
}

class _ErrorPasswordResetNotifier extends PasswordResetNotifier {
  @override
  PasswordResetState build() =>
      const PasswordResetState(errorMessage: 'ネットワークエラーが発生しました。');
}

class _LoadingPasswordResetNotifier extends PasswordResetNotifier {
  @override
  PasswordResetState build() => const PasswordResetState(
    password: 'password123',
    passwordConfirm: 'password123',
    isLoading: true,
  );
}

class _ResultSuccessPasswordResetNotifier extends PasswordResetNotifier {
  @override
  PasswordResetState build() {
    Future.microtask(
      () => state = state.copyWith(result: PasswordResetResult.success),
    );
    return const PasswordResetState();
  }
}

class _ResultExpiredPasswordResetNotifier extends PasswordResetNotifier {
  @override
  PasswordResetState build() {
    Future.microtask(
      () => state = state.copyWith(result: PasswordResetResult.expired),
    );
    return const PasswordResetState();
  }
}

class _ResultInvalidPasswordResetNotifier extends PasswordResetNotifier {
  @override
  PasswordResetState build() {
    Future.microtask(
      () => state = state.copyWith(result: PasswordResetResult.invalid),
    );
    return const PasswordResetState();
  }
}

class _SubmittablePasswordResetNotifier extends PasswordResetNotifier {
  bool submitCalled = false;

  @override
  PasswordResetState build() => const PasswordResetState(
    password: 'password123',
    passwordConfirm: 'password123',
  );

  @override
  Future<void> submit({required String token}) async {
    submitCalled = true;
  }
}

void main() {
  group('PasswordResetPage', () {
    testWidgets('初期状態: タイトルが表示され送信ボタンが無効', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const PasswordResetPage(token: 'valid-token')),
      );
      await tester.pump();

      expect(find.text('パスワード再設定'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('パスワードが一致しない場合にエラーが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const PasswordResetPage(token: 'valid-token'),
          overrides: [
            passwordResetNotifierProvider.overrideWith(
              () => _MismatchPasswordResetNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('パスワードが一致しません。'), findsOneWidget);
    });

    testWidgets('パスワードが一致し8文字以上のとき送信ボタンが有効になる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const PasswordResetPage(token: 'valid-token')),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'password123');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('errorMessageが設定されているとエラー文言が表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const PasswordResetPage(token: 'valid-token'),
          overrides: [
            passwordResetNotifierProvider.overrideWith(
              () => _ErrorPasswordResetNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('ネットワークエラーが発生しました。'), findsOneWidget);
    });

    testWidgets('送信中: ボタンが無効でローディングインジケーターが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const PasswordResetPage(token: 'valid-token'),
          overrides: [
            passwordResetNotifierProvider.overrideWith(
              () => _LoadingPasswordResetNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('トークンが空のとき/auth-resultに遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/password-reset',
              builder: (context, state) => const PasswordResetPage(token: ''),
            ),
            GoRoute(
              path: '/auth-result',
              builder: (context, state) => Scaffold(
                body: Text(
                  'auth-result:${state.uri.queryParameters['status'] ?? ''}',
                ),
              ),
            ),
          ],
          initialLocation: '/password-reset',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('auth-result:invalid'), findsOneWidget);
    });

    testWidgets('パスワードリセット成功: /auth-resultに遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/password-reset',
              builder: (context, state) =>
                  const PasswordResetPage(token: 'valid-token'),
            ),
            GoRoute(
              path: '/auth-result',
              builder: (context, state) => Scaffold(
                body: Text(
                  'auth-result:${state.uri.queryParameters['status'] ?? ''}',
                ),
              ),
            ),
          ],
          overrides: [
            passwordResetNotifierProvider.overrideWith(
              () => _ResultSuccessPasswordResetNotifier(),
            ),
          ],
          initialLocation: '/password-reset',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('auth-result:success'), findsOneWidget);
    });

    testWidgets('再発行ボタンタップで/forgot-passwordに遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/password-reset',
              builder: (context, state) =>
                  const PasswordResetPage(token: 'valid-token'),
            ),
            GoRoute(
              path: '/forgot-password',
              builder: (context, state) =>
                  const Scaffold(body: Text('forgot-password-page')),
            ),
          ],
          initialLocation: '/password-reset',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('再発行する'));
      await tester.pumpAndSettle();

      expect(find.text('forgot-password-page'), findsOneWidget);
    });

    testWidgets('期限切れ結果: /auth-result?status=expiredに遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/password-reset',
              builder: (context, state) =>
                  const PasswordResetPage(token: 'valid-token'),
            ),
            GoRoute(
              path: '/auth-result',
              builder: (context, state) => Scaffold(
                body: Text(
                  'auth-result:${state.uri.queryParameters['status'] ?? ''}',
                ),
              ),
            ),
          ],
          overrides: [
            passwordResetNotifierProvider.overrideWith(
              () => _ResultExpiredPasswordResetNotifier(),
            ),
          ],
          initialLocation: '/password-reset',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('auth-result:expired'), findsOneWidget);
    });

    testWidgets('無効トークン結果: /auth-result?status=invalidに遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/password-reset',
              builder: (context, state) =>
                  const PasswordResetPage(token: 'valid-token'),
            ),
            GoRoute(
              path: '/auth-result',
              builder: (context, state) => Scaffold(
                body: Text(
                  'auth-result:${state.uri.queryParameters['status'] ?? ''}',
                ),
              ),
            ),
          ],
          overrides: [
            passwordResetNotifierProvider.overrideWith(
              () => _ResultInvalidPasswordResetNotifier(),
            ),
          ],
          initialLocation: '/password-reset',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('auth-result:invalid'), findsOneWidget);
    });

    testWidgets('送信ボタンをタップするとsubmitが呼ばれる', (tester) async {
      final notifier = _SubmittablePasswordResetNotifier();
      await tester.pumpWidget(
        buildTestPage(
          const PasswordResetPage(token: 'valid-token'),
          overrides: [
            passwordResetNotifierProvider.overrideWith(() => notifier),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(notifier.submitCalled, isTrue);
    });

    testWidgets('ログインへ戻るボタンタップで/loginに遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/password-reset',
              builder: (context, state) =>
                  const PasswordResetPage(token: 'valid-token'),
            ),
            GoRoute(
              path: '/login',
              builder: (context, state) =>
                  const Scaffold(body: Text('login-page')),
            ),
          ],
          initialLocation: '/password-reset',
        ),
      );
      await tester.pumpAndSettle();

      // 「ログインへ戻る」テキストを持つTextButtonをタップ
      await tester.tap(find.text('ログインへ戻る'));
      await tester.pumpAndSettle();

      expect(find.text('login-page'), findsOneWidget);
    });

    testWidgets('onSubmitted: キーボードのdoneキーでsubmitが呼ばれる', (tester) async {
      final notifier = _SubmittablePasswordResetNotifier();
      await tester.pumpWidget(
        buildTestPage(
          const PasswordResetPage(token: 'valid-token'),
          overrides: [
            passwordResetNotifierProvider.overrideWith(() => notifier),
          ],
        ),
      );
      await tester.pump();

      // 2番目のTextField（パスワード確認）にフォーカスしてdoneアクションを送る
      await tester.tap(find.byType(TextField).last);
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // _SubmittablePasswordResetNotifier の state は canSubmit=true なので submit が呼ばれる
      expect(notifier.submitCalled, isTrue);
    });
  });
}
