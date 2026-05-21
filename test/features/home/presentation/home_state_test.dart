import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/home/presentation/home_state.dart';
import 'package:hw_hub_mobile/features/home/presentation/models/household_member.dart';
import 'package:hw_hub_mobile/features/home/presentation/models/shopping_item.dart';

void main() {
  group('HomeState.copyWith', () {
    test('全フィールドをコピーして新しいインスタンスを返す', () {
      const original = HomeState(
        hasHousehold: false,
        isLoading: false,
        errorMessage: null,
      );

      final updated = original.copyWith(
        myTasksSummary: const MyTasksSummary(
          todayCount: 1,
          weekCount: 2,
          overdueCount: 3,
        ),
        unassignedSummary: const UnassignedSummary(
          totalCount: 5,
          urgentCount: 2,
        ),
        shoppingItems: const [
          ShoppingItem(
            shoppingItemId: 1,
            name: '牛乳',
            status: '0',
            createdAt: '2025-01-01T00:00:00',
          ),
        ],
        householdOverview: [
          DailyOverview(
            date: DateTime(2025, 1, 1),
            countsByAssignee: const {1: 2},
          ),
        ],
        members: const [
          HouseholdMember(userId: 1, displayName: 'テスト', iconUrl: null),
        ],
        hasHousehold: true,
        isLoading: true,
        errorMessage: 'エラー',
      );

      expect(updated.myTasksSummary.todayCount, 1);
      expect(updated.myTasksSummary.weekCount, 2);
      expect(updated.myTasksSummary.overdueCount, 3);
      expect(updated.unassignedSummary.totalCount, 5);
      expect(updated.unassignedSummary.urgentCount, 2);
      expect(updated.shoppingItems.length, 1);
      expect(updated.householdOverview.length, 1);
      expect(updated.members.length, 1);
      expect(updated.hasHousehold, isTrue);
      expect(updated.isLoading, isTrue);
      expect(updated.errorMessage, 'エラー');
    });

    test('nullを渡した場合は既存の値が保持される', () {
      const original = HomeState(
        hasHousehold: true,
        isLoading: true,
        errorMessage: '既存エラー',
      );

      final updated = original.copyWith();

      expect(updated.hasHousehold, isTrue);
      expect(updated.isLoading, isTrue);
      expect(updated.errorMessage, '既存エラー');
    });

    test('clearError=trueでerrorMessageがnullになる', () {
      const original = HomeState(errorMessage: 'エラー');

      final updated = original.copyWith(clearError: true);

      expect(updated.errorMessage, isNull);
    });

    test('clearError=falseでerrorMessageが上書きされる', () {
      const original = HomeState(errorMessage: '古いエラー');

      final updated = original.copyWith(errorMessage: '新しいエラー');

      expect(updated.errorMessage, '新しいエラー');
    });

    test('isLoadingフィールドがfalseから更新される', () {
      const original = HomeState(isLoading: false);

      final updated = original.copyWith(isLoading: true);

      expect(updated.isLoading, isTrue);
    });
  });
}
