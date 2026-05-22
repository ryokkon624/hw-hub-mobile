import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/housework_settings/data/housework_settings_repository.dart';
import 'package:hw_hub_mobile/features/housework_settings/housework_settings_providers.dart';

class _FakeHouseholdNotifier extends HouseholdNotifier {
  @override
  Future<HouseholdState> build() async {
    return const HouseholdState(
      households: [Household(id: 10, name: 'テスト家')],
      selectedHousehold: Household(id: 10, name: 'テスト家'),
    );
  }
}

class _MockRepo implements HouseworkSettingsRepository {
  final bool shouldFailFetch;
  final bool shouldFailSave;
  _MockRepo({this.shouldFailFetch = false, this.shouldFailSave = false});

  @override
  Future<List<HouseworkDto>> fetchHouseworks({required int householdId}) async {
    return [];
  }

  @override
  Future<HouseworkDto> fetchHousework({required int houseworkId}) async {
    if (shouldFailFetch) throw const ServerException(message: 'フェッチエラー');
    return const HouseworkDto(
      houseworkId: 1,
      householdId: 10,
      name: '掃除機',
      description: '説明テスト',
      category: 'CLEAN',
      recurrenceType: '1',
      weeklyDays: 42,
      startDate: '2025-01-01',
      endDate: '2099-12-31',
    );
  }

  @override
  Future<List<HouseholdMemberDto>> fetchMembers({
    required int householdId,
  }) async {
    return [
      const HouseholdMemberDto(
        householdId: 10,
        userId: 1,
        displayName: 'テストユーザー',
        status: 'ACTIVE',
        role: 'OWNER',
      ),
    ];
  }

  @override
  Future<HouseworkDto> createHousework({
    required int householdId,
    required String name,
    String? description,
    required String category,
    required String recurrenceType,
    int? weeklyDays,
    int? dayOfMonth,
    int? nthWeek,
    int? weekday,
    required String startDate,
    required String endDate,
    int? defaultAssigneeUserId,
  }) async {
    return const HouseworkDto(
      houseworkId: 99,
      householdId: 10,
      name: '',
      category: 'CLEAN',
      recurrenceType: '1',
      startDate: '2025-01-01',
      endDate: '2099-12-31',
    );
  }

  @override
  Future<HouseworkDto> updateHousework({
    required int houseworkId,
    required int householdId,
    required String name,
    String? description,
    required String category,
    required String recurrenceType,
    int? weeklyDays,
    int? dayOfMonth,
    int? nthWeek,
    int? weekday,
    required String startDate,
    required String endDate,
    int? defaultAssigneeUserId,
  }) async {
    if (shouldFailSave) throw const ServerException(message: 'サーバーエラー');
    return HouseworkDto(
      houseworkId: houseworkId,
      householdId: householdId,
      name: name,
      category: category,
      recurrenceType: recurrenceType,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<HouseworkTemplateDto>> fetchTemplates() async {
    return [];
  }
}

ProviderContainer _makeContainer({
  bool shouldFailFetch = false,
  bool shouldFailSave = false,
}) {
  final container = ProviderContainer(
    overrides: [
      householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
      houseworkSettingsRepositoryProvider.overrideWithValue(
        _MockRepo(
          shouldFailFetch: shouldFailFetch,
          shouldFailSave: shouldFailSave,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  // ==================================
  // build() 初期ロード
  // ==================================

  group('build() 初期ロード', () {
    test('家事データとメンバーリストを取得してフォームに初期値をセットする', () async {
      final container = _makeContainer();

      final state = await container.read(
        houseworkEditNotifierProvider(1).future,
      );

      expect(state.form.name, '掃除機');
      expect(state.form.category, 'CLEAN');
      expect(state.members, hasLength(1));
    });

    test('取得失敗時はfetchErrorがtrueになる', () async {
      final container = _makeContainer(shouldFailFetch: true);

      final state = await container.read(
        houseworkEditNotifierProvider(1).future,
      );

      expect(state.fetchError, isTrue);
    });
  });

  // ==================================
  // save (update)
  // ==================================

  group('save() 編集', () {
    test('成功時: successMessageが設定される', () async {
      final container = _makeContainer();

      await container.read(houseworkEditNotifierProvider(1).future);
      await container.read(houseworkEditNotifierProvider(1).notifier).save();

      final state = container
          .read(houseworkEditNotifierProvider(1))
          .valueOrNull!;
      expect(state.successMessage, isNotNull);
    });

    test('APIエラー時: errorMessageが設定される', () async {
      final container = _makeContainer(shouldFailSave: true);

      await container.read(houseworkEditNotifierProvider(1).future);
      await container.read(houseworkEditNotifierProvider(1).notifier).save();

      final state = container
          .read(houseworkEditNotifierProvider(1))
          .valueOrNull!;
      expect(state.errorMessage, isNotNull);
    });
  });

  // ==================================
  // フォーム更新メソッド
  // ==================================

  group('フォーム更新', () {
    test('updateName: 名前が更新される', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);

      container
          .read(houseworkEditNotifierProvider(1).notifier)
          .updateName('新しい掃除');

      final state = container
          .read(houseworkEditNotifierProvider(1))
          .valueOrNull!;
      expect(state.form.name, '新しい掃除');
    });

    test('updateDescription: 説明が更新される', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);

      container
          .read(houseworkEditNotifierProvider(1).notifier)
          .updateDescription('新しい説明');

      final state = container
          .read(houseworkEditNotifierProvider(1))
          .valueOrNull!;
      expect(state.form.description, '新しい説明');
    });

    test('updateCategory: カテゴリが更新される', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);

      container
          .read(houseworkEditNotifierProvider(1).notifier)
          .updateCategory('COOK');

      final state = container
          .read(houseworkEditNotifierProvider(1))
          .valueOrNull!;
      expect(state.form.category, 'COOK');
    });

    test('updateRecurrenceType: 繰り返しタイプが更新される', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);

      container
          .read(houseworkEditNotifierProvider(1).notifier)
          .updateRecurrenceType('2');

      final state = container
          .read(houseworkEditNotifierProvider(1))
          .valueOrNull!;
      expect(state.form.recurrenceType, '2');
    });

    test('toggleWeeklyDay: 曜日ビットが反転する', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);
      final before = container
          .read(houseworkEditNotifierProvider(1))
          .valueOrNull!
          .form
          .weeklyDays;

      container
          .read(houseworkEditNotifierProvider(1).notifier)
          .toggleWeeklyDay(0); // bit 0 = 月曜

      final after = container
          .read(houseworkEditNotifierProvider(1))
          .valueOrNull!
          .form
          .weeklyDays;
      expect(after, before ^ 1);
    });

    test('updateDayOfMonth: 月次日が更新される', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);

      container
          .read(houseworkEditNotifierProvider(1).notifier)
          .updateDayOfMonth(15);

      final state = container
          .read(houseworkEditNotifierProvider(1))
          .valueOrNull!;
      expect(state.form.dayOfMonth, 15);
    });

    test('updateNthWeek: 第n週が更新される', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);

      container
          .read(houseworkEditNotifierProvider(1).notifier)
          .updateNthWeek(3);

      final state = container
          .read(houseworkEditNotifierProvider(1))
          .valueOrNull!;
      expect(state.form.nthWeek, 3);
    });

    test('updateWeekday: 曜日が更新される', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);

      container
          .read(houseworkEditNotifierProvider(1).notifier)
          .updateWeekday(5);

      final state = container
          .read(houseworkEditNotifierProvider(1))
          .valueOrNull!;
      expect(state.form.weekday, 5);
    });

    test('updateStartDate: 開始日が更新される', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);

      container
          .read(houseworkEditNotifierProvider(1).notifier)
          .updateStartDate('2026-06-01');

      final state = container
          .read(houseworkEditNotifierProvider(1))
          .valueOrNull!;
      expect(state.form.startDate, '2026-06-01');
    });

    test('updateEndDate: 終了日が更新される', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);

      container
          .read(houseworkEditNotifierProvider(1).notifier)
          .updateEndDate('2027-12-31');

      final state = container
          .read(houseworkEditNotifierProvider(1))
          .valueOrNull!;
      expect(state.form.endDate, '2027-12-31');
    });

    test('updateDefaultAssigneeUserId: 担当者IDが更新される', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);

      container
          .read(houseworkEditNotifierProvider(1).notifier)
          .updateDefaultAssigneeUserId(1);

      final state = container
          .read(houseworkEditNotifierProvider(1))
          .valueOrNull!;
      expect(state.form.defaultAssigneeUserId, 1);
    });

    test('updateDefaultAssigneeUserId(null): 担当者IDがクリアされる', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);
      container
          .read(houseworkEditNotifierProvider(1).notifier)
          .updateDefaultAssigneeUserId(1);

      container
          .read(houseworkEditNotifierProvider(1).notifier)
          .updateDefaultAssigneeUserId(null);

      final state = container
          .read(houseworkEditNotifierProvider(1))
          .valueOrNull!;
      expect(state.form.defaultAssigneeUserId, isNull);
    });
  });

  // ==================================
  // validate
  // ==================================

  group('validate()', () {
    test('初期値（既存データ）はバリデーション通過する', () async {
      final container = _makeContainer();

      await container.read(houseworkEditNotifierProvider(1).future);
      final errors = container
          .read(houseworkEditNotifierProvider(1).notifier)
          .validate();

      expect(errors.hasError, isFalse);
    });

    test('名前が空の場合バリデーションエラー', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);

      container.read(houseworkEditNotifierProvider(1).notifier).updateName('');

      final errors = container
          .read(houseworkEditNotifierProvider(1).notifier)
          .validate();
      expect(errors.nameError, isNotNull);
    });

    test('名前が100文字超の場合バリデーションエラー', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);

      container
          .read(houseworkEditNotifierProvider(1).notifier)
          .updateName('a' * 101);

      final errors = container
          .read(houseworkEditNotifierProvider(1).notifier)
          .validate();
      expect(errors.nameError, isNotNull);
    });

    test('週次で曜日未選択の場合バリデーションエラー', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);

      // recurrenceType=1(週次), weeklyDays=0
      final notifier = container.read(
        houseworkEditNotifierProvider(1).notifier,
      );
      // 初期データは recurrenceType='1', weeklyDays=42
      // weeklyDaysを0にする（全ビットクリア）
      // 42 = 0b101010, XOR 42 = 0
      notifier.toggleWeeklyDay(1); // bit1: 2
      notifier.toggleWeeklyDay(3); // bit3: 8
      notifier.toggleWeeklyDay(5); // bit5: 32
      // 42 XOR 2 = 40, 40 XOR 8 = 32, 32 XOR 32 = 0

      final errors = notifier.validate();
      expect(errors.weeklyDaysError, isNotNull);
    });

    test('開始日が空の場合バリデーションエラー', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);

      container
          .read(houseworkEditNotifierProvider(1).notifier)
          .updateStartDate('');

      final errors = container
          .read(houseworkEditNotifierProvider(1).notifier)
          .validate();
      expect(errors.startDateError, isNotNull);
    });

    test('終了日が開始日より前の場合バリデーションエラー', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);

      final notifier = container.read(
        houseworkEditNotifierProvider(1).notifier,
      );
      notifier.updateStartDate('2026-06-01');
      notifier.updateEndDate('2026-01-01'); // 終了 < 開始

      final errors = notifier.validate();
      expect(errors.endDateError, isNotNull);
    });

    test('startDateが存在しない日付（2月30日）のときバリデーションエラーが返る', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);

      final notifier = container.read(
        houseworkEditNotifierProvider(1).notifier,
      );
      notifier.updateStartDate('2026-02-30');

      final errors = notifier.validate();
      expect(errors.startDateError, 'houseworkCreateErrorInvalidDate');
    });

    test('endDateが存在しない日付（4月31日）のときバリデーションエラーが返る', () async {
      final container = _makeContainer();
      await container.read(houseworkEditNotifierProvider(1).future);

      final notifier = container.read(
        houseworkEditNotifierProvider(1).notifier,
      );
      notifier.updateEndDate('2026-04-31');

      final errors = notifier.validate();
      expect(errors.endDateError, 'houseworkCreateErrorInvalidDate');
    });
  });
}
