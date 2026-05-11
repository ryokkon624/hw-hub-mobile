import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

class _LoadingLoginNotifier extends LoginNotifier {
  @override
  LoginState build() => const LoginState(
        email: 'test@example.com',
        password: 'password123',
        isLoading: true,
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

    testWidgets('notice=emailVerified: 確認完了SnackBarが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const LoginPage(notice: 'emailVerified'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('確認が完了しました。ログインしてください。'), findsOneWidget);
    });

    testWidgets('notice=passwordResetSuccess: パスワード変更完了SnackBarが表示される',
        (tester) async {
      await tester.pumpWidget(buildTestPage(
        const LoginPage(notice: 'passwordResetSuccess'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('新しいパスワードでログインしてください。'), findsOneWidget);
    });

    testWidgets('送信中: ボタンが無効でローディングインジケーターが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const LoginPage(),
        overrides: [
          loginNotifierProvider.overrideWith(() => _LoadingLoginNotifier()),
        ],
      ));
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('パスワードフィールドでEnterキー: canSubmitがfalseのとき何もしない',
        (tester) async {
      await tester.pumpWidget(buildTestPage(const LoginPage()));
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'pass');
      await tester.pump();

      // パスワードフィールドにフォーカスを当てた状態でEnterを送信
      await tester.tap(find.byType(TextField).at(1));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // canSubmit は false（password < 8文字）のため submit() は呼ばれない
      // 例外が発生しないことを確認
    });

    testWidgets('パスワードを忘れた場合ボタンタップで/forgot-passwordに遷移する', (tester) async {
      await tester.pumpWidget(buildTestPageWithRouter(
        routes: [
          GoRoute(
            path: '/login',
            builder: (_, _) => const LoginPage(),
          ),
          GoRoute(
            path: '/forgot-password',
            builder: (_, _) => const Scaffold(body: Text('forgot-page')),
          ),
        ],
        initialLocation: '/login',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('パスワードを忘れた場合'));
      await tester.pumpAndSettle();

      expect(find.text('forgot-page'), findsOneWidget);
    });

    testWidgets('新規登録ボタンタップで/signupに遷移する', (tester) async {
      await tester.pumpWidget(buildTestPageWithRouter(
        routes: [
          GoRoute(
            path: '/login',
            builder: (_, _) => const LoginPage(),
          ),
          GoRoute(
            path: '/signup',
            builder: (_, _) => const Scaffold(body: Text('signup-page')),
          ),
        ],
        initialLocation: '/login',
      ));
      await tester.pumpAndSettle();

      // ページ下部にある「新規登録」ボタンが画面外の場合はスクロールして表示させる
      await tester.ensureVisible(find.text('新規登録'));
      await tester.tap(find.text('新規登録'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('signup-page'), findsOneWidget);
    });
  });
}
