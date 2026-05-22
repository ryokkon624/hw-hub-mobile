import 'package:dio/dio.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/network/s3_url_resolver.dart';
import 'models/home_raw_data.dart';
import 'models/household_member_dto.dart';
import 'models/housework_task_dto.dart';
import 'models/shopping_item_dto.dart';

abstract class HomeRepository {
  Future<HomeRawData> loadAll(int householdId);
}

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._dio, this._s3UrlResolver);

  final Dio _dio;
  final S3UrlResolver _s3UrlResolver;

  @override
  Future<HomeRawData> loadAll(int householdId) async {
    try {
      final results = await Future.wait([
        _dio.get<List<dynamic>>('/api/households/$householdId/members'),
        _dio.get<List<dynamic>>(
          '/api/housework-tasks',
          queryParameters: {'householdId': householdId, 'status': '0'},
        ),
        _dio.get<List<dynamic>>(
          '/api/housework-tasks',
          queryParameters: {'householdId': householdId, 'status': '1'},
        ),
        _dio.get<Map<String, dynamic>>(
          '/api/households/$householdId/shopping-items',
        ),
      ]);

      final members = (results[0].data as List<dynamic>)
          .map((e) => HouseholdMemberDto.fromJson(e as Map<String, dynamic>))
          .map(
            (m) => HouseholdMemberDto(
              householdId: m.householdId,
              userId: m.userId,
              displayName: m.displayName,
              iconUrl: _s3UrlResolver.resolve(m.iconUrl),
              nickname: m.nickname,
              status: m.status,
              role: m.role,
            ),
          )
          .toList();

      final openTasks = (results[1].data as List<dynamic>)
          .map((e) => HouseworkTaskDto.fromJson(e as Map<String, dynamic>))
          .toList();

      final doneTasks = (results[2].data as List<dynamic>)
          .map((e) => HouseworkTaskDto.fromJson(e as Map<String, dynamic>))
          .toList();

      final shoppingRaw = results[3].data as Map<String, dynamic>;
      final shoppingItems = (shoppingRaw['items'] as List<dynamic>)
          .map((e) => ShoppingItemDto.fromJson(e as Map<String, dynamic>))
          .toList();

      return HomeRawData(
        members: members,
        openTasks: openTasks,
        doneTasks: doneTasks,
        shoppingItems: shoppingItems,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }
}
