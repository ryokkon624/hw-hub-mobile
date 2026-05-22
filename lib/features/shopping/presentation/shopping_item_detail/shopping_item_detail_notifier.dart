import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/models/favorite_flag.dart';
import '../../../../core/network/app_exception.dart';
import '../../data/models/create_attachment_request.dart';
import '../../data/models/create_upload_url_request.dart';
import '../../data/models/update_shopping_item_request.dart';
import '../../data/shopping_repository.dart';
import '../../shopping_providers.dart';
import 'shopping_item_detail_state.dart';

export 'shopping_item_detail_state.dart';

class ShoppingItemDetailNotifier
    extends AutoDisposeFamilyNotifier<ShoppingItemDetailState, int> {
  @override
  ShoppingItemDetailState build(int itemId) {
    // 非同期で build を蹴る
    Future.microtask(() => _initialize(itemId));
    return const ShoppingItemDetailState(isLoading: true);
  }

  Future<void> _initialize(int itemId) async {
    try {
      final householdState = await ref.read(householdNotifierProvider.future);
      final householdId = householdState.selectedHousehold?.id;

      if (householdId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final repo = ref.read(shoppingRepositoryProvider);
      final attachRepo = ref.read(shoppingAttachmentRepositoryProvider);

      // item と attachments を並行取得
      final items = await repo.fetchItems(householdId: householdId);
      final attachments = await attachRepo.listAttachments(itemId: itemId);

      final item = items.firstWhere(
        (e) => e.shoppingItemId == itemId,
        orElse: () =>
            throw const ServerException(message: 'shoppingDetailItemNotFound'),
      );

      state = state.copyWith(
        item: item,
        attachments: attachments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is AppException ? e.message : 'shoppingDetailLoadError',
      );
    }
  }

  void setName(String value) {
    state = state.copyWith(editableName: value);
  }

  void setMemo(String? value) {
    state = state.copyWith(editableMemo: value ?? '');
  }

  void setStoreType(String value) {
    state = state.copyWith(editableStoreType: value);
  }

  Future<void> toggleFavorite() async {
    final item = state.item;
    if (item == null) return;

    final currentFavorite = item.favorite ?? FavoriteFlag.normal.code;
    final newFavorite = currentFavorite == FavoriteFlag.favorite.code
        ? FavoriteFlag.normal.code
        : FavoriteFlag.favorite.code;

    await _runCatching(() async {
      final repo = ref.read(shoppingRepositoryProvider);
      await repo.toggleFavorite(
        shoppingItemId: item.shoppingItemId,
        favorite: newFavorite,
      );
      state = state.copyWith(item: _copyItemWith(item, favorite: newFavorite));
    });
  }

  Future<void> updateStatus(String status) async {
    final item = state.item;
    if (item == null) return;

    await _runCatching(() async {
      final repo = ref.read(shoppingRepositoryProvider);
      await repo.updateStatus(
        shoppingItemId: item.shoppingItemId,
        status: status,
      );
      state = state.copyWith(item: _copyItemWith(item, status: status));
    });
  }

  Future<void> save() async {
    final item = state.item;
    if (item == null) return;

    state = state.copyWith(isSaving: true, errorMessage: null);

    await _runCatching(() async {
      final repo = ref.read(shoppingRepositoryProvider);
      final updated = await repo.updateItem(
        shoppingItemId: item.shoppingItemId,
        req: UpdateShoppingItemRequest(
          name: state.currentName.trim(),
          memo: state.currentMemo?.trim().isEmpty ?? true
              ? null
              : state.currentMemo?.trim(),
          storeType: state.currentStoreType,
          favorite: state.currentFavorite,
        ),
      );
      state = state.copyWith(
        item: updated,
        editableName: null,
        editableMemo: null,
        editableStoreType: null,
        editableFavorite: null,
        isSaving: false,
      );
    }, onError: (msg) => state.copyWith(isSaving: false, errorMessage: msg));
  }

  Future<void> deleteItem() async {
    final item = state.item;
    if (item == null) return;

    await _runCatching(
      () async {
        final repo = ref.read(shoppingRepositoryProvider);
        await repo.deleteItem(shoppingItemId: item.shoppingItemId);
        state = state.copyWith(isDeleted: true);
      },
      onError: (msg) => state.copyWith(errorMessage: msg),
      unexpectedErrorKey: 'shoppingDetailDeleteError',
    );
  }

  Future<void> addImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final item = state.item;
    if (item == null) return;

    await _runCatching(() async {
      final attachRepo = ref.read(shoppingAttachmentRepositoryProvider);
      final mimeType = _mimeTypeFromFileName(fileName);

      final uploadUrlResponse = await attachRepo.createUploadUrl(
        itemId: item.shoppingItemId,
        req: CreateUploadUrlRequest(fileName: fileName, mimeType: mimeType),
      );

      await attachRepo.uploadToS3(
        uploadUrl: uploadUrlResponse.uploadUrl,
        bytes: bytes,
        mimeType: mimeType,
      );

      await attachRepo.createAttachment(
        itemId: item.shoppingItemId,
        req: CreateAttachmentRequest(
          fileKey: uploadUrlResponse.fileKey,
          fileName: fileName,
          mimeType: mimeType,
        ),
      );

      // 一覧を再取得
      final attachments = await attachRepo.listAttachments(
        itemId: item.shoppingItemId,
      );
      state = state.copyWith(attachments: attachments);
    });
  }

  Future<void> deleteAttachment(int attachmentId) async {
    final item = state.item;
    if (item == null) return;

    await _runCatching(() async {
      final attachRepo = ref.read(shoppingAttachmentRepositoryProvider);
      await attachRepo.deleteAttachment(
        itemId: item.shoppingItemId,
        attachmentId: attachmentId,
      );

      // 一覧を再取得
      final attachments = await attachRepo.listAttachments(
        itemId: item.shoppingItemId,
      );
      state = state.copyWith(attachments: attachments);
    });
  }

  /// Notifier（同期ステート）向けエラーハンドリングヘルパー。
  /// [operation] が AppException を throw した場合は [onError] で state を更新する。
  /// [onError] が省略された場合はデフォルトの errorMessage copyWith を使う。
  /// 予期しない例外は [unexpectedErrorKey] の i18n キーを格納する。
  Future<void> _runCatching(
    Future<void> Function() operation, {
    ShoppingItemDetailState Function(String errorMessage)? onError,
    String unexpectedErrorKey = 'errorUnexpected',
  }) async {
    try {
      await operation();
    } on AppException catch (e) {
      state = onError != null
          ? onError(e.message)
          : state.copyWith(errorMessage: e.message);
    } catch (_) {
      state = onError != null
          ? onError(unexpectedErrorKey)
          : state.copyWith(errorMessage: unexpectedErrorKey);
    }
  }

  /// ShoppingItemDto は immutable で copyWith がないため新しいインスタンスを作成する
  ShoppingItemDto _copyItemWith(
    ShoppingItemDto item, {
    String? status,
    String? favorite,
  }) {
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

  String _mimeTypeFromFileName(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

final shoppingItemDetailNotifierProvider = NotifierProvider.autoDispose
    .family<ShoppingItemDetailNotifier, ShoppingItemDetailState, int>(
      ShoppingItemDetailNotifier.new,
    );
