import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/core/theme/app_theme.dart';
import 'package:hw_hub_mobile/features/shell/widgets/household_indicator_bar.dart';

Widget _wrap(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );
}

List<Override> _overrideWith(HouseholdState state) => [
      householdNotifierProvider.overrideWith(() => _FakeHouseholdNotifier(state)),
    ];

void main() {
  group('HouseholdIndicatorBar', () {
    testWidgets('世帯が1件以下のとき何も表示しない', (tester) async {
      final state = HouseholdState(
        households: const [Household(id: '1', name: '山田家')],
        selectedHousehold: const Household(id: '1', name: '山田家'),
      );

      await tester.pumpWidget(_wrap(
        const HouseholdIndicatorBar(),
        overrides: _overrideWith(state),
      ));
      await tester.pump();

      expect(find.text('山田家'), findsNothing);
    });

    testWidgets('世帯が2件以上のとき選択世帯名を表示する', (tester) async {
      final state = HouseholdState(
        households: const [
          Household(id: '1', name: '山田家'),
          Household(id: '2', name: '田中家'),
        ],
        selectedHousehold: const Household(id: '1', name: '山田家'),
      );

      await tester.pumpWidget(_wrap(
        const HouseholdIndicatorBar(),
        overrides: _overrideWith(state),
      ));
      await tester.pump();

      expect(find.text('山田家'), findsOneWidget);
    });

    testWidgets('バーをタップするとBottomSheetが開く', (tester) async {
      final state = HouseholdState(
        households: const [
          Household(id: '1', name: '山田家'),
          Household(id: '2', name: '田中家'),
        ],
        selectedHousehold: const Household(id: '1', name: '山田家'),
      );

      await tester.pumpWidget(_wrap(
        const HouseholdIndicatorBar(),
        overrides: _overrideWith(state),
      ));
      await tester.pump();

      await tester.tap(find.text('山田家'));
      await tester.pumpAndSettle();

      expect(find.text('世帯を選択'), findsOneWidget);
    });
  });
}

class _FakeHouseholdNotifier extends HouseholdNotifier {
  _FakeHouseholdNotifier(this._state);

  final HouseholdState _state;

  @override
  Future<HouseholdState> build() async => _state;

  @override
  Future<void> select(household) async {}
}
