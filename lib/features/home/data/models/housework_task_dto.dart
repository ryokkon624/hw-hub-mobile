import 'package:json_annotation/json_annotation.dart';

part 'housework_task_dto.g.dart';

@JsonSerializable()
class HouseworkTaskDto {
  const HouseworkTaskDto({
    required this.houseworkTaskId,
    required this.householdId,
    required this.houseworkId,
    required this.houseworkName,
    this.categoryCode,
    required this.targetDate,
    this.assigneeUserId,
    this.assigneeNickname,
    required this.status,
    this.assignReasonType,
    this.doneAt,
    this.skippedReason,
  });

  final int houseworkTaskId;
  final int householdId;
  final int houseworkId;
  final String houseworkName;
  final String? categoryCode;
  final String targetDate; // ISO date string: "2026-05-11"
  final int? assigneeUserId;
  final String? assigneeNickname;
  final String status; // "0"=open, "1"=done, "2"=skip
  final String? assignReasonType;
  final String? doneAt;
  final String? skippedReason;

  factory HouseworkTaskDto.fromJson(Map<String, dynamic> json) =>
      _$HouseworkTaskDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HouseworkTaskDtoToJson(this);
}
