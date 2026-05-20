import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/inquiry/presentation/widgets/inquiry_category_badge.dart';
import 'package:hw_hub_mobile/features/inquiry/presentation/widgets/inquiry_status_badge.dart';

import '../../../../helpers/widget_test_helpers.dart';

Widget _buildCategoryBadge(String code) =>
    buildTestPage(Scaffold(body: InquiryCategoryBadge(categoryCode: code)));

Widget _buildStatusBadge(String code) =>
    buildTestPage(Scaffold(body: InquiryStatusBadge(statusCode: code)));

void main() {
  group('InquiryCategoryBadge', () {
    testWidgets('general(10): ウィジェットが表示される', (tester) async {
      await tester.pumpWidget(_buildCategoryBadge('10'));
      await tester.pump();

      expect(find.byType(InquiryCategoryBadge), findsOneWidget);
    });

    testWidgets('housework(20): ウィジェットが表示される', (tester) async {
      await tester.pumpWidget(_buildCategoryBadge('20'));
      await tester.pump();

      expect(find.byType(InquiryCategoryBadge), findsOneWidget);
    });

    testWidgets('shopping(21): ウィジェットが表示される', (tester) async {
      await tester.pumpWidget(_buildCategoryBadge('21'));
      await tester.pump();

      expect(find.byType(InquiryCategoryBadge), findsOneWidget);
    });

    testWidgets('accountSettings(30): ウィジェットが表示される', (tester) async {
      await tester.pumpWidget(_buildCategoryBadge('30'));
      await tester.pump();

      expect(find.byType(InquiryCategoryBadge), findsOneWidget);
    });

    testWidgets('bugReport(40): ウィジェットが表示される', (tester) async {
      await tester.pumpWidget(_buildCategoryBadge('40'));
      await tester.pump();

      expect(find.byType(InquiryCategoryBadge), findsOneWidget);
    });

    testWidgets('other(90): ウィジェットが表示される', (tester) async {
      await tester.pumpWidget(_buildCategoryBadge('90'));
      await tester.pump();

      expect(find.byType(InquiryCategoryBadge), findsOneWidget);
    });

    testWidgets('unknown: ウィジェットが表示される（nullフォールバック）', (tester) async {
      await tester.pumpWidget(_buildCategoryBadge('99'));
      await tester.pump();

      expect(find.byType(InquiryCategoryBadge), findsOneWidget);
    });
  });

  group('InquiryStatusBadge', () {
    testWidgets('open(00): ウィジェットが表示される', (tester) async {
      await tester.pumpWidget(_buildStatusBadge('00'));
      await tester.pump();

      expect(find.byType(InquiryStatusBadge), findsOneWidget);
    });

    testWidgets('aiAnswered(10): ウィジェットが表示される', (tester) async {
      await tester.pumpWidget(_buildStatusBadge('10'));
      await tester.pump();

      expect(find.byType(InquiryStatusBadge), findsOneWidget);
    });

    testWidgets('pendingStaff(20): ウィジェットが表示される', (tester) async {
      await tester.pumpWidget(_buildStatusBadge('20'));
      await tester.pump();

      expect(find.byType(InquiryStatusBadge), findsOneWidget);
    });

    testWidgets('staffAnswered(30): ウィジェットが表示される', (tester) async {
      await tester.pumpWidget(_buildStatusBadge('30'));
      await tester.pump();

      expect(find.byType(InquiryStatusBadge), findsOneWidget);
    });

    testWidgets('closed(90): ウィジェットが表示される', (tester) async {
      await tester.pumpWidget(_buildStatusBadge('90'));
      await tester.pump();

      expect(find.byType(InquiryStatusBadge), findsOneWidget);
    });

    testWidgets('unknown: ウィジェットが表示される（nullフォールバック）', (tester) async {
      await tester.pumpWidget(_buildStatusBadge('99'));
      await tester.pump();

      expect(find.byType(InquiryStatusBadge), findsOneWidget);
    });
  });
}
