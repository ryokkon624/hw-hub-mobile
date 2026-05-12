import 'package:dio/dio.dart';
import '../../../core/models/task_status.dart';
import '../../../core/network/app_exception.dart';

class HouseworkTaskDto {
  const HouseworkTaskDto({
    required this.houseworkTaskId,
    required this.householdId,
    required this.houseworkId,
    required this.houseworkName,
    this.categoryCode,
    required this.targetDate,
    this.assigneeUserId,
    this.assigneeNickname,
    required this.status,
    this.assignReasonType,
    this.doneAt,
    this.skippedReason,
  });

  final int houseworkTaskId;
  final int householdId;
  final int houseworkId;
  final String houseworkName;
  final String? categoryCode;
  final String targetDate;
  final int? assigneeUserId;
  final String? assigneeNickname;
  final String status;
  final String? assignReasonType;
  final String? doneAt;
  final String? skippedReason;

  factory HouseworkTaskDto.fromJson(Map<String, dynamic> json) =>
      HouseworkTaskDto(
        houseworkTaskId: json['houseworkTaskId'] as int,
        householdId: json['householdId'] as int,
        houseworkId: json['houseworkId'] as int,
        houseworkName: json['houseworkName'] as String,
        categoryCode: json['categoryCode'] as String?,
        targetDate: json['targetDate'] as String,
        assigneeUserId: json['assigneeUserId'] as int?,
        assigneeNickname: json['assigneeNickname'] as String?,
        status: json['status'] as String,
        assignReasonType: json['assignReasonType'] as String?,
        doneAt: json['doneAt'] as String?,
        skippedReason: json['skippedReason'] as String?,
      );
}

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
