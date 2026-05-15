import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import 'data/shopping_attachment_repository.dart';
import 'data/shopping_repository.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepositoryImpl(ref.watch(dioProvider));
});

/// S3 に直接 PUT するための素 Dio（インターセプターなし）
final s3DioProvider = Provider<Dio>((ref) {
  return Dio();
});

final shoppingAttachmentRepositoryProvider =
    Provider<ShoppingAttachmentRepository>((ref) {
      return ShoppingAttachmentRepositoryImpl(
        ref.watch(dioProvider),
        ref.watch(s3DioProvider),
      );
    });
