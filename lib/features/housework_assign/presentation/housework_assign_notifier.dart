import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/di/providers.dart';
import '../../../core/models/task_assign_reason.dart';
import '../../../core/network/app_exception.dart';
import '../data/housework_assign_repository.dart';
import '../housework_assign_providers.dart';
import 'housework_assign_state.dart';

class HouseworkAssignNotifier
    extends AutoDisposeAsyncNotifier<HouseworkAssignState> {
  @override
  Future<HouseworkAssignState> build() async {
    final householdState = await ref.watch(householdNotifierProvider.future);
    final selectedHousehold = householdState.selectedHousehold;
    if (selectedHousehold == null) {
      return const HouseworkAssignState();
    }
    return _load(selectedHousehold.id);
  }

  Future<HouseworkAssignState> _load(int householdId) async {
    final repo = ref.read(houseworkAssignRepositoryProvider);
    final results = await Future.wait([
      repo.fetchTasks(householdId: householdId),
      repo.fetchMembers(householdId: householdId),
    ]);
    final tasks = results[0] as List<HouseworkTaskDto>;
    final members = results[1] as List<HouseholdMemberDto>;
    final current = state.valueOrNull;
    return HouseworkAssignState(
      tasks: tasks,
      members: members,
      filter: current?.filter ?? AssignFilter.all,
      mode: AssignMode.list,
      swipeTarget: SwipeTarget.unassigned,
      swipeIndex: 0,
    );
  }

  void setFilter(AssignFilter filter) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(filter: filter, clearError: true));
  }

  void startSwipeMode(SwipeTarget target) {
    final current = state.valueOrNull;
    if (current == null) return;
    // スワイプモード開始時に対象タスク数をスナップショットとして保持
    final count = _swipeTargetTasksFor(current.tasks, target).length;
    state = AsyncData(
      current.copyWith(
        mode: AssignMode.swipe,
        swipeTarget: target,
        swipeIndex: 0,
        swipeTaskCount: count,
        clearError: true,
      ),
    );
  }

  void exitSwipeMode() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(mode: AssignMode.list, clearError: true),
    );
  }

  /// スワイプモードで次のカードに進む（割り当てなし）
  Future<void> swipeNext() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final nextIndex = current.swipeIndex + 1;
    if (nextIndex >= current.swipeTaskCount) {
      // 全カード消化 → リスト再取得してリストモードへ
      await _reloadAndExitSwipe();
    } else {
      state = AsyncData(current.copyWith(swipeIndex: nextIndex));
    }
  }

  /// 左スワイプ: 自分に割り当て（通常リストモード）
  Future<bool> assignToMe({required int taskId}) async {
    final current = state.valueOrNull;
    if (current == null) return false;
    final authState = await ref.read(authNotifierProvider.future);
    if (authState is! AuthAuthenticated) return false;
    final myUserId = authState.user.userId;

    final repo = ref.read(houseworkAssignRepositoryProvider);
    try {
      await repo.updateAssignee(taskId: taskId, assigneeUserId: myUserId);
      // タスクリスト内の該当タスクの assigneeUserId を更新
      final updated = current.tasks.map((t) {
        if (t.houseworkTaskId == taskId) {
          return HouseworkTaskDto(
            houseworkTaskId: t.houseworkTaskId,
            householdId: t.householdId,
            houseworkId: t.houseworkId,
            houseworkName: t.houseworkName,
            categoryCode: t.categoryCode,
            targetDate: t.targetDate,
            assigneeUserId: myUserId,
            assigneeNickname: authState.user.displayName,
            status: t.status,
            assignReasonType: TaskAssignReason.selfAssigned.code,
            doneAt: t.doneAt,
            skippedReason: t.skippedReason,
          );
        }
        return t;
      }).toList();
      state = AsyncData(current.copyWith(tasks: updated, clearError: true));
      return true;
    } on AppException catch (e) {
      state = AsyncData(current.copyWith(errorMessage: e.message));
      return false;
    } catch (_) {
      state = AsyncData(
        current.copyWith(errorMessage: 'houseworkAssignErrorAssign'),
      );
      return false;
    }
  }

  /// 右スワイプ: 指定メンバーに割り当て（通常リストモード / メンバー選択モーダルから）
  Future<bool> assignToMember({
    required int taskId,
    required int? assigneeUserId,
    String? assigneeNickname,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return false;

    final repo = ref.read(houseworkAssignRepositoryProvider);
    try {
      await repo.updateAssignee(taskId: taskId, assigneeUserId: assigneeUserId);
      final updated = current.tasks.map((t) {
        if (t.houseworkTaskId == taskId) {
          return HouseworkTaskDto(
            houseworkTaskId: t.houseworkTaskId,
            householdId: t.householdId,
            houseworkId: t.houseworkId,
            houseworkName: t.houseworkName,
            categoryCode: t.categoryCode,
            targetDate: t.targetDate,
            assigneeUserId: assigneeUserId,
            assigneeNickname: assigneeNickname,
            status: t.status,
            assignReasonType: TaskAssignReason.selfAssigned.code,
            doneAt: t.doneAt,
            skippedReason: t.skippedReason,
          );
        }
        return t;
      }).toList();
      state = AsyncData(current.copyWith(tasks: updated, clearError: true));
      return true;
    } on AppException catch (e) {
      state = AsyncData(current.copyWith(errorMessage: e.message));
      return false;
    } catch (_) {
      state = AsyncData(
        current.copyWith(errorMessage: 'houseworkAssignErrorAssign'),
      );
      return false;
    }
  }

  /// スワイプモードで自分に割り当てて次へ
  Future<void> swipeAssignToMe() async {
    final current = state.valueOrNull;
    if (current == null) return;
    // スナップショット（swipeTaskCount）ベースで対象タスクを取得
    final swipeTasks = _swipeTargetTasksFor(current.tasks, current.swipeTarget);
    if (current.swipeIndex >= swipeTasks.length) return;

    final task = swipeTasks[current.swipeIndex];
    await assignToMe(taskId: task.houseworkTaskId);

    final updated = state.valueOrNull;
    if (updated == null) return;
    final nextIndex = updated.swipeIndex + 1;
    // swipeTaskCount（スナップショット）と比較して全消化判定
    if (nextIndex >= updated.swipeTaskCount) {
      await _reloadAndExitSwipe();
    } else {
      state = AsyncData(updated.copyWith(swipeIndex: nextIndex));
    }
  }

  /// 過去の未割当を一括スキップ
  Future<void> bulkSkipPastUnassigned() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pastUnassigned = current.tasks.where((t) {
      if (t.assigneeUserId != null) return false;
      final date = DateTime.tryParse(t.targetDate);
      if (date == null) return false;
      final taskDate = DateTime(date.year, date.month, date.day);
      return taskDate.isBefore(today);
    }).toList();

    if (pastUnassigned.isEmpty) return;
    final taskIds = pastUnassigned.map((t) => t.houseworkTaskId).toList();

    final repo = ref.read(houseworkAssignRepositoryProvider);
    try {
      await repo.bulkSkipPastUnassigned(taskIds: taskIds);
      final remaining = current.tasks
          .where((t) => !taskIds.contains(t.houseworkTaskId))
          .toList();
      state = AsyncData(current.copyWith(tasks: remaining, clearError: true));
    } on AppException catch (e) {
      state = AsyncData(current.copyWith(errorMessage: e.message));
    } catch (_) {
      state = AsyncData(
        current.copyWith(errorMessage: 'houseworkAssignErrorBulkSkip'),
      );
    }
  }

  List<HouseworkTaskDto> _swipeTargetTasksFor(
    List<HouseworkTaskDto> tasks,
    SwipeTarget target,
  ) {
    if (target == SwipeTarget.unassigned) {
      return tasks.where((t) => t.assigneeUserId == null).toList();
    } else {
      // others: 担当者ありのタスク
      return tasks.where((t) => t.assigneeUserId != null).toList();
    }
  }

  Future<void> _reloadAndExitSwipe() async {
    final householdState = await ref.read(householdNotifierProvider.future);
    final selectedHousehold = householdState.selectedHousehold;
    if (selectedHousehold == null) {
      state = const AsyncData(HouseworkAssignState());
      return;
    }
    try {
      final newState = await _load(selectedHousehold.id);
      state = AsyncData(newState.copyWith(mode: AssignMode.list));
    } catch (e) {
      final current = state.valueOrNull ?? const HouseworkAssignState();
      state = AsyncData(current.copyWith(mode: AssignMode.list));
    }
  }
}

final houseworkAssignNotifierProvider =
    AsyncNotifierProvider.autoDispose<
      HouseworkAssignNotifier,
      HouseworkAssignState
    >(HouseworkAssignNotifier.new);
