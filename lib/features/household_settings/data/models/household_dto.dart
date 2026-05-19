import 'package:json_annotation/json_annotation.dart';

part 'household_dto.g.dart';

@JsonSerializable()
class HouseholdSettingsDto {
  const HouseholdSettingsDto({
    required this.householdId,
    required this.name,
    this.ownerUserId,
  });

  final int householdId;
  final String name;
  final int? ownerUserId;

  factory HouseholdSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$HouseholdSettingsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HouseholdSettingsDtoToJson(this);
}
