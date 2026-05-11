import '../data/models/household_member_dto.dart';
import '../data/models/shopping_item_dto.dart';

class HomeState {
  const HomeState({
    this.myTasksSummary = const MyTasksSummary(),
    this.unassignedSummary = const UnassignedSummary(),
    this.shoppingItems = const [],
    this.householdOverview = const [],
    this.members = const [],
    this.hasHousehold = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final MyTasksSummary myTasksSummary;
  final UnassignedSummary unassignedSummary;
  final List<ShoppingItemDto> shoppingItems;
  final List<DailyOverview> householdOverview;
  final List<HouseholdMemberDto> members;
  final bool hasHousehold;
  final bool isLoading;
  final String? errorMessage;

  HomeState copyWith({
    MyTasksSummary? myTasksSummary,
    UnassignedSummary? unassignedSummary,
    List<ShoppingItemDto>? shoppingItems,
    List<DailyOverview>? householdOverview,
    List<HouseholdMemberDto>? members,
    bool? hasHousehold,
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
