import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/core/auth/auth_notifier.dart';
import 'package:hw_hub_mobile/core/auth/auth_state.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/models/auth_user.dart';
import 'package:hw_hub_mobile/core/ui/header_user_icon.dart';
import 'package:hw_hub_mobile/core/ui/user_avatar.dart';

import '../../helpers/widget_test_helpers.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

const _authenticatedUser = AuthUser(
  userId: 1,
  email: 'test@example.com',
  displayName: 'テスト',
  iconUrl: 'https://example.com/icon.png',
);

void main() {
  group('HeaderUserIcon', () {
    testWidgets('UserAvatarが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const HeaderUserIcon(),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(
                const AuthAuthenticated(_authenticatedUser),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(UserAvatar), findsOneWidget);
    });

    testWidgets('タップするとポップオーバーメニューが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Scaffold(
                appBar: AppBar(actions: const [HeaderUserIcon()]),
                body: const SizedBox(),
              ),
            ),
            GoRoute(
              path: '/settings',
              builder: (_, _) => const Scaffold(body: Text('settings-page')),
            ),
          ],
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(
                const AuthAuthenticated(_authenticatedUser),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      // UserAvatar をタップ
      await tester.tap(find.byType(UserAvatar));
      await tester.pumpAndSettle();

      // メニューが表示される
      expect(find.byKey(const Key('menuItemSettings')), findsOneWidget);
      expect(find.byKey(const Key('menuItemLogout')), findsOneWidget);
    });

    testWidgets('設定メニューをタップすると /settings に遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Scaffold(
                appBar: AppBar(actions: const [HeaderUserIcon()]),
                body: const SizedBox(),
              ),
            ),
            GoRoute(
              path: '/settings',
              builder: (_, _) => const Scaffold(body: Text('settings-page')),
            ),
          ],
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(
                const AuthAuthenticated(_authenticatedUser),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byType(UserAvatar));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('menuItemSettings')));
      await tester.pumpAndSettle();

      expect(find.text('settings-page'), findsOneWidget);
    });

    testWidgets('ログアウトメニューをタップすると確認ダイアログが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Scaffold(
                appBar: AppBar(actions: const [HeaderUserIcon()]),
                body: const SizedBox(),
              ),
            ),
          ],
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(
                const AuthAuthenticated(_authenticatedUser),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byType(UserAvatar));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('menuItemLogout')));
      await tester.pumpAndSettle();

      // 確認ダイアログが表示される
      expect(find.byType(AlertDialog), findsOneWidget);
      // AppDialog.confirm はキャンセル/確認の2つの TextButton を表示する
      expect(find.byType(TextButton), findsNWidgets(2));
    });

    testWidgets('AuthUnauthenticated の場合でも表示エラーが発生しない', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const HeaderUserIcon(),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthUnauthenticated()),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      // エラーなく表示される（displayName が空文字のため UserAvatar がイニシャル '?' を表示する）
      expect(find.byType(UserAvatar), findsOneWidget);
    });

    testWidgets('ログアウトダイアログでキャンセルをタップするとダイアログが閉じる', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Scaffold(
                appBar: AppBar(actions: const [HeaderUserIcon()]),
                body: const SizedBox(),
              ),
            ),
          ],
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(
                const AuthAuthenticated(_authenticatedUser),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byType(UserAvatar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ログアウト'));
      await tester.pumpAndSettle();

      // キャンセルをタップ
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      // ダイアログが閉じる
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('ログアウトダイアログではいをタップするとlogoutが呼ばれる', (tester) async {
      bool logoutCalled = false;

      // AuthNotifier を override してlogoutを記録する
      final notifier = _RecordingAuthNotifier(
        const AuthAuthenticated(_authenticatedUser),
        onLogout: () => logoutCalled = true,
      );

      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Scaffold(
                appBar: AppBar(actions: const [HeaderUserIcon()]),
                body: const SizedBox(),
              ),
            ),
            GoRoute(
              path: '/login',
              builder: (_, _) => const Scaffold(body: Text('login-page')),
            ),
          ],
          overrides: [authNotifierProvider.overrideWith(() => notifier)],
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byType(UserAvatar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ログアウト'));
      await tester.pumpAndSettle();

      // はいをタップ
      await tester.tap(find.text('はい'));
      await tester.pumpAndSettle();

      expect(logoutCalled, isTrue);
    });

    testWidgets('メニューをタップせずに閉じるとcase null分岐が通る', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Scaffold(
                appBar: AppBar(actions: const [HeaderUserIcon()]),
                body: const SizedBox(),
              ),
            ),
          ],
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(
                const AuthAuthenticated(_authenticatedUser),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byType(UserAvatar));
      await tester.pumpAndSettle();

      // メニューをタップせずバリア（外側）をタップして閉じる
      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();

      // クラッシュなく動作する（case null: break 分岐が通る）
      expect(find.byType(UserAvatar), findsOneWidget);
    });
  });
}

class _RecordingAuthNotifier extends AuthNotifier {
  _RecordingAuthNotifier(this._state, {required this.onLogout});
  final AuthState _state;
  final void Function() onLogout;

  @override
  Future<AuthState> build() async => _state;

  @override
  Future<void> logout() async {
    onLogout();
  }
}
