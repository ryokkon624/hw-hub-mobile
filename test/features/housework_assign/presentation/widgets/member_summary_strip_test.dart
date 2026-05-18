import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/home/data/models/household_member_dto.dart';
import 'package:hw_hub_mobile/features/housework_assign/presentation/widgets/member_summary_strip.dart';

import '../../../../helpers/widget_test_helpers.dart';

HouseholdMemberDto _member({
  required int userId,
  required String displayName,
  String? nickname,
}) => HouseholdMemberDto(
  householdId: 1,
  userId: userId,
  displayName: displayName,
  nickname: nickname,
  status: 'ACTIVE',
  role: 'MEMBER',
);

Widget _buildStrip({
  required List<HouseholdMemberDto> members,
  Map<int, int> memberTaskCounts = const {},
  int unassignedCount = 0,
  int currentUserId = 1,
}) => buildTestPage(
  SingleChildScrollView(
    child: MemberSummaryStrip(
      members: members,
      memberTaskCounts: memberTaskCounts,
      unassignedCount: unassignedCount,
      currentUserId: currentUserId,
    ),
  ),
);

void main() {
  group('MemberSummaryStrip 基本表示', () {
    testWidgets('未割当チップが表示される', (tester) async {
      await tester.pumpWidget(_buildStrip(members: [], unassignedCount: 3));
      await tester.pumpAndSettle();
      expect(find.text('未割当'), findsOneWidget);
    });

    testWidgets('メンバー件数が表示される', (tester) async {
      final members = [_member(userId: 10, displayName: 'テスト')];
      await tester.pumpWidget(
        _buildStrip(
          members: members,
          memberTaskCounts: {10: 2},
          unassignedCount: 1,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('MemberSummaryStrip #110: nicknameフォールバック（AC1）', () {
    testWidgets('AC1: nicknameが設定されている場合はnicknameが表示される', (tester) async {
      final members = [
        _member(userId: 10, displayName: 'displayNameUser', nickname: 'ニックネーム'),
      ];
      await tester.pumpWidget(_buildStrip(members: members));
      await tester.pumpAndSettle();

      expect(find.text('ニックネーム'), findsOneWidget);
      expect(find.text('displayNameUser'), findsNothing);
    });

    testWidgets('AC1: nicknameが未設定（null）の場合はdisplayNameが表示される', (tester) async {
      final members = [
        _member(userId: 10, displayName: 'displayNameUser', nickname: null),
      ];
      await tester.pumpWidget(_buildStrip(members: members));
      await tester.pumpAndSettle();

      expect(find.text('displayNameUser'), findsOneWidget);
    });

    testWidgets('AC1: nicknameが空文字の場合はdisplayNameが表示される', (tester) async {
      final members = [
        _member(userId: 10, displayName: 'displayNameUser', nickname: ''),
      ];
      await tester.pumpWidget(_buildStrip(members: members));
      await tester.pumpAndSettle();

      expect(find.text('displayNameUser'), findsOneWidget);
      expect(find.text(''), findsNothing);
    });
  });

  group('MemberSummaryStrip #111: 全メンバー表示・Wrap折り返し（AC1・AC2）', () {
    testWidgets('AC1: 4名以上のメンバーが全員表示される（Wrap折り返し）', (tester) async {
      // 4名のメンバーを設定（水平スクロールでは1名欠ける問題の再現条件）
      final members = List.generate(
        4,
        (i) => _member(userId: i + 1, displayName: 'メンバー${i + 1}'),
      );
      await tester.pumpWidget(_buildStrip(members: members));
      await tester.pumpAndSettle();

      for (var i = 1; i <= 4; i++) {
        expect(find.text('メンバー$i'), findsOneWidget, reason: 'メンバー$iが表示されること');
      }
    });

    testWidgets('AC2: Wrapウィジェットが使用されている（折り返しレイアウト）', (tester) async {
      final members = [_member(userId: 1, displayName: 'メンバー1')];
      await tester.pumpWidget(_buildStrip(members: members));
      await tester.pumpAndSettle();

      // Wrap ウィジェットが使われていること（ListView の代わりに）
      expect(find.byType(Wrap), findsOneWidget);
      // ListView(水平スクロール)が使われていないこと
      expect(
        find.byWidgetPredicate(
          (w) => w is ListView && w.scrollDirection == Axis.horizontal,
        ),
        findsNothing,
      );
    });
  });
}
