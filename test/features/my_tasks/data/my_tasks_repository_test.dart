import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/my_tasks/data/my_tasks_repository.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/mocks.mocks.dart';

Map<String, dynamic> _taskJson({
  int id = 1,
  String status = '0',
  String targetDate = '2026-05-12',
  int? assigneeUserId = 10,
}) => {
  'houseworkTaskId': id,
  'householdId': 1,
  'houseworkId': 1,
  'houseworkName': '掃除',
  'categoryCode': null,
  'targetDate': targetDate,
  'assigneeUserId': assigneeUserId,
  'assigneeNickname': null,
  'status': status,
  'assignReasonType': null,
  'doneAt': null,
  'skippedReason': null,
};

RequestOptions _req(String path) => RequestOptions(path: path);

void main() {
  late MockDio mockDio;
  late MyTasksRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = MyTasksRepositoryImpl(mockDio);
  });

  group('MyTasksRepository.fetchOpenTasks()', () {
    test('成功時: タスクリストを返す', () async {
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

      final result = await repo.fetchOpenTasks(householdId: 1);
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
        () => repo.fetchOpenTasks(householdId: 1),
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
        () => repo.fetchOpenTasks(householdId: 1),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('MyTasksRepository.updateTaskStatus()', () {
    test('成功時: 例外なく完了する', () async {
      when(
        mockDio.patch<dynamic>(
          '/api/housework-tasks/1/status',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/housework-tasks/1/status'),
          statusCode: 204,
          data: null,
        ),
      );

      await expectLater(
        repo.updateTaskStatus(taskId: 1, status: '1'),
        completes,
      );
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.patch<dynamic>(
          '/api/housework-tasks/1/status',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/housework-tasks/1/status'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.updateTaskStatus(taskId: 1, status: '1'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('MyTasksRepository.bulkUpdateStatus()', () {
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
        repo.bulkUpdateStatus(taskIds: [1, 2], status: '1'),
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
        () => repo.bulkUpdateStatus(taskIds: [1, 2], status: '1'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
