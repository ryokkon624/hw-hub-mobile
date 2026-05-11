// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'housework_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HouseworkDto _$HouseworkDtoFromJson(Map<String, dynamic> json) => HouseworkDto(
  houseworkId: (json['houseworkId'] as num).toInt(),
  householdId: (json['householdId'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  category: json['category'] as String?,
  defaultAssigneeUserId: (json['defaultAssigneeUserId'] as num?)?.toInt(),
);

Map<String, dynamic> _$HouseworkDtoToJson(HouseworkDto instance) =>
    <String, dynamic>{
      'houseworkId': instance.houseworkId,
      'householdId': instance.householdId,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'defaultAssigneeUserId': instance.defaultAssigneeUserId,
    };
