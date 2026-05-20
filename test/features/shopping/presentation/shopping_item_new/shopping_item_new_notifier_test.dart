import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/home/data/models/shopping_item_dto.dart';
import 'package:hw_hub_mobile/features/shopping/data/models/create_upload_url_response.dart';
import 'package:hw_hub_mobile/features/shopping/data/models/shopping_item_history_suggestion_dto.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/shopping_item_new/shopping_item_new_notifier.dart';
import 'package:hw_hub_mobile/features/shopping/shopping_providers.dart';
import 'package:mockito/mockito.dart';

import '../../shopping_mocks.mocks.dart';

/// テスト用 ShoppingItemDto
ShoppingItemDto _makeItem({int id = 1}) => ShoppingItemDto(
  shoppingItemId: id,
  householdId: 100,
  name: 'オリーブオイル',
  storeType: '1',
  status: '0',
  favorite: '0',
  createdAt: '2026-05-01T10:00:00',
  hasImage: false,
);

void main() {
  late MockShoppingRepository mockRepo;
  late MockShoppingAttachmentRepository mockAttachRepo;

  setUp(() {
    mockRepo = MockShoppingRepository();
    mockAttachRepo = MockShoppingAttachmentRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        shoppingRepositoryProvider.overrideWithValue(mockRepo),
        shoppingAttachmentRepositoryProvider.overrideWithValue(mockAttachRepo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ShoppingItemNewNotifier 初期状態', () {
    test('デフォルト値が正しく設定されている', () {
      final container = makeContainer();
      final state = container.read(shoppingItemNewNotifierProvider);
      expect(state.name, '');
      expect(state.storeType, '1');
      expect(state.favorite, '0');
      expect(state.isSubmitting, false);
      expect(state.canSubmit, false); // name が空なので false
    });
  });

  group('ShoppingItemNewNotifier フォーム入力', () {
    test('setName: 名前を更新する', () {
      final container = makeContainer();
      container.read(shoppingItemNewNotifierProvider.notifier).setName('牛乳');
      expect(container.read(shoppingItemNewNotifierProvider).name, '牛乳');
      expect(container.read(shoppingItemNewNotifierProvider).canSubmit, true);
    });

    test('setMemo: メモを更新する', () {
      final container = makeContainer();
      container.read(shoppingItemNewNotifierProvider.notifier).setMemo('安いやつ');
      expect(container.read(shoppingItemNewNotifierProvider).memo, '安いやつ');
    });

    test('setStoreType: 購入場所を更新する', () {
      final container = makeContainer();
      container
          .read(shoppingItemNewNotifierProvider.notifier)
          .setStoreType('2');
      expect(container.read(shoppingItemNewNotifierProvider).storeType, '2');
    });

    test('setFavorite: お気に入りフラグを更新する', () {
      final container = makeContainer();
      container.read(shoppingItemNewNotifierProvider.notifier).setFavorite('1');
      expect(container.read(shoppingItemNewNotifierProvider).favorite, '1');
    });
  });

  group('ShoppingItemNewNotifier fetchHistorySuggestions', () {
    test('成功時: サジェスト一覧を返す', () async {
      final container = makeContainer();
      when(
        mockRepo.fetchHistorySuggestions(householdId: anyNamed('householdId')),
      ).thenAnswer(
        (_) async => [
          const ShoppingItemHistorySuggestionDto(name: '牛乳', purchaseCount: 3),
        ],
      );

      final result = await container
          .read(shoppingItemNewNotifierProvider.notifier)
          .fetchHistorySuggestions(householdId: 100);

      expect(result, hasLength(1));
      expect(result.first.name, '牛乳');
    });

    test('失敗時: 空リストを返して errorMessage をセットする', () async {
      final container = makeContainer();
      when(
        mockRepo.fetchHistorySuggestions(householdId: anyNamed('householdId')),
      ).thenThrow(const NetworkException('接続エラー'));

      final result = await container
          .read(shoppingItemNewNotifierProvider.notifier)
          .fetchHistorySuggestions(householdId: 100);

      expect(result, isEmpty);
      expect(
        container.read(shoppingItemNewNotifierProvider).errorMessage,
        isNotNull,
      );
    });
  });

  group('ShoppingItemNewNotifier fetchFavorites', () {
    test('成功時: お気に入り一覧を返す', () async {
      final container = makeContainer();
      when(
        mockRepo.fetchFavorites(householdId: anyNamed('householdId')),
      ).thenAnswer((_) async => [_makeItem(id: 1)]);

      final result = await container
          .read(shoppingItemNewNotifierProvider.notifier)
          .fetchFavorites(householdId: 100);

      expect(result, hasLength(1));
    });

    test('失敗時: 空リストを返して errorMessage をセットする', () async {
      final container = makeContainer();
      when(
        mockRepo.fetchFavorites(householdId: anyNamed('householdId')),
      ).thenThrow(const NetworkException('接続エラー'));

      final result = await container
          .read(shoppingItemNewNotifierProvider.notifier)
          .fetchFavorites(householdId: 100);

      expect(result, isEmpty);
      expect(
        container.read(shoppingItemNewNotifierProvider).errorMessage,
        isNotNull,
      );
    });
  });

  group('ShoppingItemNewNotifier setFromHistory', () {
    test('履歴から選択すると name/storeType/sourceShoppingItemId をセットする', () {
      final container = makeContainer();
      final suggestion = const ShoppingItemHistorySuggestionDto(
        name: 'オリーブオイル',
        storeType: '3',
        purchaseCount: 2,
        sourceShoppingItemId: 5,
      );
      container
          .read(shoppingItemNewNotifierProvider.notifier)
          .setFromHistory(suggestion);

      final state = container.read(shoppingItemNewNotifierProvider);
      expect(state.name, 'オリーブオイル');
      expect(state.storeType, '3');
      expect(state.sourceShoppingItemId, 5);
    });

    test('履歴から選択するとメモが反映される（メモあり）', () {
      final container = makeContainer();
      final suggestion = const ShoppingItemHistorySuggestionDto(
        name: 'オリーブオイル',
        memo: '安いやつを買う',
        storeType: '3',
        purchaseCount: 2,
        sourceShoppingItemId: 5,
      );
      container
          .read(shoppingItemNewNotifierProvider.notifier)
          .setFromHistory(suggestion);

      final state = container.read(shoppingItemNewNotifierProvider);
      expect(state.memo, '安いやつを買う');
    });

    test('履歴から選択するとメモが空になる（メモなし）', () {
      final container = makeContainer();
      // 先にメモを設定しておく
      container
          .read(shoppingItemNewNotifierProvider.notifier)
          .setMemo('事前入力のメモ');
      final suggestion = const ShoppingItemHistorySuggestionDto(
        name: 'オリーブオイル',
        storeType: '3',
        purchaseCount: 2,
        sourceShoppingItemId: 5,
        // memo は null
      );
      container
          .read(shoppingItemNewNotifierProvider.notifier)
          .setFromHistory(suggestion);

      final state = container.read(shoppingItemNewNotifierProvider);
      expect(state.memo, '');
    });
  });

  group('ShoppingItemNewNotifier setFromFavorite', () {
    test('お気に入りから選択すると name/storeType/sourceShoppingItemId をセットする', () {
      final container = makeContainer();
      final item = _makeItem();
      container
          .read(shoppingItemNewNotifierProvider.notifier)
          .setFromFavorite(item);

      final state = container.read(shoppingItemNewNotifierProvider);
      expect(state.name, 'オリーブオイル');
      expect(state.storeType, '1');
      expect(state.sourceShoppingItemId, 1);
    });

    test('お気に入りから選択するとメモが反映される（メモあり）', () {
      final container = makeContainer();
      final item = ShoppingItemDto(
        shoppingItemId: 1,
        householdId: 100,
        name: 'オリーブオイル',
        memo: '高級品を買う',
        storeType: '1',
        status: '0',
        favorite: '1',
        createdAt: '2026-05-01T10:00:00',
        hasImage: false,
      );
      container
          .read(shoppingItemNewNotifierProvider.notifier)
          .setFromFavorite(item);

      final state = container.read(shoppingItemNewNotifierProvider);
      expect(state.memo, '高級品を買う');
    });

    test('お気に入りから選択するとメモが空になる（メモなし）', () {
      final container = makeContainer();
      // 先にメモを設定しておく
      container
          .read(shoppingItemNewNotifierProvider.notifier)
          .setMemo('事前入力のメモ');
      final item = _makeItem(); // memo は null
      container
          .read(shoppingItemNewNotifierProvider.notifier)
          .setFromFavorite(item);

      final state = container.read(shoppingItemNewNotifierProvider);
      expect(state.memo, '');
    });
  });

  group('ShoppingItemNewNotifier setPickedImage / clearImage', () {
    test('setPickedImage: 画像バイトと名前をセットする', () {
      final container = makeContainer();
      final bytes = Uint8List.fromList([1, 2, 3]);
      container
          .read(shoppingItemNewNotifierProvider.notifier)
          .setPickedImage(bytes, 'test.jpg');

      final state = container.read(shoppingItemNewNotifierProvider);
      expect(state.hasImage, true);
      expect(state.pickedImageName, 'test.jpg');
    });

    test('clearImage: 画像をクリアする', () {
      final container = makeContainer();
      container
          .read(shoppingItemNewNotifierProvider.notifier)
          .setPickedImage(Uint8List.fromList([1, 2, 3]), 'test.jpg');
      container.read(shoppingItemNewNotifierProvider.notifier).clearImage();

      expect(container.read(shoppingItemNewNotifierProvider).hasImage, false);
    });
  });

  group('ShoppingItemNewNotifier submit', () {
    test('成功時: successItemId がセットされ isSubmitting が false に戻る', () async {
      final container = makeContainer();
      container.read(shoppingItemNewNotifierProvider.notifier).setName('牛乳');
      when(
        mockRepo.createItem(
          householdId: anyNamed('householdId'),
          req: anyNamed('req'),
        ),
      ).thenAnswer((_) async => _makeItem(id: 10));

      await container
          .read(shoppingItemNewNotifierProvider.notifier)
          .submit(householdId: 100);

      final state = container.read(shoppingItemNewNotifierProvider);
      expect(state.successItemId, 10);
      expect(state.isSubmitting, false);
      expect(state.errorMessage, isNull);
    });

    test('画像がある場合: createItem → uploadToS3 → createAttachment を順に呼ぶ', () async {
      final container = makeContainer();
      container.read(shoppingItemNewNotifierProvider.notifier).setName('牛乳');
      final bytes = Uint8List.fromList([1, 2, 3]);
      container
          .read(shoppingItemNewNotifierProvider.notifier)
          .setPickedImage(bytes, 'test.jpg');

      when(
        mockRepo.createItem(
          householdId: anyNamed('householdId'),
          req: anyNamed('req'),
        ),
      ).thenAnswer((_) async => _makeItem(id: 10));

      when(
        mockAttachRepo.createUploadUrl(
          itemId: anyNamed('itemId'),
          req: anyNamed('req'),
        ),
      ).thenAnswer(
        (_) async => const CreateUploadUrlResponse(
          uploadUrl: 'https://s3.example.com/upload',
          fileKey: 'shopping/10/test.jpg',
        ),
      );

      when(
        mockAttachRepo.uploadToS3(
          uploadUrl: anyNamed('uploadUrl'),
          bytes: anyNamed('bytes'),
          mimeType: anyNamed('mimeType'),
        ),
      ).thenAnswer((_) async {});

      when(
        mockAttachRepo.createAttachment(
          itemId: anyNamed('itemId'),
          req: anyNamed('req'),
        ),
      ).thenAnswer((_) async {});

      await container
          .read(shoppingItemNewNotifierProvider.notifier)
          .submit(householdId: 100);

      verify(
        mockAttachRepo.createUploadUrl(
          itemId: anyNamed('itemId'),
          req: anyNamed('req'),
        ),
      ).called(1);
      verify(
        mockAttachRepo.uploadToS3(
          uploadUrl: anyNamed('uploadUrl'),
          bytes: anyNamed('bytes'),
          mimeType: anyNamed('mimeType'),
        ),
      ).called(1);
      verify(
        mockAttachRepo.createAttachment(
          itemId: anyNamed('itemId'),
          req: anyNamed('req'),
        ),
      ).called(1);
    });

    test('name が空の場合: submit を呼んでも何もしない', () async {
      final container = makeContainer();
      // name は空のまま
      await container
          .read(shoppingItemNewNotifierProvider.notifier)
          .submit(householdId: 100);

      verifyNever(
        mockRepo.createItem(
          householdId: anyNamed('householdId'),
          req: anyNamed('req'),
        ),
      );
    });

    test('createItem が失敗した場合: errorMessage がセットされる', () async {
      final container = makeContainer();
      container.read(shoppingItemNewNotifierProvider.notifier).setName('牛乳');
      when(
        mockRepo.createItem(
          householdId: anyNamed('householdId'),
          req: anyNamed('req'),
        ),
      ).thenThrow(const NetworkException('接続エラー'));

      await container
          .read(shoppingItemNewNotifierProvider.notifier)
          .submit(householdId: 100);

      final state = container.read(shoppingItemNewNotifierProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isSubmitting, false);
    });
  });
}
