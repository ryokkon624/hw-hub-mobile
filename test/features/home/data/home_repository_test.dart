import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/home/data/home_repository.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/mocks.mocks.dart';

/// テスト用メンバーJSON
Map<String, dynamic> _memberJson(int userId, String name) => {
  'householdId': 1,
  'userId': userId,
  'displayName': name,
  'iconUrl': null,
  'nickname': null,
  'status': 'active',
  'role': 'member',
};

/// テスト用タスクJSON
Map<String, dynamic> _taskJson(int id, String status, String targetDate) => {
  'houseworkTaskId': id,
  'householdId': 1,
  'houseworkId': 1,
  'houseworkName': '掃除',
  'categoryCode': null,
  'targetDate': targetDate,
  'assigneeUserId': null,
  'assigneeNickname': null,
  'status': status,
  'assignReasonType': null,
  'doneAt': null,
  'skippedReason': null,
};

/// テスト用買い物JSON
Map<String, dynamic> _shoppingJson(int id, String name) => {
  'shoppingItemId': id,
  'householdId': 1,
  'name': name,
  'memo': null,
  'storeType': 'supermarket',
  'status': '0',
  'favorite': null,
  'purchasedAt': null,
  'createdAt': '2026-05-10T10:00:00',
  'hasImage': false,
};

RequestOptions _req(String path) => RequestOptions(path: path);

void main() {
  late MockDio mockDio;
  late HomeRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = HomeRepositoryImpl(mockDio);
  });

  group('HomeRepository.loadAll()', () {
    void stubAllApis(int householdId) {
      when(
        mockDio.get<dynamic>('/api/households/$householdId/members'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/households/$householdId/members'),
          statusCode: 200,
          data: [_memberJson(10, 'ママ'), _memberJson(11, 'パパ')],
        ),
      );
      when(
        mockDio.get<dynamic>(
          '/api/housework-tasks',
          queryParameters: {'householdId': householdId, 'status': '0'},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/housework-tasks'),
          statusCode: 200,
          data: [_taskJson(100, '0', '2026-05-11')],
        ),
      );
      when(
        mockDio.get<dynamic>(
          '/api/housework-tasks',
          queryParameters: {'householdId': householdId, 'status': '1'},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/housework-tasks'),
          statusCode: 200,
          data: [_taskJson(101, '1', '2026-05-10')],
        ),
      );
      when(
        mockDio.get<dynamic>('/api/households/$householdId/shopping-items'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/households/$householdId/shopping-items'),
          statusCode: 200,
          data: {
            'items': [_shoppingJson(200, 'ミルク')],
          },
        ),
      );
    }

    test('成功時: 全APIのデータをHomeRawDataにまとめて返す', () async {
      stubAllApis(1);

      final result = await repo.loadAll(1);

      expect(result.members, hasLength(2));
      expect(result.members.first.displayName, 'ママ');
      expect(result.openTasks, hasLength(1));
      expect(result.openTasks.first.status, '0');
      expect(result.doneTasks, hasLength(1));
      expect(result.doneTasks.first.status, '1');
      expect(result.shoppingItems, hasLength(1));
      expect(result.shoppingItems.first.name, 'ミルク');
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(mockDio.get<dynamic>('/api/households/1/members')).thenThrow(
        DioException(
          requestOptions: _req('/api/households/1/members'),
          type: DioExceptionType.connectionError,
          message: 'Connection refused',
        ),
      );

      expect(() => repo.loadAll(1), throwsA(isA<NetworkException>()));
    });

    test('DioExceptionのerrorがAppExceptionの場合: そのままrethrowする', () async {
      when(mockDio.get<dynamic>('/api/households/1/members')).thenThrow(
        DioException(
          requestOptions: _req('/api/households/1/members'),
          error: const UnauthorizedException('認証失敗'),
        ),
      );

      expect(() => repo.loadAll(1), throwsA(isA<UnauthorizedException>()));
    });
  });
}
