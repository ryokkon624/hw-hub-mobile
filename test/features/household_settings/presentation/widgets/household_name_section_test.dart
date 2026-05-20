import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/features/household_settings/presentation/household_settings/household_settings_notifier.dart';
import 'package:hw_hub_mobile/features/household_settings/presentation/household_settings/household_settings_state.dart';
import 'package:hw_hub_mobile/features/household_settings/presentation/household_settings/widgets/household_name_section.dart';

import '../../../../helpers/widget_test_helpers.dart';

class _FakeHouseholdNotifier extends HouseholdNotifier {
  @override
  Future<HouseholdState> build() async => const HouseholdState(
    households: [Household(id: 1, name: '山田家')],
    selectedHousehold: Household(id: 1, name: '山田家'),
  );
}

class _FakeSettingsNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() async => const HouseholdSettingsState(
    invitations: [],
    isCurrentUserOwner: true,
    hasOtherActiveMembers: false,
  );
}

class _SavingSettingsNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() async => const HouseholdSettingsState(
    invitations: [],
    isCurrentUserOwner: true,
    hasOtherActiveMembers: false,
    isSavingName: true,
  );
}

Widget _buildSection({bool isSaving = false}) => buildTestPage(
  const Scaffold(body: SingleChildScrollView(child: HouseholdNameSection())),
  overrides: [
    householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
    householdSettingsNotifierProvider.overrideWith(
      isSaving ? _SavingSettingsNotifier.new : _FakeSettingsNotifier.new,
    ),
  ],
);

void main() {
  group('HouseholdNameSection', () {
    testWidgets('セクションが表示される', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      expect(find.byKey(const Key('householdInfoSection')), findsOneWidget);
    });

    testWidgets('テキストフィールドが表示される', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('初期状態（変更なし）: 保存ボタンが無効', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('saveHouseholdNameButton')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('世帯名を変更すると保存ボタンが有効になる', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      await tester.enterText(find.byType(TextField), '新しい世帯名');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('saveHouseholdNameButton')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('空白のみのテキストを入力すると保存ボタンが無効のまま', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      // 一度変更して有効にしてから空白にする
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('saveHouseholdNameButton')),
      );
      // '   '.trim() = '' なので isNotEmpty = false → 無効
      expect(button.onPressed, isNull);
    });

    testWidgets('空文字を入力すると保存ボタンが無効のまま', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('saveHouseholdNameButton')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('isSavingName=true のとき保存ボタンが無効', (tester) async {
      await tester.pumpWidget(_buildSection(isSaving: true));
      await tester.pump();

      // テキストを変更してもisSaving=trueなら無効
      await tester.enterText(find.byType(TextField), '新しい名前');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('saveHouseholdNameButton')),
      );
      expect(button.onPressed, isNull);
    });
  });
}
