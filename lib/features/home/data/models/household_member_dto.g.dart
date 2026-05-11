// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_member_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HouseholdMemberDto _$HouseholdMemberDtoFromJson(Map<String, dynamic> json) =>
    HouseholdMemberDto(
      householdId: (json['householdId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      displayName: json['displayName'] as String,
      iconUrl: json['iconUrl'] as String?,
      nickname: json['nickname'] as String?,
      status: json['status'] as String,
      role: json['role'] as String,
    );

Map<String, dynamic> _$HouseholdMemberDtoToJson(HouseholdMemberDto instance) =>
    <String, dynamic>{
      'householdId': instance.householdId,
      'userId': instance.userId,
      'displayName': instance.displayName,
      'iconUrl': instance.iconUrl,
      'nickname': instance.nickname,
      'status': instance.status,
      'role': instance.role,
    };
