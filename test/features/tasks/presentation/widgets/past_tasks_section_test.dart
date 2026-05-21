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

  @override
  Future<void> bulkCompletePastTasks() async {}
}

class _RecordingMyTasksNotifier extends MyTasksNotifier {
  _RecordingMyTasksNotifier(this._state);
  final MyTasksState _state;

  int? completedTaskId;
  int? skippedTaskId;

  @override
  Future<MyTasksState> build() async => _state;

  @override
  Future<void> bulkCompletePastTasks() async {}

  @override
  Future<void> completeTask(int taskId) async {
    completedTaskId = taskId;
  }

  @override
  Future<void> skipTask(int taskId) async {
    skippedTaskId = taskId;
  }
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

Widget _buildSectionWithRecorder({
  required List<HouseworkTaskDto> tasks,
  required _RecordingMyTasksNotifier notifier,
}) => buildTestPage(
  Scaffold(
    body: SingleChildScrollView(child: PastTasksSection(tasks: tasks)),
  ),
  overrides: [myTasksNotifierProvider.overrideWith(() => notifier)],
);

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

    testWidgets('一括完了ダイアログの確認ボタンでbulkCompletePastTasksが呼ばれる', (tester) async {
      await tester.pumpWidget(
        _buildSection(tasks: [_task(id: 1, targetDate: _daysAgo(1))]),
      );
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // 確認ボタン（2番目のTextButton）をタップ
      final buttons = find.byType(TextButton);
      await tester.tap(buttons.last);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('不正な日付文字列のタスクが表示される（null date parse分岐）', (tester) async {
      final invalidTask = HouseworkTaskDto(
        houseworkTaskId: 99,
        householdId: 1,
        houseworkId: 99,
        houseworkName: '不正日付タスク',
        targetDate: 'invalid-date',
        assigneeUserId: 10,
        status: '0',
      );
      await tester.pumpWidget(_buildSection(tasks: [invalidTask]));
      await tester.pump();

      expect(find.byType(SwipeableTaskCard), findsOneWidget);
    });

    testWidgets('タスクを右スワイプするとonCompleteコールバックが呼ばれる', (tester) async {
      final task = _task(id: 10, targetDate: _daysAgo(1));
      final notifier = _RecordingMyTasksNotifier(
        MyTasksState(futureTasks: [], pastTasks: [task]),
      );
      await tester.pumpWidget(
        _buildSectionWithRecorder(tasks: [task], notifier: notifier),
      );
      await tester.pump();

      await tester.drag(find.byType(Dismissible), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(notifier.completedTaskId, 10);
    });

    testWidgets('タスクを左スワイプするとonSkipコールバックが呼ばれる', (tester) async {
      final task = _task(id: 11, targetDate: _daysAgo(1));
      final notifier = _RecordingMyTasksNotifier(
        MyTasksState(futureTasks: [], pastTasks: [task]),
      );
      await tester.pumpWidget(
        _buildSectionWithRecorder(tasks: [task], notifier: notifier),
      );
      await tester.pump();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(notifier.skippedTaskId, 11);
    });

    testWidgets('一括完了ダイアログの確認後にbulkCompletePastTasksが呼ばれる', (tester) async {
      final task = _task(id: 5, targetDate: _daysAgo(1));
      final notifier = _RecordingMyTasksNotifier(
        MyTasksState(futureTasks: [], pastTasks: [task]),
      );
      await tester.pumpWidget(
        _buildSectionWithRecorder(tasks: [task], notifier: notifier),
      );
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      final buttons = find.byType(TextButton);
      await tester.tap(buttons.last);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
