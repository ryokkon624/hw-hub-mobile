import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../core/models/task_status.dart';
import '../data/my_tasks_repository.dart';
import '../my_tasks_providers.dart';
import 'my_tasks_state.dart';

class MyTasksNotifier extends AutoDisposeAsyncNotifier<MyTasksState> {
  @override
  Future<MyTasksState> build() async {
    final householdState = await ref.watch(householdNotifierProvider.future);
    final selectedHousehold = householdState.selectedHousehold;

    if (selectedHousehold == null) {
      return const MyTasksState();
    }

    return _load(selectedHousehold.id);
  }

  Future<MyTasksState> _load(int householdId) async {
    final repo = ref.read(myTasksRepositoryProvider);
    final results = await Future.wait([
      repo.fetchOpenTasks(householdId: householdId),
      repo.loadCurrentUserId(),
    ]);
    final tasks = results[0] as List<HouseworkTaskDto>;
    final currentUserId = results[1] as int;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final pastTasks = <HouseworkTaskDto>[];
    final futureTasks = <HouseworkTaskDto>[];

    for (final task in tasks) {
      // 自分以外の担当者のタスクはスキップ（未割当タスクは含める）
      if (task.assigneeUserId != null && task.assigneeUserId != currentUserId) {
        continue;
      }
      final date = DateTime.tryParse(task.targetDate);
      if (date == null) continue;
      final taskDate = DateTime(date.year, date.month, date.day);
      if (taskDate.isBefore(today)) {
        pastTasks.add(task);
      } else {
        futureTasks.add(task);
      }
    }

    final currentFilter = state.valueOrNull?.filter ?? MyTasksFilter.all;

    return MyTasksState(
      pastTasks: List.unmodifiable(pastTasks),
      futureTasks: List.unmodifiable(futureTasks),
      filter: currentFilter,
    );
  }

  void setFilter(MyTasksFilter filter) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(filter: filter));
  }

  Future<void> completeTask(int taskId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final repo = ref.read(myTasksRepositoryProvider);
    try {
      await repo.updateTaskStatus(taskId: taskId, status: TaskStatus.done.code);
      state = AsyncData(
        current.copyWith(
          pastTasks: current.pastTasks
              .where((t) => t.houseworkTaskId != taskId)
              .toList(),
          futureTasks: current.futureTasks
              .where((t) => t.houseworkTaskId != taskId)
              .toList(),
        ),
      );
    } catch (_) {
      // 失敗時はリストを変更しない
    }
  }

  Future<void> skipTask(int taskId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final repo = ref.read(myTasksRepositoryProvider);
    try {
      await repo.updateTaskStatus(
        taskId: taskId,
        status: TaskStatus.skipped.code,
      );
      state = AsyncData(
        current.copyWith(
          pastTasks: current.pastTasks
              .where((t) => t.houseworkTaskId != taskId)
              .toList(),
          futureTasks: current.futureTasks
              .where((t) => t.houseworkTaskId != taskId)
              .toList(),
        ),
      );
    } catch (_) {
      // 失敗時はリストを変更しない
    }
  }

  Future<void> bulkCompletePastTasks() async {
    final current = state.valueOrNull;
    if (current == null || current.pastTasks.isEmpty) return;

    final taskIds = current.pastTasks.map((t) => t.houseworkTaskId).toList();
    final repo = ref.read(myTasksRepositoryProvider);
    try {
      await repo.bulkUpdateStatus(
        taskIds: taskIds,
        status: TaskStatus.done.code,
      );
      state = AsyncData(current.copyWith(pastTasks: []));
    } catch (_) {
      // 失敗時はリストを変更しない
    }
  }
}

final myTasksNotifierProvider =
    AsyncNotifierProvider.autoDispose<MyTasksNotifier, MyTasksState>(
      MyTasksNotifier.new,
    );
