import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifications_providers.dart';

class NotificationGlobalState {
  const NotificationGlobalState({this.unreadCount = 0});

  final int unreadCount;

  bool get showBadge => unreadCount > 0;

  String get badgeText => unreadCount > 99 ? '99+' : unreadCount.toString();

  NotificationGlobalState copyWith({int? unreadCount}) {
    return NotificationGlobalState(
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationGlobalNotifier extends Notifier<NotificationGlobalState> {
  @override
  NotificationGlobalState build() => const NotificationGlobalState();

  Future<void> refreshUnreadCount() async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      final count = await repo.fetchUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (_) {
      // ベルバッジの更新失敗はサイレントフェイル（クラッシュさせない）
    }
  }

  void resetToZero() {
    state = state.copyWith(unreadCount: 0);
  }
}
