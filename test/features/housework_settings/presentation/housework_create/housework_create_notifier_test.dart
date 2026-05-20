import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/housework_settings/data/housework_settings_repository.dart';
import 'package:hw_hub_mobile/features/housework_settings/housework_settings_providers.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_create/housework_create_notifier.dart';

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
  /// true のとき create/update のみ失敗させる
  final bool shouldFailSave;
  _MockRepo({this.shouldFailSave = false});

  @override
  Future<List<HouseworkDto>> fetchHouseworks({required int householdId}) async {
    return [];
  }

  @override
  Future<HouseworkDto> fetchHousework({required int houseworkId}) async {
    return const HouseworkDto(
      houseworkId: 1,
      householdId: 10,
      name: '掃除機',
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
    if (shouldFailSave) throw const ServerException(message: 'サーバーエラー');
    return HouseworkDto(
      houseworkId: 99,
      householdId: householdId,
      name: name,
      category: category,
      recurrenceType: recurrenceType,
      startDate: startDate,
      endDate: endDate,
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
    return [
      const HouseworkTemplateDto(
        houseworkTemplateId: 1,
        nameJa: 'テンプレート掃除',
        nameEn: 'Template Clean',
        nameEs: 'Plantilla',
        category: 'CLEAN',
        recurrenceType: '1',
        weeklyDays: 42,
      ),
    ];
  }
}

ProviderContainer _makeContainer({bool shouldFailSave = false}) {
  final container = ProviderContainer(
    overrides: [
      householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
      houseworkSettingsRepositoryProvider.overrideWithValue(
        _MockRepo(shouldFailSave: shouldFailSave),
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
    test('世帯IDが設定されていれば世帯メンバー一覧とテンプレートを取得する', () async {
      final container = _makeContainer();

      final state = await container.read(
        houseworkCreateNotifierProvider.future,
      );

      expect(state.members, hasLength(1));
      expect(state.templates, hasLength(1));
    });
  });

  // ==================================
  // updateName
  // ==================================

  group('updateName()', () {
    test('家事名を更新する', () async {
      final container = _makeContainer();

      await container.read(houseworkCreateNotifierProvider.future);
      container
          .read(houseworkCreateNotifierProvider.notifier)
          .updateName('トイレ掃除');

      final state = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(state.form.name, 'トイレ掃除');
    });
  });

  // ==================================
  // updateRecurrenceType
  // ==================================

  group('updateRecurrenceType()', () {
    test('周期タイプをMONTHLYに変更する', () async {
      final container = _makeContainer();

      await container.read(houseworkCreateNotifierProvider.future);
      container
          .read(houseworkCreateNotifierProvider.notifier)
          .updateRecurrenceType('2');

      final state = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(state.form.recurrenceType, '2');
    });
  });

  // ==================================
  // toggleWeeklyDay
  // ==================================

  group('toggleWeeklyDay()', () {
    test('曜日ビットをON/OFFできる', () async {
      final container = _makeContainer();

      await container.read(houseworkCreateNotifierProvider.future);
      // bit1=月曜
      container
          .read(houseworkCreateNotifierProvider.notifier)
          .toggleWeeklyDay(1);

      final state = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(state.form.weeklyDays & 2, 2);

      // 再度押すとOFF
      container
          .read(houseworkCreateNotifierProvider.notifier)
          .toggleWeeklyDay(1);
      final state2 = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(state2.form.weeklyDays & 2, 0);
    });
  });

  // ==================================
  // applyTemplate
  // ==================================

  group('applyTemplate()', () {
    test('テンプレートを適用するとフォーム値が上書きされる', () async {
      final container = _makeContainer();

      await container.read(houseworkCreateNotifierProvider.future);
      final state = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      final template = state.templates.first;

      container
          .read(houseworkCreateNotifierProvider.notifier)
          .applyTemplate(template, 'ja');

      final updated = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(updated.form.name, 'テンプレート掃除');
      expect(updated.form.category, 'CLEAN');
    });
  });

  // ==================================
  // validate
  // ==================================

  group('validate()', () {
    test('家事名が空のときバリデーションエラーが返る', () async {
      final container = _makeContainer();

      await container.read(houseworkCreateNotifierProvider.future);
      // デフォルトname=''
      final errors = container
          .read(houseworkCreateNotifierProvider.notifier)
          .validate();

      expect(errors.nameError, isNotNull);
    });

    test('必須フィールドが揃っているときエラーなし', () async {
      final container = _makeContainer();

      await container.read(houseworkCreateNotifierProvider.future);
      container
          .read(houseworkCreateNotifierProvider.notifier)
          .updateName('掃除機');
      container
          .read(houseworkCreateNotifierProvider.notifier)
          .toggleWeeklyDay(1);

      final errors = container
          .read(houseworkCreateNotifierProvider.notifier)
          .validate();

      expect(errors.nameError, isNull);
      expect(errors.weeklyDaysError, isNull);
    });

    test('WEEKLYで曜日が未選択のときバリデーションエラーが返る', () async {
      final container = _makeContainer();

      await container.read(houseworkCreateNotifierProvider.future);
      container
          .read(houseworkCreateNotifierProvider.notifier)
          .updateName('掃除機');
      // weeklyDays=0のまま

      final errors = container
          .read(houseworkCreateNotifierProvider.notifier)
          .validate();

      expect(errors.weeklyDaysError, isNotNull);
    });
  });

  // ==================================
  // その他の更新メソッド
  // ==================================

  group('その他更新メソッド', () {
    test('updateDescription: 説明を更新する', () async {
      final container = _makeContainer();
      await container.read(houseworkCreateNotifierProvider.future);

      container
          .read(houseworkCreateNotifierProvider.notifier)
          .updateDescription('毎日やること');

      final state = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(state.form.description, '毎日やること');
    });

    test('updateCategory: カテゴリを更新する', () async {
      final container = _makeContainer();
      await container.read(houseworkCreateNotifierProvider.future);

      container
          .read(houseworkCreateNotifierProvider.notifier)
          .updateCategory('COOK');

      final state = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(state.form.category, 'COOK');
    });

    test('updateDayOfMonth: 月次日を更新する', () async {
      final container = _makeContainer();
      await container.read(houseworkCreateNotifierProvider.future);

      container
          .read(houseworkCreateNotifierProvider.notifier)
          .updateDayOfMonth(20);

      final state = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(state.form.dayOfMonth, 20);
    });

    test('updateNthWeek: 第n週を更新する', () async {
      final container = _makeContainer();
      await container.read(houseworkCreateNotifierProvider.future);

      container.read(houseworkCreateNotifierProvider.notifier).updateNthWeek(2);

      final state = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(state.form.nthWeek, 2);
    });

    test('updateWeekday: 曜日を更新する', () async {
      final container = _makeContainer();
      await container.read(houseworkCreateNotifierProvider.future);

      container.read(houseworkCreateNotifierProvider.notifier).updateWeekday(3);

      final state = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(state.form.weekday, 3);
    });

    test('updateStartDate: 開始日を更新する', () async {
      final container = _makeContainer();
      await container.read(houseworkCreateNotifierProvider.future);

      container
          .read(houseworkCreateNotifierProvider.notifier)
          .updateStartDate('2026-07-01');

      final state = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(state.form.startDate, '2026-07-01');
    });

    test('updateEndDate: 終了日を更新する', () async {
      final container = _makeContainer();
      await container.read(houseworkCreateNotifierProvider.future);

      container
          .read(houseworkCreateNotifierProvider.notifier)
          .updateEndDate('2027-06-30');

      final state = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(state.form.endDate, '2027-06-30');
    });

    test('updateDefaultAssigneeUserId: 担当者IDを更新する', () async {
      final container = _makeContainer();
      await container.read(houseworkCreateNotifierProvider.future);

      container
          .read(houseworkCreateNotifierProvider.notifier)
          .updateDefaultAssigneeUserId(1);

      final state = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(state.form.defaultAssigneeUserId, 1);
    });

    test('updateDefaultAssigneeUserId(null): 担当者IDをクリアする', () async {
      final container = _makeContainer();
      await container.read(houseworkCreateNotifierProvider.future);
      container
          .read(houseworkCreateNotifierProvider.notifier)
          .updateDefaultAssigneeUserId(1);

      container
          .read(houseworkCreateNotifierProvider.notifier)
          .updateDefaultAssigneeUserId(null);

      final state = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(state.form.defaultAssigneeUserId, isNull);
    });

    test('dismissRecommendation: 推薦テキストをクリアする', () async {
      final container = _makeContainer();
      await container.read(houseworkCreateNotifierProvider.future);
      // テンプレート適用で推薦テキストを設定
      final state = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      container
          .read(houseworkCreateNotifierProvider.notifier)
          .applyTemplate(state.templates.first, 'ja');

      container
          .read(houseworkCreateNotifierProvider.notifier)
          .dismissRecommendation();

      final updated = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(updated.recommendationText, isNull);
    });

    test('applyTemplate: enロケールでテンプレートを適用する', () async {
      final container = _makeContainer();
      await container.read(houseworkCreateNotifierProvider.future);
      final state = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;

      container
          .read(houseworkCreateNotifierProvider.notifier)
          .applyTemplate(state.templates.first, 'en');

      final updated = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(updated.form.name, 'Template Clean');
    });
  });

  // ==================================
  // save (create)
  // ==================================

  group('save() 新規作成', () {
    test('成功時: successMessageが設定される', () async {
      final container = _makeContainer();

      await container.read(houseworkCreateNotifierProvider.future);
      container
          .read(houseworkCreateNotifierProvider.notifier)
          .updateName('掃除機');
      container
          .read(houseworkCreateNotifierProvider.notifier)
          .toggleWeeklyDay(1);

      await container.read(houseworkCreateNotifierProvider.notifier).save();

      final state = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(state.successMessage, isNotNull);
    });

    test('APIエラー時: errorMessageが設定される', () async {
      final container = _makeContainer(shouldFailSave: true);

      await container.read(houseworkCreateNotifierProvider.future);
      container
          .read(houseworkCreateNotifierProvider.notifier)
          .updateName('掃除機');
      container
          .read(houseworkCreateNotifierProvider.notifier)
          .toggleWeeklyDay(1);

      await container.read(houseworkCreateNotifierProvider.notifier).save();

      final state = container
          .read(houseworkCreateNotifierProvider)
          .valueOrNull!;
      expect(state.errorMessage, isNotNull);
    });
  });
}
