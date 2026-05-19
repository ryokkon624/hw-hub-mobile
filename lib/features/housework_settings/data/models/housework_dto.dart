class HouseworkDto {
  const HouseworkDto({
    required this.houseworkId,
    required this.householdId,
    required this.name,
    this.description,
    required this.category,
    required this.recurrenceType,
    this.weeklyDays,
    this.dayOfMonth,
    this.nthWeek,
    this.weekday,
    required this.startDate,
    required this.endDate,
    this.defaultAssigneeUserId,
  });

  final int houseworkId;
  final int householdId;
  final String name;
  final String? description;
  final String category;
  final String recurrenceType;
  final int? weeklyDays;
  final int? dayOfMonth;
  final int? nthWeek;
  final int? weekday;
  final String startDate;
  final String endDate;
  final int? defaultAssigneeUserId;

  factory HouseworkDto.fromJson(Map<String, dynamic> json) {
    return HouseworkDto(
      houseworkId: json['houseworkId'] as int,
      householdId: json['householdId'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      recurrenceType: json['recurrenceType'] as String,
      weeklyDays: json['weeklyDays'] as int?,
      dayOfMonth: json['dayOfMonth'] as int?,
      nthWeek: json['nthWeek'] as int?,
      weekday: json['weekday'] as int?,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      defaultAssigneeUserId: json['defaultAssigneeUserId'] as int?,
    );
  }
}
