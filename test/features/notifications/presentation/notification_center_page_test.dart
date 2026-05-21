import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/notifications/data/notification_repository.dart';
import 'package:hw_hub_mobile/features/notifications/presentation/notification_center/notification_center_notifier.dart';
import 'package:hw_hub_mobile/features/notifications/presentation/notification_center/notification_center_page.dart';
import 'package:hw_hub_mobile/features/notifications/presentation/notification_center/notification_center_state.dart';

import '../../../helpers/widget_test_helpers.dart';

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

class _FakeNotificationCenterNotifier extends NotificationCenterNotifier {
  _FakeNotificationCenterNotifier(this._state);
  final NotificationCenterState _state;

  @override
  NotificationCenterState build() => _state;
}

/// reload()を記録するNotifier
class _RecordingNotifier extends NotificationCenterNotifier {
  bool reloadCalled = false;
  final NotificationCenterState _initialState;

  _RecordingNotifier(this._initialState);

  @override
  NotificationCenterState build() => _initialState;

  @override
  Future<void> reload() async {
    reloadCalled = true;
  }
}

/// 状態を変更できるNotifier（listenテスト用）
class _MutableNotifier extends NotificationCenterNotifier {
  _MutableNotifier(NotificationCenterState initialState) {
    _initial = initialState;
  }
  late final NotificationCenterState _initial;

  @override
  NotificationCenterState build() => _initial;

  void setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  void setLoaded(List<NotificationDto> notifications) {
    state = state.copyWith(isLoading: false, notifications: notifications);
  }
}

void main() {
  group('NotificationCenterPage', () {
    testWidgets('ローディング中はCircularProgressIndicatorを表示する', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const NotificationCenterPage(),
          overrides: [
            notificationCenterNotifierProvider.overrideWith(
              () => _FakeNotificationCenterNotifier(
                const NotificationCenterState(isLoading: true),
              ),
            ),
          ],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('通知が空の場合は「通知はありません」を表示する', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const NotificationCenterPage(),
          overrides: [
            notificationCenterNotifierProvider.overrideWith(
              () => _FakeNotificationCenterNotifier(
                const NotificationCenterState(
                  isLoading: false,
                  notifications: [],
                ),
              ),
            ),
          ],
        ),
      );

      expect(find.text('通知はありません'), findsOneWidget);
    });

    testWidgets('通知がある場合は通知リストを表示する', (tester) async {
      final dto = _dto(id: 1);
      await tester.pumpWidget(
        buildTestPage(
          const NotificationCenterPage(),
          overrides: [
            notificationCenterNotifierProvider.overrideWith(
              () => _FakeNotificationCenterNotifier(
                NotificationCenterState(isLoading: false, notifications: [dto]),
              ),
            ),
          ],
        ),
      );

      // タイトルキーに対応する日本語テキストが表示される
      expect(find.text('タスクが割り当てられました'), findsWidgets);
    });

    testWidgets('未読通知（isRead=false）には未読インジケーターが表示される', (tester) async {
      final dto = _dto(id: 1, isRead: false);
      await tester.pumpWidget(
        buildTestPage(
          const NotificationCenterPage(),
          overrides: [
            notificationCenterNotifierProvider.overrideWith(
              () => _FakeNotificationCenterNotifier(
                NotificationCenterState(isLoading: false, notifications: [dto]),
              ),
            ),
          ],
        ),
      );

      // 未読インジケーター（青丸）が表示されていること
      // Container with BoxDecoration.circle が存在することを確認
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasCircleDecoration = containers.any((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration &&
            decoration.shape == BoxShape.circle;
      });
      expect(hasCircleDecoration, isTrue);
    });

    testWidgets('更新ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const NotificationCenterPage(),
          overrides: [
            notificationCenterNotifierProvider.overrideWith(
              () => _FakeNotificationCenterNotifier(
                const NotificationCenterState(isLoading: false),
              ),
            ),
          ],
        ),
      );

      expect(find.text('更新'), findsOneWidget);
    });

    testWidgets('linkTypeがNONE以外の通知には chevron_right アイコンが表示される', (
      tester,
    ) async {
      final dto = _dto(id: 1); // linkType = 'MyTasks'（NONE以外）
      await tester.pumpWidget(
        buildTestPage(
          const NotificationCenterPage(),
          overrides: [
            notificationCenterNotifierProvider.overrideWith(
              () => _FakeNotificationCenterNotifier(
                NotificationCenterState(isLoading: false, notifications: [dto]),
              ),
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('更新ボタンタップでreload()が呼ばれる', (tester) async {
      final notifier = _RecordingNotifier(
        const NotificationCenterState(isLoading: false),
      );
      await tester.pumpWidget(
        buildTestPage(
          const NotificationCenterPage(),
          overrides: [
            notificationCenterNotifierProvider.overrideWith(() => notifier),
          ],
        ),
      );

      await tester.tap(find.text('更新'));
      await tester.pump();

      expect(notifier.reloadCalled, isTrue);
    });

    testWidgets('エラーメッセージがある状態に遷移するとlistenerが発火する（errorMessage分岐）', (
      tester,
    ) async {
      final notifier = _MutableNotifier(
        const NotificationCenterState(isLoading: false),
      );
      await tester.pumpWidget(
        buildTestPage(
          const NotificationCenterPage(),
          overrides: [
            notificationCenterNotifierProvider.overrideWith(() => notifier),
          ],
        ),
      );
      await tester.pump();

      // エラー状態に変更
      notifier.setError('テストエラー');
      await tester.pump();

      // クラッシュなく動作する（AppSnackBarのlistener分岐が通る）
      expect(find.byType(NotificationCenterPage), findsOneWidget);
    });

    testWidgets('通知がある状態に遷移するとlistenerが発火する（resetToZero分岐）', (tester) async {
      final notifier = _MutableNotifier(
        const NotificationCenterState(isLoading: true),
      );
      await tester.pumpWidget(
        buildTestPage(
          const NotificationCenterPage(),
          overrides: [
            notificationCenterNotifierProvider.overrideWith(() => notifier),
          ],
        ),
      );
      await tester.pump();

      // 通知が読み込まれた状態に変更
      notifier.setLoaded([_dto(id: 1)]);
      await tester.pump();

      // クラッシュなく動作する（resetToZero分岐が通る）
      expect(find.byType(NotificationCenterPage), findsOneWidget);
    });
  });
}
