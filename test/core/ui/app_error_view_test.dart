import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/core/ui/app_error_view.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  group('AppErrorView', () {
    testWidgets('エラーアイコン・メッセージ・再読み込みボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(AppErrorView(message: 'テストエラーメッセージ', onRetry: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('appErrorViewIcon')), findsOneWidget);
      expect(find.byKey(const Key('appErrorViewMessage')), findsOneWidget);
      expect(find.byKey(const Key('appErrorViewRetryButton')), findsOneWidget);
    });

    testWidgets('再読み込みボタンをタップするとonRetryが呼ばれる', (tester) async {
      var retryCalled = false;
      await tester.pumpWidget(
        buildTestPage(
          AppErrorView(
            message: 'テストエラーメッセージ',
            onRetry: () => retryCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('appErrorViewRetryButton')));
      await tester.pump();

      expect(retryCalled, isTrue);
    });
  });

  group('resolveErrorMessage', () {
    /// AppLocalizations を取得するためのヘルパー
    Future<AppLocalizations> captureL10n(WidgetTester tester) async {
      late AppLocalizations captured;
      await tester.pumpWidget(
        buildTestPage(
          Builder(
            builder: (context) {
              captured = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return captured;
    }

    testWidgets('NetworkExceptionのときerrorNetworkを返す', (tester) async {
      final l10n = await captureL10n(tester);

      final result = resolveErrorMessage(const NetworkException(), l10n);
      expect(result, l10n.errorNetwork);
    });

    testWidgets('UnauthorizedExceptionのときerrorUnauthorizedを返す', (tester) async {
      final l10n = await captureL10n(tester);

      final result = resolveErrorMessage(const UnauthorizedException(), l10n);
      expect(result, l10n.errorUnauthorized);
    });

    testWidgets('ServerExceptionのときerrorServerを返す', (tester) async {
      final l10n = await captureL10n(tester);

      final result = resolveErrorMessage(
        const ServerException(message: 'サーバーエラー'),
        l10n,
      );
      expect(result, l10n.errorServer);
    });

    testWidgets('ApiExceptionのときそのmessageを返す', (tester) async {
      final l10n = await captureL10n(tester);

      final result = resolveErrorMessage(
        const ApiException('APIエラーメッセージ'),
        l10n,
      );
      expect(result, 'APIエラーメッセージ');
    });

    testWidgets('未知のExceptionのときerrorUnexpectedを返す', (tester) async {
      final l10n = await captureL10n(tester);

      final result = resolveErrorMessage(Exception('未知のエラー'), l10n);
      expect(result, l10n.errorUnexpected);
    });
  });
}
