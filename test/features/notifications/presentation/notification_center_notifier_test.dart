import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/notifications/data/notification_repository.dart';
import 'package:hw_hub_mobile/features/notifications/notifications_providers.dart';
import 'package:hw_hub_mobile/features/notifications/presentation/notification_center/notification_center_notifier.dart';
import 'package:hw_hub_mobile/features/notifications/presentation/notification_global_notifier.dart';
import 'package:mockito/mockito.dart';

import '../notifications_mocks.mocks.dart';

NotificationDto _dto({int id = 1, bool isRead = false}) => NotificationDto(
  notificationId: id,
  isRead: isRead,
  occurredAt: '2026-05-01T10:00:00',
  titleKey: 'taskAssigned',
  bodyKey: 'taskAssigned',
  params: {
    'actorName': 'ママ',
    'household': '自宅',
    'date': '2026/05/01',
    'count': '2',
  },
  linkType: 'MyTasks',
  linkId: null,
  aggregatedCount: 1,
);

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

  group('NotificationCenterNotifier.build()', () {
    test('初期状態: isLoading=true、notificationsは空', () async {
      when(
        mockRepo.fetchNotifications(
          limit: anyNamed('limit'),
          markRead: anyNamed('markRead'),
        ),
      ).thenAnswer((_) async => [_dto()]);

      final container = _makeContainer(mockRepo: mockRepo);
      // build後すぐに確認（非同期初期化前）
      final state = container.read(notificationCenterNotifierProvider);
      expect(state.isLoading, true);
      expect(state.notifications, isEmpty);
    });

    test('初期ロード成功時: 50件取得でnotificationsがセットされる', () async {
      final dtos = [_dto(id: 1), _dto(id: 2, isRead: true)];
      when(
        mockRepo.fetchNotifications(limit: 50, markRead: true),
      ).thenAnswer((_) async => dtos);

      final container = _makeContainer(mockRepo: mockRepo);
      // AutoDispose を防ぐためサブスクリプションを保持
      final sub = container.listen(
        notificationCenterNotifierProvider,
        (_, _) {},
      );
      // microtask + async完了を待つ
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      final state = container.read(notificationCenterNotifierProvider);
      expect(state.notifications, hasLength(2));
      expect(state.isLoading, false);
      sub.close();
    });

    test('初期ロード失敗時: errorMessageがセットされる', () async {
      when(
        mockRepo.fetchNotifications(
          limit: anyNamed('limit'),
          markRead: anyNamed('markRead'),
        ),
      ).thenThrow(const NetworkException());

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(
        notificationCenterNotifierProvider,
        (_, _) {},
      );
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      final state = container.read(notificationCenterNotifierProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isLoading, false);
      sub.close();
    });
  });

  group('NotificationCenterNotifier.reload()', () {
    test('リロード成功時: 通知一覧が更新される', () async {
      when(
        mockRepo.fetchNotifications(limit: 50, markRead: true),
      ).thenAnswer((_) async => [_dto(id: 1)]);

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(
        notificationCenterNotifierProvider,
        (_, _) {},
      );
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      // 2回目のAPI呼び出しで別のデータを返す
      when(
        mockRepo.fetchNotifications(limit: 50, markRead: true),
      ).thenAnswer((_) async => [_dto(id: 1), _dto(id: 2)]);

      await container
          .read(notificationCenterNotifierProvider.notifier)
          .reload();

      final state = container.read(notificationCenterNotifierProvider);
      expect(state.notifications, hasLength(2));
      sub.close();
    });

    test('リロード失敗時: errorMessageがセットされる', () async {
      when(
        mockRepo.fetchNotifications(limit: 50, markRead: true),
      ).thenAnswer((_) async => [_dto()]);

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(
        notificationCenterNotifierProvider,
        (_, _) {},
      );
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      when(
        mockRepo.fetchNotifications(limit: 50, markRead: true),
      ).thenThrow(const NetworkException());

      await container
          .read(notificationCenterNotifierProvider.notifier)
          .reload();

      final state = container.read(notificationCenterNotifierProvider);
      expect(state.errorMessage, isNotNull);
      sub.close();
    });
  });

  group('NotificationCenterNotifier resetToZero integration', () {
    test('通知取得後にglobalNotifierがresetToZeroを呼ぶ', () async {
      when(
        mockRepo.fetchNotifications(limit: 50, markRead: true),
      ).thenAnswer((_) async => [_dto()]);

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(
        notificationCenterNotifierProvider,
        (_, _) {},
      );
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      // globalNotifier の unreadCount がリセットされているか確認
      final globalState = container.read(notificationGlobalNotifierProvider);
      expect(globalState.unreadCount, 0);
      sub.close();
    });
  });
}
