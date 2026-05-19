import '../../data/housework_settings_repository.dart';

/// フォームフィールドの状態（新規作成・編集で共用）。
class HouseworkFormState {
  const HouseworkFormState({
    this.name = '',
    this.description = '',
    this.category = 'CLEAN',
    this.recurrenceType = '1',
    this.weeklyDays = 0,
    this.dayOfMonth = 1,
    this.nthWeek = 1,
    this.weekday = 1,
    this.startDate = '2025-01-01',
    this.endDate = '2099-12-31',
    this.defaultAssigneeUserId,
  });

  final String name;
  final String description;
  final String category;
  final String recurrenceType;
  final int weeklyDays;
  final int dayOfMonth;
  final int nthWeek;
  final int weekday;
  final String startDate;
  final String endDate;
  final int? defaultAssigneeUserId;

  HouseworkFormState copyWith({
    String? name,
    String? description,
    String? category,
    String? recurrenceType,
    int? weeklyDays,
    int? dayOfMonth,
    int? nthWeek,
    int? weekday,
    String? startDate,
    String? endDate,
    int? defaultAssigneeUserId,
    bool clearAssignee = false,
  }) {
    return HouseworkFormState(
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      nthWeek: nthWeek ?? this.nthWeek,
      weekday: weekday ?? this.weekday,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      defaultAssigneeUserId: clearAssignee
          ? null
          : (defaultAssigneeUserId ?? this.defaultAssigneeUserId),
    );
  }
}

/// バリデーションエラー状態。
class HouseworkFormErrors {
  const HouseworkFormErrors({
    this.nameError,
    this.weeklyDaysError,
    this.monthlyDayError,
    this.nthWeekError,
    this.nthWeekdayError,
    this.startDateError,
    this.endDateError,
  });

  final String? nameError;
  final String? weeklyDaysError;
  final String? monthlyDayError;
  final String? nthWeekError;
  final String? nthWeekdayError;
  final String? startDateError;
  final String? endDateError;

  bool get hasError =>
      nameError != null ||
      weeklyDaysError != null ||
      monthlyDayError != null ||
      nthWeekError != null ||
      nthWeekdayError != null ||
      startDateError != null ||
      endDateError != null;

  static const empty = HouseworkFormErrors();
}

/// 家事新規作成画面の状態。
class HouseworkCreateState {
  const HouseworkCreateState({
    this.form = const HouseworkFormState(),
    this.members = const [],
    this.templates = const [],
    this.recommendationText,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  final HouseworkFormState form;
  final List<HouseholdMemberDto> members;
  final List<HouseworkTemplateDto> templates;
  final String? recommendationText;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  HouseworkCreateState copyWith({
    HouseworkFormState? form,
    List<HouseholdMemberDto>? members,
    List<HouseworkTemplateDto>? templates,
    String? recommendationText,
    bool clearRecommendation = false,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return HouseworkCreateState(
      form: form ?? this.form,
      members: members ?? this.members,
      templates: templates ?? this.templates,
      recommendationText: clearRecommendation
          ? null
          : (recommendationText ?? this.recommendationText),
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}
