import '../data/my_tasks_repository.dart';

enum MyTasksFilter { all, today, week }

class MyTasksState {
  const MyTasksState({
    this.pastTasks = const [],
    this.futureTasks = const [],
    this.filter = MyTasksFilter.all,
    this.errorMessage,
  });

  final List<HouseworkTaskDto> pastTasks;
  final List<HouseworkTaskDto> futureTasks;
  final MyTasksFilter filter;

  /// 操作エラー時のメッセージ（i18nキー名 or AppExceptionのメッセージ）
  final String? errorMessage;

  List<HouseworkTaskDto> get filteredFutureTasks {
    if (filter == MyTasksFilter.all) return futureTasks;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));

    return futureTasks.where((task) {
      final date = DateTime.tryParse(task.targetDate);
      if (date == null) return false;
      final taskDate = DateTime(date.year, date.month, date.day);
      if (filter == MyTasksFilter.today) {
        return taskDate.isAtSameMomentAs(today);
      }
      // week: 今日から7日以内（今日含む、7日後含まない）
      return !taskDate.isBefore(today) && taskDate.isBefore(weekEnd);
    }).toList();
  }

  MyTasksState copyWith({
    List<HouseworkTaskDto>? pastTasks,
    List<HouseworkTaskDto>? futureTasks,
    MyTasksFilter? filter,
    Object? errorMessage = _myTasksSentinel,
  }) {
    return MyTasksState(
      pastTasks: pastTasks ?? this.pastTasks,
      futureTasks: futureTasks ?? this.futureTasks,
      filter: filter ?? this.filter,
      errorMessage: errorMessage == _myTasksSentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

// null をリセット指定と区別するためのセンチネル値
const _myTasksSentinel = Object();
