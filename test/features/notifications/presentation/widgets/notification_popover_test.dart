import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/notifications/data/notification_repository.dart';
import 'package:hw_hub_mobile/features/notifications/notifications_providers.dart';
import 'package:hw_hub_mobile/features/notifications/presentation/notification_global_notifier.dart';
import 'package:hw_hub_mobile/features/notifications/presentation/widgets/notification_popover.dart';

import '../../../../helpers/widget_test_helpers.dart';

/// 0件を返す FakeRepository
class _EmptyRepository implements NotificationRepository {
  @override
  Future<List<NotificationDto>> fetchNotifications({
    required int limit,
    required bool markRead,
  }) async => [];

  @override
  Future<int> fetchUnreadCount() async => 0;
}

/// 2件の通知を返す FakeRepository
class _TwoItemsRepository implements NotificationRepository {
  @override
  Future<List<NotificationDto>> fetchNotifications({
    required int limit,
    required bool markRead,
  }) async => [
    const NotificationDto(
      notificationId: 1,
      isRead: false,
      occurredAt: '2026-05-01T10:00:00',
      titleKey: 'generic',
      bodyKey: 'generic',
      params: {},
      linkType: 'None',
      aggregatedCount: 1,
    ),
    const NotificationDto(
      notificationId: 2,
      isRead: true,
      occurredAt: '2026-05-02T10:00:00',
      titleKey: 'taskAssigned',
      bodyKey: 'taskAssigned',
      params: {
        'actorName': 'ママ',
        'household': '自宅',
        'date': '2026/05/01',
        'count': '1',
      },
      linkType: 'MyTasks',
      aggregatedCount: 1,
    ),
  ];

  @override
  Future<int> fetchUnreadCount() async => 2;
}

/// エラーを返す FakeRepository
class _ErrorRepository implements NotificationRepository {
  @override
  Future<List<NotificationDto>> fetchNotifications({
    required int limit,
    required bool markRead,
  }) async => throw Exception('テストエラー');

  @override
  Future<int> fetchUnreadCount() async => 0;
}

class _ZeroUnreadNotifier extends NotificationGlobalNotifier {
  @override
  NotificationGlobalState build() =>
      const NotificationGlobalState(unreadCount: 0);
}

void main() {
  group('NotificationPopover', () {
    testWidgets('ローディング中: CircularProgressIndicator が表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(body: NotificationPopover()),
          overrides: [
            notificationRepositoryProvider.overrideWithValue(
              _EmptyRepository(),
            ),
            notificationGlobalNotifierProvider.overrideWith(
              () => _ZeroUnreadNotifier(),
            ),
          ],
        ),
      );
      // pumpWidget() 直後（非同期処理完了前）にローディング状態を確認
      // 初回ビルド時は _isLoading = true なのでインジケーターが表示される
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('通知0件: 空状態テキストが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(body: NotificationPopover()),
          overrides: [
            notificationRepositoryProvider.overrideWithValue(
              _EmptyRepository(),
            ),
            notificationGlobalNotifierProvider.overrideWith(
              () => _ZeroUnreadNotifier(),
            ),
          ],
        ),
      );
      await tester.pump(); // ローディング開始
      await tester.pump(); // Future 完了

      expect(find.byType(CircularProgressIndicator), findsNothing);
      // 空状態メッセージ
      expect(find.byKey(const Key('notificationEmpty')), findsOneWidget);
    });

    testWidgets('通知2件: NotificationListItem が2件表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(body: NotificationPopover()),
          overrides: [
            notificationRepositoryProvider.overrideWithValue(
              _TwoItemsRepository(),
            ),
            notificationGlobalNotifierProvider.overrideWith(
              () => _ZeroUnreadNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const ValueKey(1)), findsOneWidget);
      expect(find.byKey(const ValueKey(2)), findsOneWidget);
    });
  });
}
