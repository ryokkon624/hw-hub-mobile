import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/features/household_settings/household_settings_providers.dart';
import 'package:hw_hub_mobile/features/household_settings/presentation/widgets/nickname_section.dart';

import '../../../../helpers/widget_test_helpers.dart';

class _FakeHouseholdNotifier extends HouseholdNotifier {
  @override
  Future<HouseholdState> build() async =>
      const HouseholdState(households: [], selectedHousehold: null);
}

class _FakeSettingsNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() async =>
      const HouseholdSettingsState(invitations: []);
}

/// currentNickname が設定された Fake Notifier
class _WithNicknameSettingsNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() async =>
      const HouseholdSettingsState(invitations: [], currentNickname: 'お父さん');
}

class _RecordingSettingsNotifier extends HouseholdSettingsNotifier {
  String? savedNickname;

  @override
  Future<HouseholdSettingsState> build() async =>
      const HouseholdSettingsState(invitations: []);

  @override
  Future<void> saveNickname({required String nickname}) async {
    savedNickname = nickname;
  }
}

Widget _buildSection({HouseholdSettingsNotifier? notifier}) => buildTestPage(
  const Scaffold(body: SingleChildScrollView(child: NicknameSection())),
  overrides: [
    householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
    householdSettingsNotifierProvider.overrideWith(
      notifier != null ? () => notifier : _FakeSettingsNotifier.new,
    ),
  ],
);

void main() {
  group('NicknameSection', () {
    testWidgets('セクションが表示される', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      expect(find.byKey(const Key('nicknameSection')), findsOneWidget);
    });

    testWidgets('入力なし: 保存ボタンが無効', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('saveNicknameButton')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('テキスト入力で保存ボタンが有効になる（onChanged分岐）', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'テストニックネーム');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('saveNicknameButton')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('保存ボタンタップでsaveNicknameが呼ばれる', (tester) async {
      final notifier = _RecordingSettingsNotifier();
      await tester.pumpWidget(_buildSection(notifier: notifier));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'ニックネーム太郎');
      await tester.pump();

      await tester.tap(find.byKey(const Key('saveNicknameButton')));
      await tester.pump();

      expect(notifier.savedNickname, 'ニックネーム太郎');
    });

    testWidgets('Stateにcurrentnicknameがある場合: 初期状態でテキストフィールドに表示される', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(body: SingleChildScrollView(child: NicknameSection())),
          overrides: [
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _WithNicknameSettingsNotifier.new,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // currentNickname が TextEditingController に反映されている
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller?.text, 'お父さん');
    });
  });
}
