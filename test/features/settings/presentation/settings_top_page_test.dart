import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/core/auth/auth_notifier.dart';
import 'package:hw_hub_mobile/core/auth/auth_state.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/models/auth_user.dart';
import 'package:hw_hub_mobile/features/settings/presentation/settings_top_page.dart';
import 'package:hw_hub_mobile/features/settings/presentation/settings_card.dart';

import '../../../helpers/widget_test_helpers.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => const AuthAuthenticated(
    AuthUser(userId: 1, email: 'a@b.com', displayName: 'テスト'),
  );
}

void main() {
  group('SettingsTopPage', () {
    testWidgets('6枚のSettingsCardが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const SettingsTopPage(),
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(SettingsCard), findsNWidgets(6));
    });

    testWidgets('アカウント設定カードが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const SettingsTopPage(),
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('アカウント設定'), findsOneWidget);
    });

    testWidgets('世帯設定カードが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const SettingsTopPage(),
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('世帯設定'), findsOneWidget);
    });

    testWidgets('家事設定カードが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const SettingsTopPage(),
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('家事設定'), findsOneWidget);
    });

    testWidgets('通知センターカードが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const SettingsTopPage(),
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('通知センター'), findsOneWidget);
    });

    testWidgets('お問い合わせカードが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const SettingsTopPage(),
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('お問い合わせ'), findsOneWidget);
    });

    testWidgets('アプリ情報カードが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const SettingsTopPage(),
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('アプリ情報'), findsOneWidget);
    });

    testWidgets('アカウント設定カードをタップすると /settings/account に遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsTopPage(),
            ),
            GoRoute(
              path: '/settings/account',
              builder: (_, _) => const Scaffold(body: Text('account-page')),
            ),
          ],
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
          ],
          initialLocation: '/settings',
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('アカウント設定'));
      await tester.pumpAndSettle();

      expect(find.text('account-page'), findsOneWidget);
    });

    testWidgets('通知センターカードをタップすると /notifications に遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsTopPage(),
            ),
            GoRoute(
              path: '/notifications',
              builder: (_, _) =>
                  const Scaffold(body: Text('notifications-page')),
            ),
          ],
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
          ],
          initialLocation: '/settings',
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('通知センター'));
      await tester.pumpAndSettle();

      expect(find.text('notifications-page'), findsOneWidget);
    });

    testWidgets('世帯設定カードをタップすると /settings/household に遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsTopPage(),
            ),
            GoRoute(
              path: '/settings/household',
              builder: (_, _) => const Scaffold(body: Text('household-page')),
            ),
          ],
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
          ],
          initialLocation: '/settings',
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('世帯設定'));
      await tester.pumpAndSettle();

      expect(find.text('household-page'), findsOneWidget);
    });

    testWidgets('家事設定カードをタップすると /settings/housework に遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsTopPage(),
            ),
            GoRoute(
              path: '/settings/housework',
              builder: (_, _) => const Scaffold(body: Text('housework-page')),
            ),
          ],
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
          ],
          initialLocation: '/settings',
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('家事設定'));
      await tester.pumpAndSettle();

      expect(find.text('housework-page'), findsOneWidget);
    });

    testWidgets('お問い合わせカードをタップすると /settings/inquiries に遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsTopPage(),
            ),
            GoRoute(
              path: '/settings/inquiries',
              builder: (_, _) => const Scaffold(body: Text('inquiry-page')),
            ),
          ],
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
          ],
          initialLocation: '/settings',
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('お問い合わせ'));
      await tester.pumpAndSettle();

      expect(find.text('inquiry-page'), findsOneWidget);
    });

    testWidgets('アプリ情報カードをタップすると /settings/app-info に遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsTopPage(),
            ),
            GoRoute(
              path: '/settings/app-info',
              builder: (_, _) => const Scaffold(body: Text('app-info-page')),
            ),
          ],
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
          ],
          initialLocation: '/settings',
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('アプリ情報'));
      await tester.pumpAndSettle();

      expect(find.text('app-info-page'), findsOneWidget);
    });
  });
}
