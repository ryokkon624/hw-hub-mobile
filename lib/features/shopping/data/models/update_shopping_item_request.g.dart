// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_shopping_item_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateShoppingItemRequest _$UpdateShoppingItemRequestFromJson(
  Map<String, dynamic> json,
) => UpdateShoppingItemRequest(
  name: json['name'] as String,
  memo: json['memo'] as String?,
  storeType: json['storeType'] as String,
  favorite: json['favorite'] as String,
);

Map<String, dynamic> _$UpdateShoppingItemRequestToJson(
  UpdateShoppingItemRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'memo': instance.memo,
  'storeType': instance.storeType,
  'favorite': instance.favorite,
};
