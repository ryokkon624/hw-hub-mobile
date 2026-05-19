// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HouseholdSettingsDto _$HouseholdSettingsDtoFromJson(
  Map<String, dynamic> json,
) => HouseholdSettingsDto(
  householdId: (json['householdId'] as num).toInt(),
  name: json['name'] as String,
  ownerUserId: (json['ownerUserId'] as num?)?.toInt(),
);

Map<String, dynamic> _$HouseholdSettingsDtoToJson(
  HouseholdSettingsDto instance,
) => <String, dynamic>{
  'householdId': instance.householdId,
  'name': instance.name,
  'ownerUserId': instance.ownerUserId,
};
