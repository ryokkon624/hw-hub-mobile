import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/models/household.dart';

void main() {
  const h1 = Household(id: '1', name: '山田家');
  const h2 = Household(id: '2', name: '田中家');

  group('HouseholdState.isMultiple', () {
    test('returns false when households is empty', () {
      final state = HouseholdState(households: const []);
      expect(state.isMultiple, isFalse);
    });

    test('returns false when only one household', () {
      final state = HouseholdState(households: const [h1]);
      expect(state.isMultiple, isFalse);
    });

    test('returns true when two or more households', () {
      final state = HouseholdState(households: const [h1, h2]);
      expect(state.isMultiple, isTrue);
    });
  });

  group('HouseholdState.copyWith', () {
    test('updates selectedHousehold', () {
      final state = HouseholdState(households: const [h1, h2], selectedHousehold: h1);
      final updated = state.copyWith(selectedHousehold: h2);
      expect(updated.selectedHousehold, h2);
      expect(updated.households, const [h1, h2]);
    });

    test('keeps original values when not specified', () {
      final state = HouseholdState(households: const [h1], selectedHousehold: h1);
      final copied = state.copyWith();
      expect(copied.households, const [h1]);
      expect(copied.selectedHousehold, h1);
    });
  });
}
