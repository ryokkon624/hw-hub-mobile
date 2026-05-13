import 'package:dio/dio.dart';
import '../../../core/models/task_status.dart';
import '../../../core/network/app_exception.dart';
import 'models/housework_task_dto.dart';

export 'models/housework_task_dto.dart';

abstract class MyTasksRepository {
  Future<List<HouseworkTaskDto>> fetchOpenTasks({required int householdId});
  Future<void> updateTaskStatus({required int taskId, required String status});
  Future<void> bulkUpdateStatus({
    required List<int> taskIds,
    required String status,
    String? skippedReason,
  });
}

class MyTasksRepositoryImpl implements MyTasksRepository {
  MyTasksRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<HouseworkTaskDto>> fetchOpenTasks({
    required int householdId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/housework-tasks',
        queryParameters: {
          'householdId': householdId,
          'status': TaskStatus.notDone.code,
        },
      );
      return (response.data as List<dynamic>)
          .map((e) => HouseworkTaskDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> updateTaskStatus({
    required int taskId,
    required String status,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/api/housework-tasks/$taskId/status',
        data: {'status': status},
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> bulkUpdateStatus({
    required List<int> taskIds,
    required String status,
    String? skippedReason,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/api/housework-tasks/bulk-status',
        data: {
          'taskIds': taskIds,
          'status': status,
          'skippedReason': skippedReason,
        },
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }
}
