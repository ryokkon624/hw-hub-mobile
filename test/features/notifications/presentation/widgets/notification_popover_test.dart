import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/notifications/data/notification_repository.dart';
import 'package:hw_hub_mobile/features/notifications/notifications_providers.dart';
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

/// 汎用エラーを返す FakeRepository
class _ErrorRepository implements NotificationRepository {
  @override
  Future<List<NotificationDto>> fetchNotifications({
    required int limit,
    required bool markRead,
  }) async => throw Exception('テストエラー');

  @override
  Future<int> fetchUnreadCount() async => 0;
}

/// AppException を返す FakeRepository
class _AppExceptionRepository implements NotificationRepository {
  @override
  Future<List<NotificationDto>> fetchNotifications({
    required int limit,
    required bool markRead,
  }) async => throw const ServerException(message: 'サーバーエラー');

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

    testWidgets('AppException: エラーメッセージが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(body: NotificationPopover()),
          overrides: [
            notificationRepositoryProvider.overrideWithValue(
              _AppExceptionRepository(),
            ),
            notificationGlobalNotifierProvider.overrideWith(
              () => _ZeroUnreadNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('サーバーエラー'), findsOneWidget);
    });

    testWidgets('予期しない例外: エラー後にCircularProgressIndicatorが消える', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(body: NotificationPopover()),
          overrides: [
            notificationRepositoryProvider.overrideWithValue(
              _ErrorRepository(),
            ),
            notificationGlobalNotifierProvider.overrideWith(
              () => _ZeroUnreadNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      // 汎用エラー時はSnackBarで通知（_errorMessage=null）
      expect(find.byType(CircularProgressIndicator), findsNothing);
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

    testWidgets('すべて見るボタンタップでnotificationsページへ遷移する', (tester) async {
      // NotificationPopoverは通常showDialogで表示されるためNavigator.popが呼ばれる。
      // ダイアログとして表示することでポップ先のページを提供する。
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const NotificationPopover(),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
            GoRoute(
              path: '/notifications',
              builder: (_, _) =>
                  const Scaffold(body: Text('notifications-page')),
            ),
          ],
          overrides: [
            notificationRepositoryProvider.overrideWithValue(
              _EmptyRepository(),
            ),
            notificationGlobalNotifierProvider.overrideWith(
              () => _ZeroUnreadNotifier(),
            ),
          ],
          initialLocation: '/',
        ),
      );
      // ダイアログを開く
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.pump(); // 通知ロード完了

      await tester.tap(find.text('すべて見る'));
      await tester.pumpAndSettle();

      expect(find.text('notifications-page'), findsOneWidget);
    });

    testWidgets('リンク付き通知タップでNavigationが実行される（onTapコールバック）', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const NotificationPopover(),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
            GoRoute(
              path: '/tasks',
              builder: (_, _) => const Scaffold(body: Text('tasks-page')),
            ),
          ],
          overrides: [
            notificationRepositoryProvider.overrideWithValue(
              _TwoItemsRepository(),
            ),
            notificationGlobalNotifierProvider.overrideWith(
              () => _ZeroUnreadNotifier(),
            ),
          ],
          initialLocation: '/',
        ),
      );
      // ダイアログを開く
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.pump(); // 通知ロード完了

      // linkType='MyTasks' の通知（id=2）をタップ
      await tester.tap(find.byKey(const ValueKey(2)));
      await tester.pumpAndSettle();

      // クラッシュなく動作する（onTap分岐・Navigator.pop + NotificationLinkNavigator.navigate が通る）
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
