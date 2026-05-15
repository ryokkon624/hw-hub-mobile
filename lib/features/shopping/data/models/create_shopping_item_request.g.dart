// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_shopping_item_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateShoppingItemRequest _$CreateShoppingItemRequestFromJson(
  Map<String, dynamic> json,
) => CreateShoppingItemRequest(
  name: json['name'] as String,
  memo: json['memo'] as String?,
  storeType: json['storeType'] as String,
  favorite: json['favorite'] as String?,
  sourceShoppingItemId: (json['sourceShoppingItemId'] as num?)?.toInt(),
);

Map<String, dynamic> _$CreateShoppingItemRequestToJson(
  CreateShoppingItemRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'memo': instance.memo,
  'storeType': instance.storeType,
  'favorite': instance.favorite,
  'sourceShoppingItemId': instance.sourceShoppingItemId,
};
