import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/housework_assign/data/housework_assign_repository.dart';
import 'package:hw_hub_mobile/features/housework_assign/presentation/widgets/member_picker_bottom_sheet.dart';

import '../../../../helpers/widget_test_helpers.dart';

const _member1 = HouseholdMemberDto(
  householdId: 10,
  userId: 1,
  displayName: '山田太郎',
  status: '1',
  role: 'OWNER',
);

const _member2 = HouseholdMemberDto(
  householdId: 10,
  userId: 2,
  displayName: '佐藤花子',
  status: '1',
  role: 'MEMBER',
);

Widget _buildSheet({
  required List<HouseholdMemberDto> members,
  void Function(int? userId, String? nickname)? onSelected,
}) {
  return buildTestPage(
    Scaffold(
      body: MemberPickerBottomSheet(
        members: members,
        onSelected: onSelected ?? (_, __) {},
      ),
    ),
  );
}

void main() {
  group('MemberPickerBottomSheet', () {
    testWidgets('メンバー一覧が表示される（2件）', (tester) async {
      await tester.pumpWidget(_buildSheet(members: [_member1, _member2]));
      await tester.pump();

      expect(find.text('山田太郎'), findsOneWidget);
      expect(find.text('佐藤花子'), findsOneWidget);
    });

    testWidgets('未割当オプションが表示される', (tester) async {
      await tester.pumpWidget(_buildSheet(members: [_member1]));
      await tester.pump();

      // 未割当アイテムのアイコンが存在する
      expect(find.byIcon(Icons.person_off), findsOneWidget);
    });

    testWidgets('メンバーにpersonアイコンが表示される', (tester) async {
      await tester.pumpWidget(_buildSheet(members: [_member1, _member2]));
      await tester.pump();

      expect(find.byIcon(Icons.person), findsNWidgets(2));
    });

    testWidgets('メンバータップでonSelectedがuserId付きで呼ばれる', (tester) async {
      int? selectedUserId;
      await tester.pumpWidget(
        _buildSheet(
          members: [_member1],
          onSelected: (userId, _) => selectedUserId = userId,
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey(1)));
      await tester.pump();

      expect(selectedUserId, 1);
    });

    testWidgets('未割当タップでonSelectedがnullで呼ばれる', (tester) async {
      int? selectedUserId = 99;
      await tester.pumpWidget(
        _buildSheet(
          members: [_member1],
          onSelected: (userId, _) => selectedUserId = userId,
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.person_off));
      await tester.pump();

      expect(selectedUserId, isNull);
    });

    testWidgets('メンバーが0件のとき未割当オプションのみ表示される', (tester) async {
      await tester.pumpWidget(_buildSheet(members: []));
      await tester.pump();

      expect(find.byIcon(Icons.person_off), findsOneWidget);
      expect(find.byIcon(Icons.person), findsNothing);
    });

    testWidgets('show()でモーダルが表示される（static showメソッド分岐）', (tester) async {
      int? selectedUserId;
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => MemberPickerBottomSheet.show(
                  context,
                  members: [_member1, _member2],
                  onSelected: (userId, _) => selectedUserId = userId,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // モーダルが表示される
      expect(find.text('山田太郎'), findsOneWidget);
      expect(find.text('佐藤花子'), findsOneWidget);

      // メンバーをタップするとモーダルが閉じてonSelectedが呼ばれる
      await tester.tap(find.byKey(const ValueKey(1)));
      await tester.pumpAndSettle();

      expect(selectedUserId, 1);
      // モーダルが閉じた
      expect(find.text('山田太郎'), findsNothing);
    });
  });
}
