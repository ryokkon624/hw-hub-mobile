import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hw_hub_mobile/core/auth/auth_state.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';
import '../data/housework_assign_repository.dart';
import 'housework_assign_notifier.dart';
import 'housework_assign_state.dart';
import 'widgets/assign_filter_chips.dart';
import 'widgets/assignable_task_card.dart';
import 'widgets/bulk_skip_dialog.dart';
import 'widgets/member_picker_bottom_sheet.dart';
import 'widgets/member_summary_strip.dart';
import 'widgets/swipe_date_calendar.dart';
import 'widgets/swipe_mode_card.dart';
import 'widgets/swipe_progress_header.dart';

class HouseworkAssignPage extends ConsumerWidget {
  const HouseworkAssignPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(houseworkAssignNotifierProvider);
    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).houseworkAssignTitle),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).houseworkAssignTitle),
        ),
        body: Center(child: Text(e.toString())),
      ),
      data: (state) {
        if (state.mode == AssignMode.swipe) {
          return _SwipeModePage(state: state);
        }
        return _ListModePage(state: state);
      },
    );
  }
}

// ─── 通常リストモード ────────────────────────────────────────

class _ListModePage extends ConsumerWidget {
  const _ListModePage({required this.state});
  final HouseworkAssignState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(houseworkAssignNotifierProvider.notifier);

    // 現在ログインユーザーIDを取得
    final authAsync = ref.watch(authNotifierProvider);
    final currentUserId = authAsync.valueOrNull is AuthAuthenticated
        ? (authAsync.valueOrNull! as AuthAuthenticated).user.userId
        : -1;

    // フィルタ適用後タスク
    final filteredTasks = _filteredTasks(state, currentUserId);

    // 未割当・割当済みタスク（スワイプボタンの有効化判定 / 件数表示で共用）
    final unassignedForSwipe = state.tasks
        .where((t) => t.assigneeUserId == null)
        .toList();
    final othersForSwipe = state.tasks
        .where((t) => t.assigneeUserId != null)
        .toList();
    final unassignedCount = unassignedForSwipe.length;

    // 過去の未割当タスク（スキップボタン表示用）
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pastUnassigned = unassignedForSwipe.where((t) {
      final date = DateTime.tryParse(t.targetDate);
      if (date == null) return false;
      return DateTime(date.year, date.month, date.day).isBefore(today);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.houseworkAssignTitle)),
      body: Column(
        children: [
          // メンバーサマリ
          MemberSummaryStrip(
            members: state.members,
            memberTaskCounts: state.memberTaskCounts,
            unassignedCount: unassignedCount,
            currentUserId: currentUserId,
          ),
          const Divider(height: 1),

          // 統計情報
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.houseworkAssignUntreatedCountLabel(
                    state.tasks.length,
                    unassignedCount,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (pastUnassigned.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.houseworkAssignPastUnassignedLabel(
                      pastUnassigned.length,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton(
                    onPressed: () async {
                      final confirmed = await BulkSkipDialog.show(
                        context,
                        count: pastUnassigned.length,
                      );
                      if (confirmed) {
                        await notifier.bulkSkipPastUnassigned();
                      }
                    },
                    child: Text(l10n.houseworkAssignBulkSkipButton),
                  ),
                ],
              ],
            ),
          ),

          // スワイプモード起動ボタン
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ElevatedButton(
              onPressed: unassignedForSwipe.isEmpty
                  ? null
                  : () => notifier.startSwipeMode(SwipeTarget.unassigned),
              child: Text(l10n.houseworkAssignStartSwipeUnassigned),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ElevatedButton(
              onPressed: othersForSwipe.isEmpty
                  ? null
                  : () => notifier.startSwipeMode(SwipeTarget.others),
              child: Text(l10n.houseworkAssignStartSwipeOthers),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // フィルタ
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AssignFilterChips(
              selected: state.filter,
              onChanged: (f) => notifier.setFilter(f),
            ),
          ),
          const Divider(height: 1),

          // タスクリスト
          Expanded(
            child: ListView(
              children: [
                ...filteredTasks.map(
                  (task) => Padding(
                    key: ValueKey(task.houseworkTaskId),
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: AssignableTaskCard(
                      task: task,
                      onAssignToMe: () =>
                          notifier.assignToMe(taskId: task.houseworkTaskId),
                      onPickMember: () => MemberPickerBottomSheet.show(
                        context,
                        members: state.members,
                        onSelected: (userId, nickname) =>
                            notifier.assignToMember(
                              taskId: task.houseworkTaskId,
                              assigneeUserId: userId,
                              assigneeNickname: nickname,
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<HouseworkTaskDto> _filteredTasks(
    HouseworkAssignState state,
    int currentUserId,
  ) {
    switch (state.filter) {
      case AssignFilter.all:
        return state.tasks;
      case AssignFilter.unassignedOnly:
        return state.tasks.where((t) => t.assigneeUserId == null).toList();
      case AssignFilter.meAndUnassigned:
        return state.tasks
            .where(
              (t) =>
                  t.assigneeUserId == null || t.assigneeUserId == currentUserId,
            )
            .toList();
    }
  }
}

// ─── スワイプモード ────────────────────────────────────────

class _SwipeModePage extends ConsumerWidget {
  const _SwipeModePage({required this.state});
  final HouseworkAssignState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(houseworkAssignNotifierProvider.notifier);

    // スワイプ対象タスク（スナップショット時点のリストから現在 index のタスクを取得）
    final swipeTasks = state.swipeTarget == SwipeTarget.unassigned
        ? state.tasks.where((t) => t.assigneeUserId == null).toList()
        : state.tasks.where((t) => t.assigneeUserId != null).toList();

    final isFinished = state.swipeIndex >= state.swipeTaskCount;
    final currentTask = (!isFinished && state.swipeIndex < swipeTasks.length)
        ? swipeTasks[state.swipeIndex]
        : null;

    return Scaffold(
      // AC2: AppBar の BackButton を削除（automaticallyImplyLeading: false）
      appBar: AppBar(
        title: Text(l10n.houseworkAssignSwipeModeTitle),
        automaticallyImplyLeading: false,
      ),
      body: isFinished
          ? Center(
              child: Text(
                l10n.houseworkAssignSwipeFinishedMessage,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            )
          : currentTask == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // AC1: 進捗を body 最上部に headlineSmall で中央寄せ表示
                SwipeProgressHeader(
                  current: state.swipeIndex + 1,
                  total: state.swipeTaskCount,
                ),

                // AC3: カレンダー表示（targetDate でハイライト）
                SwipeDateCalendar(targetDate: currentTask.targetDate),

                // スワイプカード
                Expanded(
                  child: Center(
                    child: SwipeModeCard(
                      task: currentTask,
                      onAssignToMe: () => notifier.swipeAssignToMe(),
                      onNext: () => notifier.swipeNext(),
                    ),
                  ),
                ),

                // AC2: 画面下部に「割り当てを中断する」ボタン
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: OutlinedButton(
                      onPressed: () => notifier.exitSwipeMode(),
                      child: Text(l10n.houseworkAssignSwipeExitButton),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
