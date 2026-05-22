import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/housework_assign/presentation/widgets/assignable_task_card.dart';
import 'package:hw_hub_mobile/features/my_tasks/data/models/housework_task_dto.dart';

import '../../../../helpers/widget_test_helpers.dart';

HouseworkTaskDto _task({int? assigneeUserId, String? assigneeNickname}) =>
    HouseworkTaskDto(
      houseworkTaskId: 1,
      householdId: 1,
      houseworkId: 1,
      houseworkName: 'テストタスク',
      targetDate: '2026-05-18',
      assigneeUserId: assigneeUserId,
      assigneeNickname: assigneeNickname,
      status: '0',
    );

Widget _buildCard({
  required Future<bool> Function() onAssignToMe,
  required VoidCallback onPickMember,
}) => buildTestPage(
  AssignableTaskCard(
    task: _task(),
    onAssignToMe: onAssignToMe,
    onPickMember: onPickMember,
  ),
);

void main() {
  group('AssignableTaskCard 表示', () {
    testWidgets('タスク名が表示される', (tester) async {
      await tester.pumpWidget(
        _buildCard(onAssignToMe: () async => true, onPickMember: () {}),
      );
      await tester.pumpAndSettle();
      expect(find.text('テストタスク'), findsOneWidget);
    });
  });

  group('AssignableTaskCard スワイプ方向（AC1・AC2）', () {
    testWidgets('AC1: 左スワイプ（endToStart）でonAssignToMeが呼ばれる', (tester) async {
      var assignToMeCalled = false;
      await tester.pumpWidget(
        _buildCard(
          onAssignToMe: () async {
            assignToMeCalled = true;
            return true;
          },
          onPickMember: () {},
        ),
      );
      await tester.pumpAndSettle();

      // 左スワイプ（endToStart）
      await tester.drag(find.text('テストタスク'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(assignToMeCalled, isTrue);
    });

    testWidgets('AC1: 左スワイプ（endToStart）でonPickMemberは呼ばれない', (tester) async {
      var pickMemberCalled = false;
      await tester.pumpWidget(
        _buildCard(
          onAssignToMe: () async => true,
          onPickMember: () {
            pickMemberCalled = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('テストタスク'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(pickMemberCalled, isFalse);
    });

    testWidgets('AC2: 右スワイプ（startToEnd）でonPickMemberが呼ばれる', (tester) async {
      var pickMemberCalled = false;
      await tester.pumpWidget(
        _buildCard(
          onAssignToMe: () async => false,
          onPickMember: () {
            pickMemberCalled = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      // 右スワイプ（startToEnd）
      await tester.drag(find.text('テストタスク'), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(pickMemberCalled, isTrue);
    });

    testWidgets('AC2: 右スワイプ（startToEnd）でonAssignToMeは呼ばれない', (tester) async {
      var assignToMeCalled = false;
      await tester.pumpWidget(
        _buildCard(
          onAssignToMe: () async {
            assignToMeCalled = true;
            return false;
          },
          onPickMember: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('テストタスク'), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(assignToMeCalled, isFalse);
    });
  });
}
