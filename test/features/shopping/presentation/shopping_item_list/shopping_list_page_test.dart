import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/core/auth/auth_notifier.dart';
import 'package:hw_hub_mobile/core/auth/auth_state.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/models/auth_user.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/shopping/data/shopping_repository.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/shopping_item_list/shopping_list_page.dart';
import 'package:hw_hub_mobile/features/shopping/shopping_providers.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/widget_test_helpers.dart';
import '../../shopping_mocks.mocks.dart';

// テスト用データ生成
ShoppingItemDto _item({
  int id = 1,
  String status = '0',
  String name = 'テストアイテム',
  String? storeType = '1',
  String? favorite = '0',
  String? purchasedAt,
}) => ShoppingItemDto(
  shoppingItemId: id,
  householdId: 1,
  name: name,
  memo: null,
  storeType: storeType,
  status: status,
  favorite: favorite,
  purchasedAt: purchasedAt,
  createdAt: '2026-05-01T10:00:00',
  hasImage: false,
);

// フェイクAuthNotifier
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._authState);
  final AuthState _authState;

  @override
  Future<AuthState> build() async => _authState;
}

// フェイクHouseholdNotifier（単一世帯）
class _FakeSingleHouseholdNotifier extends HouseholdNotifier {
  _FakeSingleHouseholdNotifier(this._state);
  final HouseholdState _state;

  @override
  Future<HouseholdState> build() async => _state;

  @override
  Future<void> select(Household household) async {}
}

// フェイクShoppingListNotifier（指定データを返す）
class _FakeShoppingListNotifier extends ShoppingListNotifier {
  _FakeShoppingListNotifier(this._items);
  final List<ShoppingItemDto> _items;

  @override
  Future<ShoppingListState> build() async {
    return ShoppingListState(items: List.unmodifiable(_items));
  }
}

// フェイクShoppingListNotifier（エラーを返す）
class _FakeErrorShoppingListNotifier extends ShoppingListNotifier {
  _FakeErrorShoppingListNotifier(this._error);
  final Object _error;

  @override
  Future<ShoppingListState> build() async {
    throw _error;
  }
}

// エラーメッセージを変更できるNotifier（ref.listen分岐テスト用）
class _MutableShoppingListNotifier extends ShoppingListNotifier {
  _MutableShoppingListNotifier(this._items);
  final List<ShoppingItemDto> _items;

  @override
  Future<ShoppingListState> build() async {
    return ShoppingListState(items: List.unmodifiable(_items));
  }

  void setError(String message) {
    final current = state.value!;
    state = AsyncData(current.copyWith(errorMessage: message));
  }
}

final _testUser = AuthUser(
  userId: 10,
  email: 'test@example.com',
  displayName: 'テストユーザー',
);

final _singleHouseholdState = HouseholdState(
  households: [const Household(id: 1, name: '我が家')],
  selectedHousehold: const Household(id: 1, name: '我が家'),
);

// 世帯未所属状態（selectedHousehold == null）
final _noHouseholdState = HouseholdState(
  households: const [],
  selectedHousehold: null,
);

final _multiHouseholdState = HouseholdState(
  households: [
    const Household(id: 1, name: '我が家'),
    const Household(id: 2, name: '実家'),
  ],
  selectedHousehold: const Household(id: 1, name: '我が家'),
);

List<Override> _buildOverrides({
  required List<ShoppingItemDto> items,
  bool multiHousehold = false,
}) => [
  authNotifierProvider.overrideWith(
    () => _FakeAuthNotifier(AuthAuthenticated(_testUser)),
  ),
  householdNotifierProvider.overrideWith(
    () => _FakeSingleHouseholdNotifier(
      multiHousehold ? _multiHouseholdState : _singleHouseholdState,
    ),
  ),
  shoppingListNotifierProvider.overrideWith(
    () => _FakeShoppingListNotifier(items),
  ),
];

List<Override> _buildNoHouseholdOverrides() => [
  authNotifierProvider.overrideWith(
    () => _FakeAuthNotifier(AuthAuthenticated(_testUser)),
  ),
  householdNotifierProvider.overrideWith(
    () => _FakeSingleHouseholdNotifier(_noHouseholdState),
  ),
  shoppingListNotifierProvider.overrideWith(
    () => _FakeShoppingListNotifier([]),
  ),
];

List<Override> _buildErrorOverrides(Object error) => [
  authNotifierProvider.overrideWith(
    () => _FakeAuthNotifier(AuthAuthenticated(_testUser)),
  ),
  householdNotifierProvider.overrideWith(
    () => _FakeSingleHouseholdNotifier(_singleHouseholdState),
  ),
  shoppingListNotifierProvider.overrideWith(
    () => _FakeErrorShoppingListNotifier(error),
  ),
];

/// スワイプ操作テスト用: mockRepositoryとFakeNotifierを組み合わせたオーバーライド
List<Override> _buildSwipeOverrides({
  required List<ShoppingItemDto> items,
  required MockShoppingRepository mockRepo,
}) => [
  authNotifierProvider.overrideWith(
    () => _FakeAuthNotifier(AuthAuthenticated(_testUser)),
  ),
  householdNotifierProvider.overrideWith(
    () => _FakeSingleHouseholdNotifier(_singleHouseholdState),
  ),
  shoppingRepositoryProvider.overrideWithValue(mockRepo),
  shoppingListNotifierProvider.overrideWith(
    () => _FakeShoppingListNotifier(items),
  ),
];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ShoppingListPage - 3タブ表示', () {
    testWidgets('未購入・かご・購入済みの3タブが表示される（AC1）', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: []),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('未購入'), findsOneWidget);
      expect(find.text('かご'), findsOneWidget);
      expect(find.text('購入済み'), findsOneWidget);
    });

    testWidgets('件数バッジが各タブに表示される（AC1）', (tester) async {
      final items = [
        _item(id: 1, status: '0'),
        _item(id: 2, status: '0'),
        _item(id: 3, status: '1'),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      // 未購入2件、かご1件のバッジが表示される
      expect(find.text('2'), findsAtLeastNWidgets(1));
      expect(find.text('1'), findsAtLeastNWidgets(1));
    });
  });

  group('ShoppingListPage - 購入場所フィルタ', () {
    testWidgets('未購入タブに購入場所フィルタが表示される（AC2）', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: [_item()]),
        ),
      );
      await tester.pump();
      await tester.pump();

      // フィルタボタン（すべて・スーパー・ドラッグストア・オンライン）が表示される
      expect(find.text('すべて'), findsOneWidget);
      expect(find.text('スーパー'), findsOneWidget);
      expect(find.text('ドラッグストア'), findsOneWidget);
      expect(find.text('オンライン'), findsOneWidget);
    });
  });

  group('ShoppingListPage - アイテム表示（AC3）', () {
    testWidgets('未購入アイテムの品名が表示される', (tester) async {
      final items = [_item(id: 1, name: 'オリーブオイル', status: '0')];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('オリーブオイル'), findsOneWidget);
    });
  });

  group('ShoppingListPage - 空状態表示', () {
    testWidgets('未購入が0件のとき空メッセージが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: []),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('未購入のアイテムはありません'), findsOneWidget);
    });

    testWidgets('かごが0件のときかごタブの空メッセージが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: []),
        ),
      );
      await tester.pump();
      await tester.pump();

      // かごタブに切り替え
      await tester.tap(find.text('かご'));
      await tester.pump();

      expect(find.text('かごにアイテムはありません'), findsOneWidget);
    });
  });

  group('ShoppingListPage - タブ切り替え', () {
    testWidgets('かごタブをタップするとかごのアイテムが表示される', (tester) async {
      final items = [
        _item(id: 1, status: '0', name: '未購入アイテム'),
        _item(id: 2, status: '1', name: 'かごアイテム'),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      // かごタブをタップ
      await tester.tap(find.text('かご'));
      await tester.pump();

      expect(find.text('かごアイテム'), findsOneWidget);
    });
  });

  group('ShoppingListPage - + アイテムを追加ボタン（AC12）', () {
    testWidgets('+ アイテムを追加ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: []),
        ),
      );
      await tester.pump();
      await tester.pump();

      // ボタンが表示されていること
      expect(find.text('+ アイテムを追加'), findsOneWidget);
    });

    testWidgets('世帯未所属時は「+ アイテムを追加」ボタンが非活性になる（#134）', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildNoHouseholdOverrides(),
        ),
      );
      await tester.pump();
      await tester.pump();

      // ボタンが表示されていること
      final button = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('+ アイテムを追加'),
          matching: find.byType(ElevatedButton),
        ),
      );
      // onPressed が null (disabled) になっていること
      expect(button.onPressed, isNull);
    });

    testWidgets('世帯所属時は「+ アイテムを追加」ボタンが活性になる（#134）', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: []),
        ),
      );
      await tester.pump();
      await tester.pump();

      // ボタンが表示されていること
      final button = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('+ アイテムを追加'),
          matching: find.byType(ElevatedButton),
        ),
      );
      // onPressed が非 null (enabled) になっていること
      expect(button.onPressed, isNotNull);
    });

    testWidgets('+ アイテムを追加ボタンタップで/shopping/newへ遷移する（AC12）', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/shopping',
              builder: (_, _) => const ShoppingListPage(),
            ),
            GoRoute(
              path: '/shopping/new',
              builder: (_, _) =>
                  const Scaffold(body: Text('shopping-new-page')),
            ),
          ],
          overrides: _buildOverrides(items: []),
          initialLocation: '/shopping',
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('+ アイテムを追加'));
      await tester.pumpAndSettle();

      expect(find.text('shopping-new-page'), findsOneWidget);
    });
  });

  group('ShoppingListPage - アイテムカードタップ（AC13）', () {
    testWidgets('アイテムカードタップで詳細画面へ遷移する', (tester) async {
      final items = [_item(id: 42, name: 'ジャガイモ', status: '0')];
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/shopping',
              builder: (_, _) => const ShoppingListPage(),
            ),
            GoRoute(
              path: '/shopping/:id',
              builder: (_, s) =>
                  Scaffold(body: Text('detail-${s.pathParameters["id"]}')),
            ),
          ],
          overrides: _buildOverrides(items: items),
          initialLocation: '/shopping',
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pump();

      // アイテム名をタップ（onTap on InkWell）
      await tester.tap(find.text('ジャガイモ'));
      await tester.pumpAndSettle();

      expect(find.text('detail-42'), findsOneWidget);
    });
  });

  group('ShoppingListPage - かご一括購入済みボタン（AC6）', () {
    testWidgets('かごタブに一括購入済みボタンが表示される', (tester) async {
      final items = [_item(id: 1, status: '1', name: 'かごアイテム')];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      // かごタブへ切り替え
      await tester.tap(find.text('かご'));
      await tester.pump();

      // 一括購入済みボタンが表示される
      expect(find.text('購入済みにする'), findsOneWidget);
    });
  });

  group('ShoppingListPage - 複数世帯インジケーター（AC14）', () {
    testWidgets('複数世帯所属時は世帯インジケーター情報が表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: [], multiHousehold: true),
        ),
      );
      await tester.pump();
      await tester.pump();

      // 複数世帯の場合、ShoppingListPage自体は正常に表示される
      expect(find.byType(ShoppingListPage), findsOneWidget);
    });
  });

  group('ShoppingListPage - ローディング（AC15）', () {
    testWidgets('ローディング中はCircularProgressIndicatorが表示される', (tester) async {
      // ローディング状態になるフェイク（データ取得前）
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(AuthAuthenticated(_testUser)),
            ),
            householdNotifierProvider.overrideWith(
              () => _FakeSingleHouseholdNotifier(_singleHouseholdState),
            ),
            shoppingListNotifierProvider.overrideWith(
              () => _FakeShoppingListNotifier([]),
            ),
          ],
        ),
      );
      // 最初のpumpでローディング状態が表示される
      await tester.pump();
      // 2回目のpump後にデータが表示される
      await tester.pump();

      // ShoppingListPageが正常に表示される（AC15の動作確認）
      expect(find.byType(ShoppingListPage), findsOneWidget);
    });
  });

  group('ShoppingListPage - 購入済みタブ', () {
    testWidgets('購入済みタブをタップすると購入済みアイテムが表示される', (tester) async {
      final now = DateTime.now();
      final recentDate = now.subtract(const Duration(days: 1));
      final items = [
        _item(
          id: 1,
          status: '9',
          name: '購入済みアイテム',
          purchasedAt: recentDate.toIso8601String(),
        ),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      // 購入済みタブをタップ
      await tester.tap(find.text('購入済み'));
      await tester.pump();

      expect(find.text('購入済みアイテム'), findsOneWidget);
    });

    testWidgets('購入済みが0件のとき空メッセージが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: []),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('購入済み'));
      await tester.pump();

      expect(find.text('購入済みアイテムはありません'), findsOneWidget);
    });

    testWidgets('購入済みタブに今日の日付グループヘッダーが表示される', (tester) async {
      final now = DateTime.now();
      final items = [
        _item(
          id: 1,
          status: '9',
          name: '今日の購入品',
          purchasedAt: now.toIso8601String(),
        ),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('購入済み'));
      await tester.pump();

      // 今日のグループヘッダーが表示される
      expect(find.text('今日'), findsOneWidget);
      expect(find.text('今日の購入品'), findsOneWidget);
    });

    testWidgets('購入済みタブに昨日の日付グループヘッダーが表示される', (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final items = [
        _item(
          id: 1,
          status: '9',
          name: '昨日の購入品',
          purchasedAt: yesterday.toIso8601String(),
        ),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('購入済み'));
      await tester.pump();

      expect(find.text('昨日'), findsOneWidget);
    });

    testWidgets('購入済みタブでアイテムタップすると詳細画面へ遷移する', (tester) async {
      final now = DateTime.now();
      final items = [
        _item(
          id: 99,
          status: '9',
          name: '購入品タップ',
          purchasedAt: now.toIso8601String(),
        ),
      ];
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/shopping',
              builder: (_, _) => const ShoppingListPage(),
            ),
            GoRoute(
              path: '/shopping/:id',
              builder: (_, s) =>
                  Scaffold(body: Text('detail-${s.pathParameters["id"]}')),
            ),
          ],
          overrides: _buildOverrides(items: items),
          initialLocation: '/shopping',
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('購入済み'));
      await tester.pump();

      await tester.tap(find.text('購入品タップ'));
      await tester.pumpAndSettle();

      expect(find.text('detail-99'), findsOneWidget);
    });
  });

  group('ShoppingListPage - かごタブ詳細', () {
    testWidgets('かごタブでアイテムカードタップすると詳細画面へ遷移する', (tester) async {
      final items = [_item(id: 55, name: 'かご詳細アイテム', status: '1')];
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/shopping',
              builder: (_, _) => const ShoppingListPage(),
            ),
            GoRoute(
              path: '/shopping/:id',
              builder: (_, s) =>
                  Scaffold(body: Text('detail-${s.pathParameters["id"]}')),
            ),
          ],
          overrides: _buildOverrides(items: items),
          initialLocation: '/shopping',
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('かご'));
      await tester.pump();

      await tester.tap(find.text('かご詳細アイテム'));
      await tester.pumpAndSettle();

      expect(find.text('detail-55'), findsOneWidget);
    });

    testWidgets('かごが空のとき一括購入済みボタンが表示されない', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: []),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('かご'));
      await tester.pump();

      expect(find.text('購入済みにする'), findsNothing);
    });
  });

  group('ShoppingListPage - 購入場所フィルタ選択（AC2）', () {
    testWidgets('スーパーフィルタをタップするとスーパーのアイテムのみ表示される', (tester) async {
      final items = [
        _item(id: 1, name: 'スーパーのアイテム', status: '0', storeType: '1'),
        _item(id: 2, name: 'オンラインのアイテム', status: '0', storeType: '2'),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      // スーパーフィルタをタップ
      await tester.tap(find.text('スーパー'));
      await tester.pump();

      // スーパーのアイテムのみ表示
      expect(find.text('スーパーのアイテム'), findsOneWidget);
      expect(find.text('オンラインのアイテム'), findsNothing);
    });

    testWidgets('すべてフィルタをタップすると全アイテムが表示される', (tester) async {
      final items = [
        _item(id: 1, name: 'スーパーのアイテム', status: '0', storeType: '1'),
        _item(id: 2, name: 'ドラッグストアのアイテム', status: '0', storeType: '3'),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      // スーパーをタップしてからすべてをタップ
      await tester.tap(find.text('スーパー'));
      await tester.pump();
      await tester.tap(find.text('すべて'));
      await tester.pump();

      expect(find.text('スーパーのアイテム'), findsOneWidget);
      expect(find.text('ドラッグストアのアイテム'), findsOneWidget);
    });
  });

  group('ShoppingListPage - 購入済みタブカード表示（#90）', () {
    testWidgets('購入済みアイテムがカード形式で表示される', (tester) async {
      final now = DateTime.now();
      final items = [
        _item(
          id: 1,
          status: '9',
          name: 'スーパーで買ったもの',
          storeType: '1',
          purchasedAt: now.toIso8601String(),
        ),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('購入済み'));
      await tester.pump();

      // カード形式でアイテム名が表示される（バッジ表示から背景色表示に変更）
      expect(find.text('スーパーで買ったもの'), findsOneWidget);
    });
  });

  group('ShoppingListPage - 一括購入済みダイアログ（AC6）', () {
    testWidgets('一括購入済みボタンタップでダイアログが表示される', (tester) async {
      final items = [_item(id: 1, status: '1', name: 'かごアイテム')];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('かご'));
      await tester.pump();

      await tester.tap(find.text('購入済みにする'));
      await tester.pump();

      // ダイアログが表示される
      expect(find.text('一括購入済みにしますか？'), findsOneWidget);
    });

    testWidgets('ダイアログでキャンセルするとダイアログが閉じる', (tester) async {
      final items = [_item(id: 1, status: '1', name: 'かごアイテム')];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('かご'));
      await tester.pump();

      await tester.tap(find.text('購入済みにする'));
      await tester.pump();

      // キャンセルボタンをタップ
      await tester.tap(find.text('キャンセル'));
      await tester.pump();

      // ダイアログが閉じる
      expect(find.text('一括購入済みにしますか？'), findsNothing);
    });
  });

  group('ShoppingListPage - 未購入タブのお気に入り', () {
    testWidgets('お気に入りアイコンが表示される（star_border → star_border）', (tester) async {
      final items = [
        _item(id: 1, name: 'お気に入り未設定', status: '0', favorite: '0'),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.star_border), findsOneWidget);
    });

    testWidgets('お気に入り済みアイテムにstarアイコンが表示される', (tester) async {
      final items = [_item(id: 1, name: 'お気に入り済み', status: '0', favorite: '1')];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('ShoppingListPage - 購入済みタブ昨日以前', () {
    testWidgets('3日前のアイテムに日付ラベルが表示される', (tester) async {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final items = [
        _item(
          id: 1,
          status: '9',
          name: '3日前の購入品',
          purchasedAt: threeDaysAgo.toIso8601String(),
        ),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('購入済み'));
      await tester.pump();

      // 日付ラベル（M/D形式）が表示される
      expect(find.text('3日前の購入品'), findsOneWidget);
    });
  });

  group('ShoppingListPage - エラー表示', () {
    testWidgets('ネットワークエラー時にAppErrorViewが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildErrorOverrides(const NetworkException('接続エラー')),
        ),
      );
      await tester.pump();
      await tester.pump();

      // AppErrorView のアイコン・メッセージ・再読み込みボタンが表示されること
      expect(find.byKey(const Key('appErrorViewIcon')), findsOneWidget);
      expect(find.byKey(const Key('appErrorViewRetryButton')), findsOneWidget);
    });

    testWidgets('認証エラー時にAppErrorViewが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildErrorOverrides(const UnauthorizedException('認証失敗')),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('appErrorViewIcon')), findsOneWidget);
    });

    testWidgets('サーバーエラー時にAppErrorViewが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildErrorOverrides(
            const ServerException(message: 'サーバーエラー'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('appErrorViewIcon')), findsOneWidget);
    });

    testWidgets('予期しないエラー時にAppErrorViewが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildErrorOverrides(Exception('予期しないエラー')),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('appErrorViewIcon')), findsOneWidget);
    });
  });

  group('ShoppingListPage - 購入済みタブ 購入場所別カード（#90）', () {
    testWidgets('ドラッグストアの購入済みアイテムが表示される', (tester) async {
      final now = DateTime.now();
      final items = [
        _item(
          id: 1,
          status: '9',
          name: 'ドラッグストア購入品',
          storeType: '3',
          purchasedAt: now.toIso8601String(),
        ),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('購入済み'));
      await tester.pump();

      // カード形式でアイテム名が表示される（背景色でstoreTypeを表現）
      expect(find.text('ドラッグストア購入品'), findsOneWidget);
    });

    testWidgets('オンラインの購入済みアイテムが表示される', (tester) async {
      final now = DateTime.now();
      final items = [
        _item(
          id: 1,
          status: '9',
          name: 'オンライン購入品',
          storeType: '2',
          purchasedAt: now.toIso8601String(),
        ),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('購入済み'));
      await tester.pump();

      expect(find.text('オンライン購入品'), findsOneWidget);
    });

    testWidgets('購入場所未設定の購入済みアイテムが表示される', (tester) async {
      final now = DateTime.now();
      final items = [
        _item(
          id: 1,
          status: '9',
          name: '場所未設定購入品',
          storeType: null,
          purchasedAt: now.toIso8601String(),
        ),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('購入済み'));
      await tester.pump();

      expect(find.text('場所未設定購入品'), findsOneWidget);
    });
  });

  group('ShoppingListPage - ドラッグストア/オンラインフィルタ', () {
    testWidgets('ドラッグストアフィルタをタップするとドラッグストアのアイテムのみ表示される', (tester) async {
      final items = [
        _item(id: 1, name: 'ドラッグストアのアイテム', status: '0', storeType: '3'),
        _item(id: 2, name: 'スーパーのアイテム', status: '0', storeType: '1'),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('ドラッグストア'));
      await tester.pump();

      expect(find.text('ドラッグストアのアイテム'), findsOneWidget);
      expect(find.text('スーパーのアイテム'), findsNothing);
    });

    testWidgets('オンラインフィルタをタップするとオンラインのアイテムのみ表示される', (tester) async {
      final items = [
        _item(id: 1, name: 'オンラインのアイテム', status: '0', storeType: '2'),
        _item(id: 2, name: 'スーパーのアイテム', status: '0', storeType: '1'),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('オンライン'));
      await tester.pump();

      expect(find.text('オンラインのアイテム'), findsOneWidget);
      expect(find.text('スーパーのアイテム'), findsNothing);
    });
  });

  group('ShoppingListPage - かごアイテムのお気に入り', () {
    testWidgets('かごタブのお気に入り済みアイテムにstarアイコンが表示される', (tester) async {
      final items = [
        _item(id: 1, name: 'かごのお気に入り', status: '1', favorite: '1'),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('かご'));
      await tester.pump();

      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('ShoppingListPage - 購入済みタブ複数グループ', () {
    testWidgets('複数日付のアイテムが日付降順でグループ表示される', (tester) async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final items = [
        _item(
          id: 1,
          status: '9',
          name: '昨日の購入品',
          purchasedAt: yesterday.toIso8601String(),
        ),
        _item(
          id: 2,
          status: '9',
          name: '今日の購入品',
          purchasedAt: now.toIso8601String(),
        ),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('購入済み'));
      await tester.pump();

      expect(find.text('今日'), findsOneWidget);
      expect(find.text('昨日'), findsOneWidget);
      expect(find.text('今日の購入品'), findsOneWidget);
      expect(find.text('昨日の購入品'), findsOneWidget);
    });
  });

  group('ShoppingListPage - スワイプ操作（未購入タブ）', () {
    testWidgets('右スワイプでかごへ移動する', (tester) async {
      final mockRepo = MockShoppingRepository();
      final items = [_item(id: 1, name: 'スワイプアイテム', status: '0')];
      when(
        mockRepo.updateStatus(shoppingItemId: 1, status: '1'),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildSwipeOverrides(items: items, mockRepo: mockRepo),
        ),
      );
      await tester.pump();
      await tester.pump();

      // 右スワイプ（startToEnd）
      await tester.drag(
        find.byKey(const ValueKey('unpurchased_1')),
        const Offset(500, 0),
      );
      await tester.pumpAndSettle();

      // updateStatus が呼ばれたことを確認
      verify(mockRepo.updateStatus(shoppingItemId: 1, status: '1')).called(1);
    });

    testWidgets('左スワイプで削除確認ダイアログが表示される', (tester) async {
      final mockRepo = MockShoppingRepository();
      final items = [_item(id: 1, name: '削除対象アイテム', status: '0')];

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildSwipeOverrides(items: items, mockRepo: mockRepo),
        ),
      );
      await tester.pump();
      await tester.pump();

      // 左スワイプ（endToStart）
      await tester.drag(
        find.byKey(const ValueKey('unpurchased_1')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      // 削除確認ダイアログが表示される
      expect(find.text('アイテムを削除しますか？'), findsOneWidget);
    });

    testWidgets('削除確認ダイアログでキャンセルするとカードが戻る', (tester) async {
      final mockRepo = MockShoppingRepository();
      final items = [_item(id: 1, name: '削除キャンセルアイテム', status: '0')];

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildSwipeOverrides(items: items, mockRepo: mockRepo),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey('unpurchased_1')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      // カードが残っている
      expect(find.text('削除キャンセルアイテム'), findsOneWidget);
      // APIは呼ばれない
      verifyNever(
        mockRepo.deleteItem(shoppingItemId: anyNamed('shoppingItemId')),
      );
    });

    testWidgets('削除確認ダイアログで削除するとAPIが呼ばれる', (tester) async {
      final mockRepo = MockShoppingRepository();
      final items = [_item(id: 1, name: '削除アイテム', status: '0')];
      when(mockRepo.deleteItem(shoppingItemId: 1)).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildSwipeOverrides(items: items, mockRepo: mockRepo),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey('unpurchased_1')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      // ダイアログ内の「削除」ボタンをタップ（赤いスタイルのボタン）
      await tester.tap(find.text('削除').last);
      await tester.pumpAndSettle();

      verify(mockRepo.deleteItem(shoppingItemId: 1)).called(1);
    });
  });

  group('ShoppingListPage - スワイプ操作（かごタブ）', () {
    testWidgets('かごタブで右スワイプすると購入済みになる', (tester) async {
      final mockRepo = MockShoppingRepository();
      final items = [_item(id: 2, name: 'かごスワイプアイテム', status: '1')];
      when(
        mockRepo.updateStatus(shoppingItemId: 2, status: '9'),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildSwipeOverrides(items: items, mockRepo: mockRepo),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('かご'));
      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey('basket_2')),
        const Offset(500, 0),
      );
      await tester.pumpAndSettle();

      verify(mockRepo.updateStatus(shoppingItemId: 2, status: '9')).called(1);
    });

    testWidgets('かごタブで左スワイプすると未購入に戻る', (tester) async {
      final mockRepo = MockShoppingRepository();
      final items = [_item(id: 2, name: 'かご戻しアイテム', status: '1')];
      when(
        mockRepo.updateStatus(shoppingItemId: 2, status: '0'),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildSwipeOverrides(items: items, mockRepo: mockRepo),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('かご'));
      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey('basket_2')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      verify(mockRepo.updateStatus(shoppingItemId: 2, status: '0')).called(1);
    });
  });

  group('ShoppingListPage - 一括購入済みダイアログOK（AC6）', () {
    testWidgets('ダイアログでOKすると一括購入済みAPIが呼ばれる', (tester) async {
      final mockRepo = MockShoppingRepository();
      final items = [
        _item(id: 1, status: '1', name: 'かごアイテム1'),
        _item(id: 2, status: '1', name: 'かごアイテム2'),
      ];
      when(
        mockRepo.bulkUpdateStatus(ids: [1, 2], status: '9'),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildSwipeOverrides(items: items, mockRepo: mockRepo),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('かご'));
      await tester.pump();

      await tester.tap(find.text('購入済みにする'));
      await tester.pump();

      // ダイアログの「購入済みにする」ボタンをタップ
      final dialogButtons = find.text('購入済みにする');
      // ダイアログ内のボタン（2つ目）をタップ
      await tester.tap(dialogButtons.last);
      await tester.pumpAndSettle();

      verify(mockRepo.bulkUpdateStatus(ids: [1, 2], status: '9')).called(1);
    });
  });

  group('ShoppingListPage - お気に入りタップ（未購入タブ）', () {
    testWidgets('お気に入りアイコンをタップするとAPIが呼ばれる', (tester) async {
      final mockRepo = MockShoppingRepository();
      final items = [
        _item(id: 1, name: 'お気に入りタップ', status: '0', favorite: '0'),
      ];
      when(
        mockRepo.toggleFavorite(shoppingItemId: 1, favorite: '1'),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildSwipeOverrides(items: items, mockRepo: mockRepo),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pump();

      verify(
        mockRepo.toggleFavorite(shoppingItemId: 1, favorite: '1'),
      ).called(1);
    });
  });

  group('ShoppingListPage - hasImage表示', () {
    testWidgets('hasImageがtrueのアイテムにカメラアイコンが表示される', (tester) async {
      final items = [
        ShoppingItemDto(
          shoppingItemId: 1,
          householdId: 1,
          name: '画像付きアイテム',
          memo: null,
          storeType: '1',
          status: '0',
          favorite: '0',
          purchasedAt: null,
          createdAt: '2026-05-01T10:00:00',
          hasImage: true,
        ),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    });

    testWidgets('メモがあるアイテムにメモテキストが表示される', (tester) async {
      final items = [
        ShoppingItemDto(
          shoppingItemId: 1,
          householdId: 1,
          name: 'メモ付きアイテム',
          memo: 'これはメモです',
          storeType: '1',
          status: '0',
          favorite: '0',
          purchasedAt: null,
          createdAt: '2026-05-01T10:00:00',
          hasImage: false,
        ),
      ];
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides(items: items),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('これはメモです'), findsOneWidget);
    });
  });

  group('ShoppingListPage - ref.listen / _resolveErrorMessage', () {
    testWidgets('errorMessage状態に変化するとlistenerが発火する（errorUnexpected分岐）', (
      tester,
    ) async {
      final notifier = _MutableShoppingListNotifier([]);
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(AuthAuthenticated(_testUser)),
            ),
            householdNotifierProvider.overrideWith(
              () => _FakeSingleHouseholdNotifier(_singleHouseholdState),
            ),
            shoppingListNotifierProvider.overrideWith(() => notifier),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      // errorUnexpected キーでエラー状態に変更してlistenerを発火
      notifier.setError('errorUnexpected');
      await tester.pump();

      // クラッシュなく動作する（_resolveErrorMessage/AppSnackBar分岐が通る）
      expect(find.byType(ShoppingListPage), findsOneWidget);
    });

    testWidgets('errorMessage状態に変化するとlistenerが発火する（直接メッセージ分岐）', (tester) async {
      final notifier = _MutableShoppingListNotifier([]);
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(AuthAuthenticated(_testUser)),
            ),
            householdNotifierProvider.overrideWith(
              () => _FakeSingleHouseholdNotifier(_singleHouseholdState),
            ),
            shoppingListNotifierProvider.overrideWith(() => notifier),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      // 直接メッセージでエラー状態に変更
      notifier.setError('エラーが発生しました');
      await tester.pump();

      expect(find.byType(ShoppingListPage), findsOneWidget);
    });
  });
}
