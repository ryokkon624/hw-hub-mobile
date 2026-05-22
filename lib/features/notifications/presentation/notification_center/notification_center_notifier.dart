import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/app_exception.dart';
import '../../notifications_providers.dart';

class NotificationCenterNotifier extends Notifier<NotificationCenterState> {
  @override
  NotificationCenterState build() {
    Future.microtask(_initialize);
    return const NotificationCenterState();
  }

  Future<void> _initialize() async {
    await _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _runCatching(
      () async {
        final repo = ref.read(notificationRepositoryProvider);
        final notifications = await repo.fetchNotifications(
          limit: 50,
          markRead: true,
        );
        state = state.copyWith(notifications: notifications, isLoading: false);
        // 既読になるため未読件数をリセット
        ref.read(notificationGlobalNotifierProvider.notifier).resetToZero();
      },
      onError: (msg) => state.copyWith(isLoading: false, errorMessage: msg),
      rethrowUnexpected: true,
    );
  }

  /// Notifier（同期ステート）向けエラーハンドリングヘルパー。
  /// [rethrowUnexpected] が true の場合、AppException 以外の予期しない例外は rethrow する。
  Future<void> _runCatching(
    Future<void> Function() operation, {
    NotificationCenterState Function(String errorMessage)? onError,
    bool rethrowUnexpected = false,
  }) async {
    try {
      await operation();
    } on AppException catch (e) {
      state = onError != null
          ? onError(e.message)
          : state.copyWith(errorMessage: e.message);
    } catch (_) {
      if (rethrowUnexpected) rethrow;
      state = onError != null
          ? onError('errorUnexpected')
          : state.copyWith(errorMessage: 'errorUnexpected');
    }
  }

  Future<void> reload() async {
    await _fetchNotifications();
  }
}
