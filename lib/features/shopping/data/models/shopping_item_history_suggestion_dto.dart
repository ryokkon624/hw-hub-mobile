import 'package:json_annotation/json_annotation.dart';

part 'shopping_item_history_suggestion_dto.g.dart';

@JsonSerializable()
class ShoppingItemHistorySuggestionDto {
  const ShoppingItemHistorySuggestionDto({
    required this.name,
    this.memo,
    this.storeType,
    this.lastPurchasedDate,
    required this.purchaseCount,
    this.sourceShoppingItemId,
    this.favorite,
  });

  final String name;
  final String? memo;
  final String? storeType;
  final String? lastPurchasedDate; // ISO date string: "2026-01-15"
  final int purchaseCount;
  final int? sourceShoppingItemId;
  final String? favorite;

  factory ShoppingItemHistorySuggestionDto.fromJson(
    Map<String, dynamic> json,
  ) => _$ShoppingItemHistorySuggestionDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ShoppingItemHistorySuggestionDtoToJson(this);
}
