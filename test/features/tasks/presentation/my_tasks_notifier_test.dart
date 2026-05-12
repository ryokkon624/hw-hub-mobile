import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/features/tasks/data/models/housework_task_dto.dart';
import 'package:hw_hub_mobile/features/tasks/data/my_tasks_repository.dart';
import 'package:hw_hub_mobile/features/tasks/my_tasks_providers.dart';
import 'package:hw_hub_mobile/features/tasks/presentation/my_tasks_notifier.dart';
import 'package:hw_hub_mobile/features/tasks/presentation/my_tasks_state.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tasks_mocks.mocks.dart';

String _dateStr(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _today() => _dateStr(DateTime.now());
String _daysFromNow(int days) =>
    _dateStr(DateTime.now().add(Duration(days: days)));

HouseworkTaskDto _task({
  int id = 1,
  String? targetDate,
  int? assigneeUserId = 10,
}) => HouseworkTaskDto(
  houseworkTaskId: id,
  householdId: 1,
  houseworkId: 1,
  houseworkName: 'テストタスク$id',
  targetDate: targetDate ?? _today(),
  assigneeUserId: assigneeUserId,
  status: '0',
);

ProviderContainer _makeContainer({
  required MockMyTasksRepository mockRepo,
  Household? selectedHousehold,
}) {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer(
    overrides: [
      myTasksRepositoryProvider.overrideWithValue(mockRepo),
      householdNotifierProvider.overrideWith(
        () => _FakeHouseholdNotifier(
          HouseholdState(
            households: selectedHousehold != null ? [selectedHousehold] : [],
            selectedHousehold: selectedHousehold,
          ),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late MockMyTasksRepository mockRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepo = MockMyTasksRepository();
    // loadCurrentUserId はデフォルト userId=10 を返す（_task の assigneeUserId デフォルトと一致）
    when(mockRepo.loadCurrentUserId()).thenAnswer((_) async => 10);
  });

  group('MyTasksNotifier 担当者フィルタ', () {
    test('自分以外の assigneeUserId のタスクは past/future に含まれない', () async {
      const h = Household(id: 1, name: '山田家');
      // userId=10 が自分、userId=99 が他人
      when(mockRepo.loadCurrentUserId()).thenAnswer((_) async => 10);
      final tasks = [
        _task(id: 1, targetDate: _today(), assigneeUserId: 10), // 自分
        _task(id: 2, targetDate: _today(), assigneeUserId: 99), // 他人
        _task(
          id: 3,
          targetDate: _daysFromNow(-1),
          assigneeUserId: 10,
        ), // 自分（過去）
        _task(
          id: 4,
          targetDate: _daysFromNow(-1),
          assigneeUserId: 99,
        ), // 他人（過去）
        _task(id: 5, targetDate: _today(), assigneeUserId: null), // 未割当
      ];
      when(
        mockRepo.fetchOpenTasks(householdId: 1),
      ).thenAnswer((_) async => tasks);

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );

      final state = await container.read(myTasksNotifierProvider.future);

      // 自分（id=1）と未割当（id=5）のみ future に含まれる
      expect(state.futureTasks, hasLength(2));
      expect(
        state.futureTasks.map((t) => t.houseworkTaskId),
        containsAll([1, 5]),
      );
      // 他人（id=2, 4）は含まれない
      expect(state.futureTasks.any((t) => t.houseworkTaskId == 2), isFalse);

      // 自分（id=3）のみ past に含まれる
      expect(state.pastTasks, hasLength(1));
      expect(state.pastTasks.first.houseworkTaskId, 3);
      // 他人（id=4）は含まれない
      expect(state.pastTasks.any((t) => t.houseworkTaskId == 4), isFalse);
    });
  });

  group('MyTasksNotifier.build()', () {
    test('世帯未所属時: 空の状態を返す', () async {
      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: null,
      );

      final state = await container.read(myTasksNotifierProvider.future);

      expect(state.pastTasks, isEmpty);
      expect(state.futureTasks, isEmpty);
      verifyNever(
        mockRepo.fetchOpenTasks(householdId: anyNamed('householdId')),
      );
    });

    test('世帯所属時: 過去タスクと未来タスクを振り分ける', () async {
      const h = Household(id: 1, name: '山田家');
      final tasks = [
        _task(id: 1, targetDate: _daysFromNow(-1)), // 過去
        _task(id: 2, targetDate: _today()), // 今日（future）
        _task(id: 3, targetDate: _daysFromNow(1)), // 未来
      ];
      when(
        mockRepo.fetchOpenTasks(householdId: 1),
      ).thenAnswer((_) async => tasks);

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );

      final state = await container.read(myTasksNotifierProvider.future);

      expect(state.pastTasks, hasLength(1));
      expect(state.pastTasks.first.houseworkTaskId, 1);
      expect(state.futureTasks, hasLength(2));
    });

    test('API失敗時: AsyncErrorになる', () async {
      const h = Household(id: 1, name: '山田家');
      when(
        mockRepo.fetchOpenTasks(householdId: 1),
      ).thenThrow(Exception('Network error'));

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );
      container.listen(myTasksNotifierProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final result = container.read(myTasksNotifierProvider);
      expect(result.hasError, isTrue);
    });
  });

  group('MyTasksNotifier フィルタ', () {
    test('filterを今日に変えると今日のタスクのみfilteredFutureTasksに含まれる', () async {
      const h = Household(id: 1, name: '山田家');
      final tasks = [
        _task(id: 1, targetDate: _today()),
        _task(id: 2, targetDate: _daysFromNow(1)),
      ];
      when(
        mockRepo.fetchOpenTasks(householdId: 1),
      ).thenAnswer((_) async => tasks);

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );
      await container.read(myTasksNotifierProvider.future);

      container
          .read(myTasksNotifierProvider.notifier)
          .setFilter(MyTasksFilter.today);

      final state = container.read(myTasksNotifierProvider).value!;
      expect(state.filter, MyTasksFilter.today);
      expect(state.filteredFutureTasks, hasLength(1));
      expect(state.filteredFutureTasks.first.houseworkTaskId, 1);
    });

    test('filterを1週間に変えると7日以内のタスクのみ含まれる', () async {
      const h = Household(id: 1, name: '山田家');
      final tasks = [
        _task(id: 1, targetDate: _today()),
        _task(id: 2, targetDate: _daysFromNow(6)),
        _task(id: 3, targetDate: _daysFromNow(8)),
      ];
      when(
        mockRepo.fetchOpenTasks(householdId: 1),
      ).thenAnswer((_) async => tasks);

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );
      await container.read(myTasksNotifierProvider.future);

      container
          .read(myTasksNotifierProvider.notifier)
          .setFilter(MyTasksFilter.week);

      final state = container.read(myTasksNotifierProvider).value!;
      expect(state.filteredFutureTasks, hasLength(2));
    });
  });

  group('MyTasksNotifier.completeTask()', () {
    test('完了成功時: タスクがリストから削除される', () async {
      const h = Household(id: 1, name: '山田家');
      final tasks = [_task(id: 1, targetDate: _today())];
      when(
        mockRepo.fetchOpenTasks(householdId: 1),
      ).thenAnswer((_) async => tasks);
      when(
        mockRepo.updateTaskStatus(taskId: 1, status: '1'),
      ).thenAnswer((_) async {});

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );
      await container.read(myTasksNotifierProvider.future);

      await container.read(myTasksNotifierProvider.notifier).completeTask(1);

      final state = container.read(myTasksNotifierProvider).value!;
      expect(state.futureTasks.any((t) => t.houseworkTaskId == 1), isFalse);
    });

    test('完了失敗時: タスクがリストに残る', () async {
      const h = Household(id: 1, name: '山田家');
      final tasks = [_task(id: 1, targetDate: _today())];
      when(
        mockRepo.fetchOpenTasks(householdId: 1),
      ).thenAnswer((_) async => tasks);
      when(
        mockRepo.updateTaskStatus(taskId: 1, status: '1'),
      ).thenThrow(Exception('Error'));

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );
      await container.read(myTasksNotifierProvider.future);

      await container.read(myTasksNotifierProvider.notifier).completeTask(1);

      final state = container.read(myTasksNotifierProvider).value!;
      expect(state.futureTasks.any((t) => t.houseworkTaskId == 1), isTrue);
    });
  });

  group('MyTasksNotifier.skipTask()', () {
    test('スキップ成功時: タスクがリストから削除される', () async {
      const h = Household(id: 1, name: '山田家');
      final tasks = [_task(id: 1, targetDate: _today())];
      when(
        mockRepo.fetchOpenTasks(householdId: 1),
      ).thenAnswer((_) async => tasks);
      when(
        mockRepo.updateTaskStatus(taskId: 1, status: '2'),
      ).thenAnswer((_) async {});

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );
      await container.read(myTasksNotifierProvider.future);

      await container.read(myTasksNotifierProvider.notifier).skipTask(1);

      final state = container.read(myTasksNotifierProvider).value!;
      expect(state.futureTasks.any((t) => t.houseworkTaskId == 1), isFalse);
    });
  });

  group('MyTasksNotifier.bulkCompletePastTasks()', () {
    test('一括完了成功時: 過去タスクがリストから消える', () async {
      const h = Household(id: 1, name: '山田家');
      final tasks = [
        _task(id: 1, targetDate: _daysFromNow(-1)),
        _task(id: 2, targetDate: _daysFromNow(-2)),
      ];
      when(
        mockRepo.fetchOpenTasks(householdId: 1),
      ).thenAnswer((_) async => tasks);
      when(
        mockRepo.bulkUpdateStatus(taskIds: [1, 2], status: '1'),
      ).thenAnswer((_) async {});

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );
      await container.read(myTasksNotifierProvider.future);

      await container
          .read(myTasksNotifierProvider.notifier)
          .bulkCompletePastTasks();

      final state = container.read(myTasksNotifierProvider).value!;
      expect(state.pastTasks, isEmpty);
    });

    test('一括完了失敗時: 過去タスクがリストに残る', () async {
      const h = Household(id: 1, name: '山田家');
      final tasks = [_task(id: 1, targetDate: _daysFromNow(-1))];
      when(
        mockRepo.fetchOpenTasks(householdId: 1),
      ).thenAnswer((_) async => tasks);
      when(
        mockRepo.bulkUpdateStatus(taskIds: [1], status: '1'),
      ).thenThrow(Exception('Error'));

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );
      await container.read(myTasksNotifierProvider.future);

      await container
          .read(myTasksNotifierProvider.notifier)
          .bulkCompletePastTasks();

      final state = container.read(myTasksNotifierProvider).value!;
      expect(state.pastTasks, hasLength(1));
    });
  });
}

class _FakeHouseholdNotifier extends HouseholdNotifier {
  _FakeHouseholdNotifier(this._state);
  final HouseholdState _state;

  @override
  Future<HouseholdState> build() async => _state;

  @override
  Future<void> select(Household household) async {}
}
