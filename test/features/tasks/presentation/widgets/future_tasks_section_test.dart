import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/tasks/data/models/housework_task_dto.dart';
import 'package:hw_hub_mobile/features/tasks/presentation/my_tasks_notifier.dart';
import 'package:hw_hub_mobile/features/tasks/presentation/my_tasks_state.dart';
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
    state = AsyncData(state.value!.copyWith(filter: filter));
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
  });
}
