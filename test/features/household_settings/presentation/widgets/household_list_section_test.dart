import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/features/household_settings/presentation/household_settings/widgets/household_list_section.dart';

import '../../../../helpers/widget_test_helpers.dart';

/// 2世帯 / 選択済み = 1番目
class _TwoHouseholdsNotifier extends HouseholdNotifier {
  @override
  Future<HouseholdState> build() async => const HouseholdState(
    households: [
      Household(id: 1, name: '山田家'),
      Household(id: 2, name: '田中家'),
    ],
    selectedHousehold: Household(id: 1, name: '山田家'),
  );
}

/// 1世帯 / 選択済み
class _OneHouseholdNotifier extends HouseholdNotifier {
  @override
  Future<HouseholdState> build() async => const HouseholdState(
    households: [Household(id: 1, name: 'テスト家')],
    selectedHousehold: Household(id: 1, name: 'テスト家'),
  );
}

void main() {
  group('HouseholdListSection', () {
    testWidgets('世帯リストが表示される（2世帯）', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: HouseholdListSection()),
          ),
          overrides: [
            householdNotifierProvider.overrideWith(_TwoHouseholdsNotifier.new),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('householdsSection')), findsOneWidget);
      expect(find.text('山田家'), findsOneWidget);
      expect(find.text('田中家'), findsOneWidget);
    });

    testWidgets('現在選択中の世帯にCurrentバッジが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: HouseholdListSection()),
          ),
          overrides: [
            householdNotifierProvider.overrideWith(_TwoHouseholdsNotifier.new),
          ],
        ),
      );
      await tester.pump();

      // 現在選択中（山田家）にはChipが表示される
      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('世帯追加ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: HouseholdListSection()),
          ),
          overrides: [
            householdNotifierProvider.overrideWith(_OneHouseholdNotifier.new),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('addHouseholdButton')), findsOneWidget);
    });

    testWidgets('世帯追加ボタンタップでダイアログが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: HouseholdListSection()),
          ),
          overrides: [
            householdNotifierProvider.overrideWith(_OneHouseholdNotifier.new),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('addHouseholdButton')));
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('1世帯のみの場合でもセクションが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: HouseholdListSection()),
          ),
          overrides: [
            householdNotifierProvider.overrideWith(_OneHouseholdNotifier.new),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('householdsSection')), findsOneWidget);
      expect(find.text('テスト家'), findsOneWidget);
    });
  });
}
