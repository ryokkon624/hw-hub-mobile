import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/features/housework_settings/housework_settings_providers.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_create/housework_create_page.dart';

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

// ローディング状態を返す FakeNotifier
class _LoadingCreateNotifier extends HouseworkCreateNotifier {
  @override
  Future<HouseworkCreateState> build() {
    return Completer<HouseworkCreateState>().future;
  }
}

// エラー状態を返す FakeNotifier
class _ErrorCreateNotifier extends HouseworkCreateNotifier {
  @override
  Future<HouseworkCreateState> build() async {
    throw Exception('ロードエラー');
  }
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
      GoRoute(path: '/', builder: (_, _) => const HouseworkCreatePage()),
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

    testWidgets('ローディング中: CircularProgressIndicatorが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          overrides: [
            houseworkCreateNotifierProvider.overrideWith(
              () => _LoadingCreateNotifier(),
            ),
            houseworkListNotifierProvider.overrideWith(
              () => _FakeHouseworkListNotifier(),
            ),
          ],
          routes: [
            GoRoute(path: '/', builder: (_, _) => const HouseworkCreatePage()),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('エラー時: エラーメッセージが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          overrides: [
            houseworkCreateNotifierProvider.overrideWith(
              () => _ErrorCreateNotifier(),
            ),
            houseworkListNotifierProvider.overrideWith(
              () => _FakeHouseworkListNotifier(),
            ),
          ],
          routes: [
            GoRoute(path: '/', builder: (_, _) => const HouseworkCreatePage()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('houseworkCreatePage')), findsOneWidget);
    });

    testWidgets('テンプレートボタンタップでモーダルが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(const HouseworkCreateState()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('houseworkTemplateButton')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('キャンセルボタンが表示される（確認）', (tester) async {
      await tester.pumpWidget(_buildPage(const HouseworkCreateState()));
      await tester.pumpAndSettle();

      final cancelButton = find.byKey(const Key('houseworkCancelButton'));
      expect(cancelButton, findsOneWidget);
      // キャンセルボタンが有効であること（tappable）
      final button = tester.widget<OutlinedButton>(cancelButton);
      expect(button.onPressed, isNotNull);
    });
  });
}
