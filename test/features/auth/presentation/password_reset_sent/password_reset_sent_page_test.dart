import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_reset_sent/password_reset_sent_notifier.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_reset_sent/password_reset_sent_page.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_reset_sent/password_reset_sent_state.dart';

import '../../../../helpers/widget_test_helpers.dart';

class _ResentSuccessPasswordResetSentNotifier extends PasswordResetSentNotifier {
  @override
  PasswordResetSentState build(String arg) {
    Future.microtask(() => state = state.copyWith(resentSuccess: true));
    return const PasswordResetSentState();
  }
}

void main() {
  group('PasswordResetSentPage', () {
    testWidgets('タイトルとメールアドレスが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const PasswordResetSentPage(email: 'test@example.com'),
      ));
      await tester.pump();

      expect(find.text('メールを確認してください'), findsOneWidget);
      expect(find.text('(test@example.com)'), findsOneWidget);
    });

    testWidgets('初期状態: 再送ボタンが有効', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const PasswordResetSentPage(email: 'test@example.com'),
      ));
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
      expect(find.text('メールを再送'), findsOneWidget);
    });

    testWidgets('resentSuccessがtrueになるとSnackBarが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const PasswordResetSentPage(email: 'test@example.com'),
        overrides: [
          passwordResetSentNotifierProvider
              .overrideWith(() => _ResentSuccessPasswordResetSentNotifier()),
        ],
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('メールを再送しました'), findsOneWidget);
    });

    testWidgets('AppBarの戻るボタンタップで/forgot-passwordに遷移する', (tester) async {
      await tester.pumpWidget(buildTestPageWithRouter(
        routes: [
          GoRoute(
            path: '/forgot-password/sent',
            builder: (_, _) =>
                const PasswordResetSentPage(email: 'test@example.com'),
          ),
          GoRoute(
            path: '/forgot-password',
            builder: (_, _) =>
                const Scaffold(body: Text('forgot-password-page')),
          ),
        ],
        initialLocation: '/forgot-password/sent',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('forgot-password-page'), findsOneWidget);
    });

    testWidgets('別のメールアドレスを使うボタンタップで/forgot-passwordに遷移する', (tester) async {
      await tester.pumpWidget(buildTestPageWithRouter(
        routes: [
          GoRoute(
            path: '/forgot-password/sent',
            builder: (_, _) =>
                const PasswordResetSentPage(email: 'test@example.com'),
          ),
          GoRoute(
            path: '/forgot-password',
            builder: (_, _) =>
                const Scaffold(body: Text('forgot-password-page')),
          ),
        ],
        initialLocation: '/forgot-password/sent',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('別のメールアドレスを使う'));
      await tester.pumpAndSettle();

      expect(find.text('forgot-password-page'), findsOneWidget);
    });

    testWidgets('ログインへ戻るボタンタップで/loginに遷移する', (tester) async {
      await tester.pumpWidget(buildTestPageWithRouter(
        routes: [
          GoRoute(
            path: '/forgot-password/sent',
            builder: (_, _) =>
                const PasswordResetSentPage(email: 'test@example.com'),
          ),
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: Text('login-page')),
          ),
        ],
        initialLocation: '/forgot-password/sent',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ログインへ戻る'));
      await tester.pumpAndSettle();

      expect(find.text('login-page'), findsOneWidget);
    });
  });
}
