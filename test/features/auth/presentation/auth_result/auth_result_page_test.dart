import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

    testWidgets('emailVerify/invalid: エラーアイコンと無効タイトルが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const AuthResultPage(type: 'emailVerify', status: 'invalid'),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('無効な認証リンクです'), findsOneWidget);
      expect(find.text('サインアップへ'), findsOneWidget);
    });

    testWidgets('passwordReset/invalid: エラーアイコンと無効タイトルが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const AuthResultPage(type: 'passwordReset', status: 'invalid'),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('無効なリセットリンクです'), findsOneWidget);
      expect(find.text('パスワード再設定をやり直す'), findsOneWidget);
    });

    testWidgets('未知のtype: フォールバックエラーが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const AuthResultPage(type: 'unknown', status: 'any'),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('予期しないエラーが発生しました。'), findsOneWidget);
      expect(find.text('ログインへ'), findsOneWidget);
    });

    testWidgets('emailVerify/success: ログインへボタンタップでloginに遷移する',
        (tester) async {
      await tester.pumpWidget(buildTestPageWithRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) =>
                const AuthResultPage(type: 'emailVerify', status: 'success'),
          ),
          GoRoute(
            path: '/login',
            builder: (_, state) => Scaffold(
                body: Text(
                    'to-login:${state.uri.queryParameters['notice'] ?? ''}')),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ログインへ'));
      await tester.pumpAndSettle();

      expect(find.text('to-login:emailVerified'), findsOneWidget);
    });

    testWidgets('emailVerify/expired: サインアップへボタンタップでsignupに遷移する',
        (tester) async {
      await tester.pumpWidget(buildTestPageWithRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) =>
                const AuthResultPage(type: 'emailVerify', status: 'expired'),
          ),
          GoRoute(
            path: '/signup',
            builder: (_, __) =>
                const Scaffold(body: Text('to-signup')),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('サインアップへ'));
      await tester.pumpAndSettle();

      expect(find.text('to-signup'), findsOneWidget);
    });

    testWidgets('passwordReset/success: ログインへボタンタップでloginに遷移する',
        (tester) async {
      await tester.pumpWidget(buildTestPageWithRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const AuthResultPage(
                type: 'passwordReset', status: 'success'),
          ),
          GoRoute(
            path: '/login',
            builder: (_, state) => Scaffold(
                body: Text(
                    'to-login:${state.uri.queryParameters['notice'] ?? ''}')),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ログインへ'));
      await tester.pumpAndSettle();

      expect(find.text('to-login:passwordResetSuccess'), findsOneWidget);
    });

    testWidgets(
        'passwordReset/expired: パスワード再設定をやり直すボタンタップでforgot-passwordに遷移する',
        (tester) async {
      await tester.pumpWidget(buildTestPageWithRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const AuthResultPage(
                type: 'passwordReset', status: 'expired'),
          ),
          GoRoute(
            path: '/forgot-password',
            builder: (_, __) =>
                const Scaffold(body: Text('to-forgot-password')),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('パスワード再設定をやり直す'));
      await tester.pumpAndSettle();

      expect(find.text('to-forgot-password'), findsOneWidget);
    });

    testWidgets('未知のtype: ログインへボタンタップで/loginに遷移する', (tester) async {
      await tester.pumpWidget(buildTestPageWithRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) =>
                const AuthResultPage(type: 'unknown', status: 'any'),
          ),
          GoRoute(
            path: '/login',
            builder: (_, state) => Scaffold(
                body: Text(
                    'to-login:${state.uri.queryParameters['notice'] ?? ''}')),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ログインへ'));
      await tester.pumpAndSettle();

      expect(find.text('to-login:'), findsOneWidget);
    });
  });
}
