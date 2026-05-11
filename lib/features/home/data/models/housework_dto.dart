import 'package:json_annotation/json_annotation.dart';

part 'housework_dto.g.dart';

@JsonSerializable()
class HouseworkDto {
  const HouseworkDto({
    required this.houseworkId,
    required this.householdId,
    required this.name,
    this.description,
    this.category,
    this.defaultAssigneeUserId,
  });

  final int houseworkId;
  final int householdId;
  final String name;
  final String? description;
  final String? category;
  final int? defaultAssigneeUserId;

  factory HouseworkDto.fromJson(Map<String, dynamic> json) =>
      _$HouseworkDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HouseworkDtoToJson(this);
}
