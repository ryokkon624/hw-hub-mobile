// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_item_history_suggestion_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShoppingItemHistorySuggestionDto _$ShoppingItemHistorySuggestionDtoFromJson(
  Map<String, dynamic> json,
) => ShoppingItemHistorySuggestionDto(
  name: json['name'] as String,
  memo: json['memo'] as String?,
  storeType: json['storeType'] as String?,
  lastPurchasedDate: json['lastPurchasedDate'] as String?,
  purchaseCount: (json['purchaseCount'] as num).toInt(),
  sourceShoppingItemId: (json['sourceShoppingItemId'] as num?)?.toInt(),
  favorite: json['favorite'] as String?,
);

Map<String, dynamic> _$ShoppingItemHistorySuggestionDtoToJson(
  ShoppingItemHistorySuggestionDto instance,
) => <String, dynamic>{
  'name': instance.name,
  'memo': instance.memo,
  'storeType': instance.storeType,
  'lastPurchasedDate': instance.lastPurchasedDate,
  'purchaseCount': instance.purchaseCount,
  'sourceShoppingItemId': instance.sourceShoppingItemId,
  'favorite': instance.favorite,
};
