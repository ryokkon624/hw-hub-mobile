import 'package:json_annotation/json_annotation.dart';

part 'shopping_attachment_dto.g.dart';

@JsonSerializable()
class ShoppingAttachmentDto {
  const ShoppingAttachmentDto({
    required this.id,
    required this.fileName,
    required this.imageUrl,
    required this.sortOrder,
  });

  final int id;
  final String fileName;
  final String imageUrl;
  final int sortOrder;

  factory ShoppingAttachmentDto.fromJson(Map<String, dynamic> json) =>
      _$ShoppingAttachmentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ShoppingAttachmentDtoToJson(this);
}
