class HouseworkTemplateDto {
  const HouseworkTemplateDto({
    required this.houseworkTemplateId,
    required this.nameJa,
    required this.nameEn,
    required this.nameEs,
    this.descriptionJa,
    this.descriptionEn,
    this.descriptionEs,
    this.recommendationJa,
    this.recommendationEn,
    this.recommendationEs,
    required this.category,
    required this.recurrenceType,
    this.weeklyDays,
    this.dayOfMonth,
    this.nthWeek,
    this.weekday,
  });

  final int houseworkTemplateId;
  final String nameJa;
  final String nameEn;
  final String nameEs;
  final String? descriptionJa;
  final String? descriptionEn;
  final String? descriptionEs;
  final String? recommendationJa;
  final String? recommendationEn;
  final String? recommendationEs;
  final String category;
  final String recurrenceType;
  final int? weeklyDays;
  final int? dayOfMonth;
  final int? nthWeek;
  final int? weekday;

  factory HouseworkTemplateDto.fromJson(Map<String, dynamic> json) {
    return HouseworkTemplateDto(
      houseworkTemplateId: json['houseworkTemplateId'] as int,
      nameJa: json['nameJa'] as String,
      nameEn: json['nameEn'] as String,
      nameEs: json['nameEs'] as String,
      descriptionJa: json['descriptionJa'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      descriptionEs: json['descriptionEs'] as String?,
      recommendationJa: json['recommendationJa'] as String?,
      recommendationEn: json['recommendationEn'] as String?,
      recommendationEs: json['recommendationEs'] as String?,
      category: json['category'] as String,
      recurrenceType: json['recurrenceType'] as String,
      weeklyDays: json['weeklyDays'] as int?,
      dayOfMonth: json['dayOfMonth'] as int?,
      nthWeek: json['nthWeek'] as int?,
      weekday: json['weekday'] as int?,
    );
  }
}
