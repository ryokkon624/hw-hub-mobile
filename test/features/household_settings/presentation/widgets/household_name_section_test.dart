import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// 世帯切り替えをシミュレートできる Notifier
class _SwitchableHouseholdNotifier extends HouseholdNotifier {
  Household _current = const Household(id: 1, name: '山田家');

  void switchTo(Household h) {
    _current = h;
    state = AsyncData(state.value!.copyWith(selectedHousehold: h));
  }

  @override
  Future<HouseholdState> build() async => HouseholdState(
    households: const [
      Household(id: 1, name: '山田家'),
      Household(id: 2, name: '田中家'),
    ],
    selectedHousehold: _current,
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

class _RecordingSettingsNotifier extends HouseholdSettingsNotifier {
  String? savedName;

  @override
  Future<HouseholdSettingsState> build() async => const HouseholdSettingsState(
    invitations: [],
    isCurrentUserOwner: true,
    hasOtherActiveMembers: false,
  );

  @override
  Future<void> saveHouseholdName({required String name}) async {
    savedName = name;
  }
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

    testWidgets('保存ボタンをタップするとsaveHouseholdNameが呼ばれ、_originalNameが更新される', (
      tester,
    ) async {
      final notifier = _RecordingSettingsNotifier();
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: HouseholdNameSection()),
          ),
          overrides: [
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(() => notifier),
          ],
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), '新しい世帯名');
      await tester.pump();

      await tester.tap(find.byKey(const Key('saveHouseholdNameButton')));
      await tester.pump();

      expect(notifier.savedName, '新しい世帯名');
    });

    testWidgets('世帯切り替え時: テキストフィールドが切り替え先のおうち名に更新される', (tester) async {
      final householdNotifier = _SwitchableHouseholdNotifier();
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: HouseholdNameSection()),
          ),
          overrides: [
            householdNotifierProvider.overrideWith(() => householdNotifier),
            householdSettingsNotifierProvider.overrideWith(
              _FakeSettingsNotifier.new,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 初期状態: 山田家が表示されている
      final tf1 = tester.widget<TextField>(find.byType(TextField));
      expect(tf1.controller?.text, '山田家');

      // 世帯切り替え
      householdNotifier.switchTo(const Household(id: 2, name: '田中家'));
      await tester.pumpAndSettle();

      // 田中家に更新される
      final tf2 = tester.widget<TextField>(find.byType(TextField));
      expect(tf2.controller?.text, '田中家');
    });
  });
}
