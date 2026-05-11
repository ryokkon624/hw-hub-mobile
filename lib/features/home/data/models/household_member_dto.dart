import 'package:json_annotation/json_annotation.dart';

part 'household_member_dto.g.dart';

@JsonSerializable()
class HouseholdMemberDto {
  const HouseholdMemberDto({
    required this.householdId,
    required this.userId,
    required this.displayName,
    this.iconUrl,
    this.nickname,
    required this.status,
    required this.role,
  });

  final int householdId;
  final int userId;
  final String displayName;
  final String? iconUrl;
  final String? nickname;
  final String status;
  final String role;

  factory HouseholdMemberDto.fromJson(Map<String, dynamic> json) =>
      _$HouseholdMemberDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HouseholdMemberDtoToJson(this);
}
