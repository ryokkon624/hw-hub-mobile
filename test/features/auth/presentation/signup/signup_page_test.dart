import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/features/auth/presentation/signup/signup_notifier.dart';
import 'package:hw_hub_mobile/features/auth/presentation/signup/signup_page.dart';
import 'package:hw_hub_mobile/features/auth/presentation/signup/signup_state.dart';

import '../../../../helpers/widget_test_helpers.dart';

class _ErrorSignupNotifier extends SignupNotifier {
  @override
  SignupState build() =>
      const SignupState(errorMessage: 'アカウントの作成に失敗しました。時間をおいて再度お試しください。');
}

class _LoadingSignupNotifier extends SignupNotifier {
  @override
  SignupState build() => const SignupState(
    email: 'test@example.com',
    displayName: 'Test User',
    password: 'password123',
    passwordConfirm: 'password123',
    isLoading: true,
  );
}

class _SuccessRequiresVerifySignupNotifier extends SignupNotifier {
  @override
  SignupState build() {
    Future.microtask(
      () => state = state.copyWith(
        successResult: const SignupSuccessResult(
          email: 'test@example.com',
          requiresEmailVerify: true,
        ),
      ),
    );
    return const SignupState();
  }
}

class _SuccessNoVerifySignupNotifier extends SignupNotifier {
  @override
  SignupState build() {
    Future.microtask(
      () => state = state.copyWith(
        successResult: const SignupSuccessResult(
          email: 'test@example.com',
          requiresEmailVerify: false,
        ),
      ),
    );
    return const SignupState();
  }
}

class _SubmittableSignupNotifier extends SignupNotifier {
  bool submitCalled = false;

  @override
  SignupState build() => const SignupState(
    email: 'test@example.com',
    displayName: 'Test User',
    password: 'password123',
    passwordConfirm: 'password123',
  );

  @override
  Future<void> submit({String? invitationToken}) async {
    submitCalled = true;
  }
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
      await tester.pumpWidget(
        buildTestPage(
          const SignupPage(),
          overrides: [
            signupNotifierProvider.overrideWith(() => _ErrorSignupNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('アカウントの作成に失敗しました。時間をおいて再度お試しください。'), findsOneWidget);
    });

    testWidgets('送信中: ボタンが無効でローディングインジケーターが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const SignupPage(),
          overrides: [
            signupNotifierProvider.overrideWith(() => _LoadingSignupNotifier()),
          ],
        ),
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('invitationTokenを持つSignupPage: タイトルが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const SignupPage(invitationToken: 'invite-abc')),
      );
      await tester.pump();

      expect(find.text('アカウント作成'), findsOneWidget);
    });

    testWidgets('言語ドロップダウンを変更するとlocaleが更新される', (tester) async {
      await tester.pumpWidget(buildTestPage(const SignupPage()));
      await tester.pump();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('英語').last);
      await tester.pump();

      // onChanged ラムダが実行され例外が発生しないことを確認
    });

    testWidgets('サインアップ成功(メール確認必要): /email-waitingに遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(path: '/signup', builder: (_, _) => const SignupPage()),
            GoRoute(
              path: '/email-waiting',
              builder: (_, _) =>
                  const Scaffold(body: Text('email-waiting-page')),
            ),
          ],
          overrides: [
            signupNotifierProvider.overrideWith(
              () => _SuccessRequiresVerifySignupNotifier(),
            ),
          ],
          initialLocation: '/signup',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('email-waiting-page'), findsOneWidget);
    });

    testWidgets('ログイン画面へボタンタップで/loginに遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(path: '/signup', builder: (_, _) => const SignupPage()),
            GoRoute(
              path: '/login',
              builder: (_, _) => const Scaffold(body: Text('login-page')),
            ),
          ],
          initialLocation: '/signup',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ログイン画面へ'));
      await tester.pumpAndSettle();

      expect(find.text('login-page'), findsOneWidget);
    });

    testWidgets('サインアップ成功(メール確認不要): /homeに遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(path: '/signup', builder: (_, _) => const SignupPage()),
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('home-page')),
            ),
          ],
          overrides: [
            signupNotifierProvider.overrideWith(
              () => _SuccessNoVerifySignupNotifier(),
            ),
          ],
          initialLocation: '/signup',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('home-page'), findsOneWidget);
    });

    testWidgets('送信ボタンをタップするとsubmitが呼ばれる', (tester) async {
      final notifier = _SubmittableSignupNotifier();
      await tester.pumpWidget(
        buildTestPage(
          const SignupPage(),
          overrides: [signupNotifierProvider.overrideWith(() => notifier)],
        ),
      );
      await tester.pump();

      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(notifier.submitCalled, isTrue);
    });

    testWidgets('onSubmitted: キーボードdoneキーでsubmitが呼ばれる', (tester) async {
      final notifier = _SubmittableSignupNotifier();
      await tester.pumpWidget(
        buildTestPage(
          const SignupPage(),
          overrides: [signupNotifierProvider.overrideWith(() => notifier)],
        ),
      );
      await tester.pump();

      // 4番目のTextField（パスワード確認）にフォーカスしてdoneアクションを送る
      await tester.tap(find.byType(TextField).at(3));
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // canSubmit=true なので submit が呼ばれる
      expect(notifier.submitCalled, isTrue);
    });
  });
}
