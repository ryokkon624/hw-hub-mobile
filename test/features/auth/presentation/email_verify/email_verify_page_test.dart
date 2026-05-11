import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/auth/presentation/email_verify/email_verify_notifier.dart';
import 'package:hw_hub_mobile/features/auth/presentation/email_verify/email_verify_page.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  group('EmailVerifyPage', () {
    testWidgets('トークン検証中はCircularProgressIndicatorが表示される', (tester) async {
      // Completer を使うことでタイマーを作らずに未完了の Future を提供する
      final completer = Completer<EmailVerifyResult>();
      await tester.pumpWidget(buildTestPage(
        const EmailVerifyPage(token: 'test-token'),
        overrides: [
          emailVerifyResultProvider('test-token').overrideWith(
            (ref) => completer.future,
          ),
        ],
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
