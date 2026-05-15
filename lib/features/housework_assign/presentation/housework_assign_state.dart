import '../data/housework_assign_repository.dart';

enum AssignFilter { all, unassignedOnly, meAndUnassigned }

enum AssignMode { list, swipe }

enum SwipeTarget { unassigned, others }

class HouseworkAssignState {
  const HouseworkAssignState({
    this.tasks = const [],
    this.members = const [],
    this.filter = AssignFilter.all,
    this.mode = AssignMode.list,
    this.swipeTarget = SwipeTarget.unassigned,
    this.swipeIndex = 0,
    this.swipeTaskCount = 0,
    this.isBusy = false,
    this.errorMessage,
  });

  final List<HouseworkTaskDto> tasks;
  final List<HouseholdMemberDto> members;
  final AssignFilter filter;
  final AssignMode mode;
  final SwipeTarget swipeTarget;
  final int swipeIndex;

  /// スワイプモード開始時の対象タスク総数（スナップショット）
  final int swipeTaskCount;

  final bool isBusy;
  final String? errorMessage;

  HouseworkAssignState copyWith({
    List<HouseworkTaskDto>? tasks,
    List<HouseholdMemberDto>? members,
    AssignFilter? filter,
    AssignMode? mode,
    SwipeTarget? swipeTarget,
    int? swipeIndex,
    int? swipeTaskCount,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HouseworkAssignState(
      tasks: tasks ?? this.tasks,
      members: members ?? this.members,
      filter: filter ?? this.filter,
      mode: mode ?? this.mode,
      swipeTarget: swipeTarget ?? this.swipeTarget,
      swipeIndex: swipeIndex ?? this.swipeIndex,
      swipeTaskCount: swipeTaskCount ?? this.swipeTaskCount,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
