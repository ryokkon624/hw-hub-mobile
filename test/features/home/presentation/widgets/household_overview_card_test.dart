import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/home/presentation/home_state.dart';
import 'package:hw_hub_mobile/features/home/presentation/models/household_member.dart';
import 'package:hw_hub_mobile/features/home/presentation/widgets/household_overview_card.dart';

import '../../../../helpers/widget_test_helpers.dart';

final _today = DateTime(2025, 6, 15);

DailyOverview _day(Map<int?, int> counts) =>
    DailyOverview(date: _today, countsByAssignee: counts);

const _member1 = HouseholdMember(userId: 1, displayName: '山田太郎');
const _member2 = HouseholdMember(userId: 2, displayName: '山田花子');

Widget _buildCard({
  List<DailyOverview>? overview,
  List<HouseholdMember> members = const [],
}) {
  return buildTestPage(
    Scaffold(
      body: SingleChildScrollView(
        child: HouseholdOverviewCard(
          overview: overview ?? [_day({})],
          members: members,
        ),
      ),
    ),
  );
}

void main() {
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
  });
}
