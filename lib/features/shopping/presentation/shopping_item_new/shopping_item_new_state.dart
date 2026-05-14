import 'dart:typed_data';

/// 買い物アイテム作成画面の状態クラス。
class ShoppingItemNewState {
  const ShoppingItemNewState({
    this.name = '',
    this.memo,
    this.storeType = '1', // デフォルト: スーパー
    this.favorite = '0',
    this.pickedImageBytes,
    this.pickedImageName,
    this.sourceShoppingItemId,
    this.isSubmitting = false,
    this.errorMessage,
    this.successItemId,
  });

  final String name;
  final String? memo;
  final String storeType;
  final String favorite; // "0" or "1"
  final Uint8List? pickedImageBytes;
  final String? pickedImageName;
  final int? sourceShoppingItemId;
  final bool isSubmitting;
  final String? errorMessage;
  final int? successItemId; // 登録成功した場合に設定される

  bool get hasImage => pickedImageBytes != null;
  bool get canSubmit => name.trim().isNotEmpty && !isSubmitting;

  ShoppingItemNewState copyWith({
    String? name,
    Object? memo = _sentinel,
    String? storeType,
    String? favorite,
    Object? pickedImageBytes = _sentinel,
    Object? pickedImageName = _sentinel,
    Object? sourceShoppingItemId = _sentinel,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
    Object? successItemId = _sentinel,
  }) {
    return ShoppingItemNewState(
      name: name ?? this.name,
      memo: memo == _sentinel ? this.memo : memo as String?,
      storeType: storeType ?? this.storeType,
      favorite: favorite ?? this.favorite,
      pickedImageBytes: pickedImageBytes == _sentinel
          ? this.pickedImageBytes
          : pickedImageBytes as Uint8List?,
      pickedImageName: pickedImageName == _sentinel
          ? this.pickedImageName
          : pickedImageName as String?,
      sourceShoppingItemId: sourceShoppingItemId == _sentinel
          ? this.sourceShoppingItemId
          : sourceShoppingItemId as int?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      successItemId: successItemId == _sentinel
          ? this.successItemId
          : successItemId as int?,
    );
  }
}

const _sentinel = Object();
