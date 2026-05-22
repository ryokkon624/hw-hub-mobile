import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import 'data/shopping_attachment_repository.dart';
import 'data/shopping_repository.dart';
import 'presentation/shopping_item_detail/shopping_item_detail_notifier.dart';
import 'presentation/shopping_item_list/shopping_list_notifier.dart';
import 'presentation/shopping_item_list/shopping_list_state.dart';
import 'presentation/shopping_item_new/shopping_item_new_notifier.dart';

export 'presentation/shopping_item_detail/shopping_item_detail_notifier.dart';
export 'presentation/shopping_item_detail/shopping_item_detail_state.dart';
export 'presentation/shopping_item_list/shopping_list_notifier.dart';
export 'presentation/shopping_item_list/shopping_list_state.dart';
export 'presentation/shopping_item_new/shopping_item_new_notifier.dart';
export 'presentation/shopping_item_new/shopping_item_new_state.dart';

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

final shoppingListNotifierProvider =
    AsyncNotifierProvider.autoDispose<ShoppingListNotifier, ShoppingListState>(
      ShoppingListNotifier.new,
    );

final shoppingItemDetailNotifierProvider = NotifierProvider.autoDispose
    .family<ShoppingItemDetailNotifier, ShoppingItemDetailState, int>(
      ShoppingItemDetailNotifier.new,
    );

final shoppingItemNewNotifierProvider =
    NotifierProvider.autoDispose<ShoppingItemNewNotifier, ShoppingItemNewState>(
      ShoppingItemNewNotifier.new,
    );
