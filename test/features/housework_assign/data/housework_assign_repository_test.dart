import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/housework_assign/data/housework_assign_repository.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/mocks.mocks.dart';

Map<String, dynamic> _taskJson({int id = 1, int? assigneeUserId}) => {
  'houseworkTaskId': id,
  'householdId': 1,
  'houseworkId': 1,
  'houseworkName': '掃除',
  'categoryCode': null,
  'targetDate': '2026-05-20',
  'assigneeUserId': assigneeUserId,
  'assigneeNickname': null,
  'status': '0',
  'assignReasonType': null,
  'doneAt': null,
  'skippedReason': null,
};

Map<String, dynamic> _memberJson({int userId = 10}) => {
  'householdId': 1,
  'userId': userId,
  'displayName': 'テストユーザー$userId',
  'iconUrl': null,
  'nickname': null,
  'status': 'ACTIVE',
  'role': 'OWNER',
};

RequestOptions _req(String path) => RequestOptions(path: path);

void main() {
  late MockDio mockDio;
  late HouseworkAssignRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = HouseworkAssignRepositoryImpl(mockDio);
  });

  group('HouseworkAssignRepository.fetchTasks()', () {
    test('成功時: タスクリストを返す（フラット配列）', () async {
      when(
        mockDio.get<dynamic>(
          '/api/housework-tasks',
          queryParameters: {'householdId': 1, 'status': '0'},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/housework-tasks'),
          statusCode: 200,
          data: [_taskJson(id: 1), _taskJson(id: 2)],
        ),
      );

      final result = await repo.fetchTasks(householdId: 1);
      expect(result, hasLength(2));
      expect(result.first.houseworkTaskId, 1);
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.get<dynamic>(
          '/api/housework-tasks',
          queryParameters: {'householdId': 1, 'status': '0'},
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/housework-tasks'),
          type: DioExceptionType.connectionError,
          message: 'Connection refused',
        ),
      );

      expect(
        () => repo.fetchTasks(householdId: 1),
        throwsA(isA<NetworkException>()),
      );
    });

    test('DioExceptionのerrorがAppExceptionの場合: そのままrethrowする', () async {
      when(
        mockDio.get<dynamic>(
          '/api/housework-tasks',
          queryParameters: {'householdId': 1, 'status': '0'},
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/housework-tasks'),
          error: const UnauthorizedException('認証失敗'),
        ),
      );

      expect(
        () => repo.fetchTasks(householdId: 1),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('HouseworkAssignRepository.fetchMembers()', () {
    test('成功時: メンバーリストを返す（フラット配列）', () async {
      when(mockDio.get<dynamic>('/api/households/1/members')).thenAnswer(
        (_) async => Response(
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
      when(mockDio.get<dynamic>('/api/households/1/members')).thenThrow(
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
  });

  group('HouseworkAssignRepository.updateAssignee()', () {
    test('成功時: 例外なく完了する', () async {
      when(
        mockDio.patch<dynamic>(
          '/api/housework-tasks/1/assign',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/housework-tasks/1/assign'),
          statusCode: 204,
          data: null,
        ),
      );

      await expectLater(
        repo.updateAssignee(taskId: 1, assigneeUserId: 10),
        completes,
      );
    });

    test('assigneeUserId=null（未割当に戻す）でも成功する', () async {
      when(
        mockDio.patch<dynamic>(
          '/api/housework-tasks/1/assign',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/housework-tasks/1/assign'),
          statusCode: 204,
          data: null,
        ),
      );

      await expectLater(
        repo.updateAssignee(taskId: 1, assigneeUserId: null),
        completes,
      );
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.patch<dynamic>(
          '/api/housework-tasks/1/assign',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/housework-tasks/1/assign'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.updateAssignee(taskId: 1, assigneeUserId: 10),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('HouseworkAssignRepository.bulkSkipPastUnassigned()', () {
    test('成功時: 例外なく完了する', () async {
      when(
        mockDio.patch<dynamic>(
          '/api/housework-tasks/bulk-status',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/housework-tasks/bulk-status'),
          statusCode: 204,
          data: null,
        ),
      );

      await expectLater(
        repo.bulkSkipPastUnassigned(taskIds: [1, 2]),
        completes,
      );
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.patch<dynamic>(
          '/api/housework-tasks/bulk-status',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/housework-tasks/bulk-status'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.bulkSkipPastUnassigned(taskIds: [1, 2]),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
