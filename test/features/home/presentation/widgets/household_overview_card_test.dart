import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/home/presentation/home_state.dart';
import 'package:hw_hub_mobile/features/home/presentation/models/household_member.dart';
import 'package:hw_hub_mobile/features/home/presentation/widgets/household_overview_card.dart';
import 'package:hw_hub_mobile/features/home/presentation/widgets/overview_tooltip_builder.dart';

import '../../../../helpers/widget_test_helpers.dart';

final _today = DateTime(2025, 6, 15);

DailyOverview _day(Map<int?, int> counts) =>
    DailyOverview(date: _today, countsByAssignee: counts);

const _member1 = HouseholdMember(userId: 1, displayName: '山田太郎');
const _member2 = HouseholdMember(userId: 2, displayName: '山田花子');

Widget _buildCard({
  List<DailyOverview>? overview,
  List<HouseholdMember> members = const [],
  bool hasOverviewData = true,
}) {
  return buildTestPage(
    Scaffold(
      body: SingleChildScrollView(
        child: HouseholdOverviewCard(
          overview: overview ?? [_day({})],
          members: members,
          hasOverviewData: hasOverviewData,
        ),
      ),
    ),
  );
}

void main() {
  group('buildTooltipLines', () {
    test('メンバーあり・未割当あり・0件なしの場合に全行が含まれる', () {
      final day = DailyOverview(
        date: DateTime(2025, 6, 15),
        countsByAssignee: {1: 3, 2: 1, null: 2},
      );
      final members = [
        const HouseholdMember(userId: 1, displayName: '山田太郎', nickname: 'パパ'),
        const HouseholdMember(userId: 2, displayName: '山田花子'),
      ];
      final lines = buildTooltipLines(day, members, unassignedLabel: '未割り当て');

      // メンバー行（nickname優先）
      expect(lines, contains('パパ: 3'));
      // nicknameなしはdisplayName
      expect(lines, contains('山田花子: 1'));
      // 未割当は末尾
      expect(lines.last, '未割り当て: 2');
    });

    test('0件のメンバーはスキップされる', () {
      final day = DailyOverview(
        date: DateTime(2025, 6, 15),
        countsByAssignee: {1: 2, 2: 0},
      );
      final members = [
        const HouseholdMember(userId: 1, displayName: '山田太郎'),
        const HouseholdMember(userId: 2, displayName: '山田花子'),
      ];
      final lines = buildTooltipLines(day, members, unassignedLabel: '未割り当て');

      expect(lines, contains('山田太郎: 2'));
      // 0件のメンバーは含まれない
      expect(lines.any((l) => l.contains('山田花子')), isFalse);
    });

    test('全件0の日はデータなし行のみ返される', () {
      final day = DailyOverview(
        date: DateTime(2025, 6, 15),
        countsByAssignee: {1: 0, null: 0},
      );
      final members = [const HouseholdMember(userId: 1, displayName: '山田太郎')];
      final lines = buildTooltipLines(
        day,
        members,
        unassignedLabel: '未割り当て',
        noDataLabel: 'データなし',
      );

      expect(lines, equals(['データなし']));
    });

    test('メンバーなし・未割当のみの場合', () {
      final day = DailyOverview(
        date: DateTime(2025, 6, 15),
        countsByAssignee: {null: 5},
      );
      final lines = buildTooltipLines(day, [], unassignedLabel: '未割り当て');

      expect(lines, equals(['未割り当て: 5']));
    });
  });

  group('HouseholdOverviewCard', () {
    testWidgets('メンバー0件でカードが表示される', (tester) async {
      await tester.pumpWidget(_buildCard());
      await tester.pump();

      expect(find.byType(HouseholdOverviewCard), findsOneWidget);
    });

    testWidgets('メンバーがいる場合に凡例ドットが表示される', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          overview: [
            _day({1: 2, 2: 1}),
          ],
          members: [_member1, _member2],
        ),
      );
      await tester.pump();

      expect(find.byType(HouseholdOverviewCard), findsOneWidget);
    });

    testWidgets('メンバーに割り当てられたタスクがある場合にチャートが表示される', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          overview: List.generate(
            13,
            (i) => DailyOverview(
              date: _today.add(Duration(days: i - 6)),
              countsByAssignee: {1: 2},
            ),
          ),
          members: [_member1],
        ),
      );
      await tester.pump();

      expect(find.byType(HouseholdOverviewCard), findsOneWidget);
    });

    testWidgets('未割当タスクがある場合にチャートが表示される', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          overview: [
            _day({null: 3}),
          ],
          members: [],
        ),
      );
      await tester.pump();

      expect(find.byType(HouseholdOverviewCard), findsOneWidget);
    });

    testWidgets('メンバーとunassigned両方あるカードが表示される', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          overview: [
            DailyOverview(date: _today, countsByAssignee: {1: 2, null: 1}),
          ],
          members: [_member1],
        ),
      );
      await tester.pump();

      expect(find.byType(HouseholdOverviewCard), findsOneWidget);
    });

    testWidgets('メンバーにnicknameがある場合に凡例にnicknameが使われる', (tester) async {
      const memberWithNickname = HouseholdMember(
        userId: 3,
        displayName: '山田三郎',
        nickname: 'サブロー',
      );
      await tester.pumpWidget(
        _buildCard(
          overview: [
            _day({3: 1}),
          ],
          members: [memberWithNickname],
        ),
      );
      await tester.pump();

      expect(find.byType(HouseholdOverviewCard), findsOneWidget);
    });

    testWidgets('6人以上のメンバーがいる場合でもカードが表示される', (tester) async {
      final manyMembers = List.generate(
        7,
        (i) => HouseholdMember(userId: i + 1, displayName: 'メンバー${i + 1}'),
      );
      await tester.pumpWidget(
        _buildCard(
          overview: [
            DailyOverview(
              date: _today,
              countsByAssignee: {for (var i = 1; i <= 7; i++) i: 1},
            ),
          ],
          members: manyMembers,
        ),
      );
      await tester.pump();

      expect(find.byType(HouseholdOverviewCard), findsOneWidget);
    });

    testWidgets('hasOverviewData=falseの場合に空状態が表示されBarChartが表示されない', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCard(
          overview: List.generate(
            13,
            (i) => DailyOverview(
              date: _today.add(Duration(days: i - 6)),
              countsByAssignee: {},
            ),
          ),
          hasOverviewData: false,
        ),
      );
      await tester.pump();

      // 空状態ウィジェットが表示されている
      expect(find.byKey(const Key('overviewEmpty')), findsOneWidget);
      // BarChartが表示されていない
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('hasOverviewData=trueの場合にBarChartが表示され空状態が表示されない', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCard(
          overview: [
            DailyOverview(date: _today, countsByAssignee: {1: 2}),
          ],
          members: [_member1],
          hasOverviewData: true,
        ),
      );
      await tester.pump();

      // BarChartが表示されている
      expect(find.byType(BarChart), findsOneWidget);
      // 空状態ウィジェットが表示されていない
      expect(find.byKey(const Key('overviewEmpty')), findsNothing);
    });
  });
}
