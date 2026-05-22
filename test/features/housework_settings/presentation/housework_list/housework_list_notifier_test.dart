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
  final bool shouldFail;
  final List<HouseworkDto> houseworks;

  _MockRepo({this.shouldFail = false, List<HouseworkDto>? houseworks})
    : houseworks =
          houseworks ??
          [
            const HouseworkDto(
              houseworkId: 1,
              householdId: 10,
              name: '掃除機',
              category: 'CLEAN',
              recurrenceType: '1',
              weeklyDays: 42,
              startDate: '2025-01-01',
              endDate: '2099-12-31',
            ),
            const HouseworkDto(
              houseworkId: 2,
              householdId: 10,
              name: 'トイレ掃除',
              category: 'CLEAN',
              recurrenceType: '1',
              weeklyDays: 64,
              startDate: '2025-01-01',
              endDate: '2099-12-31',
            ),
          ];

  void _maybeThrow() {
    if (shouldFail) throw const ServerException(message: 'サーバーエラー');
  }

  @override
  Future<List<HouseworkDto>> fetchHouseworks({required int householdId}) async {
    _maybeThrow();
    return houseworks;
  }

  @override
  Future<HouseworkDto> fetchHousework({required int houseworkId}) async {
    _maybeThrow();
    return houseworks.firstWhere((h) => h.houseworkId == houseworkId);
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
    _maybeThrow();
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
    _maybeThrow();
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
  Future<List<HouseholdMemberDto>> fetchMembers({
    required int householdId,
  }) async {
    _maybeThrow();
    return [];
  }

  @override
  Future<List<HouseworkTemplateDto>> fetchTemplates() async {
    _maybeThrow();
    return [];
  }
}

ProviderContainer _makeContainer({
  bool shouldFail = false,
  List<HouseworkDto>? houseworks,
}) {
  final container = ProviderContainer(
    overrides: [
      householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
      houseworkSettingsRepositoryProvider.overrideWithValue(
        _MockRepo(shouldFail: shouldFail, houseworks: houseworks),
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
    test('世帯IDが設定されていれば家事一覧を取得してstateに設定する', () async {
      final container = _makeContainer();

      final result = await container.read(houseworkListNotifierProvider.future);

      expect(result.allHouseworks, hasLength(2));
      expect(result.filteredHouseworks, hasLength(2));
      expect(result.allHouseworks.first.name, '掃除機');
    });

    test('APIエラー時はstateがエラーになる', () async {
      final container = _makeContainer(shouldFail: true);

      expect(
        () => container.read(houseworkListNotifierProvider.future),
        throwsA(isA<AppException>()),
      );
    });
  });

  // ==================================
  // filterByCategory
  // ==================================

  group('filterByCategory()', () {
    test('カテゴリフィルタを設定するとfilteredHouseworksが絞り込まれる', () async {
      final container = _makeContainer(
        houseworks: [
          const HouseworkDto(
            houseworkId: 1,
            householdId: 10,
            name: '掃除機',
            category: 'CLEAN',
            recurrenceType: '1',
            weeklyDays: 42,
            startDate: '2025-01-01',
            endDate: '2099-12-31',
          ),
          const HouseworkDto(
            houseworkId: 2,
            householdId: 10,
            name: 'ゴミ出し',
            category: 'GARBAGE',
            recurrenceType: '1',
            weeklyDays: 3,
            startDate: '2025-01-01',
            endDate: '2099-12-31',
          ),
        ],
      );

      await container.read(houseworkListNotifierProvider.future);
      container
          .read(houseworkListNotifierProvider.notifier)
          .filterByCategory('CLEAN');

      final state = container.read(houseworkListNotifierProvider).valueOrNull!;
      expect(state.filteredHouseworks, hasLength(1));
      expect(state.filteredHouseworks.first.category, 'CLEAN');
      expect(state.selectedCategory, 'CLEAN');
      expect(state.currentPage, 1);
    });

    test('nullを渡すと全件表示になる', () async {
      final container = _makeContainer();

      await container.read(houseworkListNotifierProvider.future);
      container
          .read(houseworkListNotifierProvider.notifier)
          .filterByCategory('CLEAN');
      container
          .read(houseworkListNotifierProvider.notifier)
          .filterByCategory(null);

      final state = container.read(houseworkListNotifierProvider).valueOrNull!;
      expect(state.filteredHouseworks, hasLength(2));
      expect(state.selectedCategory, isNull);
    });
  });

  // ==================================
  // goToPage
  // ==================================

  group('goToPage()', () {
    test('ページを変更するとcurrentPageが更新される', () async {
      final container = _makeContainer();

      await container.read(houseworkListNotifierProvider.future);
      container.read(houseworkListNotifierProvider.notifier).goToPage(2);

      final state = container.read(houseworkListNotifierProvider).valueOrNull!;
      expect(state.currentPage, 2);
    });
  });

  // ==================================
  // reload
  // ==================================

  group('reload()', () {
    test('reload()を呼ぶと状態がAsyncDataとして取得できる', () async {
      final container = _makeContainer();

      // 初期ロードを待つ
      await container.read(houseworkListNotifierProvider.future);

      // reload() を呼ぶ
      await container.read(houseworkListNotifierProvider.notifier).reload();

      // reload後も AsyncData として読み取れること
      final async = container.read(houseworkListNotifierProvider);
      expect(async.hasValue, true);
      expect(async.value!.allHouseworks, hasLength(2));
    });
  });

  // ==================================
  // pagedHouseworks
  // ==================================

  group('pagedHouseworks', () {
    test('10件以下のデータはすべて1ページに表示される', () async {
      final container = _makeContainer();

      final state = await container.read(houseworkListNotifierProvider.future);
      expect(state.pagedHouseworks, hasLength(2));
      expect(state.totalPages, 1);
    });

    test('11件以上のデータは10件/ページでページネーションされる', () async {
      final items = List.generate(
        11,
        (i) => HouseworkDto(
          houseworkId: i + 1,
          householdId: 10,
          name: '家事${i + 1}',
          category: 'CLEAN',
          recurrenceType: '1',
          weeklyDays: 42,
          startDate: '2025-01-01',
          endDate: '2099-12-31',
        ),
      );
      final container = _makeContainer(houseworks: items);

      final state = await container.read(houseworkListNotifierProvider.future);
      expect(state.pagedHouseworks, hasLength(10));
      expect(state.totalPages, 2);

      container.read(houseworkListNotifierProvider.notifier).goToPage(2);
      final state2 = container.read(houseworkListNotifierProvider).valueOrNull!;
      expect(state2.pagedHouseworks, hasLength(1));
    });
  });
}
