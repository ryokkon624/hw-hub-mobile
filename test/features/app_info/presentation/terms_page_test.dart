import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/app_info/presentation/terms_page.dart';

import '../../../helpers/widget_test_helpers.dart';

void main() {
  group('TermsPage', () {
    testWidgets('スクロール可能なコンテンツが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(const TermsPage()));
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('利用規約の各条文セクションが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(const TermsPage()));
      await tester.pump();

      expect(find.byKey(const Key('termsArticle1')), findsOneWidget);
      expect(find.byKey(const Key('termsArticle2')), findsOneWidget);
      expect(find.byKey(const Key('termsArticle3')), findsOneWidget);
      expect(find.byKey(const Key('termsArticle4')), findsOneWidget);
      expect(find.byKey(const Key('termsArticle5')), findsOneWidget);
      expect(find.byKey(const Key('termsArticle6')), findsOneWidget);
    });

    testWidgets('注記が表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(const TermsPage()));
      await tester.pump();

      expect(find.byKey(const Key('termsNote')), findsOneWidget);
    });
  });
}
