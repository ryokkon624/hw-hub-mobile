import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../data/models/home_raw_data.dart';
import '../home_providers.dart';
import 'home_state.dart';
import 'models/household_member.dart';
import 'models/shopping_item.dart';

final homeNotifierProvider =
    AsyncNotifierProvider.autoDispose<HomeNotifier, HomeState>(
      HomeNotifier.new,
    );

class HomeNotifier extends AutoDisposeAsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async {
    final householdState = await ref.watch(householdNotifierProvider.future);
    final selectedHousehold = householdState.selectedHousehold;

    if (selectedHousehold == null) {
      return const HomeState(hasHousehold: false);
    }

    return _load(selectedHousehold.id);
  }

  Future<HomeState> _load(int householdId) async {
    final repo = ref.read(homeRepositoryProvider);
    final raw = await repo.loadAll(householdId);

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final myTasksSummary = _calcMyTasksSummary(raw, todayDate);
    final unassignedSummary = _calcUnassignedSummary(raw, todayDate);
    final householdOverview = _calcDailyOverview(raw, todayDate);

    // DTOからプレゼンテーション用モデルに変換
    final shoppingItems = raw.shoppingItems
        .map(
          (dto) => ShoppingItem(
            shoppingItemId: dto.shoppingItemId,
            name: dto.name,
            storeType: dto.storeType,
            status: dto.status,
            createdAt: dto.createdAt,
          ),
        )
        .toList();

    final members = raw.members
        .map(
          (dto) => HouseholdMember(
            userId: dto.userId,
            displayName: dto.displayName,
            iconUrl: dto.iconUrl,
            nickname: dto.nickname,
          ),
        )
        .toList();

    return HomeState(
      myTasksSummary: myTasksSummary,
      unassignedSummary: unassignedSummary,
      shoppingItems: shoppingItems,
      householdOverview: householdOverview,
      members: members,
      hasHousehold: true,
    );
  }

  Future<void> refresh() async {
    final householdState = ref.read(householdNotifierProvider).valueOrNull;
    final selectedHousehold = householdState?.selectedHousehold;
    if (selectedHousehold == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(selectedHousehold.id));
  }
}

/// My Tasks 集計。
/// assigneeUserId が null でないタスク（割り当て済み）を対象に today/week/overdue を計算する。
/// NOTE: Phase 4 でユーザーID取得を実装する際に、自分のタスクのみに絞り込みを追加する。
MyTasksSummary _calcMyTasksSummary(HomeRawData raw, DateTime todayDate) {
  // assigneeUserId が有効（null でない）タスクを「自分のタスク」として扱う（Phase 4 で絞り込み予定）
  final myTasks = raw.openTasks.where((t) => t.assigneeUserId != null).toList();

  int todayCount = 0;
  int weekCount = 0;
  int overdueCount = 0;

  final weekEnd = todayDate.add(const Duration(days: 7));

  for (final task in myTasks) {
    final taskDate = _parseDate(task.targetDate);
    if (taskDate == null) continue;

    if (taskDate.isBefore(todayDate)) {
      overdueCount++;
    } else if (taskDate.isAtSameMomentAs(todayDate)) {
      todayCount++;
      weekCount++;
    } else if (taskDate.isBefore(weekEnd)) {
      weekCount++;
    }
  }

  return MyTasksSummary(
    todayCount: todayCount,
    weekCount: weekCount,
    overdueCount: overdueCount,
  );
}

/// 未割り当てタスク集計。openTasks から assigneeUserId == null のタスクを集計する。
UnassignedSummary _calcUnassignedSummary(HomeRawData raw, DateTime todayDate) {
  final urgentEnd = todayDate.add(const Duration(days: 3));
  int totalCount = 0;
  int urgentCount = 0;

  for (final task in raw.openTasks) {
    if (task.assigneeUserId != null) continue;
    totalCount++;
    final taskDate = _parseDate(task.targetDate);
    if (taskDate == null) continue;
    if (!taskDate.isBefore(todayDate) && !taskDate.isAfter(urgentEnd)) {
      urgentCount++;
    }
  }

  return UnassignedSummary(totalCount: totalCount, urgentCount: urgentCount);
}

/// おうちの様子（13日分の日別タスク数）を集計する。open + done 両方が対象。
List<DailyOverview> _calcDailyOverview(HomeRawData raw, DateTime todayDate) {
  final allTasks = [...raw.openTasks, ...raw.doneTasks];
  final days = List.generate(13, (i) => todayDate.add(Duration(days: i - 6)));

  return days.map((day) {
    final Map<int?, int> counts = {};
    for (final task in allTasks) {
      final taskDate = _parseDate(task.targetDate);
      if (taskDate == null) continue;
      if (taskDate.year == day.year &&
          taskDate.month == day.month &&
          taskDate.day == day.day) {
        final key = task.assigneeUserId;
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    return DailyOverview(date: day, countsByAssignee: counts);
  }).toList();
}

DateTime? _parseDate(String dateStr) {
  try {
    return DateTime.parse(dateStr);
  } catch (_) {
    return null;
  }
}
