import 'models/household_member.dart';
import 'models/shopping_item.dart';

class HomeState {
  const HomeState({
    this.myTasksSummary = const MyTasksSummary(),
    this.unassignedSummary = const UnassignedSummary(),
    this.shoppingItems = const [],
    this.householdOverview = const [],
    this.members = const [],
    this.hasHousehold = false,
    this.hasOverviewData = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final MyTasksSummary myTasksSummary;
  final UnassignedSummary unassignedSummary;
  final List<ShoppingItem> shoppingItems;
  final List<DailyOverview> householdOverview;
  final List<HouseholdMember> members;
  final bool hasHousehold;

  /// householdOverview に1件以上のタスクが存在するか（棒グラフの空状態表示制御用）
  final bool hasOverviewData;
  final bool isLoading;
  final String? errorMessage;

  HomeState copyWith({
    MyTasksSummary? myTasksSummary,
    UnassignedSummary? unassignedSummary,
    List<ShoppingItem>? shoppingItems,
    List<DailyOverview>? householdOverview,
    List<HouseholdMember>? members,
    bool? hasHousehold,
    bool? hasOverviewData,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      myTasksSummary: myTasksSummary ?? this.myTasksSummary,
      unassignedSummary: unassignedSummary ?? this.unassignedSummary,
      shoppingItems: shoppingItems ?? this.shoppingItems,
      householdOverview: householdOverview ?? this.householdOverview,
      members: members ?? this.members,
      hasHousehold: hasHousehold ?? this.hasHousehold,
      hasOverviewData: hasOverviewData ?? this.hasOverviewData,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class MyTasksSummary {
  const MyTasksSummary({
    this.todayCount = 0,
    this.weekCount = 0,
    this.overdueCount = 0,
  });

  final int todayCount;
  final int weekCount;
  final int overdueCount;
}

class UnassignedSummary {
  const UnassignedSummary({this.totalCount = 0, this.urgentCount = 0});

  final int totalCount;
  final int urgentCount; // 今日〜3日以内
}

class DailyOverview {
  const DailyOverview({required this.date, required this.countsByAssignee});

  final DateTime date;
  final Map<int?, int> countsByAssignee; // null=未割当, key=userId
}
