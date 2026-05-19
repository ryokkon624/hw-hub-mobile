import 'package:dio/dio.dart';
import '../../../core/network/app_exception.dart';
import '../../../features/home/data/models/household_member_dto.dart';
import 'models/housework_dto.dart';
import 'models/housework_template_dto.dart';

export '../../../features/home/data/models/household_member_dto.dart';
export 'models/housework_dto.dart';
export 'models/housework_template_dto.dart';

abstract class HouseworkSettingsRepository {
  Future<List<HouseworkDto>> fetchHouseworks({required int householdId});
  Future<HouseworkDto> fetchHousework({required int houseworkId});
  Future<List<HouseholdMemberDto>> fetchMembers({required int householdId});
  Future<HouseworkDto> createHousework({
    required int householdId,
    required String name,
    String? description,
    required String category,
    required String recurrenceType,
    int? weeklyDays,
    int? dayOfMonth,
    int? nthWeek,
    int? weekday,
    required String startDate,
    required String endDate,
    int? defaultAssigneeUserId,
  });
  Future<HouseworkDto> updateHousework({
    required int houseworkId,
    required int householdId,
    required String name,
    String? description,
    required String category,
    required String recurrenceType,
    int? weeklyDays,
    int? dayOfMonth,
    int? nthWeek,
    int? weekday,
    required String startDate,
    required String endDate,
    int? defaultAssigneeUserId,
  });
  Future<List<HouseworkTemplateDto>> fetchTemplates();
}

class HouseworkSettingsRepositoryImpl implements HouseworkSettingsRepository {
  HouseworkSettingsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<HouseworkDto>> fetchHouseworks({required int householdId}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/houseworks',
        queryParameters: {'householdId': householdId},
      );
      return (response.data as List<dynamic>)
          .map((e) => HouseworkDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<HouseworkDto> fetchHousework({required int houseworkId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/houseworks/$houseworkId',
      );
      return HouseworkDto.fromJson(response.data as Map<String, dynamic>);
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
      final response = await _dio.get<List<dynamic>>(
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
  Future<HouseworkDto> createHousework({
    required int householdId,
    required String name,
    String? description,
    required String category,
    required String recurrenceType,
    int? weeklyDays,
    int? dayOfMonth,
    int? nthWeek,
    int? weekday,
    required String startDate,
    required String endDate,
    int? defaultAssigneeUserId,
  }) async {
    try {
      final body = <String, dynamic>{
        'householdId': householdId,
        'name': name,
        'category': category,
        'recurrenceType': recurrenceType,
        'startDate': startDate,
        'endDate': endDate,
      };
      if (description != null) body['description'] = description;
      if (weeklyDays != null) body['weeklyDays'] = weeklyDays;
      if (dayOfMonth != null) body['dayOfMonth'] = dayOfMonth;
      if (nthWeek != null) body['nthWeek'] = nthWeek;
      if (weekday != null) body['weekday'] = weekday;
      if (defaultAssigneeUserId != null) {
        body['defaultAssigneeUserId'] = defaultAssigneeUserId;
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/api/houseworks',
        data: body,
      );
      return HouseworkDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<HouseworkDto> updateHousework({
    required int houseworkId,
    required int householdId,
    required String name,
    String? description,
    required String category,
    required String recurrenceType,
    int? weeklyDays,
    int? dayOfMonth,
    int? nthWeek,
    int? weekday,
    required String startDate,
    required String endDate,
    int? defaultAssigneeUserId,
  }) async {
    try {
      final body = <String, dynamic>{
        'householdId': householdId,
        'name': name,
        'category': category,
        'recurrenceType': recurrenceType,
        'startDate': startDate,
        'endDate': endDate,
      };
      if (description != null) body['description'] = description;
      if (weeklyDays != null) body['weeklyDays'] = weeklyDays;
      if (dayOfMonth != null) body['dayOfMonth'] = dayOfMonth;
      if (nthWeek != null) body['nthWeek'] = nthWeek;
      if (weekday != null) body['weekday'] = weekday;
      if (defaultAssigneeUserId != null) {
        body['defaultAssigneeUserId'] = defaultAssigneeUserId;
      }

      final response = await _dio.put<Map<String, dynamic>>(
        '/api/houseworks/$houseworkId',
        data: body,
      );
      return HouseworkDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<List<HouseworkTemplateDto>> fetchTemplates() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/housework-templates',
      );
      return (response.data as List<dynamic>)
          .map((e) => HouseworkTemplateDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }
}
