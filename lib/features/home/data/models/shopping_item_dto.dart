import 'package:json_annotation/json_annotation.dart';

part 'shopping_item_dto.g.dart';

@JsonSerializable()
class ShoppingItemDto {
  const ShoppingItemDto({
    required this.shoppingItemId,
    required this.householdId,
    required this.name,
    this.memo,
    this.storeType,
    required this.status,
    this.favorite,
    this.purchasedAt,
    required this.createdAt,
    required this.hasImage,
  });

  final int shoppingItemId;
  final int householdId;
  final String name;
  final String? memo;
  final String? storeType;
  final String status; // "0"=open, "1"=purchased
  final String? favorite;
  final String? purchasedAt;
  final String createdAt; // ISO datetime string
  final bool hasImage;

  factory ShoppingItemDto.fromJson(Map<String, dynamic> json) =>
      _$ShoppingItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ShoppingItemDtoToJson(this);
}
