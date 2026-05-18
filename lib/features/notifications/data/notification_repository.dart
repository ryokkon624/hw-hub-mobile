import 'package:dio/dio.dart';
import '../../../core/network/app_exception.dart';
import 'models/notification_dto.dart';

export 'models/notification_dto.dart';

abstract class NotificationRepository {
  Future<List<NotificationDto>> fetchNotifications({
    required int limit,
    required bool markRead,
  });

  Future<int> fetchUnreadCount();
}

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<NotificationDto>> fetchNotifications({
    required int limit,
    required bool markRead,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/notifications',
        queryParameters: <String, dynamic>{
          'limit': limit,
          'markRead': markRead,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List<dynamic>)
          .map((e) => NotificationDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<int> fetchUnreadCount() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/notifications/unread-count',
      );
      final data = response.data as Map<String, dynamic>;
      return data['unreadCount'] as int;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }
}
