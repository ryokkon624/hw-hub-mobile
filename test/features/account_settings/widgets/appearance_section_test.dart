import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/theme/theme_mode_notifier.dart';
import 'package:hw_hub_mobile/features/account_settings/presentation/widgets/appearance_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/widget_test_helpers.dart';

/// AppearanceSection のテスト用フェイク ThemeModeNotifier。
class _FakeThemeModeNotifier extends ThemeModeNotifier {
  _FakeThemeModeNotifier(this._initialMode);

  final ThemeMode _initialMode;
  ThemeMode? capturedMode;

  @override
  Future<ThemeMode> build() async => _initialMode;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    capturedMode = mode;
    state = AsyncData(mode);
  }
}

Widget _buildSection({
  ThemeMode initialMode = ThemeMode.system,
  _FakeThemeModeNotifier? notifier,
}) {
  final fake = notifier ?? _FakeThemeModeNotifier(initialMode);
  return buildTestPage(
    const Scaffold(body: SingleChildScrollView(child: AppearanceSection())),
    overrides: [themeModeNotifierProvider.overrideWith(() => fake)],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppearanceSection', () {
    testWidgets('appearanceSectionキーのウィジェットが表示される', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      expect(find.byKey(const Key('appearanceSection')), findsOneWidget);
    });

    testWidgets('SegmentedButtonが表示される', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    });

    testWidgets('システム連動・ライト・ダークの3セグメントが表示される', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      // 3つの ButtonSegment を確認（SegmentedButton が3つのラベルを持つ）
      final segmented = tester.widget<SegmentedButton<ThemeMode>>(
        find.byType(SegmentedButton<ThemeMode>),
      );
      expect(segmented.segments.length, 3);
      expect(segmented.segments[0].value, ThemeMode.system);
      expect(segmented.segments[1].value, ThemeMode.light);
      expect(segmented.segments[2].value, ThemeMode.dark);
    });

    testWidgets('初期状態がシステム連動のとき: ThemeMode.system が選択済み', (tester) async {
      await tester.pumpWidget(_buildSection(initialMode: ThemeMode.system));
      await tester.pump();

      final segmented = tester.widget<SegmentedButton<ThemeMode>>(
        find.byType(SegmentedButton<ThemeMode>),
      );
      expect(segmented.selected, {ThemeMode.system});
    });

    testWidgets('初期状態がライトのとき: ThemeMode.light が選択済み', (tester) async {
      await tester.pumpWidget(_buildSection(initialMode: ThemeMode.light));
      await tester.pump();

      final segmented = tester.widget<SegmentedButton<ThemeMode>>(
        find.byType(SegmentedButton<ThemeMode>),
      );
      expect(segmented.selected, {ThemeMode.light});
    });

    testWidgets('初期状態がダークのとき: ThemeMode.dark が選択済み', (tester) async {
      await tester.pumpWidget(_buildSection(initialMode: ThemeMode.dark));
      await tester.pump();

      final segmented = tester.widget<SegmentedButton<ThemeMode>>(
        find.byType(SegmentedButton<ThemeMode>),
      );
      expect(segmented.selected, {ThemeMode.dark});
    });

    testWidgets(
      'SegmentedButton の onSelectionChanged が ThemeModeNotifier.setThemeMode() を呼ぶ',
      (tester) async {
        final fakeNotifier = _FakeThemeModeNotifier(ThemeMode.system);
        await tester.pumpWidget(_buildSection(notifier: fakeNotifier));
        await tester.pump();

        // SegmentedButton の onSelectionChanged を直接呼び出して動作確認
        final segmented = tester.widget<SegmentedButton<ThemeMode>>(
          find.byType(SegmentedButton<ThemeMode>),
        );
        segmented.onSelectionChanged!({ThemeMode.dark});
        await tester.pump();

        expect(fakeNotifier.capturedMode, ThemeMode.dark);
      },
    );

    testWidgets(
      'setThemeMode(light) 呼び出し後: SegmentedButton の selected が更新される',
      (tester) async {
        final fakeNotifier = _FakeThemeModeNotifier(ThemeMode.system);
        await tester.pumpWidget(_buildSection(notifier: fakeNotifier));
        await tester.pump();

        // Notifier の setThemeMode を直接呼んで state を変更
        await fakeNotifier.setThemeMode(ThemeMode.light);
        await tester.pump();

        final segmented = tester.widget<SegmentedButton<ThemeMode>>(
          find.byType(SegmentedButton<ThemeMode>),
        );
        expect(segmented.selected, {ThemeMode.light});
      },
    );
  });
}
