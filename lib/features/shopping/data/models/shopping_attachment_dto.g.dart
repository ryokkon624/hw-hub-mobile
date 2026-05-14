// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_attachment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShoppingAttachmentDto _$ShoppingAttachmentDtoFromJson(
  Map<String, dynamic> json,
) => ShoppingAttachmentDto(
  id: (json['id'] as num).toInt(),
  fileName: json['fileName'] as String,
  imageUrl: json['imageUrl'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
);

Map<String, dynamic> _$ShoppingAttachmentDtoToJson(
  ShoppingAttachmentDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'fileName': instance.fileName,
  'imageUrl': instance.imageUrl,
  'sortOrder': instance.sortOrder,
};
