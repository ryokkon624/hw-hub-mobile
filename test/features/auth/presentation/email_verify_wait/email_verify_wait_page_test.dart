import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/features/auth/auth_providers.dart';
import 'package:hw_hub_mobile/features/auth/presentation/email_verify_wait/email_verify_wait_page.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';

import '../../../../helpers/widget_test_helpers.dart';

class _SendingEmailVerifyWaitNotifier extends EmailVerifyWaitNotifier {
  @override
  EmailVerifyWaitState build(String arg) =>
      const EmailVerifyWaitState(isSending: true);
}

class _ResentSuccessNotifier extends EmailVerifyWaitNotifier {
  @override
  EmailVerifyWaitState build(String arg) {
    // Schedule a state change after build to trigger ref.listen
    Future.microtask(
      () => state = const EmailVerifyWaitState(resentSuccess: true),
    );
    return const EmailVerifyWaitState();
  }
}

class _ErrorMessageNotifier extends EmailVerifyWaitNotifier {
  @override
  EmailVerifyWaitState build(String arg) {
    Future.microtask(
      () => state = const EmailVerifyWaitState(errorMessage: 'テストエラー'),
    );
    return const EmailVerifyWaitState();
  }
}

class _CooldownEmailVerifyWaitNotifier extends EmailVerifyWaitNotifier {
  @override
  EmailVerifyWaitState build(String arg) =>
      const EmailVerifyWaitState(cooldownSeconds: 30);
}

void main() {
  group('EmailVerifyWaitPage', () {
    testWidgets('メールアドレスが渡されると確認メール送信済みタイトルが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const EmailVerifyWaitPage(email: 'test@example.com')),
      );
      await tester.pump();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(EmailVerifyWaitPage)),
      );
      expect(find.text(l10n.emailVerifyWaitTitle), findsOneWidget);
      expect(find.textContaining('test@example.com'), findsOneWidget);
    });

    testWidgets('初期状態: 再送ボタンが有効（クールダウンなし）', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const EmailVerifyWaitPage(email: 'test@example.com')),
      );
      await tester.pump();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(EmailVerifyWaitPage)),
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
      expect(find.text(l10n.emailVerifyWaitResendButton), findsOneWidget);
    });

    testWidgets('送信中: 再送ボタンが無効になる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const EmailVerifyWaitPage(email: 'test@example.com'),
          overrides: [
            emailVerifyWaitNotifierProvider.overrideWith(
              () => _SendingEmailVerifyWaitNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('クールダウン中: ボタンが無効で残り秒数が表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const EmailVerifyWaitPage(email: 'test@example.com'),
          overrides: [
            emailVerifyWaitNotifierProvider.overrideWith(
              () => _CooldownEmailVerifyWaitNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(EmailVerifyWaitPage)),
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.text(l10n.emailVerifyWaitResendCooldown(30)), findsOneWidget);
    });

    testWidgets('メールアドレスが空のとき/signupに遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          initialLocation: '/email-waiting',
          routes: [
            GoRoute(
              path: '/email-waiting',
              builder: (_, _) => const EmailVerifyWaitPage(email: ''),
            ),
            GoRoute(
              path: '/signup',
              builder: (_, _) => const Scaffold(body: Text('signup-page')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('signup-page'), findsOneWidget);
    });

    testWidgets('再送成功: 再送完了SnackBarが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const EmailVerifyWaitPage(email: 'test@example.com'),
          overrides: [
            emailVerifyWaitNotifierProvider.overrideWith(
              () => _ResentSuccessNotifier(),
            ),
          ],
          withSnackBarKey: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(EmailVerifyWaitPage)),
      );
      expect(find.text(l10n.emailVerifyWaitAlertResent), findsOneWidget);
    });

    testWidgets('エラー発生: エラーSnackBarが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const EmailVerifyWaitPage(email: 'test@example.com'),
          overrides: [
            emailVerifyWaitNotifierProvider.overrideWith(
              () => _ErrorMessageNotifier(),
            ),
          ],
          withSnackBarKey: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('テストエラー'), findsOneWidget);
    });
  });
}
