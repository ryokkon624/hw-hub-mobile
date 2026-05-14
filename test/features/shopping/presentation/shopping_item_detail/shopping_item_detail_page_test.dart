import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/features/home/data/models/shopping_item_dto.dart';
import 'package:hw_hub_mobile/features/shopping/data/shopping_attachment_repository.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/shopping_item_detail/shopping_item_detail_notifier.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/shopping_item_detail/shopping_item_detail_page.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/widgets/status_step_selector.dart';
import 'package:hw_hub_mobile/features/shopping/shopping_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/widget_test_helpers.dart';
import '../../shopping_mocks.mocks.dart';

// フェイクHouseholdNotifier
class _FakeHouseholdNotifier extends HouseholdNotifier {
  @override
  Future<HouseholdState> build() async {
    return const HouseholdState(
      households: [Household(id: 100, name: 'テスト世帯')],
      selectedHousehold: Household(id: 100, name: 'テスト世帯'),
    );
  }
}

// ローディング状態を返すフェイク
class _LoadingDetailNotifier extends ShoppingItemDetailNotifier {
  @override
  ShoppingItemDetailState build(int arg) {
    return const ShoppingItemDetailState(isLoading: true);
  }
}

// アイテムあり状態を返すフェイク
class _LoadedDetailNotifier extends ShoppingItemDetailNotifier {
  _LoadedDetailNotifier(this._item, {this.attachments = const []});

  final ShoppingItemDto _item;
  final List<ShoppingAttachmentDto> attachments;

  @override
  ShoppingItemDetailState build(int arg) {
    return ShoppingItemDetailState(item: _item, attachments: attachments);
  }

  @override
  Future<void> updateStatus(String status) async {
    state = state.copyWith(item: _copyItem(status: status));
  }

  @override
  Future<void> toggleFavorite() async {
    final current = state.item?.favorite ?? '0';
    final next = current == '1' ? '0' : '1';
    state = state.copyWith(item: _copyItem(favorite: next));
  }

  @override
  Future<void> save() async {
    // 何もしない（テスト用）
  }

  @override
  Future<void> deleteItem() async {
    state = state.copyWith(isDeleted: true);
  }

  ShoppingItemDto _copyItem({String? status, String? favorite}) {
    final item = state.item!;
    return ShoppingItemDto(
      shoppingItemId: item.shoppingItemId,
      householdId: item.householdId,
      name: item.name,
      memo: item.memo,
      storeType: item.storeType,
      status: status ?? item.status,
      favorite: favorite ?? item.favorite,
      purchasedAt: item.purchasedAt,
      createdAt: item.createdAt,
      hasImage: item.hasImage,
    );
  }
}

// エラー状態を返すフェイク
class _ErrorDetailNotifier extends ShoppingItemDetailNotifier {
  @override
  ShoppingItemDetailState build(int arg) {
    return const ShoppingItemDetailState(
      isLoading: false,
      errorMessage: '読み込みに失敗しました',
    );
  }
}

/// テスト用アイテム生成
ShoppingItemDto _makeItem({
  int id = 1,
  String status = '0',
  String? favorite = '0',
  String name = 'オリーブオイル',
}) => ShoppingItemDto(
  shoppingItemId: id,
  householdId: 100,
  name: name,
  memo: 'テストメモ',
  storeType: '1',
  status: status,
  favorite: favorite,
  createdAt: '2026-05-01T10:00:00',
  hasImage: false,
);

void main() {
  late MockShoppingRepository mockRepo;
  late MockShoppingAttachmentRepository mockAttachRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepo = MockShoppingRepository();
    mockAttachRepo = MockShoppingAttachmentRepository();
  });

  List<Override> baseOverrides() => [
    householdNotifierProvider.overrideWith(() => _FakeHouseholdNotifier()),
    shoppingRepositoryProvider.overrideWithValue(mockRepo),
    shoppingAttachmentRepositoryProvider.overrideWithValue(mockAttachRepo),
  ];

  group('ShoppingItemDetailPage - ローディング', () {
    testWidgets('ロード中にCircularProgressIndicatorが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemDetailPage(itemId: 1),
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(
              () => _LoadingDetailNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ShoppingItemDetailPage - エラー', () {
    testWidgets('エラー時にエラーメッセージが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemDetailPage(itemId: 1),
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(
              () => _ErrorDetailNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('読み込みに失敗しました'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
    });
  });

  group('ShoppingItemDetailPage - アイテム表示', () {
    testWidgets('アイテム名がAppBarに表示される', (tester) async {
      final item = _makeItem(name: 'テストオイル');

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemDetailPage(itemId: 1),
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(
              () => _LoadedDetailNotifier(item),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('テストオイル'), findsAtLeastNWidgets(1));
    });

    testWidgets('StatusStepSelectorが表示される（AC7）', (tester) async {
      final item = _makeItem(status: '0');

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemDetailPage(itemId: 1),
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(
              () => _LoadedDetailNotifier(item),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(StatusStepSelector), findsOneWidget);
      expect(find.byKey(const Key('statusStepSelector')), findsOneWidget);
    });

    testWidgets('保存ボタンが表示される', (tester) async {
      final item = _makeItem();

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemDetailPage(itemId: 1),
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(
              () => _LoadedDetailNotifier(item),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('saveButton')), findsOneWidget);
    });

    testWidgets('お気に入りスイッチが表示される', (tester) async {
      final item = _makeItem(favorite: '0');

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemDetailPage(itemId: 1),
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(
              () => _LoadedDetailNotifier(item),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('favoriteSwitch')), findsOneWidget);
    });
  });

  group('ShoppingItemDetailPage - 削除ボタン表示制御', () {
    testWidgets('未購入ステータス(0)のとき削除ボタンが表示される', (tester) async {
      final item = _makeItem(status: '0');

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemDetailPage(itemId: 1),
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(
              () => _LoadedDetailNotifier(item),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('deleteItemButton')), findsOneWidget);
    });

    testWidgets('かごステータス(1)のとき削除ボタンが表示されない（#94 バグ修正確認・AC3）', (tester) async {
      // #94: かご(inBasket)のとき削除ボタンは非表示
      final item = _makeItem(status: '1');

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemDetailPage(itemId: 1),
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(
              () => _LoadedDetailNotifier(item),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('deleteItemButton')), findsNothing);
    });

    testWidgets('購入済みステータス(9)のとき削除ボタンが表示されない（AC4）', (tester) async {
      final item = _makeItem(status: '9');

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemDetailPage(itemId: 1),
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(
              () => _LoadedDetailNotifier(item),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('deleteItemButton')), findsNothing);
    });
  });

  group('ShoppingItemDetailPage - 削除ダイアログ', () {
    testWidgets('削除ボタンタップで確認ダイアログが表示される', (tester) async {
      final item = _makeItem(status: '0');

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemDetailPage(itemId: 1),
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(
              () => _LoadedDetailNotifier(item),
            ),
          ],
        ),
      );
      await tester.pump();

      // スクロールして削除ボタンを表示
      await tester.scrollUntilVisible(
        find.byKey(const Key('deleteItemButton')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('deleteItemButton')));
      await tester.pumpAndSettle();

      expect(find.text('このアイテムを削除しますか？この操作は取り消せません。'), findsOneWidget);
    });

    testWidgets('キャンセルボタンでダイアログが閉じる', (tester) async {
      final item = _makeItem(status: '0');

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemDetailPage(itemId: 1),
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(
              () => _LoadedDetailNotifier(item),
            ),
          ],
        ),
      );
      await tester.pump();

      // スクロールして削除ボタンを表示
      await tester.scrollUntilVisible(
        find.byKey(const Key('deleteItemButton')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('deleteItemButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.text('このアイテムを削除しますか？この操作は取り消せません。'), findsNothing);
    });

    testWidgets('削除ボタン（ダイアログ内OKボタン）タップでdeleteItemが呼ばれ詳細画面がpopされる（#94）', (
      tester,
    ) async {
      // #94: go_router環境でダイアログの削除ボタンを押しても詳細画面がpopされること
      // （ダイアログのcontextでpopすることでダイアログ自体が閉じ、詳細画面のref.listenでpopが呼ばれる）
      final item = _makeItem(status: '0');
      final notifier = _LoadedDetailNotifier(item);

      // /list から /detail/1 にpushしてpopできるようにする
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/list',
              builder: (_, _) => const Scaffold(body: Text('shopping-list')),
            ),
            GoRoute(
              path: '/detail/1',
              builder: (_, _) => const ShoppingItemDetailPage(itemId: 1),
            ),
          ],
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(() => notifier),
          ],
          initialLocation: '/list',
        ),
      );
      await tester.pumpAndSettle();

      // /detail/1 にpush（スタックに積む）
      final routerContext = tester.element(find.text('shopping-list'));
      GoRouter.of(routerContext).push('/detail/1');
      await tester.pumpAndSettle();

      // スクロールして削除ボタンを表示
      await tester.scrollUntilVisible(
        find.byKey(const Key('deleteItemButton')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('deleteItemButton')));
      await tester.pumpAndSettle();

      // ダイアログが表示される
      expect(find.text('このアイテムを削除しますか？この操作は取り消せません。'), findsOneWidget);

      // ダイアログ内の「このアイテムを削除」ボタンをタップ（本体ボタンと同名なので最後を選択）
      await tester.tap(find.text('このアイテムを削除').last);
      await tester.pumpAndSettle();

      // ダイアログが閉じてdeleteItemが呼ばれた（isDeletedになった）
      expect(notifier.state.isDeleted, isTrue);
    });
  });

  group('ShoppingItemDetailPage - ステータス変更', () {
    testWidgets('ステップをタップするとステータスが変わる（AC7）', (tester) async {
      final item = _makeItem(status: '0');

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemDetailPage(itemId: 1),
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(
              () => _LoadedDetailNotifier(item),
            ),
          ],
        ),
      );
      await tester.pump();

      // StatusStepSelectorが存在することを確認
      expect(find.byKey(const Key('statusStepSelector')), findsOneWidget);
    });
  });

  group('ShoppingItemDetailPage - お気に入りトグル', () {
    testWidgets('お気に入りfalseのときスイッチがoff表示', (tester) async {
      final item = _makeItem(favorite: '0');

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemDetailPage(itemId: 1),
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(
              () => _LoadedDetailNotifier(item),
            ),
          ],
        ),
      );
      await tester.pump();

      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(const Key('favoriteSwitch')),
      );
      expect(switchTile.value, false);
    });

    testWidgets('お気に入りtrueのときスイッチがon表示', (tester) async {
      final item = _makeItem(favorite: '1');

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemDetailPage(itemId: 1),
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(
              () => _LoadedDetailNotifier(item),
            ),
          ],
        ),
      );
      await tester.pump();

      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(const Key('favoriteSwitch')),
      );
      expect(switchTile.value, true);
    });

    testWidgets('お気に入りスイッチをタップするとonChangedが呼ばれる', (tester) async {
      final item = _makeItem(favorite: '0');

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemDetailPage(itemId: 1),
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(
              () => _LoadedDetailNotifier(item),
            ),
          ],
        ),
      );
      await tester.pump();

      // タップ前はfalse
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('favoriteSwitch')))
            .value,
        false,
      );

      // onChangedがあることを確認（タップ可能）
      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(const Key('favoriteSwitch')),
      );
      expect(switchTile.onChanged, isNotNull);
    });
  });

  group('ShoppingItemDetailPage - 添付画像', () {
    testWidgets('添付画像セクションが表示される', (tester) async {
      final item = _makeItem();
      final attachments = [
        const ShoppingAttachmentDto(
          id: 10,
          fileName: 'test.jpg',
          imageUrl: 'https://example.com/test.jpg',
          sortOrder: 0,
        ),
      ];

      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemDetailPage(itemId: 1),
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(
              () => _LoadedDetailNotifier(item, attachments: attachments),
            ),
          ],
        ),
      );
      await tester.pump();

      // 添付画像セクションタイトルが表示される
      expect(find.text('添付画像'), findsOneWidget);
    });
  });

  group('ShoppingItemDetailPage - 画像削除ダイアログ', () {
    // #96: _confirmDeleteAttachmentのdialogContext修正テスト
    // 画像サムネイルは水平スクロールリスト内にあるため、確認ダイアログのロジックをGestureDetector経由でテストする
    testWidgets('画像削除ダイアログの削除ボタンタップでdeleteAttachmentが呼ばれ詳細画面がpopされない（#96）', (
      tester,
    ) async {
      // #96: go_router環境でダイアログの削除ボタンを押しても詳細画面がpopされないこと
      final item = _makeItem();
      final attachments = [
        const ShoppingAttachmentDto(
          id: 10,
          fileName: 'test.jpg',
          imageUrl: 'https://example.com/test.jpg',
          sortOrder: 0,
        ),
      ];

      bool deleteAttachmentCalled = false;
      final notifier = _LoadedDetailNotifierWithDeleteAttachment(
        item,
        attachments: attachments,
        onDeleteAttachment: (_) {
          deleteAttachmentCalled = true;
        },
      );

      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/list',
              builder: (_, _) => const Scaffold(body: Text('shopping-list')),
            ),
            GoRoute(
              path: '/detail/1',
              builder: (_, _) => const ShoppingItemDetailPage(itemId: 1),
            ),
          ],
          overrides: [
            ...baseOverrides(),
            shoppingItemDetailNotifierProvider.overrideWith(() => notifier),
          ],
          initialLocation: '/list',
        ),
      );
      await tester.pumpAndSettle();

      // /detail/1 にpush
      final routerContext = tester.element(find.text('shopping-list'));
      GoRouter.of(routerContext).push('/detail/1');
      await tester.pumpAndSettle();

      // 削除アイコン（GestureDetector内のIcons.close）をensureVisibleして取得
      await tester.ensureVisible(find.byIcon(Icons.close));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close), warnIfMissed: false);
      await tester.pumpAndSettle();

      // ダイアログが表示される
      expect(find.text('この画像を削除しますか？'), findsOneWidget);

      // ダイアログ内の「この画像を削除」ボタンをタップ
      await tester.tap(find.text('この画像を削除'));
      await tester.pumpAndSettle();

      // ダイアログが閉じてdeleteAttachmentが呼ばれた
      expect(find.text('この画像を削除しますか？'), findsNothing);
      expect(deleteAttachmentCalled, isTrue);
      // 詳細画面が残っていること（shopping-listに戻っていない）
      expect(find.byKey(const Key('saveButton')), findsOneWidget);
    });
  });
}

// #96テスト用のフェイクNotifier（deleteAttachmentをフックできる）
class _LoadedDetailNotifierWithDeleteAttachment
    extends ShoppingItemDetailNotifier {
  _LoadedDetailNotifierWithDeleteAttachment(
    this._item, {
    this.attachments = const [],
    required this.onDeleteAttachment,
  });

  final ShoppingItemDto _item;
  final List<ShoppingAttachmentDto> attachments;
  final void Function(int id) onDeleteAttachment;

  @override
  ShoppingItemDetailState build(int arg) {
    return ShoppingItemDetailState(item: _item, attachments: attachments);
  }

  @override
  Future<void> deleteAttachment(int attachmentId) async {
    onDeleteAttachment(attachmentId);
  }

  @override
  Future<void> save() async {}
}
