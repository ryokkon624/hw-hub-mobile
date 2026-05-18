import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notifications_providers.dart';
import '../notification_global_notifier.dart';
import 'notification_center_state.dart';

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
    try {
      final repo = ref.read(notificationRepositoryProvider);
      final notifications = await repo.fetchNotifications(
        limit: 50,
        markRead: true,
      );
      state = state.copyWith(notifications: notifications, isLoading: false);
      // 既読になるため未読件数をリセット
      ref.read(notificationGlobalNotifierProvider.notifier).resetToZero();
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'errorUnexpected');
    }
  }

  Future<void> reload() async {
    await _fetchNotifications();
  }
}

final notificationCenterNotifierProvider =
    NotifierProvider<NotificationCenterNotifier, NotificationCenterState>(
      NotificationCenterNotifier.new,
    );
