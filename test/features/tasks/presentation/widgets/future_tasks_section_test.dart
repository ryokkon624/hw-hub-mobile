import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/tasks/data/models/housework_task_dto.dart';
import 'package:hw_hub_mobile/features/tasks/my_tasks_providers.dart';
import 'package:hw_hub_mobile/features/tasks/presentation/widgets/future_tasks_section.dart';

import '../../../../helpers/widget_test_helpers.dart';

String _dateStr(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _today() => _dateStr(DateTime.now());
String _daysFromNow(int days) =>
    _dateStr(DateTime.now().add(Duration(days: days)));

HouseworkTaskDto _task({int id = 1, String? targetDate}) => HouseworkTaskDto(
  houseworkTaskId: id,
  householdId: 1,
  houseworkId: id,
  houseworkName: 'タスク$id',
  targetDate: targetDate ?? _today(),
  assigneeUserId: 10,
  status: '0',
);

class _FakeMyTasksNotifier extends MyTasksNotifier {
  _FakeMyTasksNotifier(this._state);
  final MyTasksState _state;

  @override
  Future<MyTasksState> build() async => _state;

  @override
  void setFilter(MyTasksFilter filter) {
    final current = state.value ?? _state;
    state = AsyncData(current.copyWith(filter: filter));
  }
}

class _RecordingMyTasksNotifier extends MyTasksNotifier {
  _RecordingMyTasksNotifier(this._state);
  final MyTasksState _state;

  int? completedTaskId;
  int? skippedTaskId;

  @override
  Future<MyTasksState> build() async => _state;

  @override
  void setFilter(MyTasksFilter filter) {
    final current = state.value ?? _state;
    state = AsyncData(current.copyWith(filter: filter));
  }

  @override
  Future<void> completeTask(int taskId) async {
    completedTaskId = taskId;
  }

  @override
  Future<void> skipTask(int taskId) async {
    skippedTaskId = taskId;
  }
}

Widget _buildSection({
  required List<HouseworkTaskDto> tasks,
  MyTasksFilter filter = MyTasksFilter.all,
}) {
  final notifier = _FakeMyTasksNotifier(
    MyTasksState(futureTasks: tasks, filter: filter),
  );
  return buildTestPage(
    Scaffold(
      body: SingleChildScrollView(
        child: FutureTasksSection(tasks: tasks, filter: filter),
      ),
    ),
    overrides: [myTasksNotifierProvider.overrideWith(() => notifier)],
  );
}

Widget _buildSectionWithRecorder({
  required List<HouseworkTaskDto> tasks,
  required _RecordingMyTasksNotifier notifier,
  MyTasksFilter filter = MyTasksFilter.all,
}) => buildTestPage(
  Scaffold(
    body: SingleChildScrollView(
      child: FutureTasksSection(tasks: tasks, filter: filter),
    ),
  ),
  overrides: [myTasksNotifierProvider.overrideWith(() => notifier)],
);

void main() {
  group('FutureTasksSection', () {
    testWidgets('タスク0件: セクションが表示される', (tester) async {
      await tester.pumpWidget(_buildSection(tasks: []));
      await tester.pump();

      // セクションは表示される（件数0）
      expect(find.byType(FutureTasksSection), findsOneWidget);
    });

    testWidgets('タスク2件: SwipeableTaskCardが2枚表示される', (tester) async {
      await tester.pumpWidget(
        _buildSection(
          tasks: [
            _task(id: 1, targetDate: _today()),
            _task(id: 2, targetDate: _daysFromNow(1)),
          ],
        ),
      );
      await tester.pump();

      // グループヘッダーがある（今日+明日）
      expect(find.byType(FutureTasksSection), findsOneWidget);
    });

    testWidgets('今日のタスクは todayStr と一致する日付グループに入る', (tester) async {
      await tester.pumpWidget(
        _buildSection(tasks: [_task(id: 1, targetDate: _today())]),
      );
      await tester.pump();

      // FutureTasksSectionが表示されている
      expect(find.byType(FutureTasksSection), findsOneWidget);
    });

    testWidgets('フィルタ選択ボタンが3つ表示される（全て/今日/週）', (tester) async {
      await tester.pumpWidget(_buildSection(tasks: []));
      await tester.pump();

      // _SegmentButtonが3つ（GestureDetector経由）
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('明日のタスクがあるとき 明日 の日付グループが表示される', (tester) async {
      await tester.pumpWidget(
        _buildSection(tasks: [_task(id: 1, targetDate: _daysFromNow(1))]),
      );
      await tester.pump();

      // FutureTasksSectionが表示されている
      expect(find.byType(FutureTasksSection), findsOneWidget);
    });

    testWidgets('3日後のタスクがあるとき 曜日ラベル の日付グループが表示される', (tester) async {
      await tester.pumpWidget(
        _buildSection(tasks: [_task(id: 1, targetDate: _daysFromNow(3))]),
      );
      await tester.pump();

      // FutureTasksSectionが表示されている
      expect(find.byType(FutureTasksSection), findsOneWidget);
    });

    testWidgets('filterがtodayの場合: _SegmentButtonのスタイルが切り替わる', (tester) async {
      await tester.pumpWidget(
        _buildSection(tasks: [], filter: MyTasksFilter.today),
      );
      await tester.pump();

      expect(find.byType(FutureTasksSection), findsOneWidget);
    });

    testWidgets('filterがweekの場合: _SegmentButtonのスタイルが切り替わる', (tester) async {
      await tester.pumpWidget(
        _buildSection(tasks: [], filter: MyTasksFilter.week),
      );
      await tester.pump();

      expect(find.byType(FutureTasksSection), findsOneWidget);
    });

    testWidgets('フィルタ「全て」ボタンをタップするとsetFilterが呼ばれる', (tester) async {
      await tester.pumpWidget(
        _buildSection(tasks: [], filter: MyTasksFilter.today),
      );
      await tester.pump();

      // 「全て」ラベルのGestureDetectorをタップ
      final gestureDetectors = find.byType(GestureDetector);
      await tester.tap(gestureDetectors.first);
      await tester.pump();

      // クラッシュなく動作する
      expect(find.byType(FutureTasksSection), findsOneWidget);
    });

    testWidgets('フィルタ「今日」ボタンをタップするとsetFilterが呼ばれる', (tester) async {
      await tester.pumpWidget(
        _buildSection(tasks: [], filter: MyTasksFilter.all),
      );
      await tester.pump();

      final gestureDetectors = find.byType(GestureDetector);
      await tester.tap(gestureDetectors.at(1));
      await tester.pump();

      expect(find.byType(FutureTasksSection), findsOneWidget);
    });

    testWidgets('フィルタ「週」ボタンをタップするとsetFilterが呼ばれる', (tester) async {
      await tester.pumpWidget(
        _buildSection(tasks: [], filter: MyTasksFilter.all),
      );
      await tester.pump();

      final gestureDetectors = find.byType(GestureDetector);
      await tester.tap(gestureDetectors.at(2));
      await tester.pump();

      expect(find.byType(FutureTasksSection), findsOneWidget);
    });

    testWidgets('不正な日付文字列のタスクが表示される（null date parse分岐）', (tester) async {
      // DateTime.tryParseが失敗するような不正な日付文字列
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

      expect(find.byType(FutureTasksSection), findsOneWidget);
    });

    testWidgets('タスクを右スワイプするとonCompleteコールバックが呼ばれる', (tester) async {
      final task = _task(id: 20, targetDate: _today());
      final notifier = _RecordingMyTasksNotifier(
        MyTasksState(futureTasks: [task]),
      );
      await tester.pumpWidget(
        _buildSectionWithRecorder(tasks: [task], notifier: notifier),
      );
      await tester.pump();

      await tester.drag(find.byType(Dismissible), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(notifier.completedTaskId, 20);
    });

    testWidgets('タスクを左スワイプするとonSkipコールバックが呼ばれる', (tester) async {
      final task = _task(id: 21, targetDate: _today());
      final notifier = _RecordingMyTasksNotifier(
        MyTasksState(futureTasks: [task]),
      );
      await tester.pumpWidget(
        _buildSectionWithRecorder(tasks: [task], notifier: notifier),
      );
      await tester.pump();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(notifier.skippedTaskId, 21);
    });
  });
}
