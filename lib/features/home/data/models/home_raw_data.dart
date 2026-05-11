import 'household_member_dto.dart';
import 'housework_dto.dart';
import 'housework_task_dto.dart';
import 'shopping_item_dto.dart';

class HomeRawData {
  const HomeRawData({
    required this.members,
    required this.houseworks,
    required this.openTasks,
    required this.doneTasks,
    required this.shoppingItems,
  });

  final List<HouseholdMemberDto> members;
  final List<HouseworkDto> houseworks;
  final List<HouseworkTaskDto> openTasks;
  final List<HouseworkTaskDto> doneTasks;
  final List<ShoppingItemDto> shoppingItems;
}
