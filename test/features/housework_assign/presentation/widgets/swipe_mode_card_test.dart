import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/housework_assign/presentation/widgets/swipe_mode_card.dart';
import 'package:hw_hub_mobile/features/tasks/data/models/housework_task_dto.dart';

import '../../../../helpers/widget_test_helpers.dart';

HouseworkTaskDto _task({
  String targetDate = '2099-12-31',
  int? assigneeUserId,
}) => HouseworkTaskDto(
  houseworkTaskId: 1,
  householdId: 1,
  houseworkId: 1,
  houseworkName: 'テストタスク',
  targetDate: targetDate,
  assigneeUserId: assigneeUserId,
  status: '0',
);

Widget _buildCard({
  required VoidCallback onAssignToMe,
  required VoidCallback onNext,
  String targetDate = '2099-12-31',
  int? assigneeUserId,
  String? assigneeIconUrl,
}) => buildTestPage(
  SwipeModeCard(
    task: _task(targetDate: targetDate, assigneeUserId: assigneeUserId),
    onAssignToMe: onAssignToMe,
    onNext: onNext,
    assigneeIconUrl: assigneeIconUrl,
  ),
);

void main() {
  group('SwipeModeCard 表示', () {
    testWidgets('タスク名が表示される', (tester) async {
      await tester.pumpWidget(_buildCard(onAssignToMe: () {}, onNext: () {}));
      await tester.pump();
      expect(find.text('テストタスク'), findsOneWidget);
    });
  });

  group('SwipeModeCard スワイプ方向', () {
    testWidgets('左スワイプ（endToStart）でonAssignToMeが呼ばれる', (tester) async {
      var assignToMeCalled = false;
      await tester.pumpWidget(
        _buildCard(
          onAssignToMe: () {
            assignToMeCalled = true;
          },
          onNext: () {},
        ),
      );
      await tester.pumpAndSettle();

      // 左スワイプ（endToStart）
      await tester.drag(find.text('テストタスク'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(assignToMeCalled, isTrue);
    });

    testWidgets('左スワイプ（endToStart）でonNextは呼ばれない', (tester) async {
      var nextCalled = false;
      await tester.pumpWidget(
        _buildCard(
          onAssignToMe: () {},
          onNext: () {
            nextCalled = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('テストタスク'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(nextCalled, isFalse);
    });

    testWidgets('右スワイプ（startToEnd）でonNextが呼ばれる', (tester) async {
      var nextCalled = false;
      await tester.pumpWidget(
        _buildCard(
          onAssignToMe: () {},
          onNext: () {
            nextCalled = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      // 右スワイプ（startToEnd）
      await tester.drag(find.text('テストタスク'), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(nextCalled, isTrue);
    });

    testWidgets('右スワイプ（startToEnd）でonAssignToMeは呼ばれない', (tester) async {
      var assignToMeCalled = false;
      await tester.pumpWidget(
        _buildCard(
          onAssignToMe: () {
            assignToMeCalled = true;
          },
          onNext: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('テストタスク'), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(assignToMeCalled, isFalse);
    });
  });

  group('SwipeModeCard Overdue 表示', () {
    testWidgets('targetDateが今日より前ならOverdueスタイルで実施日が表示される', (tester) async {
      // 過去日付（Overdue）
      await tester.pumpWidget(
        _buildCard(
          onAssignToMe: () {},
          onNext: () {},
          targetDate: '2020-01-01',
        ),
      );
      await tester.pump();

      // Overdue 表示がある（Container の color や Text の style は
      // ウィジェットの存在確認のみ行う）
      expect(
        find.byKey(const Key('swipe_mode_card_date_container')),
        findsOneWidget,
      );
      final container = tester.widget<Container>(
        find.byKey(const Key('swipe_mode_card_date_container')),
      );
      // Overdue の場合はコンテナに色が設定されている
      expect(container.color, isNotNull);
    });

    testWidgets('targetDateが今日以降なら通常スタイルで実施日が表示される', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          onAssignToMe: () {},
          onNext: () {},
          targetDate: '2099-12-31',
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('swipe_mode_card_date_container')),
        findsOneWidget,
      );
      final container = tester.widget<Container>(
        find.byKey(const Key('swipe_mode_card_date_container')),
      );
      // 通常の場合はコンテナに色が設定されていない
      expect(container.color, isNull);
    });
  });

  group('SwipeModeCard UserAvatar', () {
    testWidgets('assigneeIconUrlを渡すとUserAvatarが表示される', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          onAssignToMe: () {},
          onNext: () {},
          assigneeUserId: 1,
          assigneeIconUrl: 'https://example.com/icon.png',
        ),
      );
      await tester.pump();

      // UserAvatar ウィジェットが表示される
      expect(
        find.byKey(const Key('swipe_mode_card_assignee_avatar')),
        findsOneWidget,
      );
    });

    testWidgets('assigneeUserIdがnullなら未割当UserAvatarが表示される', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          onAssignToMe: () {},
          onNext: () {},
          assigneeUserId: null,
          assigneeIconUrl: null,
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('swipe_mode_card_assignee_avatar')),
        findsOneWidget,
      );
    });

    testWidgets('UserAvatarがカード本体の行レイアウト（左側）に配置される', (tester) async {
      // カードコンテンツのRowを見つけ、UserAvatarが最初の子（左側）であることを確認する
      await tester.pumpWidget(
        _buildCard(
          onAssignToMe: () {},
          onNext: () {},
          assigneeUserId: 1,
          assigneeIconUrl: null,
        ),
      );
      await tester.pump();

      // swipe_mode_card_content_row が存在する（行レイアウト）
      final rowFinder = find.byKey(const Key('swipe_mode_card_content_row'));
      expect(rowFinder, findsOneWidget);

      // swipe_mode_card_assignee_avatar が swipe_mode_card_content_row の子孫に存在する
      // 左側に配置されていることはRowの最初の子であることで確認
      final row = tester.widget<Row>(rowFinder);
      expect(
        row.children.first.key,
        const Key('swipe_mode_card_assignee_avatar'),
      );
    });
  });
}
