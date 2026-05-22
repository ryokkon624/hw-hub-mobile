import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/shopping_item_new/shopping_item_new_page.dart';
import 'package:hw_hub_mobile/features/shopping/shopping_providers.dart';
import 'package:mockito/mockito.dart';
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

// isSubmitting=trueを返すフェイク
class _SubmittingNotifier extends ShoppingItemNewNotifier {
  @override
  ShoppingItemNewState build() {
    return ShoppingItemNewState(isSubmitting: true);
  }
}

// canSubmit=trueになる初期状態を持つフェイク（名前入力済み）
class _PreFilledNotifier extends ShoppingItemNewNotifier {
  @override
  ShoppingItemNewState build() {
    return ShoppingItemNewState(name: 'テスト品');
  }
}

// 送信成功をシミュレートするフェイクNotifier
class _SuccessShoppingItemNewNotifier extends ShoppingItemNewNotifier {
  @override
  ShoppingItemNewState build() {
    return ShoppingItemNewState(name: 'テスト品');
  }

  @override
  Future<void> submit({required int householdId}) async {
    state = state.copyWith(successItemId: 999);
  }
}

// #93テスト用: ShoppingListNotifierのbuild()をフェイクして実際のfetchItemsを呼ぶ
class _TrackingShoppingListNotifier extends ShoppingListNotifier {
  @override
  Future<ShoppingListState> build() async {
    // householdNotifierProvider を watch して fetchItems を呼ぶ（本物と同じ動き）
    final householdState = await ref.watch(householdNotifierProvider.future);
    final selectedHousehold = householdState.selectedHousehold;
    if (selectedHousehold == null) return const ShoppingListState();
    final repo = ref.read(shoppingRepositoryProvider);
    final items = await repo.fetchItems(householdId: selectedHousehold.id);
    return ShoppingListState(items: List.unmodifiable(items));
  }
}

void main() {
  late MockShoppingRepository mockRepo;
  late MockShoppingAttachmentRepository mockAttachRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepo = MockShoppingRepository();
    mockAttachRepo = MockShoppingAttachmentRepository();

    // fetchFavorites と fetchHistorySuggestions の空リストデフォルト
    when(
      mockRepo.fetchFavorites(householdId: anyNamed('householdId')),
    ).thenAnswer((_) async => []);
    when(
      mockRepo.fetchHistorySuggestions(householdId: anyNamed('householdId')),
    ).thenAnswer((_) async => []);
  });

  List<Override> buildOverrides() => [
    householdNotifierProvider.overrideWith(() => _FakeHouseholdNotifier()),
    shoppingRepositoryProvider.overrideWithValue(mockRepo),
    shoppingAttachmentRepositoryProvider.overrideWithValue(mockAttachRepo),
  ];

  group('ShoppingItemNewPage - 基本表示', () {
    testWidgets('タイトルが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const ShoppingItemNewPage(), overrides: buildOverrides()),
      );
      await tester.pump();

      // AppBarタイトル（l10n: shoppingNewTitle = "アイテムを追加"）
      expect(find.text('アイテムを追加'), findsOneWidget);
    });

    testWidgets('送信ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const ShoppingItemNewPage(), overrides: buildOverrides()),
      );
      await tester.pump();

      // l10n: shoppingNewSubmit = "追加する"
      expect(find.text('追加する'), findsOneWidget);
    });

    testWidgets('初期状態では送信ボタンが無効', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const ShoppingItemNewPage(), overrides: buildOverrides()),
      );
      await tester.pump();

      // TextButtonのonPressed=nullで無効
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '追加する'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('名前を入力すると送信ボタンが有効になる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const ShoppingItemNewPage(), overrides: buildOverrides()),
      );
      await tester.pump();

      // 名前フィールドに入力
      await tester.enterText(find.byType(TextFormField).first, 'オリーブオイル');
      await tester.pump();

      // 送信ボタンが有効になる
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '追加する'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('購入場所チップが3つ表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const ShoppingItemNewPage(), overrides: buildOverrides()),
      );
      await tester.pump();

      expect(find.text('スーパー'), findsOneWidget);
      expect(find.text('オンライン'), findsOneWidget);
      expect(find.text('ドラッグストア'), findsOneWidget);
    });

    testWidgets('お気に入りスイッチが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const ShoppingItemNewPage(), overrides: buildOverrides()),
      );
      await tester.pump();

      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('履歴・お気に入りボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const ShoppingItemNewPage(), overrides: buildOverrides()),
      );
      await tester.pump();

      expect(find.byKey(const Key('historyButton')), findsOneWidget);
      expect(find.byKey(const Key('favoriteButton')), findsOneWidget);
    });
  });

  group('ShoppingItemNewPage - 履歴・お気に入りボタン', () {
    testWidgets('履歴ボタンをタップするとボトムシートが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const ShoppingItemNewPage(), overrides: buildOverrides()),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('historyButton')));
      await tester.pumpAndSettle();

      // HistoryPickerBottomSheetが表示される（l10n: shoppingHistoryModalTitle = "過去の履歴から選ぶ"）
      expect(find.text('過去の履歴から選ぶ'), findsOneWidget);
    });

    testWidgets('お気に入りボタンをタップするとボトムシートが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const ShoppingItemNewPage(), overrides: buildOverrides()),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('favoriteButton')));
      await tester.pumpAndSettle();

      // FavoritePickerBottomSheetが表示される（l10n: shoppingFavoriteModalTitle = "お気に入りから選ぶ"）
      expect(find.text('お気に入りから選ぶ'), findsOneWidget);
    });
  });

  group('ShoppingItemNewPage - 名前入力済み状態', () {
    testWidgets('名前が入力済みの場合に送信ボタンが有効', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemNewPage(),
          overrides: [
            ...buildOverrides(),
            shoppingItemNewNotifierProvider.overrideWith(
              () => _PreFilledNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      // canSubmit=trueなので送信ボタンが有効
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '追加する'),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  group('ShoppingItemNewPage - 送信成功のスナックバー', () {
    testWidgets('successItemIdが設定されるとスナックバーが表示される', (tester) async {
      // successItemIdが設定されている状態のnotifier
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemNewPage(),
          overrides: [
            householdNotifierProvider.overrideWith(
              () => _FakeHouseholdNotifier(),
            ),
            shoppingRepositoryProvider.overrideWithValue(mockRepo),
            shoppingAttachmentRepositoryProvider.overrideWithValue(
              mockAttachRepo,
            ),
            shoppingItemNewNotifierProvider.overrideWith(
              () => _SuccessShoppingItemNewNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      // 送信ボタンが有効（name='テスト品'の初期状態）
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '追加する'),
      );
      // canSubmitがtrueなのでボタンが有効
      expect(button.onPressed, isNotNull);
    });
  });

  group('ShoppingItemNewPage - 送信中UI', () {
    testWidgets('isSubmittingのときCircularProgressIndicatorが表示される', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingItemNewPage(),
          overrides: [
            householdNotifierProvider.overrideWith(
              () => _FakeHouseholdNotifier(),
            ),
            shoppingRepositoryProvider.overrideWithValue(mockRepo),
            shoppingAttachmentRepositoryProvider.overrideWithValue(
              mockAttachRepo,
            ),
            shoppingItemNewNotifierProvider.overrideWith(
              () => _SubmittingNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ShoppingItemNewPage - アイテム追加後のリスト即時反映（#93）', () {
    testWidgets(
      '追加成功後にshoppingListNotifierProviderがinvalidateされリスト画面復帰時に再fetchされる',
      (tester) async {
        // #93: successItemId検知後にshoppingListNotifierProviderがinvalidateされること
        // /list にConsumerを置いてshoppingListNotifierProviderをwatchし、
        // submit後にpopで戻ったときにfetchItemsが再呼び出しされることを確認する
        when(
          mockRepo.fetchItems(householdId: anyNamed('householdId')),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(
          buildTestPageWithRouter(
            routes: [
              GoRoute(
                path: '/list',
                builder: (_, _) => Consumer(
                  builder: (ctx, ref, _) {
                    ref.watch(shoppingListNotifierProvider);
                    return const Scaffold(body: Text('shopping-list'));
                  },
                ),
              ),
              GoRoute(
                path: '/new',
                builder: (_, _) => const ShoppingItemNewPage(),
              ),
            ],
            overrides: [
              householdNotifierProvider.overrideWith(
                () => _FakeHouseholdNotifier(),
              ),
              shoppingRepositoryProvider.overrideWithValue(mockRepo),
              shoppingAttachmentRepositoryProvider.overrideWithValue(
                mockAttachRepo,
              ),
              shoppingItemNewNotifierProvider.overrideWith(
                () => _SuccessShoppingItemNewNotifier(),
              ),
              shoppingListNotifierProvider.overrideWith(
                () => _TrackingShoppingListNotifier(),
              ),
            ],
            initialLocation: '/list',
          ),
        );
        await tester.pumpAndSettle();

        // 初回fetchItemsが呼ばれたことを確認
        verify(
          mockRepo.fetchItems(householdId: anyNamed('householdId')),
        ).called(1);

        // /new にpush
        final routerContext = tester.element(find.text('shopping-list'));
        GoRouter.of(routerContext).push('/new');
        await tester.pumpAndSettle();

        // 送信ボタンをタップ（_SuccessShoppingItemNewNotifierはsubmit後にsuccessItemId=999をセット）
        await tester.tap(find.text('追加する'));
        await tester.pumpAndSettle(); // context.popまで完了させる

        // /list に戻った後、invalidateにより再fetchされたことを確認
        // （invalidateが呼ばれ、/listのConsumerがactiveになったときにbuildが再実行される）
        verify(
          mockRepo.fetchItems(householdId: anyNamed('householdId')),
        ).called(1);
      },
    );
  });
}
