import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/notifications/notifications_providers.dart';
import 'package:hw_hub_mobile/features/notifications/presentation/notification_global_notifier.dart';
import 'package:mockito/mockito.dart';

import '../notifications_mocks.mocks.dart';

ProviderContainer _makeContainer({
  required MockNotificationRepository mockRepo,
}) {
  final container = ProviderContainer(
    overrides: [notificationRepositoryProvider.overrideWithValue(mockRepo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late MockNotificationRepository mockRepo;

  setUp(() {
    mockRepo = MockNotificationRepository();
  });

  group('NotificationGlobalNotifier.build()', () {
    test('初期状態: unreadCount=0', () {
      final container = _makeContainer(mockRepo: mockRepo);
      final state = container.read(notificationGlobalNotifierProvider);
      expect(state.unreadCount, 0);
    });
  });

  group('NotificationGlobalNotifier.refreshUnreadCount()', () {
    test('成功時: unreadCountが更新される', () async {
      when(mockRepo.fetchUnreadCount()).thenAnswer((_) async => 5);

      final container = _makeContainer(mockRepo: mockRepo);
      await container
          .read(notificationGlobalNotifierProvider.notifier)
          .refreshUnreadCount();

      final state = container.read(notificationGlobalNotifierProvider);
      expect(state.unreadCount, 5);
    });

    test('失敗時: unreadCountは変わらない（エラーを握りつぶさない・silent fail）', () async {
      when(mockRepo.fetchUnreadCount()).thenThrow(const NetworkException());

      final container = _makeContainer(mockRepo: mockRepo);
      // エラーが発生してもクラッシュしないこと
      await container
          .read(notificationGlobalNotifierProvider.notifier)
          .refreshUnreadCount();

      final state = container.read(notificationGlobalNotifierProvider);
      expect(state.unreadCount, 0);
    });
  });

  group('NotificationGlobalNotifier.resetToZero()', () {
    test('unreadCountが0になる', () async {
      when(mockRepo.fetchUnreadCount()).thenAnswer((_) async => 8);

      final container = _makeContainer(mockRepo: mockRepo);
      await container
          .read(notificationGlobalNotifierProvider.notifier)
          .refreshUnreadCount();
      expect(container.read(notificationGlobalNotifierProvider).unreadCount, 8);

      container.read(notificationGlobalNotifierProvider.notifier).resetToZero();
      expect(container.read(notificationGlobalNotifierProvider).unreadCount, 0);
    });
  });

  group('NotificationGlobalNotifier バッジ表示', () {
    test('unreadCountが99超の場合: badgeTextは99+', () async {
      when(mockRepo.fetchUnreadCount()).thenAnswer((_) async => 100);

      final container = _makeContainer(mockRepo: mockRepo);
      await container
          .read(notificationGlobalNotifierProvider.notifier)
          .refreshUnreadCount();

      final state = container.read(notificationGlobalNotifierProvider);
      expect(state.badgeText, '99+');
    });

    test('unreadCountが1〜99の場合: badgeTextはその数値', () async {
      when(mockRepo.fetchUnreadCount()).thenAnswer((_) async => 42);

      final container = _makeContainer(mockRepo: mockRepo);
      await container
          .read(notificationGlobalNotifierProvider.notifier)
          .refreshUnreadCount();

      final state = container.read(notificationGlobalNotifierProvider);
      expect(state.badgeText, '42');
    });

    test('unreadCountが0の場合: showBadgeはfalse', () {
      final container = _makeContainer(mockRepo: mockRepo);
      final state = container.read(notificationGlobalNotifierProvider);
      expect(state.showBadge, false);
    });

    test('unreadCountが1以上の場合: showBadgeはtrue', () async {
      when(mockRepo.fetchUnreadCount()).thenAnswer((_) async => 3);

      final container = _makeContainer(mockRepo: mockRepo);
      await container
          .read(notificationGlobalNotifierProvider.notifier)
          .refreshUnreadCount();

      final state = container.read(notificationGlobalNotifierProvider);
      expect(state.showBadge, true);
    });
  });
}
