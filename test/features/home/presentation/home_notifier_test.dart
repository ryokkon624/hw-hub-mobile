import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/auth/auth_notifier.dart';
import 'package:hw_hub_mobile/core/auth/auth_state.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/models/auth_user.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/features/home/data/models/home_raw_data.dart';
import 'package:hw_hub_mobile/features/home/data/models/household_member_dto.dart';
import 'package:hw_hub_mobile/features/home/data/models/housework_task_dto.dart';
import 'package:hw_hub_mobile/features/home/data/models/shopping_item_dto.dart';
import 'package:hw_hub_mobile/features/home/home_providers.dart';
import 'package:hw_hub_mobile/features/home/presentation/home_notifier.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home_mocks.mocks.dart';

/// 今日の日付文字列 (yyyy-MM-dd)
String _today() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// N日後の日付文字列
String _daysFromNow(int days) {
  final d = DateTime.now().add(Duration(days: days));
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

HouseworkTaskDto _openTask({
  int id = 1,
  String targetDate = '',
  int? assigneeUserId,
}) => HouseworkTaskDto(
  houseworkTaskId: id,
  householdId: 1,
  houseworkId: 1,
  houseworkName: '掃除',
  targetDate: targetDate.isEmpty ? _today() : targetDate,
  assigneeUserId: assigneeUserId,
  status: '0',
);

const _member1 = HouseholdMemberDto(
  householdId: 1,
  userId: 10,
  displayName: 'ママ',
  status: 'active',
  role: 'member',
);

HomeRawData _makeRawData({
  List<HouseworkTaskDto> openTasks = const [],
  List<HouseworkTaskDto> doneTasks = const [],
  List<ShoppingItemDto> shoppingItems = const [],
}) => HomeRawData(
  members: const [_member1],
  openTasks: openTasks,
  doneTasks: doneTasks,
  shoppingItems: shoppingItems,
);

ProviderContainer _makeContainer({
  required MockHomeRepository mockRepo,
  Household? selectedHousehold,
  int currentUserId = 10,
}) {
  SharedPreferences.setMockInitialValues({});

  final testUser = AuthUser(
    userId: currentUserId,
    email: 'test@example.com',
    displayName: 'テスト',
  );

  final container = ProviderContainer(
    overrides: [
      homeRepositoryProvider.overrideWithValue(mockRepo),
      householdNotifierProvider.overrideWith(
        () => _FakeHouseholdNotifier(
          HouseholdState(
            households: selectedHousehold != null ? [selectedHousehold] : [],
            selectedHousehold: selectedHousehold,
          ),
        ),
      ),
      authNotifierProvider.overrideWith(
        () => _FakeAuthNotifier(AuthAuthenticated(testUser)),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late MockHomeRepository mockRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepo = MockHomeRepository();
  });

  group('HomeNotifier.build()', () {
    test('世帯未所属時: hasHousehold=false で即座に返す', () async {
      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: null,
      );

      final state = await container.read(homeNotifierProvider.future);

      expect(state.hasHousehold, isFalse);
      verifyNever(mockRepo.loadAll(any));
    });

    test('世帯所属時: APIを呼び出しHomeStateを返す', () async {
      const h = Household(id: 1, name: '山田家');
      when(mockRepo.loadAll(1)).thenAnswer((_) async => _makeRawData());

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );

      final state = await container.read(homeNotifierProvider.future);

      expect(state.hasHousehold, isTrue);
      verify(mockRepo.loadAll(1)).called(1);
    });

    test('API失敗時: AsyncErrorになる', () async {
      const h = Household(id: 1, name: '山田家');
      when(mockRepo.loadAll(1)).thenThrow(Exception('Network error'));

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );
      container.listen(homeNotifierProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final result = container.read(homeNotifierProvider);
      expect(result.hasError, isTrue);
    });
  });

  group('集計: MyTasksSummary', () {
    test('今日のタスク件数を正しく集計する', () async {
      const h = Household(id: 1, name: '山田家');
      final tasks = [
        _openTask(id: 1, targetDate: _today(), assigneeUserId: 10),
        _openTask(id: 2, targetDate: _today(), assigneeUserId: 10),
        _openTask(id: 3, targetDate: _daysFromNow(1), assigneeUserId: 10),
      ];
      when(
        mockRepo.loadAll(1),
      ).thenAnswer((_) async => _makeRawData(openTasks: tasks));

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );
      final state = await container.read(homeNotifierProvider.future);

      // ログインユーザーID=10（_member1.userId）
      expect(state.myTasksSummary.todayCount, 2);
    });

    test('直近1週間のタスク件数を集計する', () async {
      const h = Household(id: 1, name: '山田家');
      final tasks = [
        _openTask(id: 1, targetDate: _today(), assigneeUserId: 10),
        _openTask(id: 2, targetDate: _daysFromNow(6), assigneeUserId: 10),
        _openTask(
          id: 3,
          targetDate: _daysFromNow(7),
          assigneeUserId: 10,
        ), // 7日後は含まない
      ];
      when(
        mockRepo.loadAll(1),
      ).thenAnswer((_) async => _makeRawData(openTasks: tasks));

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );
      final state = await container.read(homeNotifierProvider.future);

      expect(state.myTasksSummary.weekCount, 2);
    });

    test('期限超過タスクを集計する（今日より前）', () async {
      const h = Household(id: 1, name: '山田家');
      final tasks = [
        _openTask(id: 1, targetDate: _daysFromNow(-1), assigneeUserId: 10),
        _openTask(id: 2, targetDate: _daysFromNow(-2), assigneeUserId: 10),
        _openTask(id: 3, targetDate: _today(), assigneeUserId: 10),
      ];
      when(
        mockRepo.loadAll(1),
      ).thenAnswer((_) async => _makeRawData(openTasks: tasks));

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );
      final state = await container.read(homeNotifierProvider.future);

      expect(state.myTasksSummary.overdueCount, 2);
    });

    test('他ユーザーに割り当てられたタスクはMyTasksに含まれない', () async {
      const h = Household(id: 1, name: '山田家');
      final tasks = [
        _openTask(id: 1, targetDate: _today(), assigneeUserId: 10), // 自分
        _openTask(id: 2, targetDate: _today(), assigneeUserId: 99), // 他ユーザー
        _openTask(id: 3, targetDate: _today(), assigneeUserId: null), // 未割当
      ];
      when(
        mockRepo.loadAll(1),
      ).thenAnswer((_) async => _makeRawData(openTasks: tasks));

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );
      final state = await container.read(homeNotifierProvider.future);

      // ログインユーザーID=10のタスクのみカウント（99と未割当は除外）
      expect(state.myTasksSummary.todayCount, 1);
    });
  });

  group('集計: UnassignedSummary', () {
    test('未割り当てタスクの総件数を集計する', () async {
      const h = Household(id: 1, name: '山田家');
      final tasks = [
        _openTask(id: 1, assigneeUserId: null), // 未割り当て
        _openTask(id: 2, assigneeUserId: null), // 未割り当て
        _openTask(id: 3, assigneeUserId: 10), // 割り当て済み
      ];
      when(
        mockRepo.loadAll(1),
      ).thenAnswer((_) async => _makeRawData(openTasks: tasks));

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );
      final state = await container.read(homeNotifierProvider.future);

      expect(state.unassignedSummary.totalCount, 2);
    });

    test('今日〜3日以内の未割り当て件数（urgent）を集計する', () async {
      const h = Household(id: 1, name: '山田家');
      final tasks = [
        _openTask(id: 1, targetDate: _today(), assigneeUserId: null), // urgent
        _openTask(
          id: 2,
          targetDate: _daysFromNow(3),
          assigneeUserId: null,
        ), // urgent
        _openTask(
          id: 3,
          targetDate: _daysFromNow(4),
          assigneeUserId: null,
        ), // not urgent
      ];
      when(
        mockRepo.loadAll(1),
      ).thenAnswer((_) async => _makeRawData(openTasks: tasks));

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );
      final state = await container.read(homeNotifierProvider.future);

      expect(state.unassignedSummary.urgentCount, 2);
    });
  });

  group('集計: DailyOverview (おうちの様子)', () {
    test('13日分のDailyOverviewが生成される', () async {
      const h = Household(id: 1, name: '山田家');
      when(mockRepo.loadAll(1)).thenAnswer((_) async => _makeRawData());

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );
      final state = await container.read(homeNotifierProvider.future);

      expect(state.householdOverview, hasLength(13));
    });

    test('タスクが正しい日に集計される', () async {
      const h = Household(id: 1, name: '山田家');
      final tasks = [
        _openTask(id: 1, targetDate: _today(), assigneeUserId: 10),
        _openTask(id: 2, targetDate: _today(), assigneeUserId: null),
      ];
      when(
        mockRepo.loadAll(1),
      ).thenAnswer((_) async => _makeRawData(openTasks: tasks));

      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: h,
      );
      final state = await container.read(homeNotifierProvider.future);

      final today = DateTime.now();
      final todayOverview = state.householdOverview.firstWhere(
        (o) =>
            o.date.year == today.year &&
            o.date.month == today.month &&
            o.date.day == today.day,
      );
      expect(todayOverview.countsByAssignee[10], 1);
      expect(todayOverview.countsByAssignee[null], 1);
    });
  });
}

class _FakeHouseholdNotifier extends HouseholdNotifier {
  _FakeHouseholdNotifier(this._state);
  final HouseholdState _state;

  @override
  Future<HouseholdState> build() async => _state;

  @override
  Future<void> select(Household household) async {}
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._authState);
  final AuthState _authState;

  @override
  Future<AuthState> build() async => _authState;
}
