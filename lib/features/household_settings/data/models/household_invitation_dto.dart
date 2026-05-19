import 'package:json_annotation/json_annotation.dart';

part 'household_invitation_dto.g.dart';

@JsonSerializable()
class HouseholdInvitationDto {
  const HouseholdInvitationDto({
    required this.householdId,
    required this.invitationToken,
    required this.invitedEmail,
    required this.status,
    this.expiresAt,
    this.acceptedUserId,
    this.acceptedUserName,
    this.inviterUserId,
    this.inviterDisplayName,
    this.createdAt,
  });

  final int householdId;
  final String invitationToken;
  final String invitedEmail;
  final String status;
  final String? expiresAt;
  final int? acceptedUserId;
  final String? acceptedUserName;
  final int? inviterUserId;
  final String? inviterDisplayName;
  final String? createdAt;

  factory HouseholdInvitationDto.fromJson(Map<String, dynamic> json) =>
      _$HouseholdInvitationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HouseholdInvitationDtoToJson(this);
}
