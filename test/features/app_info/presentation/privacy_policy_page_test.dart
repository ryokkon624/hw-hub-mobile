import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/app_info/presentation/privacy_policy_page.dart';

import '../../../helpers/widget_test_helpers.dart';

void main() {
  group('PrivacyPolicyPage', () {
    testWidgets('スクロール可能なコンテンツが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(const PrivacyPolicyPage()));
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('プライバシーポリシーの各セクションが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(const PrivacyPolicyPage()));
      await tester.pump();

      expect(find.byKey(const Key('privacySection1')), findsOneWidget);
      expect(find.byKey(const Key('privacySection2')), findsOneWidget);
      expect(find.byKey(const Key('privacySection3')), findsOneWidget);
      expect(find.byKey(const Key('privacySection4')), findsOneWidget);
      expect(find.byKey(const Key('privacySection5')), findsOneWidget);
      expect(find.byKey(const Key('privacySection6')), findsOneWidget);
    });

    testWidgets('注記が表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(const PrivacyPolicyPage()));
      await tester.pump();

      expect(find.byKey(const Key('privacyNote')), findsOneWidget);
    });
  });
}
