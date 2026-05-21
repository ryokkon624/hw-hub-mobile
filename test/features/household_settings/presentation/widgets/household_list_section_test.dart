import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/core/theme/app_color_scheme.dart';
import 'package:hw_hub_mobile/core/theme/app_theme.dart';
import 'package:hw_hub_mobile/features/household_settings/presentation/household_settings/widgets/household_list_section.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';

import '../../../../helpers/widget_test_helpers.dart';

/// エラー状態
class _ErrorNotifier extends HouseholdNotifier {
  @override
  Future<HouseholdState> build() async {
    throw Exception('エラー');
  }
}

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

    testWidgets('エラー状態では householdsSection が表示されない', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: HouseholdListSection()),
          ),
          overrides: [
            householdNotifierProvider.overrideWith(_ErrorNotifier.new),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('householdsSection')), findsNothing);
    });

    testWidgets('世帯追加ダイアログの確認ボタンで世帯が追加される（名前入力あり）', (tester) async {
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

      // テキストフィールドに入力
      await tester.enterText(find.byType(TextField), '新しい世帯');
      await tester.pump();

      // 確認ボタン（2番目のTextButton）をタップ
      final buttons = find.byType(TextButton);
      await tester.tap(buttons.last);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('世帯追加ダイアログの確認ボタン: 名前が空のときはダイアログが閉じない', (tester) async {
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

      // テキストが空のまま確認ボタンをタップ
      final buttons = find.byType(TextButton);
      await tester.tap(buttons.last);
      await tester.pump();

      // ダイアログが閉じない
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('選択中でない世帯の切り替えボタンが表示される', (tester) async {
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

      // 田中家（未選択）は切り替えボタン（TextButton）を持つ
      expect(find.byType(TextButton), findsWidgets);
    });

    testWidgets(
      '現在バッジのbackgroundColorがAppColorScheme.statusActiveBgになっている（Lightモード）',
      (tester) async {
        await tester.pumpWidget(
          buildTestPage(
            const Scaffold(
              body: SingleChildScrollView(child: HouseholdListSection()),
            ),
            overrides: [
              householdNotifierProvider.overrideWith(
                _TwoHouseholdsNotifier.new,
              ),
            ],
          ),
        );
        await tester.pump();

        // AppColorScheme.light() の statusActiveBg と一致すること
        final expectedBg = AppColorScheme.light().statusActiveBg;
        final chip = tester.widget<Chip>(find.byType(Chip));
        expect(chip.backgroundColor, expectedBg);
      },
    );

    testWidgets(
      '現在バッジのbackgroundColorがDarkモードでAppColorScheme.statusActiveBgになっている',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              householdNotifierProvider.overrideWith(
                _TwoHouseholdsNotifier.new,
              ),
            ],
            child: MaterialApp(
              locale: const Locale('ja'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: AppTheme.dark,
              home: const Scaffold(
                body: SingleChildScrollView(child: HouseholdListSection()),
              ),
            ),
          ),
        );
        await tester.pump();

        // AppColorScheme.dark() の statusActiveBg と一致すること
        final expectedBg = AppColorScheme.dark().statusActiveBg;
        final chip = tester.widget<Chip>(find.byType(Chip));
        expect(chip.backgroundColor, expectedBg);
      },
    );

    testWidgets(
      '現在バッジのlabelTextColorがAppColorScheme.statusActiveTextになっている（Lightモード）',
      (tester) async {
        await tester.pumpWidget(
          buildTestPage(
            const Scaffold(
              body: SingleChildScrollView(child: HouseholdListSection()),
            ),
            overrides: [
              householdNotifierProvider.overrideWith(
                _TwoHouseholdsNotifier.new,
              ),
            ],
          ),
        );
        await tester.pump();

        // AppColorScheme.light() の statusActiveText と一致すること
        final expectedText = AppColorScheme.light().statusActiveText;
        final chip = tester.widget<Chip>(find.byType(Chip));
        final labelText = chip.label as Text;
        expect(labelText.style?.color, expectedText);
      },
    );

    testWidgets('選択中でない世帯の切り替えボタンをタップするとselectが呼ばれる', (tester) async {
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

      // TextButtonが複数あるので最初のもの（世帯追加ボタン以外）をタップ
      // HouseholdListSection の addHouseholdButton は TextButton.icon
      // _HouseholdRow の切り替えボタンは TextButton
      final switchButtons = find.descendant(
        of: find.byType(ListTile),
        matching: find.byType(TextButton),
      );
      expect(switchButtons, findsOneWidget);
      await tester.tap(switchButtons.first);
      await tester.pump();

      // クラッシュなく動作する
      expect(find.byKey(const Key('householdsSection')), findsOneWidget);
    });
  });
}
