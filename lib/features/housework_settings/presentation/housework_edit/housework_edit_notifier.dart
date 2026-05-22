import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../features/home/data/models/household_member_dto.dart';
import '../../housework_settings_providers.dart';
import '../housework_create/housework_create_state.dart';
import 'housework_edit_state.dart';

class HouseworkEditNotifier
    extends AutoDisposeFamilyAsyncNotifier<HouseworkEditState, int> {
  @override
  Future<HouseworkEditState> build(int houseworkId) async {
    final householdState = await ref.watch(householdNotifierProvider.future);
    final householdId = householdState.selectedHousehold?.id;
    if (householdId == null) {
      return const HouseworkEditState(fetchError: true);
    }

    final repo = ref.read(houseworkSettingsRepositoryProvider);

    try {
      final results = await Future.wait([
        repo.fetchHousework(houseworkId: houseworkId),
        repo.fetchMembers(householdId: householdId),
      ]);

      final hw = results[0] as dynamic;
      final members = results[1] as List<HouseholdMemberDto>;

      final form = HouseworkFormState(
        name: hw.name as String,
        description: hw.description as String? ?? '',
        category: hw.category as String,
        recurrenceType: hw.recurrenceType as String,
        weeklyDays: (hw.weeklyDays as int?) ?? 0,
        dayOfMonth: (hw.dayOfMonth as int?) ?? 1,
        nthWeek: (hw.nthWeek as int?) ?? 1,
        weekday: (hw.weekday as int?) ?? 1,
        startDate: hw.startDate as String,
        endDate: hw.endDate as String,
        defaultAssigneeUserId: hw.defaultAssigneeUserId as int?,
      );

      return HouseworkEditState(
        houseworkId: houseworkId,
        form: form,
        members: members,
      );
    } catch (_) {
      return const HouseworkEditState(fetchError: true);
    }
  }

  int? get _householdId =>
      ref.read(householdNotifierProvider).valueOrNull?.selectedHousehold?.id;

  void updateName(String value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(name: value)),
    );
  }

  void updateDescription(String value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(description: value)),
    );
  }

  void updateCategory(String value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(category: value)),
    );
  }

  void updateRecurrenceType(String value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(recurrenceType: value)),
    );
  }

  void toggleWeeklyDay(int bit) {
    final current = state.valueOrNull;
    if (current == null) return;
    final newMask = current.form.weeklyDays ^ (1 << bit);
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(weeklyDays: newMask)),
    );
  }

  void updateDayOfMonth(int value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(dayOfMonth: value)),
    );
  }

  void updateNthWeek(int value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(nthWeek: value)),
    );
  }

  void updateWeekday(int value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(weekday: value)),
    );
  }

  void updateStartDate(String value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(startDate: value)),
    );
  }

  void updateEndDate(String value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(form: current.form.copyWith(endDate: value)),
    );
  }

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

  HouseworkFormErrors validate() {
    final current = state.valueOrNull;
    if (current == null) return HouseworkFormErrors.empty;

    final form = current.form;
    String? nameError;
    String? weeklyDaysError;
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

  Future<void> save() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final householdId = _householdId;
    if (householdId == null) return;
    final houseworkId = current.houseworkId;
    if (houseworkId == null) return;

    final errors = validate();
    if (errors.hasError) return;

    state = AsyncData(current.copyWith(isSaving: true, clearError: true));

    await _runCatching(
      current,
      (c) async {
        final repo = ref.read(houseworkSettingsRepositoryProvider);
        final form = c.form;

        await repo.updateHousework(
          houseworkId: houseworkId,
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
            successMessage: 'houseworkEditSaveSuccess',
            clearError: true,
          ),
        );
      },
      onError: (c, msg) =>
          c.copyWith(isSaving: false, errorMessage: msg, clearSuccess: true),
    );
  }

  /// AsyncFamilyNotifier 向けエラーハンドリングヘルパー。
  Future<void> _runCatching(
    HouseworkEditState current,
    Future<void> Function(HouseworkEditState c) operation, {
    HouseworkEditState Function(HouseworkEditState c, String errorMessage)?
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

final houseworkEditNotifierProvider =
    AutoDisposeAsyncNotifierProvider.family<
      HouseworkEditNotifier,
      HouseworkEditState,
      int
    >(HouseworkEditNotifier.new);
