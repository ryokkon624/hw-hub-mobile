import '../../../../core/models/favorite_flag.dart';
import '../../../../core/models/purchase_location_type.dart';
import '../../../../core/models/shopping_item_status.dart';
import '../../data/shopping_repository.dart';
import '../../data/shopping_attachment_repository.dart';

/// 買い物アイテム詳細画面の状態クラス。
class ShoppingItemDetailState {
  const ShoppingItemDetailState({
    this.item,
    this.attachments = const [],
    this.editableName,
    this.editableMemo,
    this.editableStoreType,
    this.editableFavorite,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.isDeleted = false,
  });

  final ShoppingItemDto? item;
  final List<ShoppingAttachmentDto> attachments;

  /// 編集用フィールド（null の場合は item の値を使う）
  final String? editableName;
  final String? editableMemo;
  final String? editableStoreType;
  final String? editableFavorite;

  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool isDeleted;

  /// 編集中の名前（item または editable の値）
  String get currentName => editableName ?? item?.name ?? '';
  String? get currentMemo => editableMemo ?? item?.memo;
  String get currentStoreType =>
      editableStoreType ??
      item?.storeType ??
      PurchaseLocationType.supermarket.code;
  String get currentFavorite =>
      editableFavorite ?? item?.favorite ?? FavoriteFlag.normal.code;

  /// 未購入ステータスかどうか（削除ボタン表示制御用）
  /// #94: 未購入（notPurchased）のときのみ true。かご（inBasket）は含まない
  bool get isNotPurchased =>
      item?.status == ShoppingItemStatus.notPurchased.code;

  ShoppingItemDetailState copyWith({
    Object? item = _sentinel,
    List<ShoppingAttachmentDto>? attachments,
    Object? editableName = _sentinel,
    Object? editableMemo = _sentinel,
    Object? editableStoreType = _sentinel,
    Object? editableFavorite = _sentinel,
    bool? isLoading,
    bool? isSaving,
    Object? errorMessage = _sentinel,
    bool? isDeleted,
  }) {
    return ShoppingItemDetailState(
      item: item == _sentinel ? this.item : item as ShoppingItemDto?,
      attachments: attachments ?? this.attachments,
      editableName: editableName == _sentinel
          ? this.editableName
          : editableName as String?,
      editableMemo: editableMemo == _sentinel
          ? this.editableMemo
          : editableMemo as String?,
      editableStoreType: editableStoreType == _sentinel
          ? this.editableStoreType
          : editableStoreType as String?,
      editableFavorite: editableFavorite == _sentinel
          ? this.editableFavorite
          : editableFavorite as String?,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

const _sentinel = Object();
