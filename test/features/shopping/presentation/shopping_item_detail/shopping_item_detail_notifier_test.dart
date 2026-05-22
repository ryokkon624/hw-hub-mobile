import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/home/data/models/shopping_item_dto.dart';
import 'package:hw_hub_mobile/features/shopping/data/models/create_upload_url_response.dart';
import 'package:hw_hub_mobile/features/shopping/data/models/shopping_attachment_dto.dart';
import 'package:hw_hub_mobile/features/shopping/shopping_providers.dart';
import 'package:mockito/mockito.dart';

import '../../shopping_mocks.mocks.dart';

/// テスト用の世帯状態（householdId=100）を返すフェイク Notifier
class _FakeHouseholdNotifier extends HouseholdNotifier {
  @override
  Future<HouseholdState> build() async {
    return const HouseholdState(
      households: [Household(id: 100, name: 'テスト世帯')],
      selectedHousehold: Household(id: 100, name: 'テスト世帯'),
    );
  }
}

ShoppingItemDto _makeItem({
  int id = 1,
  String status = '0',
  String? favorite = '0',
}) => ShoppingItemDto(
  shoppingItemId: id,
  householdId: 100,
  name: 'オリーブオイル',
  memo: 'メモ',
  storeType: '1',
  status: status,
  favorite: favorite,
  createdAt: '2026-05-01T10:00:00',
  hasImage: false,
);

ShoppingAttachmentDto _makeAttachment({int id = 10}) => ShoppingAttachmentDto(
  id: id,
  fileName: 'abc.jpg',
  imageUrl: 'https://cdn.example.com/abc.jpg',
  sortOrder: 0,
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
        householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
        shoppingRepositoryProvider.overrideWithValue(mockRepo),
        shoppingAttachmentRepositoryProvider.overrideWithValue(mockAttachRepo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ShoppingItemDetailNotifier build()', () {
    test('build: item と attachments を並行取得して状態にセットする', () async {
      when(
        mockRepo.fetchItems(householdId: anyNamed('householdId')),
      ).thenAnswer((_) async => [_makeItem(id: 1)]);
      when(
        mockAttachRepo.listAttachments(itemId: anyNamed('itemId')),
      ).thenAnswer((_) async => [_makeAttachment()]);

      final container = makeContainer();
      // NotifierProvider.autoDispose.family なので provider(1) として読む
      final sub = container.listen(
        shoppingItemDetailNotifierProvider(1),
        (_, _) {},
      );
      // build() → microtask → householdNotifier.future → fetchItems の非同期完了を待つ
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(shoppingItemDetailNotifierProvider(1));
      expect(state.item?.shoppingItemId, 1);
      expect(state.attachments, hasLength(1));
      sub.close();
    });
  });

  group('ShoppingItemDetailNotifier フォーム編集', () {
    setUp(() {
      when(
        mockRepo.fetchItems(householdId: anyNamed('householdId')),
      ).thenAnswer((_) async => [_makeItem(id: 1)]);
      when(
        mockAttachRepo.listAttachments(itemId: anyNamed('itemId')),
      ).thenAnswer((_) async => []);
    });

    test('setStoreType: editableStoreType を更新する', () async {
      final container = makeContainer();
      final sub = container.listen(
        shoppingItemDetailNotifierProvider(1),
        (_, _) {},
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      container
          .read(shoppingItemDetailNotifierProvider(1).notifier)
          .setStoreType('2');
      expect(
        container.read(shoppingItemDetailNotifierProvider(1)).currentStoreType,
        '2',
      );
      sub.close();
    });

    test('setName: editableName を更新する', () async {
      final container = makeContainer();
      final sub = container.listen(
        shoppingItemDetailNotifierProvider(1),
        (_, _) {},
      );
      // build() が Future.microtask → householdNotifier.future → fetchItems の順で非同期完了するため複数回待つ
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      container
          .read(shoppingItemDetailNotifierProvider(1).notifier)
          .setName('牛乳');
      expect(
        container.read(shoppingItemDetailNotifierProvider(1)).currentName,
        '牛乳',
      );
      sub.close();
    });

    test('setMemo: editableMemo を更新する', () async {
      final container = makeContainer();
      final sub = container.listen(
        shoppingItemDetailNotifierProvider(1),
        (_, _) {},
      );
      // build() が Future.microtask → householdNotifier.future → fetchItems の順で非同期完了するため複数回待つ
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      container
          .read(shoppingItemDetailNotifierProvider(1).notifier)
          .setMemo('新しいメモ');
      expect(
        container.read(shoppingItemDetailNotifierProvider(1)).currentMemo,
        '新しいメモ',
      );
      sub.close();
    });
  });

  group('ShoppingItemDetailNotifier save()', () {
    setUp(() {
      when(
        mockRepo.fetchItems(householdId: anyNamed('householdId')),
      ).thenAnswer((_) async => [_makeItem(id: 1)]);
      when(
        mockAttachRepo.listAttachments(itemId: anyNamed('itemId')),
      ).thenAnswer((_) async => []);
    });

    test('成功時: item が更新され isSaving が false に戻る', () async {
      when(
        mockRepo.updateItem(
          shoppingItemId: anyNamed('shoppingItemId'),
          req: anyNamed('req'),
        ),
      ).thenAnswer((_) async => _makeItem(id: 1));

      final container = makeContainer();
      final sub = container.listen(
        shoppingItemDetailNotifierProvider(1),
        (_, _) {},
      );
      // build() が Future.microtask → householdNotifier.future → fetchItems の順で非同期完了するため複数回待つ
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(shoppingItemDetailNotifierProvider(1).notifier)
          .save();

      final state = container.read(shoppingItemDetailNotifierProvider(1));
      expect(state.isSaving, false);
      expect(state.errorMessage, isNull);
      sub.close();
    });

    test('失敗時: errorMessage がセットされる', () async {
      when(
        mockRepo.updateItem(
          shoppingItemId: anyNamed('shoppingItemId'),
          req: anyNamed('req'),
        ),
      ).thenThrow(const NetworkException('接続エラー'));

      final container = makeContainer();
      final sub = container.listen(
        shoppingItemDetailNotifierProvider(1),
        (_, _) {},
      );
      // build() が Future.microtask → householdNotifier.future → fetchItems の順で非同期完了するため複数回待つ
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(shoppingItemDetailNotifierProvider(1).notifier)
          .save();

      expect(
        container.read(shoppingItemDetailNotifierProvider(1)).errorMessage,
        isNotNull,
      );
      sub.close();
    });
  });

  group('ShoppingItemDetailNotifier deleteItem()', () {
    setUp(() {
      when(
        mockRepo.fetchItems(householdId: anyNamed('householdId')),
      ).thenAnswer((_) async => [_makeItem(id: 1)]);
      when(
        mockAttachRepo.listAttachments(itemId: anyNamed('itemId')),
      ).thenAnswer((_) async => []);
    });

    test('成功時: isDeleted が true になる', () async {
      when(
        mockRepo.deleteItem(shoppingItemId: anyNamed('shoppingItemId')),
      ).thenAnswer((_) async {});

      final container = makeContainer();
      final sub = container.listen(
        shoppingItemDetailNotifierProvider(1),
        (_, _) {},
      );
      // build() が Future.microtask → householdNotifier.future → fetchItems の順で非同期完了するため複数回待つ
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(shoppingItemDetailNotifierProvider(1).notifier)
          .deleteItem();

      expect(
        container.read(shoppingItemDetailNotifierProvider(1)).isDeleted,
        true,
      );
      sub.close();
    });

    test('失敗時: errorMessage がセットされる', () async {
      when(
        mockRepo.deleteItem(shoppingItemId: anyNamed('shoppingItemId')),
      ).thenThrow(const NetworkException('接続エラー'));

      final container = makeContainer();
      final sub = container.listen(
        shoppingItemDetailNotifierProvider(1),
        (_, _) {},
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(shoppingItemDetailNotifierProvider(1).notifier)
          .deleteItem();

      final state = container.read(shoppingItemDetailNotifierProvider(1));
      expect(state.isDeleted, false);
      expect(state.errorMessage, isNotNull);
      sub.close();
    });
  });

  group('ShoppingItemDetailNotifier updateStatus()', () {
    setUp(() {
      when(
        mockRepo.fetchItems(householdId: anyNamed('householdId')),
      ).thenAnswer((_) async => [_makeItem(id: 1, status: '0')]);
      when(
        mockAttachRepo.listAttachments(itemId: anyNamed('itemId')),
      ).thenAnswer((_) async => []);
    });

    test('エラー時: errorMessageがセットされitemは変化しない', () async {
      when(
        mockRepo.updateStatus(
          shoppingItemId: anyNamed('shoppingItemId'),
          status: anyNamed('status'),
        ),
      ).thenThrow(const NetworkException('接続エラー'));

      final container = makeContainer();
      final sub = container.listen(
        shoppingItemDetailNotifierProvider(1),
        (_, _) {},
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(shoppingItemDetailNotifierProvider(1).notifier)
          .updateStatus('1');

      final state = container.read(shoppingItemDetailNotifierProvider(1));
      expect(state.item?.status, '0'); // 変化しない
      expect(state.errorMessage, isNotNull);
      sub.close();
    });

    test('成功時: item.status が更新される', () async {
      when(
        mockRepo.updateStatus(
          shoppingItemId: anyNamed('shoppingItemId'),
          status: anyNamed('status'),
        ),
      ).thenAnswer((_) async {});

      final container = makeContainer();
      final sub = container.listen(
        shoppingItemDetailNotifierProvider(1),
        (_, _) {},
      );
      // build() が Future.microtask → householdNotifier.future → fetchItems の順で非同期完了するため複数回待つ
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(shoppingItemDetailNotifierProvider(1).notifier)
          .updateStatus('1');

      expect(
        container.read(shoppingItemDetailNotifierProvider(1)).item?.status,
        '1',
      );
      sub.close();
    });
  });

  group('ShoppingItemDetailNotifier toggleFavorite()', () {
    setUp(() {
      when(
        mockRepo.fetchItems(householdId: anyNamed('householdId')),
      ).thenAnswer((_) async => [_makeItem(id: 1, favorite: '0')]);
      when(
        mockAttachRepo.listAttachments(itemId: anyNamed('itemId')),
      ).thenAnswer((_) async => []);
    });

    test('エラー時: errorMessageがセットされitemは変化しない', () async {
      when(
        mockRepo.toggleFavorite(
          shoppingItemId: anyNamed('shoppingItemId'),
          favorite: anyNamed('favorite'),
        ),
      ).thenThrow(const NetworkException('接続エラー'));

      final container = makeContainer();
      final sub = container.listen(
        shoppingItemDetailNotifierProvider(1),
        (_, _) {},
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(shoppingItemDetailNotifierProvider(1).notifier)
          .toggleFavorite();

      final state = container.read(shoppingItemDetailNotifierProvider(1));
      expect(state.item?.favorite, '0'); // 変化しない
      expect(state.errorMessage, isNotNull);
      sub.close();
    });

    test('favorite が "0" の場合: "1" に反転してAPIを呼ぶ', () async {
      when(
        mockRepo.toggleFavorite(
          shoppingItemId: anyNamed('shoppingItemId'),
          favorite: anyNamed('favorite'),
        ),
      ).thenAnswer((_) async {});

      final container = makeContainer();
      final sub = container.listen(
        shoppingItemDetailNotifierProvider(1),
        (_, _) {},
      );
      // build() が Future.microtask → householdNotifier.future → fetchItems の順で非同期完了するため複数回待つ
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(shoppingItemDetailNotifierProvider(1).notifier)
          .toggleFavorite();

      verify(
        mockRepo.toggleFavorite(shoppingItemId: 1, favorite: '1'),
      ).called(1);
      sub.close();
    });
  });

  group('ShoppingItemDetailNotifier addImage()', () {
    setUp(() {
      when(
        mockRepo.fetchItems(householdId: anyNamed('householdId')),
      ).thenAnswer((_) async => [_makeItem(id: 1)]);
      when(
        mockAttachRepo.listAttachments(itemId: anyNamed('itemId')),
      ).thenAnswer((_) async => []);
    });

    test('エラー時: errorMessageがセットされattachmentsは変化しない', () async {
      when(
        mockAttachRepo.createUploadUrl(
          itemId: anyNamed('itemId'),
          req: anyNamed('req'),
        ),
      ).thenThrow(const NetworkException('接続エラー'));

      final container = makeContainer();
      final sub = container.listen(
        shoppingItemDetailNotifierProvider(1),
        (_, _) {},
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(shoppingItemDetailNotifierProvider(1).notifier)
          .addImage(bytes: Uint8List.fromList([1, 2, 3]), fileName: 'test.jpg');

      final state = container.read(shoppingItemDetailNotifierProvider(1));
      expect(state.attachments, isEmpty);
      expect(state.errorMessage, isNotNull);
      sub.close();
    });

    test('成功時: attachments が更新される', () async {
      when(
        mockAttachRepo.createUploadUrl(
          itemId: anyNamed('itemId'),
          req: anyNamed('req'),
        ),
      ).thenAnswer(
        (_) async => const CreateUploadUrlResponse(
          uploadUrl: 'https://s3.example.com/upload',
          fileKey: 'shopping/1/test.jpg',
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
      when(
        mockAttachRepo.listAttachments(itemId: anyNamed('itemId')),
      ).thenAnswer((_) async => [_makeAttachment()]);

      final container = makeContainer();
      final sub = container.listen(
        shoppingItemDetailNotifierProvider(1),
        (_, _) {},
      );
      // build() が Future.microtask → householdNotifier.future → fetchItems の順で非同期完了するため複数回待つ
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(shoppingItemDetailNotifierProvider(1).notifier)
          .addImage(bytes: Uint8List.fromList([1, 2, 3]), fileName: 'test.jpg');

      expect(
        container.read(shoppingItemDetailNotifierProvider(1)).attachments,
        hasLength(1),
      );
      sub.close();
    });
  });

  group('ShoppingItemDetailNotifier deleteAttachment()', () {
    setUp(() {
      when(
        mockRepo.fetchItems(householdId: anyNamed('householdId')),
      ).thenAnswer((_) async => [_makeItem(id: 1)]);
      when(
        mockAttachRepo.listAttachments(itemId: anyNamed('itemId')),
      ).thenAnswer((_) async => [_makeAttachment()]);
    });

    test('エラー時: errorMessageがセットされattachmentsは変化しない', () async {
      when(
        mockAttachRepo.deleteAttachment(
          itemId: anyNamed('itemId'),
          attachmentId: anyNamed('attachmentId'),
        ),
      ).thenThrow(const NetworkException('接続エラー'));

      final container = makeContainer();
      final sub = container.listen(
        shoppingItemDetailNotifierProvider(1),
        (_, _) {},
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(shoppingItemDetailNotifierProvider(1).notifier)
          .deleteAttachment(10);

      final state = container.read(shoppingItemDetailNotifierProvider(1));
      expect(state.attachments, hasLength(1)); // 変化しない
      expect(state.errorMessage, isNotNull);
      sub.close();
    });

    test('成功時: 削除後に attachments を再取得する', () async {
      when(
        mockAttachRepo.deleteAttachment(
          itemId: anyNamed('itemId'),
          attachmentId: anyNamed('attachmentId'),
        ),
      ).thenAnswer((_) async {});
      // 削除後に再取得すると空リストが返る
      var callCount = 0;
      when(
        mockAttachRepo.listAttachments(itemId: anyNamed('itemId')),
      ).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return [_makeAttachment()]; // 初回（build）
        return []; // 削除後の再取得
      });

      final container = makeContainer();
      final sub = container.listen(
        shoppingItemDetailNotifierProvider(1),
        (_, _) {},
      );
      // build() が Future.microtask → householdNotifier.future → fetchItems の順で非同期完了するため複数回待つ
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(shoppingItemDetailNotifierProvider(1).notifier)
          .deleteAttachment(10);

      expect(
        container.read(shoppingItemDetailNotifierProvider(1)).attachments,
        isEmpty,
      );
      sub.close();
    });
  });
}
