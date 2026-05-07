import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HouseholdNotifier', () {
    test('初期状態は空のhouseholds・selectedはnull', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = await container.read(
        AsyncNotifierProvider<HouseholdNotifier, HouseholdState>(
          HouseholdNotifier.new,
        ).future,
      );

      expect(state.households, isEmpty);
      expect(state.selectedHousehold, isNull);
    });

    test('select()でselectedHouseholdが更新される', () async {
      const h1 = Household(id: '1', name: '山田家');
      const h2 = Household(id: '2', name: '田中家');

      final provider = AsyncNotifierProvider<HouseholdNotifier, HouseholdState>(
        HouseholdNotifier.new,
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 初期化後に直接 state を書き換えてテスト用データをセット
      await container.read(provider.future);
      container.read(provider.notifier).state = AsyncData(
        HouseholdState(households: const [h1, h2], selectedHousehold: h1),
      );

      await container.read(provider.notifier).select(h2);

      final updated = container.read(provider).value!;
      expect(updated.selectedHousehold, h2);
    });

    test('select()でSharedPreferencesに選択IDが保存される', () async {
      SharedPreferences.setMockInitialValues({});
      const h = Household(id: 'house-42', name: 'テスト家');

      final provider = AsyncNotifierProvider<HouseholdNotifier, HouseholdState>(
        HouseholdNotifier.new,
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(provider.future);
      container.read(provider.notifier).state = AsyncData(
        HouseholdState(households: const [h], selectedHousehold: h),
      );

      await container.read(provider.notifier).select(h);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_household_id'), 'house-42');
    });
  });
}
