// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_invitation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HouseholdInvitationDto _$HouseholdInvitationDtoFromJson(
  Map<String, dynamic> json,
) => HouseholdInvitationDto(
  householdId: (json['householdId'] as num).toInt(),
  invitationToken: json['invitationToken'] as String,
  invitedEmail: json['invitedEmail'] as String,
  status: json['status'] as String,
  expiresAt: json['expiresAt'] as String?,
  acceptedUserId: (json['acceptedUserId'] as num?)?.toInt(),
  acceptedUserName: json['acceptedUserName'] as String?,
  inviterUserId: (json['inviterUserId'] as num?)?.toInt(),
  inviterDisplayName: json['inviterDisplayName'] as String?,
  createdAt: json['createdAt'] as String?,
);

Map<String, dynamic> _$HouseholdInvitationDtoToJson(
  HouseholdInvitationDto instance,
) => <String, dynamic>{
  'householdId': instance.householdId,
  'invitationToken': instance.invitationToken,
  'invitedEmail': instance.invitedEmail,
  'status': instance.status,
  'expiresAt': instance.expiresAt,
  'acceptedUserId': instance.acceptedUserId,
  'acceptedUserName': instance.acceptedUserName,
  'inviterUserId': instance.inviterUserId,
  'inviterDisplayName': instance.inviterDisplayName,
  'createdAt': instance.createdAt,
};
