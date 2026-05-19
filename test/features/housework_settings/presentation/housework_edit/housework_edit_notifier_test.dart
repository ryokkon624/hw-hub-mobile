import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/housework_settings/data/housework_settings_repository.dart';
import 'package:hw_hub_mobile/features/housework_settings/housework_settings_providers.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_edit/housework_edit_notifier.dart';

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
  });
}
