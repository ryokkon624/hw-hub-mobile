import 'package:dio/dio.dart';
import '../../../core/models/task_assign_reason.dart';
import '../../../core/models/task_status.dart';
import '../../../core/network/app_exception.dart';
import '../../../features/home/data/models/household_member_dto.dart';
import '../../../features/tasks/data/models/housework_task_dto.dart';

export '../../../features/home/data/models/household_member_dto.dart';
export '../../../features/tasks/data/models/housework_task_dto.dart';

abstract class HouseworkAssignRepository {
  Future<List<HouseworkTaskDto>> fetchTasks({required int householdId});
  Future<List<HouseholdMemberDto>> fetchMembers({required int householdId});
  Future<void> updateAssignee({
    required int taskId,
    required int? assigneeUserId,
  });
  Future<void> bulkSkipPastUnassigned({required List<int> taskIds});
}

class HouseworkAssignRepositoryImpl implements HouseworkAssignRepository {
  HouseworkAssignRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<HouseworkTaskDto>> fetchTasks({required int householdId}) async {
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
  Future<List<HouseholdMemberDto>> fetchMembers({
    required int householdId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/households/$householdId/members',
      );
      return (response.data as List<dynamic>)
          .map((e) => HouseholdMemberDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> updateAssignee({
    required int taskId,
    required int? assigneeUserId,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/api/housework-tasks/$taskId/assign',
        data: {
          'assigneeUserId': assigneeUserId,
          'assignReasonType': TaskAssignReason.selfAssigned.code,
        },
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> bulkSkipPastUnassigned({required List<int> taskIds}) async {
    try {
      await _dio.patch<dynamic>(
        '/api/housework-tasks/bulk-status',
        data: {'taskIds': taskIds, 'status': TaskStatus.skipped.code},
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }
}
