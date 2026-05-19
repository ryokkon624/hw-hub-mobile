import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/app_info/data/app_info_repository.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/mocks.mocks.dart';

void main() {
  late MockDio mockDio;
  late AppInfoRepositoryImpl repo;

  setUp(() {
    mockDio = MockDio();
    repo = AppInfoRepositoryImpl(mockDio);
  });

  group('AppInfoRepository.fetchApiVersion()', () {
    test('成功時: バージョン文字列を返す', () async {
      when(mockDio.get<Map<String, dynamic>>('/actuator/info')).thenAnswer(
        (_) async => Response(
          data: {
            'app': {'version': '1.2.3'},
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/actuator/info'),
        ),
      );

      final result = await repo.fetchApiVersion();

      expect(result, '1.2.3');
    });

    test('appキーがない場合: nullを返す', () async {
      when(mockDio.get<Map<String, dynamic>>('/actuator/info')).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/actuator/info'),
        ),
      );

      final result = await repo.fetchApiVersion();

      expect(result, isNull);
    });

    test('versionキーがない場合: nullを返す', () async {
      when(mockDio.get<Map<String, dynamic>>('/actuator/info')).thenAnswer(
        (_) async => Response(
          data: {'app': <String, dynamic>{}},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/actuator/info'),
        ),
      );

      final result = await repo.fetchApiVersion();

      expect(result, isNull);
    });

    test('DioException 時: NetworkException をスローする', () async {
      when(mockDio.get<Map<String, dynamic>>('/actuator/info')).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/actuator/info')),
      );

      expect(() => repo.fetchApiVersion(), throwsA(isA<NetworkException>()));
    });

    test('DioException.error が AppException の場合: そのままスローする', () async {
      when(mockDio.get<Map<String, dynamic>>('/actuator/info')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/actuator/info'),
          error: const ServerException(
            message: 'Server error',
            statusCode: 500,
          ),
        ),
      );

      expect(() => repo.fetchApiVersion(), throwsA(isA<ServerException>()));
    });
  });
}
