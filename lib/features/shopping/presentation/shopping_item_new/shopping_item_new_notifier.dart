import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/app_exception.dart';
import '../../data/models/create_attachment_request.dart';
import '../../data/models/create_shopping_item_request.dart';
import '../../data/models/create_upload_url_request.dart';
import '../../data/shopping_repository.dart';
import '../../shopping_providers.dart';
import 'shopping_item_new_state.dart';

export 'shopping_item_new_state.dart';

class ShoppingItemNewNotifier
    extends AutoDisposeNotifier<ShoppingItemNewState> {
  @override
  ShoppingItemNewState build() => ShoppingItemNewState();

  void setName(String value) {
    state = state.copyWith(name: value, errorMessage: null);
  }

  void setMemo(String? value) {
    state = state.copyWith(memo: value ?? '');
  }

  void setStoreType(String value) {
    state = state.copyWith(storeType: value);
  }

  void setFavorite(String value) {
    state = state.copyWith(favorite: value);
  }

  /// 過去の購入履歴候補を取得して返す（Page からの呼び出し用）
  Future<List<ShoppingItemHistorySuggestionDto>> fetchHistorySuggestions({
    required int householdId,
  }) async {
    try {
      final repo = ref.read(shoppingRepositoryProvider);
      return await repo.fetchHistorySuggestions(householdId: householdId);
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return [];
    } catch (_) {
      state = state.copyWith(errorMessage: 'errorUnexpected');
      return [];
    }
  }

  /// お気に入りアイテム一覧を取得して返す（Page からの呼び出し用）
  Future<List<ShoppingItemDto>> fetchFavorites({
    required int householdId,
  }) async {
    try {
      final repo = ref.read(shoppingRepositoryProvider);
      return await repo.fetchFavorites(householdId: householdId);
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return [];
    } catch (_) {
      state = state.copyWith(errorMessage: 'errorUnexpected');
      return [];
    }
  }

  // Note: fetchHistorySuggestions と fetchFavorites は戻り値があるため
  // _runCatching パターンを適用せず、個別の try/catch を維持する。

  /// 過去履歴から選択: name / storeType / sourceShoppingItemId / memo をセット
  void setFromHistory(ShoppingItemHistorySuggestionDto suggestion) {
    state = state.copyWith(
      name: suggestion.name,
      storeType: suggestion.storeType ?? state.storeType,
      sourceShoppingItemId: suggestion.sourceShoppingItemId,
      memo: suggestion.memo ?? '',
    );
  }

  /// お気に入りから選択: name / storeType / sourceShoppingItemId / memo をセット
  void setFromFavorite(ShoppingItemDto item) {
    state = state.copyWith(
      name: item.name,
      storeType: item.storeType ?? state.storeType,
      sourceShoppingItemId: item.shoppingItemId,
      memo: item.memo ?? '',
    );
  }

  /// 画像バイトをセットする（ウィジェット側で image_picker を呼び出してから渡す）
  void setPickedImage(Uint8List bytes, String fileName) {
    state = state.copyWith(pickedImageBytes: bytes, pickedImageName: fileName);
  }

  void clearImage() {
    state = state.copyWith(pickedImageBytes: null, pickedImageName: null);
  }

  /// 登録処理
  Future<void> submit({required int householdId}) async {
    if (!state.canSubmit) return;

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    await _runCatching(
      () async {
        final repo = ref.read(shoppingRepositoryProvider);
        final item = await repo.createItem(
          householdId: householdId,
          req: CreateShoppingItemRequest(
            name: state.name.trim(),
            memo: state.memo?.trim().isEmpty ?? true
                ? null
                : state.memo?.trim(),
            storeType: state.storeType,
            favorite: state.favorite,
            sourceShoppingItemId: state.sourceShoppingItemId,
          ),
        );

        // 画像があればアップロード
        final imageBytes = state.pickedImageBytes;
        final imageName = state.pickedImageName;
        if (imageBytes != null && imageName != null) {
          await _uploadAttachment(
            itemId: item.shoppingItemId,
            bytes: imageBytes,
            fileName: imageName,
          );
        }

        state = state.copyWith(
          isSubmitting: false,
          successItemId: item.shoppingItemId,
        );
      },
      onError: (msg) => state.copyWith(isSubmitting: false, errorMessage: msg),
      unexpectedErrorKey: 'shoppingNewSubmitError',
    );
  }

  /// AutoDisposeNotifier 向けエラーハンドリングヘルパー。
  /// [operation] が AppException を throw した場合は [onError] で state を更新する。
  /// [onError] が省略された場合はデフォルトの errorMessage copyWith を使う。
  /// 予期しない例外は [unexpectedErrorKey] の i18n キーを格納する。
  Future<void> _runCatching(
    Future<void> Function() operation, {
    ShoppingItemNewState Function(String errorMessage)? onError,
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

  Future<void> _uploadAttachment({
    required int itemId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final attachRepo = ref.read(shoppingAttachmentRepositoryProvider);

    // mimeType を拡張子から推定
    final mimeType = _mimeTypeFromFileName(fileName);

    final uploadUrlResponse = await attachRepo.createUploadUrl(
      itemId: itemId,
      req: CreateUploadUrlRequest(fileName: fileName, mimeType: mimeType),
    );

    await attachRepo.uploadToS3(
      uploadUrl: uploadUrlResponse.uploadUrl,
      bytes: bytes,
      mimeType: mimeType,
    );

    await attachRepo.createAttachment(
      itemId: itemId,
      req: CreateAttachmentRequest(
        fileKey: uploadUrlResponse.fileKey,
        fileName: fileName,
        mimeType: mimeType,
      ),
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

final shoppingItemNewNotifierProvider =
    NotifierProvider.autoDispose<ShoppingItemNewNotifier, ShoppingItemNewState>(
      ShoppingItemNewNotifier.new,
    );
