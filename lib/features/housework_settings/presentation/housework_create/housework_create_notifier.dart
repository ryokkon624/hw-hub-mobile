import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/network/app_exception.dart';
import '../../data/models/housework_template_dto.dart';
import '../../housework_settings_providers.dart';
import '../../../../features/home/data/models/household_member_dto.dart';
import 'housework_create_state.dart';

class HouseworkCreateNotifier
    extends AutoDisposeAsyncNotifier<HouseworkCreateState> {
  @override
  Future<HouseworkCreateState> build() async {
    final householdState = await ref.watch(householdNotifierProvider.future);
    final householdId = householdState.selectedHousehold?.id;
    if (householdId == null) {
      return const HouseworkCreateState();
    }

    final repo = ref.read(houseworkSettingsRepositoryProvider);
    final results = await Future.wait([
      repo.fetchMembers(householdId: householdId),
      repo.fetchTemplates(),
    ]);

    return HouseworkCreateState(
      members: results[0] as List<HouseholdMemberDto>,
      templates: results[1] as List<HouseworkTemplateDto>,
    );
  }

  int? get _householdId =>
      ref.read(householdNotifierProvider).valueOrNull?.selectedHousehold?.id;

  /// 家事名を更新する。
  void updateName(String value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(name: value)),
    );
  }

  /// 説明を更新する。
  void updateDescription(String value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(description: value)),
    );
  }

  /// カテゴリを更新する。
  void updateCategory(String value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(category: value)),
    );
  }

  /// 周期タイプを更新する。
  void updateRecurrenceType(String value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(recurrenceType: value)),
    );
  }

  /// 曜日ビットマスクをトグルする（bit=曜日インデックス 0=日〜6=土）。
  void toggleWeeklyDay(int bit) {
    final current = state.valueOrNull;
    if (current == null) return;
    final newMask = current.form.weeklyDays ^ (1 << bit);
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(weeklyDays: newMask)),
    );
  }

  /// 月の日付を更新する。
  void updateDayOfMonth(int value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(dayOfMonth: value)),
    );
  }

  /// 第n週を更新する。
  void updateNthWeek(int value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(nthWeek: value)),
    );
  }

  /// 曜日（NTH_WEEKDAY用）を更新する。
  void updateWeekday(int value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(weekday: value)),
    );
  }

  /// 開始日を更新する。
  void updateStartDate(String value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(startDate: value)),
    );
  }

  /// 終了日を更新する。
  void updateEndDate(String value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(endDate: value)),
    );
  }

  /// デフォルト担当者を更新する（nullは未設定）。
  void updateDefaultAssigneeUserId(int? value) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (value == null) {
      state = AsyncData(
        current.copyWith(form: current.form.copyWith(clearAssignee: true)),
      );
    } else {
      state = AsyncData(
        current.copyWith(
          form: current.form.copyWith(defaultAssigneeUserId: value),
        ),
      );
    }
  }

  /// テンプレートを適用してフォームを上書きする。
  void applyTemplate(HouseworkTemplateDto template, String locale) {
    final current = state.valueOrNull;
    if (current == null) return;

    final name = locale == 'es'
        ? template.nameEs
        : locale == 'en'
        ? template.nameEn
        : template.nameJa;
    final description = locale == 'es'
        ? template.descriptionEs
        : locale == 'en'
        ? template.descriptionEn
        : template.descriptionJa;
    final recommendation = locale == 'es'
        ? template.recommendationEs
        : locale == 'en'
        ? template.recommendationEn
        : template.recommendationJa;

    final newForm = current.form.copyWith(
      name: name,
      description: description ?? '',
      category: template.category,
      recurrenceType: template.recurrenceType,
      weeklyDays: template.weeklyDays ?? 0,
      dayOfMonth: template.dayOfMonth ?? 1,
      nthWeek: template.nthWeek ?? 1,
      weekday: template.weekday ?? 1,
    );

    state = AsyncData(
      current.copyWith(form: newForm, recommendationText: recommendation),
    );
  }

  /// 推薦メモを閉じる。
  void dismissRecommendation() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearRecommendation: true));
  }

  /// バリデーションを実行してエラーを返す。
  HouseworkFormErrors validate() {
    final current = state.valueOrNull;
    if (current == null) return HouseworkFormErrors.empty;

    final form = current.form;
    String? nameError;
    String? weeklyDaysError;
    String? monthlyDayError;
    String? nthWeekError;
    String? nthWeekdayError;
    String? startDateError;
    String? endDateError;

    if (form.name.trim().isEmpty) {
      nameError = 'houseworkCreateErrorNameRequired';
    } else if (form.name.length > 100) {
      nameError = 'houseworkCreateErrorNameTooLong';
    }

    if (form.recurrenceType == '1' && form.weeklyDays == 0) {
      weeklyDaysError = 'houseworkCreateErrorWeeklyDaysRequired';
    }

    if (form.startDate.isEmpty) {
      startDateError = 'houseworkCreateErrorStartDateRequired';
    } else if (!_isValidDate(form.startDate)) {
      startDateError = 'houseworkCreateErrorInvalidDate';
    }
    if (form.endDate.isEmpty) {
      endDateError = 'houseworkCreateErrorEndDateRequired';
    } else if (!_isValidDate(form.endDate)) {
      endDateError = 'houseworkCreateErrorInvalidDate';
    }
    if (startDateError == null &&
        endDateError == null &&
        form.startDate.isNotEmpty &&
        form.endDate.isNotEmpty &&
        form.endDate.compareTo(form.startDate) < 0) {
      endDateError = 'houseworkCreateErrorEndDateBeforeStart';
    }

    return HouseworkFormErrors(
      nameError: nameError,
      weeklyDaysError: weeklyDaysError,
      monthlyDayError: monthlyDayError,
      nthWeekError: nthWeekError,
      nthWeekdayError: nthWeekdayError,
      startDateError: startDateError,
      endDateError: endDateError,
    );
  }

  /// 日付文字列（YYYY-MM-DD）が実在する日付かどうかを検証する。
  /// Dart の DateTime は無効な日付を自動繰り越しするため、
  /// parse 後の月・日が入力値と一致するかで存在チェックする。
  bool _isValidDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return false;
    // 例: '2026-02-30' → parse で 2026-03-02 に繰り越される → toIso8601String で月が変わる
    return parsed.toIso8601String().substring(0, 10) == value;
  }

  /// 保存する（新規作成）。
  Future<void> save() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final householdId = _householdId;
    if (householdId == null) return;

    final errors = validate();
    if (errors.hasError) return;

    state = AsyncData(current.copyWith(isSaving: true, clearError: true));

    await _runCatching(
      current,
      (c) async {
        final repo = ref.read(houseworkSettingsRepositoryProvider);
        final form = c.form;

        await repo.createHousework(
          householdId: householdId,
          name: form.name,
          description: form.description.isEmpty ? null : form.description,
          category: form.category,
          recurrenceType: form.recurrenceType,
          weeklyDays: form.recurrenceType == '1' ? form.weeklyDays : null,
          dayOfMonth: form.recurrenceType == '2' ? form.dayOfMonth : null,
          nthWeek: form.recurrenceType == '3' ? form.nthWeek : null,
          weekday: form.recurrenceType == '3' ? form.weekday : null,
          startDate: form.startDate,
          endDate: form.endDate,
          defaultAssigneeUserId: form.defaultAssigneeUserId,
        );

        state = AsyncData(
          c.copyWith(
            isSaving: false,
            successMessage: 'houseworkCreateSaveSuccess',
            clearError: true,
          ),
        );
      },
      onError: (c, msg) =>
          c.copyWith(isSaving: false, errorMessage: msg, clearSuccess: true),
    );
  }

  /// AsyncNotifier 向けエラーハンドリングヘルパー。
  Future<void> _runCatching(
    HouseworkCreateState current,
    Future<void> Function(HouseworkCreateState c) operation, {
    HouseworkCreateState Function(HouseworkCreateState c, String errorMessage)?
    onError,
  }) async {
    try {
      await operation(current);
    } on AppException catch (e) {
      state = AsyncData(
        onError != null
            ? onError(current, e.message)
            : current.copyWith(errorMessage: e.message),
      );
    } catch (_) {
      state = AsyncData(
        onError != null
            ? onError(current, 'errorUnexpected')
            : current.copyWith(errorMessage: 'errorUnexpected'),
      );
    }
  }
}

final houseworkCreateNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      HouseworkCreateNotifier,
      HouseworkCreateState
    >(HouseworkCreateNotifier.new);
