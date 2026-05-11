import '../models/household.dart';

class HouseholdState {
  const HouseholdState({required this.households, this.selectedHousehold});

  final List<Household> households;
  final Household? selectedHousehold;

  bool get isMultiple => households.length > 1;

  HouseholdState copyWith({
    List<Household>? households,
    Household? selectedHousehold,
  }) => HouseholdState(
    households: households ?? this.households,
    selectedHousehold: selectedHousehold ?? this.selectedHousehold,
  );
}
