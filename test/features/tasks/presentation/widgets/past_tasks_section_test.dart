import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/tasks/data/models/housework_task_dto.dart';
import 'package:hw_hub_mobile/features/tasks/presentation/my_tasks_notifier.dart';
import 'package:hw_hub_mobile/features/tasks/presentation/my_tasks_state.dart';
import 'package:hw_hub_mobile/features/tasks/presentation/widgets/past_tasks_section.dart';
import 'package:hw_hub_mobile/features/tasks/presentation/widgets/swipeable_task_card.dart';

import '../../../../helpers/widget_test_helpers.dart';

String _dateStr(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _daysAgo(int days) =>
    _dateStr(DateTime.now().subtract(Duration(days: days)));

HouseworkTaskDto _task({int id = 1, String? targetDate}) => HouseworkTaskDto(
  houseworkTaskId: id,
  householdId: 1,
  houseworkId: id,
  houseworkName: '過去タスク$id',
  targetDate: targetDate ?? _daysAgo(1),
  assigneeUserId: 10,
  status: '0',
);

class _FakeMyTasksNotifier extends MyTasksNotifier {
  _FakeMyTasksNotifier(this._state);
  final MyTasksState _state;

  @override
  Future<MyTasksState> build() async => _state;
}

Widget _buildSection({required List<HouseworkTaskDto> tasks}) {
  final notifier = _FakeMyTasksNotifier(
    MyTasksState(futureTasks: [], pastTasks: tasks),
  );
  return buildTestPage(
    Scaffold(
      body: SingleChildScrollView(child: PastTasksSection(tasks: tasks)),
    ),
    overrides: [myTasksNotifierProvider.overrideWith(() => notifier)],
  );
}

void main() {
  group('PastTasksSection', () {
    testWidgets('タスク0件のとき SizedBox.shrink が返る（セクション非表示）', (tester) async {
      await tester.pumpWidget(_buildSection(tasks: []));
      await tester.pump();

      expect(find.byType(PastTasksSection), findsOneWidget);
      // タスクがないので内部コンテンツは表示されない
      expect(find.byType(SwipeableTaskCard), findsNothing);
    });

    testWidgets('タスク1件: SwipeableTaskCard が1枚表示される', (tester) async {
      await tester.pumpWidget(
        _buildSection(tasks: [_task(id: 1, targetDate: _daysAgo(1))]),
      );
      await tester.pump();

      expect(find.byType(SwipeableTaskCard), findsOneWidget);
    });

    testWidgets('タスク2件（異なる日付）: SwipeableTaskCard が2枚表示される', (tester) async {
      await tester.pumpWidget(
        _buildSection(
          tasks: [
            _task(id: 1, targetDate: _daysAgo(1)),
            _task(id: 2, targetDate: _daysAgo(2)),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(SwipeableTaskCard), findsNWidgets(2));
    });

    testWidgets('タスク2件（同じ日付）: グループ化されて2枚表示される', (tester) async {
      await tester.pumpWidget(
        _buildSection(
          tasks: [
            _task(id: 1, targetDate: _daysAgo(1)),
            _task(id: 2, targetDate: _daysAgo(1)),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(SwipeableTaskCard), findsNWidgets(2));
    });

    testWidgets('一括完了ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        _buildSection(tasks: [_task(id: 1, targetDate: _daysAgo(1))]),
      );
      await tester.pump();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('一括完了ボタンタップで BulkCompleteDialog が表示される', (tester) async {
      await tester.pumpWidget(
        _buildSection(tasks: [_task(id: 1, targetDate: _daysAgo(1))]),
      );
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('一括完了ダイアログのキャンセルでダイアログが閉じる', (tester) async {
      await tester.pumpWidget(
        _buildSection(tasks: [_task(id: 1, targetDate: _daysAgo(1))]),
      );
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      final cancelButtons = find.byType(TextButton);
      await tester.tap(cancelButtons.first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
