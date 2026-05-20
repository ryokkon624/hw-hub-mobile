import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_create/housework_create_notifier.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_create/housework_create_page.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_create/housework_create_state.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_list/housework_list_notifier.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_list/housework_list_state.dart';

import '../../../../helpers/widget_test_helpers.dart';

class _FakeHouseworkCreateNotifier extends HouseworkCreateNotifier {
  _FakeHouseworkCreateNotifier(this._state);

  final HouseworkCreateState _state;

  @override
  Future<HouseworkCreateState> build() async => _state;
}

class _FakeHouseworkListNotifier extends HouseworkListNotifier {
  @override
  Future<HouseworkListState> build() async => const HouseworkListState();
}

Widget _buildPage(HouseworkCreateState state) {
  return buildTestPageWithRouter(
    overrides: [
      houseworkCreateNotifierProvider.overrideWith(
        () => _FakeHouseworkCreateNotifier(state),
      ),
      houseworkListNotifierProvider.overrideWith(
        () => _FakeHouseworkListNotifier(),
      ),
    ],
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HouseworkCreatePage()),
    ],
  );
}

void main() {
  group('HouseworkCreatePage', () {
    testWidgets('houseworkCreatePageキーのScaffoldが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(const HouseworkCreateState()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('houseworkCreatePage')), findsOneWidget);
    });

    testWidgets('テンプレートから選択ボタンが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(const HouseworkCreateState()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('houseworkTemplateButton')), findsOneWidget);
    });

    testWidgets('家事名フィールドが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(const HouseworkCreateState()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('houseworkNameField')), findsOneWidget);
    });

    testWidgets('保存ボタンが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(const HouseworkCreateState()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('houseworkSaveButton')), findsOneWidget);
    });

    testWidgets('キャンセルボタンが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(const HouseworkCreateState()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('houseworkCancelButton')), findsOneWidget);
    });

    testWidgets('isSaving=trueのとき保存ボタンが無効', (tester) async {
      await tester.pumpWidget(
        _buildPage(const HouseworkCreateState(isSaving: true)),
      );
      // pumpAndSettle はCircularProgressIndicator のアニメーションでタイムアウトするため pump のみ
      await tester.pump();
      await tester.pump();

      final saveButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('houseworkSaveButton')),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('recommendationTextがある場合にバナーが表示される', (tester) async {
      await tester.pumpWidget(
        _buildPage(const HouseworkCreateState(recommendationText: 'おすすめのメモ')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dismissRecommendation')), findsOneWidget);
    });

    testWidgets('recommendationTextがない場合にバナーが表示されない', (tester) async {
      await tester.pumpWidget(_buildPage(const HouseworkCreateState()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dismissRecommendation')), findsNothing);
    });
  });
}
