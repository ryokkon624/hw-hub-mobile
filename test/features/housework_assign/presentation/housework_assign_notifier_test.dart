import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/auth/auth_notifier.dart';
import 'package:hw_hub_mobile/core/auth/auth_state.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/models/auth_user.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/features/housework_assign/data/housework_assign_repository.dart';
import 'package:hw_hub_mobile/features/housework_assign/housework_assign_providers.dart';
import 'package:hw_hub_mobile/features/housework_assign/presentation/housework_assign_notifier.dart';
import 'package:hw_hub_mobile/features/housework_assign/presentation/housework_assign_state.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../housework_assign_mocks.mocks.dart';

String _dateStr(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _today() => _dateStr(DateTime.now());
String _daysFromNow(int days) =>
    _dateStr(DateTime.now().add(Duration(days: days)));

HouseworkTaskDto _task({
  int id = 1,
  String? targetDate,
  int? assigneeUserId,
  String? assigneeNickname,
}) => HouseworkTaskDto(
  houseworkTaskId: id,
  householdId: 1,
  houseworkId: id,
  houseworkName: 'タスク$id',
  targetDate: targetDate ?? _today(),
  assigneeUserId: assigneeUserId,
  assigneeNickname: assigneeNickname,
  status: '0',
);

HouseholdMemberDto _member({int userId = 10, String displayName = 'テスト'}) =>
    HouseholdMemberDto(
      householdId: 1,
      userId: userId,
      displayName: displayName,
      status: 'ACTIVE',
      role: 'OWNER',
    );

ProviderContainer _makeContainer({
  required MockHouseworkAssignRepository mockRepo,
  Household? selectedHousehold = const Household(id: 1, name: '山田家'),
  int currentUserId = 10,
  String currentDisplayName = 'テスト太郎',
}) {
  SharedPreferences.setMockInitialValues({});

  final testUser = AuthUser(
    userId: currentUserId,
    email: 'test@example.com',
    displayName: currentDisplayName,
  );

  final container = ProviderContainer(
    overrides: [
      houseworkAssignRepositoryProvider.overrideWithValue(mockRepo),
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
  late MockHouseworkAssignRepository mockRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepo = MockHouseworkAssignRepository();
  });

  group('HouseworkAssignNotifier.build()', () {
    test('世帯未所属時: 空の状態を返す', () async {
      final container = _makeContainer(
        mockRepo: mockRepo,
        selectedHousehold: null,
      );

      final state = await container.read(
        houseworkAssignNotifierProvider.future,
      );
      expect(state.tasks, isEmpty);
      expect(state.members, isEmpty);
      verifyNever(mockRepo.fetchTasks(householdId: anyNamed('householdId')));
    });

    test('世帯所属時: タスクとメンバーを取得する', () async {
      when(mockRepo.fetchTasks(householdId: 1)).thenAnswer(
        (_) async => [
          _task(id: 1, assigneeUserId: 10),
          _task(id: 2, assigneeUserId: 20),
        ],
      );
      when(
        mockRepo.fetchMembers(householdId: 1),
      ).thenAnswer((_) async => [_member(userId: 10), _member(userId: 20)]);

      final container = _makeContainer(mockRepo: mockRepo);
      final state = await container.read(
        houseworkAssignNotifierProvider.future,
      );

      expect(state.tasks, hasLength(2));
      expect(state.members, hasLength(2));
      expect(state.filter, AssignFilter.all);
      expect(state.mode, AssignMode.list);
      // memberTaskCounts が事前計算されていることを確認
      expect(state.memberTaskCounts[10], 1);
      expect(state.memberTaskCounts[20], 1);
    });

    test('API失敗時: AsyncErrorになる', () async {
      when(
        mockRepo.fetchTasks(householdId: 1),
      ).thenThrow(Exception('Network error'));
      when(mockRepo.fetchMembers(householdId: 1)).thenAnswer((_) async => []);

      final container = _makeContainer(mockRepo: mockRepo);
      container.listen(houseworkAssignNotifierProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final result = container.read(houseworkAssignNotifierProvider);
      expect(result.hasError, isTrue);
    });
  });

  group('HouseworkAssignNotifier.setFilter()', () {
    test('filterを変更するとstateに反映される', () async {
      when(mockRepo.fetchTasks(householdId: 1)).thenAnswer((_) async => []);
      when(mockRepo.fetchMembers(householdId: 1)).thenAnswer((_) async => []);

      final container = _makeContainer(mockRepo: mockRepo);
      await container.read(houseworkAssignNotifierProvider.future);

      container
          .read(houseworkAssignNotifierProvider.notifier)
          .setFilter(AssignFilter.unassignedOnly);

      final state = container.read(houseworkAssignNotifierProvider).value!;
      expect(state.filter, AssignFilter.unassignedOnly);
    });
  });

  group('HouseworkAssignNotifier.assignToMe()', () {
    test('成功時: 対象タスクのassigneeUserIdが自分に更新される', () async {
      when(
        mockRepo.fetchTasks(householdId: 1),
      ).thenAnswer((_) async => [_task(id: 1, assigneeUserId: null)]);
      when(
        mockRepo.fetchMembers(householdId: 1),
      ).thenAnswer((_) async => [_member(userId: 10)]);
      when(
        mockRepo.updateAssignee(taskId: 1, assigneeUserId: 10),
      ).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo: mockRepo);
      await container.read(houseworkAssignNotifierProvider.future);

      final result = await container
          .read(houseworkAssignNotifierProvider.notifier)
          .assignToMe(taskId: 1);

      expect(result, isTrue);
      final state = container.read(houseworkAssignNotifierProvider).value!;
      final task = state.tasks.firstWhere((t) => t.houseworkTaskId == 1);
      expect(task.assigneeUserId, 10);
      // memberTaskCounts が割り当て後に更新されていることを確認
      expect(state.memberTaskCounts[10], 1);
    });

    test('API失敗時: errorMessageがセットされtrueを返さない', () async {
      when(
        mockRepo.fetchTasks(householdId: 1),
      ).thenAnswer((_) async => [_task(id: 1)]);
      when(mockRepo.fetchMembers(householdId: 1)).thenAnswer((_) async => []);
      when(
        mockRepo.updateAssignee(taskId: 1, assigneeUserId: 10),
      ).thenThrow(Exception('Error'));

      final container = _makeContainer(mockRepo: mockRepo);
      await container.read(houseworkAssignNotifierProvider.future);

      final result = await container
          .read(houseworkAssignNotifierProvider.notifier)
          .assignToMe(taskId: 1);

      expect(result, isFalse);
      final state = container.read(houseworkAssignNotifierProvider).value!;
      expect(state.errorMessage, isNotNull);
    });
  });

  group('HouseworkAssignNotifier.assignToMember()', () {
    test('成功時: 対象タスクのassigneeUserIdが指定メンバーに更新される', () async {
      when(
        mockRepo.fetchTasks(householdId: 1),
      ).thenAnswer((_) async => [_task(id: 1, assigneeUserId: null)]);
      when(
        mockRepo.fetchMembers(householdId: 1),
      ).thenAnswer((_) async => [_member(userId: 20)]);
      when(
        mockRepo.updateAssignee(taskId: 1, assigneeUserId: 20),
      ).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo: mockRepo);
      await container.read(houseworkAssignNotifierProvider.future);

      final result = await container
          .read(houseworkAssignNotifierProvider.notifier)
          .assignToMember(
            taskId: 1,
            assigneeUserId: 20,
            assigneeNickname: 'メンバー',
          );

      expect(result, isTrue);
      final state = container.read(houseworkAssignNotifierProvider).value!;
      final task = state.tasks.firstWhere((t) => t.houseworkTaskId == 1);
      expect(task.assigneeUserId, 20);
    });
  });

  group('HouseworkAssignNotifier.bulkSkipPastUnassigned()', () {
    test('成功時: 過去の未割当タスクがリストから消える', () async {
      final pastUnassigned = _task(
        id: 1,
        targetDate: _daysFromNow(-1),
        assigneeUserId: null,
      );
      final futureTask = _task(
        id: 2,
        targetDate: _today(),
        assigneeUserId: null,
      );
      when(
        mockRepo.fetchTasks(householdId: 1),
      ).thenAnswer((_) async => [pastUnassigned, futureTask]);
      when(mockRepo.fetchMembers(householdId: 1)).thenAnswer((_) async => []);
      when(
        mockRepo.bulkSkipPastUnassigned(taskIds: [1]),
      ).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo: mockRepo);
      await container.read(houseworkAssignNotifierProvider.future);

      await container
          .read(houseworkAssignNotifierProvider.notifier)
          .bulkSkipPastUnassigned();

      final state = container.read(houseworkAssignNotifierProvider).value!;
      expect(state.tasks.any((t) => t.houseworkTaskId == 1), isFalse);
      expect(state.tasks.any((t) => t.houseworkTaskId == 2), isTrue);
    });

    test('失敗時: errorMessageがセットされる', () async {
      final pastUnassigned = _task(
        id: 1,
        targetDate: _daysFromNow(-1),
        assigneeUserId: null,
      );
      when(
        mockRepo.fetchTasks(householdId: 1),
      ).thenAnswer((_) async => [pastUnassigned]);
      when(mockRepo.fetchMembers(householdId: 1)).thenAnswer((_) async => []);
      when(
        mockRepo.bulkSkipPastUnassigned(taskIds: [1]),
      ).thenThrow(Exception('Error'));

      final container = _makeContainer(mockRepo: mockRepo);
      await container.read(houseworkAssignNotifierProvider.future);

      await container
          .read(houseworkAssignNotifierProvider.notifier)
          .bulkSkipPastUnassigned();

      final state = container.read(houseworkAssignNotifierProvider).value!;
      expect(state.tasks, hasLength(1));
      expect(state.errorMessage, isNotNull);
    });
  });

  group('HouseworkAssignNotifier スワイプモード', () {
    test('startSwipeMode: modeがswipeになりswipeIndexが0になる', () async {
      when(
        mockRepo.fetchTasks(householdId: 1),
      ).thenAnswer((_) async => [_task(id: 1, assigneeUserId: null)]);
      when(mockRepo.fetchMembers(householdId: 1)).thenAnswer((_) async => []);

      final container = _makeContainer(mockRepo: mockRepo);
      await container.read(houseworkAssignNotifierProvider.future);

      container
          .read(houseworkAssignNotifierProvider.notifier)
          .startSwipeMode(SwipeTarget.unassigned);

      final state = container.read(houseworkAssignNotifierProvider).value!;
      expect(state.mode, AssignMode.swipe);
      expect(state.swipeTarget, SwipeTarget.unassigned);
      expect(state.swipeIndex, 0);
    });

    test('exitSwipeMode: modeがlistに戻る', () async {
      when(
        mockRepo.fetchTasks(householdId: 1),
      ).thenAnswer((_) async => [_task(id: 1, assigneeUserId: null)]);
      when(mockRepo.fetchMembers(householdId: 1)).thenAnswer((_) async => []);

      final container = _makeContainer(mockRepo: mockRepo);
      await container.read(houseworkAssignNotifierProvider.future);

      container
          .read(houseworkAssignNotifierProvider.notifier)
          .startSwipeMode(SwipeTarget.unassigned);
      container.read(houseworkAssignNotifierProvider.notifier).exitSwipeMode();

      final state = container.read(houseworkAssignNotifierProvider).value!;
      expect(state.mode, AssignMode.list);
    });

    test('swipeNext: swipeIndexが進む', () async {
      when(mockRepo.fetchTasks(householdId: 1)).thenAnswer(
        (_) async => [
          _task(id: 1, assigneeUserId: null),
          _task(id: 2, assigneeUserId: null),
        ],
      );
      when(mockRepo.fetchMembers(householdId: 1)).thenAnswer((_) async => []);

      final container = _makeContainer(mockRepo: mockRepo);
      await container.read(houseworkAssignNotifierProvider.future);

      container
          .read(houseworkAssignNotifierProvider.notifier)
          .startSwipeMode(SwipeTarget.unassigned);
      await container
          .read(houseworkAssignNotifierProvider.notifier)
          .swipeNext();

      final state = container.read(houseworkAssignNotifierProvider).value!;
      expect(state.swipeIndex, 1);
    });

    test('swipeAssignToMe: 自分に割り当てて次のカードに進む（2枚中1枚目）', () async {
      // 未割当が2枚ある状態でindex=0を割り当てると index=1 に進む
      when(mockRepo.fetchTasks(householdId: 1)).thenAnswer(
        (_) async => [
          _task(id: 1, assigneeUserId: null),
          _task(id: 2, assigneeUserId: null),
        ],
      );
      when(mockRepo.fetchMembers(householdId: 1)).thenAnswer((_) async => []);
      when(
        mockRepo.updateAssignee(taskId: 1, assigneeUserId: 10),
      ).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo: mockRepo);
      await container.read(houseworkAssignNotifierProvider.future);

      container
          .read(houseworkAssignNotifierProvider.notifier)
          .startSwipeMode(SwipeTarget.unassigned);
      await container
          .read(houseworkAssignNotifierProvider.notifier)
          .swipeAssignToMe();

      final state = container.read(houseworkAssignNotifierProvider).value!;
      // id=1 が自分に割り当てられた後、残り未割当(id=2)が1枚あるのでスワイプモード継続
      // swipeIndex が 1 に進む（未割当リストは再計算されるため id=2 が対象）
      expect(state.mode, AssignMode.swipe);
      expect(state.swipeIndex, 1);
    });

    test('swipeAssignToMe: 最後の1枚を割り当てるとリストモードに戻る', () async {
      // 未割当が1枚の状態で割り当てると全消化となりリストモードへ戻る
      // _reloadAndExitSwipe が呼ばれるため fetchTasks を再度モック
      when(
        mockRepo.fetchTasks(householdId: 1),
      ).thenAnswer((_) async => [_task(id: 1, assigneeUserId: null)]);
      when(mockRepo.fetchMembers(householdId: 1)).thenAnswer((_) async => []);
      when(
        mockRepo.updateAssignee(taskId: 1, assigneeUserId: 10),
      ).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo: mockRepo);
      await container.read(houseworkAssignNotifierProvider.future);

      container
          .read(houseworkAssignNotifierProvider.notifier)
          .startSwipeMode(SwipeTarget.unassigned);

      // _reloadAndExitSwipe 内で _load が呼ばれるため再度stubが必要
      when(
        mockRepo.fetchTasks(householdId: 1),
      ).thenAnswer((_) async => [_task(id: 1, assigneeUserId: 10)]);

      await container
          .read(houseworkAssignNotifierProvider.notifier)
          .swipeAssignToMe();

      final state = container.read(houseworkAssignNotifierProvider).value!;
      // 全カード消化でリストモードに戻る
      expect(state.mode, AssignMode.list);
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
