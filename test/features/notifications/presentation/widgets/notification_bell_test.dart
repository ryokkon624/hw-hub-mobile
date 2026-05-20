import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/notifications/presentation/notification_global_notifier.dart';
import 'package:hw_hub_mobile/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:hw_hub_mobile/features/notifications/presentation/widgets/notification_popover.dart';
import 'package:hw_hub_mobile/features/notifications/notifications_providers.dart';
import 'package:hw_hub_mobile/features/notifications/data/notification_repository.dart';

import '../../../../helpers/widget_test_helpers.dart';

/// 未読0件の NotificationGlobalNotifier
class _ZeroUnreadNotifier extends NotificationGlobalNotifier {
  @override
  NotificationGlobalState build() =>
      const NotificationGlobalState(unreadCount: 0);
}

/// 未読3件の NotificationGlobalNotifier
class _ThreeUnreadNotifier extends NotificationGlobalNotifier {
  @override
  NotificationGlobalState build() =>
      const NotificationGlobalState(unreadCount: 3);
}

/// 未読100件（99+表示）の NotificationGlobalNotifier
class _OverflowUnreadNotifier extends NotificationGlobalNotifier {
  @override
  NotificationGlobalState build() =>
      const NotificationGlobalState(unreadCount: 100);
}

/// テスト用のダミー NotificationRepository（ポップオーバーが開いたときのAPIコール用）
class _FakeNotificationRepository implements NotificationRepository {
  @override
  Future<List<NotificationDto>> fetchNotifications({
    required int limit,
    required bool markRead,
  }) async => [];

  @override
  Future<int> fetchUnreadCount() async => 0;
}

Widget _buildBell({required NotificationGlobalNotifier notifier}) {
  return buildTestPage(
    const Scaffold(appBar: null, body: NotificationBell()),
    overrides: [
      notificationGlobalNotifierProvider.overrideWith(() => notifier),
      notificationRepositoryProvider.overrideWithValue(
        _FakeNotificationRepository(),
      ),
    ],
  );
}

void main() {
  group('NotificationBell', () {
    testWidgets('未読0件のとき: バッジが表示されない', (tester) async {
      await tester.pumpWidget(_buildBell(notifier: _ZeroUnreadNotifier()));
      await tester.pump();

      // アイコンボタンが存在する
      expect(find.byType(IconButton), findsOneWidget);
      // バッジ（赤い小円）が表示されない → Stack内のPositionedがない
      expect(find.byType(Positioned), findsNothing);
    });

    testWidgets('未読3件のとき: バッジに "3" が表示される', (tester) async {
      await tester.pumpWidget(_buildBell(notifier: _ThreeUnreadNotifier()));
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('未読100件のとき: バッジに "99+" が表示される', (tester) async {
      await tester.pumpWidget(_buildBell(notifier: _OverflowUnreadNotifier()));
      await tester.pump();

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('ベルアイコンをタップするとNotificationPopoverが開く', (tester) async {
      await tester.pumpWidget(_buildBell(notifier: _ZeroUnreadNotifier()));
      await tester.pump();

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      // NotificationPopover がダイアログとして表示される
      expect(find.byType(NotificationPopover), findsOneWidget);
    });
  });
}
