import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/features/household_settings/data/household_settings_repository.dart';
import 'package:hw_hub_mobile/features/household_settings/household_settings_providers.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mocks.mocks.dart';

/// テスト用の /api/users/me/households レスポンスJSON
List<Map<String, dynamic>> _householdsJson(List<Household> households) {
  return households
      .map((h) => {'householdId': h.id, 'name': h.name, 'ownerUserId': 1})
      .toList();
}

/// Mockリポジトリ
class _MockHouseholdSettingsRepository implements HouseholdSettingsRepository {
  @override
  Future<int> fetchHouseworkCount({required int householdId}) async => 3;

  @override
  Future<int> fetchShoppingCount({required int householdId}) async => 5;

  @override
  Future<List<HouseholdSettingsMemberDto>> fetchMembers({
    required int householdId,
  }) async => [];

  @override
  Future<List<HouseholdInvitationDto>> fetchInvitations({
    required int householdId,
  }) async => [];

  @override
  Future<HouseholdInvitationDto> createInvitation({
    required int householdId,
    required String invitedEmail,
  }) async => throw UnimplementedError();

  @override
  Future<void> revokeInvitation({required String token}) async {}

  @override
  Future<void> updateHouseholdName({
    required int householdId,
    required String name,
  }) async {}

  @override
  Future<void> updateNickname({
    required int householdId,
    required String nickname,
  }) async {}

  @override
  Future<void> removeMember({
    required int householdId,
    required int userId,
  }) async {}

  @override
  Future<void> transferOwner({
    required int householdId,
    required int newOwnerUserId,
  }) async {}

  @override
  Future<void> leaveHousehold({required int householdId}) async {}

  @override
  Future<HouseholdSettingsDto> createHousehold({required String name}) async =>
      const HouseholdSettingsDto(
        householdId: 99,
        name: '新しいおうち',
        ownerUserId: 1,
      );

  @override
  Future<void> deleteHousehold({required int householdId}) async {}
}

ProviderContainer _makeContainer(Dio dio) {
  final container = ProviderContainer(
    overrides: [
      dioProvider.overrideWithValue(dio),
      householdSettingsRepositoryProvider.overrideWithValue(
        _MockHouseholdSettingsRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late MockDio mockDio;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockDio = MockDio();
  });

  void setupHouseholdsApi(MockDio dio, List<Household> households) {
    when(dio.get<List<dynamic>>('/api/users/me/households')).thenAnswer(
      (_) async => Response<List<dynamic>>(
        requestOptions: RequestOptions(path: '/api/users/me/households'),
        statusCode: 200,
        data: _householdsJson(households),
      ),
    );
  }

  group('HouseholdNotifier.refresh()', () {
    test('refresh()で世帯リストが再取得される', () async {
      setupHouseholdsApi(mockDio, [const Household(id: 1, name: '山田家')]);

      final container = _makeContainer(mockDio);
      await container.read(householdNotifierProvider.future);

      // 2回目の呼び出しで新しいデータを返す
      when(mockDio.get<List<dynamic>>('/api/users/me/households')).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/api/users/me/households'),
          statusCode: 200,
          data: _householdsJson([
            const Household(id: 1, name: '山田家'),
            const Household(id: 2, name: '新しいおうち'),
          ]),
        ),
      );

      await container.read(householdNotifierProvider.notifier).refresh();
      final state = container.read(householdNotifierProvider).value!;
      expect(state.households, hasLength(2));
    });
  });

  group('HouseholdNotifier.addHousehold()', () {
    test('addHousehold()で世帯が追加されてリストが更新される', () async {
      setupHouseholdsApi(mockDio, [const Household(id: 1, name: '山田家')]);

      final container = _makeContainer(mockDio);
      await container.read(householdNotifierProvider.future);

      // 再取得時に新しいリストを返す
      when(mockDio.get<List<dynamic>>('/api/users/me/households')).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/api/users/me/households'),
          statusCode: 200,
          data: _householdsJson([
            const Household(id: 1, name: '山田家'),
            const Household(id: 99, name: '新しいおうち'),
          ]),
        ),
      );

      await container
          .read(householdNotifierProvider.notifier)
          .addHousehold(name: '新しいおうち');

      final state = container.read(householdNotifierProvider).value!;
      expect(state.households, hasLength(2));
    });
  });
}
