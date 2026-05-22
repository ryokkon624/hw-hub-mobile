import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/my_tasks/data/models/housework_task_dto.dart';
import 'package:hw_hub_mobile/features/my_tasks/presentation/widgets/swipeable_task_card.dart';

import '../../../../helpers/widget_test_helpers.dart';

HouseworkTaskDto _task({int id = 1, String name = 'テストタスク'}) =>
    HouseworkTaskDto(
      houseworkTaskId: id,
      householdId: 1,
      houseworkId: id,
      houseworkName: name,
      targetDate: '2026-05-20',
      assigneeUserId: 10,
      status: '0',
    );

Widget _buildCard({
  HouseworkTaskDto? task,
  bool isPast = false,
  bool isToday = false,
  VoidCallback? onComplete,
  VoidCallback? onSkip,
}) => buildTestPage(
  Scaffold(
    body: SwipeableTaskCard(
      task: task ?? _task(),
      onComplete: onComplete ?? () {},
      onSkip: onSkip ?? () {},
      isPast: isPast,
      isToday: isToday,
    ),
  ),
);

void main() {
  group('SwipeableTaskCard', () {
    testWidgets('タスク名が表示される', (tester) async {
      await tester.pumpWidget(_buildCard(task: _task(name: 'テスト家事')));
      await tester.pump();

      expect(find.text('テスト家事'), findsOneWidget);
    });

    testWidgets('デフォルト状態（isPast=false, isToday=false）でウィジェットが表示される', (
      tester,
    ) async {
      await tester.pumpWidget(_buildCard());
      await tester.pump();

      expect(find.byType(SwipeableTaskCard), findsOneWidget);
    });

    testWidgets('isPast=true でウィジェットが表示される', (tester) async {
      await tester.pumpWidget(_buildCard(isPast: true));
      await tester.pump();

      expect(find.byType(SwipeableTaskCard), findsOneWidget);
    });

    testWidgets('isToday=true でウィジェットが表示される', (tester) async {
      await tester.pumpWidget(_buildCard(isToday: true));
      await tester.pump();

      expect(find.byType(SwipeableTaskCard), findsOneWidget);
    });

    testWidgets('Dismissible ウィジェットが存在する', (tester) async {
      await tester.pumpWidget(_buildCard());
      await tester.pump();

      expect(find.byType(Dismissible), findsOneWidget);
    });

    testWidgets('右スワイプで onComplete が呼ばれる', (tester) async {
      bool completed = false;
      await tester.pumpWidget(_buildCard(onComplete: () => completed = true));
      await tester.pump();

      await tester.drag(find.byType(Dismissible), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('左スワイプで onSkip が呼ばれる', (tester) async {
      bool skipped = false;
      await tester.pumpWidget(_buildCard(onSkip: () => skipped = true));
      await tester.pump();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(skipped, isTrue);
    });
  });
}
