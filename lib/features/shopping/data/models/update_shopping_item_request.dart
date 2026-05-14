import 'package:json_annotation/json_annotation.dart';

part 'update_shopping_item_request.g.dart';

@JsonSerializable()
class UpdateShoppingItemRequest {
  const UpdateShoppingItemRequest({
    required this.name,
    this.memo,
    required this.storeType,
    required this.favorite,
  });

  final String name;
  final String? memo;
  final String storeType;
  final String favorite; // "0" or "1"

  Map<String, dynamic> toJson() => _$UpdateShoppingItemRequestToJson(this);

  factory UpdateShoppingItemRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateShoppingItemRequestFromJson(json);
}
