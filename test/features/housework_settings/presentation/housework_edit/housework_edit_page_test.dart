import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/features/housework_settings/housework_settings_providers.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_edit/housework_edit_page.dart';

import '../../../../helpers/widget_test_helpers.dart';

class _FakeHouseworkEditNotifier extends HouseworkEditNotifier {
  _FakeHouseworkEditNotifier(this._state);

  final HouseworkEditState _state;

  @override
  Future<HouseworkEditState> build(int houseworkId) async => _state;
}

class _FakeHouseworkListNotifier extends HouseworkListNotifier {
  @override
  Future<HouseworkListState> build() async => const HouseworkListState();
}

const _defaultState = HouseworkEditState(
  houseworkId: 1,
  form: HouseworkFormState(name: '掃除機がけ'),
);

Widget _buildPage(HouseworkEditState state) {
  return buildTestPageWithRouter(
    overrides: [
      houseworkEditNotifierProvider.overrideWith(
        () => _FakeHouseworkEditNotifier(state),
      ),
      houseworkListNotifierProvider.overrideWith(
        () => _FakeHouseworkListNotifier(),
      ),
    ],
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>const HouseworkEditPage(houseworkId: 1),
      ),
      GoRoute(
        path: '/settings/housework',
        builder: (_, _) =>const Scaffold(body: Text('一覧画面')),
      ),
    ],
  );
}

void main() {
  group('HouseworkEditPage', () {
    testWidgets('houseworkEditPageキーのScaffoldが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(_defaultState));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('houseworkEditPage')), findsOneWidget);
    });

    testWidgets('家事名フィールドが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(_defaultState));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('houseworkNameField')), findsOneWidget);
    });

    testWidgets('保存ボタンが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(_defaultState));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('houseworkEditSaveButton')), findsOneWidget);
    });

    testWidgets('キャンセルボタンが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(_defaultState));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('houseworkEditCancelButton')),
        findsOneWidget,
      );
    });

    testWidgets('isSaving=trueのとき保存ボタンが無効', (tester) async {
      await tester.pumpWidget(
        _buildPage(
          const HouseworkEditState(
            houseworkId: 1,
            form: HouseworkFormState(name: '掃除機がけ'),
            isSaving: true,
          ),
        ),
      );
      // CircularProgressIndicator アニメーションがあるため pump のみ
      await tester.pump();
      await tester.pump();

      final saveButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('houseworkEditSaveButton')),
      );
      expect(saveButton.onPressed, isNull);
    });
  });
}
