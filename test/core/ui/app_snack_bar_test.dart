import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/core/ui/app_snack_bar.dart';

import '../../helpers/widget_test_helpers.dart';

Widget _buildHost(VoidCallback onTap) => buildTestPage(
  Scaffold(
    body: TextButton(onPressed: onTap, child: const Text('show')),
  ),
  withSnackBarKey: true,
);

void main() {
  group('AppSnackBar.showWarning', () {
    testWidgets('警告メッセージと警告アイコンが表示される', (tester) async {
      await tester.pumpWidget(
        _buildHost(() => AppSnackBar.showWarning('警告メッセージ')),
      );
      await tester.tap(find.text('show'));
      await tester.pump();

      expect(find.text('警告メッセージ'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });
  });

  group('AppExceptionSnackBar.showAsSnackBar', () {
    testWidgets('NetworkException: エラースナックバーが表示される', (tester) async {
      await tester.pumpWidget(
        _buildHost(() => const NetworkException('ネットワークエラー').showAsSnackBar()),
      );
      await tester.tap(find.text('show'));
      await tester.pump();

      expect(find.text('ネットワークエラー'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('UnauthorizedException: エラースナックバーが表示される', (tester) async {
      await tester.pumpWidget(
        _buildHost(() => const UnauthorizedException('認証エラー').showAsSnackBar()),
      );
      await tester.tap(find.text('show'));
      await tester.pump();

      expect(find.text('認証エラー'), findsOneWidget);
    });

    testWidgets('ServerException: エラースナックバーが表示される', (tester) async {
      await tester.pumpWidget(
        _buildHost(
          () => const ServerException(message: 'サーバーエラー').showAsSnackBar(),
        ),
      );
      await tester.tap(find.text('show'));
      await tester.pump();

      expect(find.text('サーバーエラー'), findsOneWidget);
    });

    testWidgets('ApiException: エラースナックバーが表示される', (tester) async {
      await tester.pumpWidget(
        _buildHost(() => const ApiException('APIエラー').showAsSnackBar()),
      );
      await tester.tap(find.text('show'));
      await tester.pump();

      expect(find.text('APIエラー'), findsOneWidget);
    });
  });
}
