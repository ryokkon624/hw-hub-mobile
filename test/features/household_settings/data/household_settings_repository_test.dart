import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/household_settings/data/household_settings_repository.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/mocks.mocks.dart';

RequestOptions _req(String path) => RequestOptions(path: path);

Map<String, dynamic> _memberJson({
  int userId = 10,
  String status = 'ACTIVE',
  String role = 'OWNER',
}) => {
  'householdId': 1,
  'userId': userId,
  'displayName': 'テストユーザー$userId',
  'iconUrl': null,
  'nickname': null,
  'status': status,
  'role': role,
};

Map<String, dynamic> _invitationJson({
  String token = 'test-token',
  String status = '0',
}) => {
  'householdId': 1,
  'invitationToken': token,
  'invitedEmail': 'invited@example.com',
  'status': status,
  'expiresAt': '2026-06-01T00:00:00',
  'acceptedUserId': null,
  'acceptedUserName': null,
  'inviterUserId': 1,
  'inviterDisplayName': '招待者',
  'createdAt': '2026-05-01T00:00:00',
};

void main() {
  late MockDio mockDio;
  late HouseholdSettingsRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = HouseholdSettingsRepositoryImpl(mockDio);
  });

  // ==================================
  // fetchMembers
  // ==================================

  group('fetchMembers()', () {
    test('成功時: メンバーリストを返す', () async {
      when(mockDio.get<List<dynamic>>('/api/households/1/members')).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: _req('/api/households/1/members'),
          statusCode: 200,
          data: [_memberJson(userId: 10), _memberJson(userId: 20)],
        ),
      );

      final result = await repo.fetchMembers(householdId: 1);
      expect(result, hasLength(2));
      expect(result.first.userId, 10);
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(mockDio.get<List<dynamic>>('/api/households/1/members')).thenThrow(
        DioException(
          requestOptions: _req('/api/households/1/members'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.fetchMembers(householdId: 1),
        throwsA(isA<NetworkException>()),
      );
    });

    test('DioExceptionのerrorがAppExceptionの場合: そのままrethrowする', () async {
      when(mockDio.get<List<dynamic>>('/api/households/1/members')).thenThrow(
        DioException(
          requestOptions: _req('/api/households/1/members'),
          error: const UnauthorizedException('認証失敗'),
        ),
      );

      expect(
        () => repo.fetchMembers(householdId: 1),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  // ==================================
  // fetchInvitations
  // ==================================

  group('fetchInvitations()', () {
    test('成功時: 招待リストを返す', () async {
      when(
        mockDio.get<List<dynamic>>('/api/households/1/invitations'),
      ).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: _req('/api/households/1/invitations'),
          statusCode: 200,
          data: [
            _invitationJson(token: 'token-1'),
            _invitationJson(token: 'token-2', status: '1'),
          ],
        ),
      );

      final result = await repo.fetchInvitations(householdId: 1);
      expect(result, hasLength(2));
      expect(result.first.invitationToken, 'token-1');
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.get<List<dynamic>>('/api/households/1/invitations'),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/households/1/invitations'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.fetchInvitations(householdId: 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ==================================
  // createInvitation
  // ==================================

  group('createInvitation()', () {
    test('成功時: 作成された招待DTOを返す', () async {
      when(
        mockDio.post<Map<String, dynamic>>(
          '/api/households/1/invitations',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: _req('/api/households/1/invitations'),
          statusCode: 200,
          data: _invitationJson(),
        ),
      );

      final result = await repo.createInvitation(
        householdId: 1,
        invitedEmail: 'invited@example.com',
      );
      expect(result.invitationToken, 'test-token');
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.post<Map<String, dynamic>>(
          '/api/households/1/invitations',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/households/1/invitations'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.createInvitation(
          householdId: 1,
          invitedEmail: 'invited@example.com',
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ==================================
  // revokeInvitation
  // ==================================

  group('revokeInvitation()', () {
    test('成功時: 例外なく完了する', () async {
      when(
        mockDio.post<void>('/api/household-invitations/test-token/revoke'),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: _req('/api/household-invitations/test-token/revoke'),
          statusCode: 204,
        ),
      );

      await expectLater(repo.revokeInvitation(token: 'test-token'), completes);
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.post<void>('/api/household-invitations/test-token/revoke'),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/household-invitations/test-token/revoke'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.revokeInvitation(token: 'test-token'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ==================================
  // updateHouseholdName
  // ==================================

  group('updateHouseholdName()', () {
    test('成功時: 例外なく完了する', () async {
      when(
        mockDio.put<dynamic>('/api/households/1', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/households/1'),
          statusCode: 204,
        ),
      );

      await expectLater(
        repo.updateHouseholdName(householdId: 1, name: '新しい名前'),
        completes,
      );
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.put<dynamic>('/api/households/1', data: anyNamed('data')),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/households/1'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.updateHouseholdName(householdId: 1, name: '新しい名前'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ==================================
  // updateNickname
  // ==================================

  group('updateNickname()', () {
    test('成功時: 例外なく完了する', () async {
      when(
        mockDio.put<dynamic>(
          '/api/households/1/members/me/nickname',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/households/1/members/me/nickname'),
          statusCode: 204,
        ),
      );

      await expectLater(
        repo.updateNickname(householdId: 1, nickname: 'お父さん'),
        completes,
      );
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.put<dynamic>(
          '/api/households/1/members/me/nickname',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/households/1/members/me/nickname'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.updateNickname(householdId: 1, nickname: 'お父さん'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ==================================
  // removeMember
  // ==================================

  group('removeMember()', () {
    test('成功時: 例外なく完了する', () async {
      when(mockDio.delete<dynamic>('/api/households/1/members/20')).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/households/1/members/20'),
          statusCode: 204,
        ),
      );

      await expectLater(
        repo.removeMember(householdId: 1, userId: 20),
        completes,
      );
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(mockDio.delete<dynamic>('/api/households/1/members/20')).thenThrow(
        DioException(
          requestOptions: _req('/api/households/1/members/20'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.removeMember(householdId: 1, userId: 20),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ==================================
  // transferOwner
  // ==================================

  group('transferOwner()', () {
    test('成功時: 例外なく完了する', () async {
      when(
        mockDio.put<dynamic>(
          '/api/households/1/transfer-owner',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/households/1/transfer-owner'),
          statusCode: 200,
        ),
      );

      await expectLater(
        repo.transferOwner(householdId: 1, newOwnerUserId: 20),
        completes,
      );
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.put<dynamic>(
          '/api/households/1/transfer-owner',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/households/1/transfer-owner'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.transferOwner(householdId: 1, newOwnerUserId: 20),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ==================================
  // leaveHousehold
  // ==================================

  group('leaveHousehold()', () {
    test('成功時: 例外なく完了する', () async {
      when(mockDio.delete<dynamic>('/api/households/1/members/me')).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/households/1/members/me'),
          statusCode: 204,
        ),
      );

      await expectLater(repo.leaveHousehold(householdId: 1), completes);
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(mockDio.delete<dynamic>('/api/households/1/members/me')).thenThrow(
        DioException(
          requestOptions: _req('/api/households/1/members/me'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.leaveHousehold(householdId: 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ==================================
  // createHousehold
  // ==================================

  group('createHousehold()', () {
    test('成功時: 作成された世帯DTOを返す', () async {
      when(
        mockDio.post<Map<String, dynamic>>(
          '/api/households',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: _req('/api/households'),
          statusCode: 200,
          data: {'householdId': 99, 'name': '新しいおうち', 'ownerUserId': 1},
        ),
      );

      final result = await repo.createHousehold(name: '新しいおうち');
      expect(result.householdId, 99);
      expect(result.name, '新しいおうち');
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.post<Map<String, dynamic>>(
          '/api/households',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/households'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.createHousehold(name: '新しいおうち'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ==================================
  // deleteHousehold
  // ==================================

  group('deleteHousehold()', () {
    test('成功時: 例外なく完了する', () async {
      when(mockDio.delete<dynamic>('/api/households/1')).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/households/1'),
          statusCode: 204,
        ),
      );

      await expectLater(repo.deleteHousehold(householdId: 1), completes);
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(mockDio.delete<dynamic>('/api/households/1')).thenThrow(
        DioException(
          requestOptions: _req('/api/households/1'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.deleteHousehold(householdId: 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ==================================
  // fetchHouseworkCount
  // ==================================

  group('fetchHouseworkCount()', () {
    test('成功時: 家事件数を返す', () async {
      when(
        mockDio.get<List<dynamic>>(
          '/api/houseworks',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: _req('/api/houseworks'),
          statusCode: 200,
          data: [
            {'houseworkId': 1},
            {'houseworkId': 2},
          ],
        ),
      );

      final count = await repo.fetchHouseworkCount(householdId: 1);
      expect(count, 2);
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.get<List<dynamic>>(
          '/api/houseworks',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/houseworks'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.fetchHouseworkCount(householdId: 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ==================================
  // fetchShoppingCount
  // ==================================

  group('fetchShoppingCount()', () {
    test('成功時: 買い物件数を返す', () async {
      when(
        mockDio.get<Map<String, dynamic>>(
          '/api/households/1/shopping-items',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: _req('/api/households/1/shopping-items'),
          statusCode: 200,
          data: {
            'items': [
              {'shoppingItemId': 1},
              {'shoppingItemId': 2},
              {'shoppingItemId': 3},
            ],
          },
        ),
      );

      final count = await repo.fetchShoppingCount(householdId: 1);
      expect(count, 3);
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.get<Map<String, dynamic>>(
          '/api/households/1/shopping-items',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/households/1/shopping-items'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.fetchShoppingCount(householdId: 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
