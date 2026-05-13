import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/shopping/data/shopping_repository.dart';

import '../../../helpers/mocks.mocks.dart';
import 'package:mockito/mockito.dart';

Map<String, dynamic> _itemJson({
  int id = 1,
  String status = '0',
  String? storeType = '1',
  String? favorite = '0',
}) => {
  'shoppingItemId': id,
  'householdId': 1,
  'name': 'オリーブオイル',
  'memo': null,
  'storeType': storeType,
  'status': status,
  'favorite': favorite,
  'purchasedAt': null,
  'createdAt': '2026-05-01T10:00:00',
  'hasImage': false,
};

RequestOptions _req(String path) => RequestOptions(path: path);

void main() {
  late MockDio mockDio;
  late ShoppingRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = ShoppingRepositoryImpl(mockDio);
  });

  group('ShoppingRepository.fetchItems()', () {
    test('成功時: アイテムリストを返す', () async {
      when(
        mockDio.get<dynamic>(
          '/api/households/1/shopping-items',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/households/1/shopping-items'),
          statusCode: 200,
          // APIレスポンスは {"items": [...]} のラッパー構造
          data: {
            'items': [_itemJson(id: 1), _itemJson(id: 2)],
          },
        ),
      );

      final result = await repo.fetchItems(householdId: 1);
      expect(result, hasLength(2));
      expect(result.first.shoppingItemId, 1);
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.get<dynamic>(
          '/api/households/1/shopping-items',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/households/1/shopping-items'),
          type: DioExceptionType.connectionError,
          message: 'Connection refused',
        ),
      );

      expect(
        () => repo.fetchItems(householdId: 1),
        throwsA(isA<NetworkException>()),
      );
    });

    test('DioExceptionのerrorがAppExceptionの場合: そのままrethrowする', () async {
      when(
        mockDio.get<dynamic>(
          '/api/households/1/shopping-items',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/households/1/shopping-items'),
          error: const UnauthorizedException('認証失敗'),
        ),
      );

      expect(
        () => repo.fetchItems(householdId: 1),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('ShoppingRepository.updateStatus()', () {
    test('成功時: 例外なく完了する', () async {
      when(
        mockDio.patch<dynamic>(
          '/api/shopping-items/1/status',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/shopping-items/1/status'),
          statusCode: 204,
          data: null,
        ),
      );

      await expectLater(
        repo.updateStatus(shoppingItemId: 1, status: '1'),
        completes,
      );
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.patch<dynamic>(
          '/api/shopping-items/1/status',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/shopping-items/1/status'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.updateStatus(shoppingItemId: 1, status: '1'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('ShoppingRepository.bulkUpdateStatus()', () {
    test('成功時: 例外なく完了する', () async {
      when(
        mockDio.patch<dynamic>(
          '/api/shopping-items/bulk-status',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/shopping-items/bulk-status'),
          statusCode: 204,
          data: null,
        ),
      );

      await expectLater(
        repo.bulkUpdateStatus(ids: [1, 2], status: '9'),
        completes,
      );
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.patch<dynamic>(
          '/api/shopping-items/bulk-status',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/shopping-items/bulk-status'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.bulkUpdateStatus(ids: [1, 2], status: '9'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('ShoppingRepository.toggleFavorite()', () {
    test('成功時: 例外なく完了する', () async {
      when(
        mockDio.patch<dynamic>(
          '/api/shopping-items/1/favorite',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/shopping-items/1/favorite'),
          statusCode: 204,
          data: null,
        ),
      );

      await expectLater(
        repo.toggleFavorite(shoppingItemId: 1, favorite: '1'),
        completes,
      );
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.patch<dynamic>(
          '/api/shopping-items/1/favorite',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/shopping-items/1/favorite'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.toggleFavorite(shoppingItemId: 1, favorite: '1'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('ShoppingRepository.deleteItem()', () {
    test('成功時: 例外なく完了する', () async {
      when(mockDio.delete<dynamic>('/api/shopping-items/1')).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/shopping-items/1'),
          statusCode: 204,
          data: null,
        ),
      );

      await expectLater(repo.deleteItem(shoppingItemId: 1), completes);
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(mockDio.delete<dynamic>('/api/shopping-items/1')).thenThrow(
        DioException(
          requestOptions: _req('/api/shopping-items/1'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.deleteItem(shoppingItemId: 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
