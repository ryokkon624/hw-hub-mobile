// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_member_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HouseholdSettingsMemberDto _$HouseholdSettingsMemberDtoFromJson(
  Map<String, dynamic> json,
) => HouseholdSettingsMemberDto(
  householdId: (json['householdId'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  displayName: json['displayName'] as String,
  iconUrl: json['iconUrl'] as String?,
  nickname: json['nickname'] as String?,
  status: json['status'] as String,
  role: json['role'] as String,
);

Map<String, dynamic> _$HouseholdSettingsMemberDtoToJson(
  HouseholdSettingsMemberDto instance,
) => <String, dynamic>{
  'householdId': instance.householdId,
  'userId': instance.userId,
  'displayName': instance.displayName,
  'iconUrl': instance.iconUrl,
  'nickname': instance.nickname,
  'status': instance.status,
  'role': instance.role,
};
