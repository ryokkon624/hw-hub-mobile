import 'package:json_annotation/json_annotation.dart';

part 'create_shopping_item_request.g.dart';

@JsonSerializable()
class CreateShoppingItemRequest {
  const CreateShoppingItemRequest({
    required this.name,
    this.memo,
    required this.storeType,
    this.favorite,
    this.sourceShoppingItemId,
  });

  final String name;
  final String? memo;
  final String storeType;
  final String? favorite;
  final int? sourceShoppingItemId;

  Map<String, dynamic> toJson() => _$CreateShoppingItemRequestToJson(this);

  factory CreateShoppingItemRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateShoppingItemRequestFromJson(json);
}
