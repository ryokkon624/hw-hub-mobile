import 'package:dio/dio.dart';
import '../../../core/network/app_exception.dart';
import '../../home/data/models/shopping_item_dto.dart';

export '../../home/data/models/shopping_item_dto.dart';

abstract class ShoppingRepository {
  Future<List<ShoppingItemDto>> fetchItems({required int householdId});
  Future<void> updateStatus({
    required int shoppingItemId,
    required String status,
  });
  Future<void> bulkUpdateStatus({
    required List<int> ids,
    required String status,
  });
  Future<void> toggleFavorite({
    required int shoppingItemId,
    required String favorite,
  });
  Future<void> deleteItem({required int shoppingItemId});
}

class ShoppingRepositoryImpl implements ShoppingRepository {
  ShoppingRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<ShoppingItemDto>> fetchItems({required int householdId}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/households/$householdId/shopping-items',
        queryParameters: <String, dynamic>{},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List<dynamic>)
          .map((e) => ShoppingItemDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> updateStatus({
    required int shoppingItemId,
    required String status,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/api/shopping-items/$shoppingItemId/status',
        data: {'status': status},
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> bulkUpdateStatus({
    required List<int> ids,
    required String status,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/api/shopping-items/bulk-status',
        data: {'ids': ids, 'status': status},
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> toggleFavorite({
    required int shoppingItemId,
    required String favorite,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/api/shopping-items/$shoppingItemId/favorite',
        data: {'favorite': favorite},
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> deleteItem({required int shoppingItemId}) async {
    try {
      await _dio.delete<dynamic>('/api/shopping-items/$shoppingItemId');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }
}
