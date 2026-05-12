// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShoppingItemDto _$ShoppingItemDtoFromJson(Map<String, dynamic> json) =>
    ShoppingItemDto(
      shoppingItemId: (json['shoppingItemId'] as num).toInt(),
      householdId: (json['householdId'] as num).toInt(),
      name: json['name'] as String,
      memo: json['memo'] as String?,
      storeType: json['storeType'] as String?,
      status: json['status'] as String,
      favorite: json['favorite'] as String?,
      purchasedAt: json['purchasedAt'] as String?,
      createdAt: json['createdAt'] as String,
      hasImage: json['hasImage'] as bool,
    );

Map<String, dynamic> _$ShoppingItemDtoToJson(ShoppingItemDto instance) =>
    <String, dynamic>{
      'shoppingItemId': instance.shoppingItemId,
      'householdId': instance.householdId,
      'name': instance.name,
      'memo': instance.memo,
      'storeType': instance.storeType,
      'status': instance.status,
      'favorite': instance.favorite,
      'purchasedAt': instance.purchasedAt,
      'createdAt': instance.createdAt,
      'hasImage': instance.hasImage,
    };
