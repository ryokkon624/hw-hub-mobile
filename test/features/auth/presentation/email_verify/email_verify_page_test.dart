import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/features/auth/presentation/email_verify/email_verify_notifier.dart';
import 'package:hw_hub_mobile/features/auth/presentation/email_verify/email_verify_page.dart';

import '../../../../helpers/widget_test_helpers.dart';

List<GoRoute> _buildRoutes() => [
  GoRoute(
    path: '/email-verify',
    builder: (_, _) => const EmailVerifyPage(token: 'test-token'),
  ),
  GoRoute(
    path: '/auth-result',
    builder: (_, state) =>
        Scaffold(body: Text('result:${state.uri.queryParameters['status']}')),
  ),
];

void main() {
  group('EmailVerifyPage', () {
    testWidgets('トークン検証中はCircularProgressIndicatorが表示される', (tester) async {
      // Completer を使うことでタイマーを作らずに未完了の Future を提供する
      final completer = Completer<EmailVerifyResult>();
      await tester.pumpWidget(
        buildTestPage(
          const EmailVerifyPage(token: 'test-token'),
          overrides: [
            emailVerifyResultProvider(
              'test-token',
            ).overrideWith((ref) => completer.future),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('検証成功: /auth-result?status=successに遷移する', (tester) async {
      final overrides = [
        emailVerifyResultProvider(
          'test-token',
        ).overrideWith((ref) async => EmailVerifyResult.success),
      ];
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: _buildRoutes(),
          overrides: overrides,
          initialLocation: '/email-verify',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('result:success'), findsOneWidget);
    });

    testWidgets('検証期限切れ: /auth-result?status=expiredに遷移する', (tester) async {
      final overrides = [
        emailVerifyResultProvider(
          'test-token',
        ).overrideWith((ref) async => EmailVerifyResult.expired),
      ];
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: _buildRoutes(),
          overrides: overrides,
          initialLocation: '/email-verify',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('result:expired'), findsOneWidget);
    });

    testWidgets('検証無効: /auth-result?status=invalidに遷移する', (tester) async {
      final overrides = [
        emailVerifyResultProvider(
          'test-token',
        ).overrideWith((ref) async => EmailVerifyResult.invalid),
      ];
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: _buildRoutes(),
          overrides: overrides,
          initialLocation: '/email-verify',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('result:invalid'), findsOneWidget);
    });
  });
}
