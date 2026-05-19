import 'package:json_annotation/json_annotation.dart';

part 'household_member_dto.g.dart';

@JsonSerializable()
class HouseholdSettingsMemberDto {
  const HouseholdSettingsMemberDto({
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

  factory HouseholdSettingsMemberDto.fromJson(Map<String, dynamic> json) =>
      _$HouseholdSettingsMemberDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HouseholdSettingsMemberDtoToJson(this);

  HouseholdSettingsMemberDto copyWith({String? role}) {
    return HouseholdSettingsMemberDto(
      householdId: householdId,
      userId: userId,
      displayName: displayName,
      iconUrl: iconUrl,
      nickname: nickname,
      status: status,
      role: role ?? this.role,
    );
  }
}
