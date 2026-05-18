import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/notifications/data/notification_repository.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/mocks.mocks.dart';

void main() {
  late MockDio mockDio;
  late NotificationRepositoryImpl repo;

  setUp(() {
    mockDio = MockDio();
    repo = NotificationRepositoryImpl(mockDio);
  });

  group('NotificationRepository.fetchNotifications()', () {
    test('成功時: 通知リストを返す', () async {
      when(
        mockDio.get<dynamic>(
          '/api/notifications',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'items': [
              {
                'notificationId': 1,
                'isRead': false,
                'occurredAt': '2026-05-01T10:00:00',
                'titleKey': 'taskAssigned',
                'bodyKey': 'taskAssigned',
                'params': {
                  'actorName': 'ママ',
                  'household': '自宅',
                  'date': '2026/05/01',
                  'count': '2',
                },
                'linkType': 'MyTasks',
                'linkId': null,
                'aggregatedCount': 2,
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/notifications'),
        ),
      );

      final result = await repo.fetchNotifications(limit: 20, markRead: true);

      expect(result, hasLength(1));
      expect(result.first.notificationId, 1);
      expect(result.first.isRead, false);
      expect(result.first.titleKey, 'taskAssigned');
      expect(result.first.linkType, 'MyTasks');
    });

    test('DioException 時: NetworkException をスローする', () async {
      when(
        mockDio.get<dynamic>(
          '/api/notifications',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/notifications'),
        ),
      );

      expect(
        () => repo.fetchNotifications(limit: 20, markRead: true),
        throwsA(isA<NetworkException>()),
      );
    });

    test('DioException.error が AppException の場合: そのままスローする', () async {
      when(
        mockDio.get<dynamic>(
          '/api/notifications',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/notifications'),
          error: const ServerException(
            message: 'Server error',
            statusCode: 500,
          ),
        ),
      );

      expect(
        () => repo.fetchNotifications(limit: 20, markRead: true),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('NotificationRepository.fetchUnreadCount()', () {
    test('成功時: 未読件数を返す', () async {
      when(mockDio.get<dynamic>('/api/notifications/unread-count')).thenAnswer(
        (_) async => Response(
          data: {'unreadCount': 5},
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/api/notifications/unread-count',
          ),
        ),
      );

      final result = await repo.fetchUnreadCount();

      expect(result, 5);
    });

    test('DioException 時: NetworkException をスローする', () async {
      when(mockDio.get<dynamic>('/api/notifications/unread-count')).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/api/notifications/unread-count',
          ),
        ),
      );

      expect(() => repo.fetchUnreadCount(), throwsA(isA<NetworkException>()));
    });
  });
}
