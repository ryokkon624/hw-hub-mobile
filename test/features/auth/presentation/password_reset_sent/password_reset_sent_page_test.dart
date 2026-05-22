import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_reset_sent/password_reset_sent_notifier.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_reset_sent/password_reset_sent_page.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_reset_sent/password_reset_sent_state.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';

import '../../../../helpers/widget_test_helpers.dart';

class _ResentSuccessPasswordResetSentNotifier
    extends PasswordResetSentNotifier {
  @override
  PasswordResetSentState build(String arg) {
    Future.microtask(() => state = state.copyWith(resentSuccess: true));
    return const PasswordResetSentState();
  }
}

void main() {
  group('PasswordResetSentPage', () {
    testWidgets('タイトルとメールアドレスが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const PasswordResetSentPage(email: 'test@example.com')),
      );
      await tester.pump();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(PasswordResetSentPage)),
      );
      expect(find.text(l10n.passwordResetSentTitle), findsOneWidget);
      expect(find.text('(test@example.com)'), findsOneWidget);
    });

    testWidgets('初期状態: 再送ボタンが有効', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const PasswordResetSentPage(email: 'test@example.com')),
      );
      await tester.pump();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(PasswordResetSentPage)),
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
      expect(find.text(l10n.passwordResetSentResend), findsOneWidget);
    });

    testWidgets('resentSuccessがtrueになるとSnackBarが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const PasswordResetSentPage(email: 'test@example.com'),
          overrides: [
            passwordResetSentNotifierProvider.overrideWith(
              () => _ResentSuccessPasswordResetSentNotifier(),
            ),
          ],
          withSnackBarKey: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(PasswordResetSentPage)),
      );
      expect(find.text(l10n.passwordResetSentResendSuccess), findsOneWidget);
    });

    testWidgets('AppBarの戻るボタンタップで/forgot-passwordに遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
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
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('forgot-password-page'), findsOneWidget);
    });

    testWidgets('別のメールアドレスを使うボタンタップで/forgot-passwordに遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
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
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(PasswordResetSentPage)),
      );
      await tester.tap(find.text(l10n.passwordResetSentUseDifferentEmail));
      await tester.pumpAndSettle();

      expect(find.text('forgot-password-page'), findsOneWidget);
    });

    testWidgets('ログインへ戻るボタンタップで/loginに遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
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
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(PasswordResetSentPage)),
      );
      await tester.tap(find.text(l10n.passwordResetSentBackToLogin));
      await tester.pumpAndSettle();

      expect(find.text('login-page'), findsOneWidget);
    });
  });
}
