import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/di/providers.dart';
import '../../../core/models/task_assign_reason.dart';
import '../../../core/network/app_exception.dart';
import '../data/housework_assign_repository.dart';
import '../housework_assign_providers.dart';

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
      memberTaskCounts: _computeMemberTaskCounts(tasks),
      memberIconUrls: _computeMemberIconUrls(members),
      filter: current?.filter ?? AssignFilter.all,
      mode: AssignMode.list,
      swipeTarget: SwipeTarget.unassigned,
      swipeIndex: 0,
    );
  }

  /// userId → アイコン URL マップを一括計算する（O(メンバー数)）
  Map<int, String?> _computeMemberIconUrls(List<HouseholdMemberDto> members) {
    return {for (final m in members) m.userId: m.iconUrl};
  }

  /// userId → 未対応タスク件数マップを一括計算する（O(タスク数)）
  Map<int, int> _computeMemberTaskCounts(List<HouseworkTaskDto> tasks) {
    final counts = <int, int>{};
    for (final t in tasks) {
      final uid = t.assigneeUserId;
      if (uid != null) {
        counts[uid] = (counts[uid] ?? 0) + 1;
      }
    }
    return counts;
  }

  void setFilter(AssignFilter filter) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(filter: filter, clearError: true));
  }

  void startSwipeMode(SwipeTarget target, int currentUserId) {
    final current = state.valueOrNull;
    if (current == null) return;
    // スワイプモード開始時に対象タスク数をスナップショットとして保持
    final count = _swipeTargetTasksFor(
      current.tasks,
      target,
      currentUserId,
    ).length;
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

    bool success = false;
    final repo = ref.read(houseworkAssignRepositoryProvider);
    await _runCatching(current, (c) async {
      await repo.updateAssignee(taskId: taskId, assigneeUserId: myUserId);
      // タスクリスト内の該当タスクの assigneeUserId を更新
      final updated = c.tasks.map((t) {
        if (t.houseworkTaskId == taskId) {
          return t.copyWith(
            assigneeUserId: myUserId,
            assigneeNickname: authState.user.displayName,
            assignReasonType: TaskAssignReason.selfAssigned.code,
          );
        }
        return t;
      }).toList();
      state = AsyncData(
        c.copyWith(
          tasks: updated,
          memberTaskCounts: _computeMemberTaskCounts(updated),
          clearError: true,
        ),
      );
      success = true;
    }, unexpectedErrorKey: 'houseworkAssignErrorAssign');
    return success;
  }

  /// 右スワイプ: 指定メンバーに割り当て（通常リストモード / メンバー選択モーダルから）
  Future<bool> assignToMember({
    required int taskId,
    required int? assigneeUserId,
    String? assigneeNickname,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return false;

    bool success = false;
    final repo = ref.read(houseworkAssignRepositoryProvider);
    await _runCatching(current, (c) async {
      await repo.updateAssignee(taskId: taskId, assigneeUserId: assigneeUserId);
      final updated = c.tasks.map((t) {
        if (t.houseworkTaskId == taskId) {
          return t.copyWith(
            assigneeUserId: assigneeUserId,
            assigneeNickname: assigneeNickname,
            assignReasonType: TaskAssignReason.selfAssigned.code,
          );
        }
        return t;
      }).toList();
      state = AsyncData(
        c.copyWith(
          tasks: updated,
          memberTaskCounts: _computeMemberTaskCounts(updated),
          clearError: true,
        ),
      );
      success = true;
    }, unexpectedErrorKey: 'houseworkAssignErrorAssign');
    return success;
  }

  /// スワイプモードで自分に割り当てて次へ
  Future<void> swipeAssignToMe() async {
    final current = state.valueOrNull;
    if (current == null) return;
    // currentUserId を取得してフィルタに渡す
    final authState = await ref.read(authNotifierProvider.future);
    final myUserId = authState is AuthAuthenticated
        ? authState.user.userId
        : -1;
    // スナップショット（swipeTaskCount）ベースで対象タスクを取得
    final swipeTasks = _swipeTargetTasksFor(
      current.tasks,
      current.swipeTarget,
      myUserId,
    );
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
    await _runCatching(current, (c) async {
      await repo.bulkSkipPastUnassigned(taskIds: taskIds);
      final remaining = c.tasks
          .where((t) => !taskIds.contains(t.houseworkTaskId))
          .toList();
      state = AsyncData(
        c.copyWith(
          tasks: remaining,
          memberTaskCounts: _computeMemberTaskCounts(remaining),
          clearError: true,
        ),
      );
    }, unexpectedErrorKey: 'houseworkAssignErrorBulkSkip');
  }

  /// AsyncNotifier 向けエラーハンドリングヘルパー。
  Future<void> _runCatching(
    HouseworkAssignState current,
    Future<void> Function(HouseworkAssignState c) operation, {
    String unexpectedErrorKey = 'errorUnexpected',
  }) async {
    try {
      await operation(current);
    } on AppException catch (e) {
      state = AsyncData(current.copyWith(errorMessage: e.message));
    } catch (_) {
      state = AsyncData(current.copyWith(errorMessage: unexpectedErrorKey));
    }
  }

  List<HouseworkTaskDto> _swipeTargetTasksFor(
    List<HouseworkTaskDto> tasks,
    SwipeTarget target,
    int currentUserId,
  ) {
    if (target == SwipeTarget.unassigned) {
      return tasks.where((t) => t.assigneeUserId == null).toList();
    } else {
      // others: 担当者ありかつ自分以外のタスク（自分のタスクは除外）
      return tasks
          .where(
            (t) =>
                t.assigneeUserId != null && t.assigneeUserId != currentUserId,
          )
          .toList();
    }
  }

  /// 手動リロード（pull-to-refresh 用）。
  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
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
