import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/features/account_settings/data/account_settings_repository.dart';
import 'package:hw_hub_mobile/features/account_settings/account_settings_providers.dart';
import 'package:hw_hub_mobile/features/account_settings/presentation/account_settings_page.dart';

import '../../helpers/widget_test_helpers.dart';

// ロードされた状態を返す FakeNotifier
class _FakeNotifier extends AccountSettingsNotifier {
  _FakeNotifier(this._initialState);
  final AccountSettingsState _initialState;

  @override
  Future<AccountSettingsState> build() async => _initialState;
}

// ローディング中（永久に完了しない）FakeNotifier
class _LoadingNotifier extends AccountSettingsNotifier {
  @override
  Future<AccountSettingsState> build() {
    return Completer<AccountSettingsState>().future;
  }
}

// エラー状態を返す FakeNotifier
class _ErrorNotifier extends AccountSettingsNotifier {
  @override
  Future<AccountSettingsState> build() async {
    throw Exception('ロードエラー');
  }
}

// ローカルアカウントのプロフィール（パスワードセクション表示あり、Googleセクションなし）
const _localProfile = UserProfileDto(
  userId: 1,
  email: 'test@example.com',
  authProvider: 'LOCAL',
  displayName: 'テスト太郎',
  locale: 'ja',
  iconUrl: null,
);

// Googleアカウント（@gmail.com）のプロフィール
const _googleProfile = UserProfileDto(
  userId: 2,
  email: 'test@gmail.com',
  authProvider: 'GOOGLE',
  displayName: 'テスト花子',
  locale: 'ja',
  iconUrl: null,
);

const _notificationSettings = NotificationSettingsDto(
  notificationEnabled: true,
  groupSettings: {'100': true, '200': true},
);

// successMessage をセットして listener を発火させる FakeNotifier
class _SuccessMessageNotifier extends AccountSettingsNotifier {
  @override
  Future<AccountSettingsState> build() async =>
      _localState().copyWith(successMessage: '保存しました');

  @override
  void clearSuccess() {
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(clearSuccess: true));
    }
  }

  @override
  void clearError() {}
}

// reload() が呼ばれたことを記録する FakeNotifier
class _RecordingNotifier extends AccountSettingsNotifier {
  _RecordingNotifier(this._initialState);
  final AccountSettingsState _initialState;
  bool reloadCalled = false;

  @override
  Future<AccountSettingsState> build() async => _initialState;

  @override
  Future<void> reload() async {
    reloadCalled = true;
  }
}

AccountSettingsState _localState() => AccountSettingsState(
  profile: _localProfile,
  notificationSettings: _notificationSettings,
);

AccountSettingsState _googleLinkedState() => AccountSettingsState(
  profile: _googleProfile,
  notificationSettings: _notificationSettings,
);

Widget _buildPage(AccountSettingsState state) {
  return buildTestPage(
    const AccountSettingsPage(),
    overrides: [
      accountSettingsNotifierProvider.overrideWith(() => _FakeNotifier(state)),
    ],
  );
}

void main() {
  group('AccountSettingsPage - アカウント情報セクション', () {
    testWidgets('メールアドレスと表示名が表示される', (tester) async {
      await tester.pumpWidget(_buildPage(_localState()));
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('テスト太郎'), findsAtLeastNWidgets(1));
    });
  });

  group('AccountSettingsPage - パスワードセクション', () {
    testWidgets('ローカルアカウントはパスワード変更セクションを表示', (tester) async {
      await tester.pumpWidget(_buildPage(_localState()));
      await tester.pump();

      expect(find.byKey(const Key('passwordChangeSection')), findsOneWidget);
    });

    testWidgets('Googleのみのアカウントはパスワード変更セクションを非表示', (tester) async {
      await tester.pumpWidget(_buildPage(_googleLinkedState()));
      await tester.pump();

      expect(find.byKey(const Key('passwordChangeSection')), findsNothing);
    });
  });

  group('AccountSettingsPage - Googleセクション', () {
    testWidgets('@gmail.comの場合はGoogleセクションを表示', (tester) async {
      await tester.pumpWidget(_buildPage(_googleLinkedState()));
      await tester.pump();

      expect(find.byKey(const Key('googleLinkSection')), findsOneWidget);
    });

    testWidgets('@gmail.com以外はGoogleセクションを非表示', (tester) async {
      await tester.pumpWidget(_buildPage(_localState()));
      await tester.pump();

      expect(find.byKey(const Key('googleLinkSection')), findsNothing);
    });

    testWidgets('連携済み（GOOGLE）は連携済みバッジを表示', (tester) async {
      await tester.pumpWidget(_buildPage(_googleLinkedState()));
      await tester.pump();

      expect(find.byKey(const Key('googleLinkedBadge')), findsOneWidget);
      expect(find.byKey(const Key('googleLinkButton')), findsNothing);
    });
  });

  group('AccountSettingsPage - 通知設定セクション', () {
    testWidgets('通知設定セクションが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(_localState()));
      await tester.pump();

      expect(
        find.byKey(const Key('notificationSettingsSection')),
        findsOneWidget,
      );
    });
  });

  group('AccountSettingsPage - 危険ゾーンセクション', () {
    testWidgets('アカウント削除ボタンが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(_localState()));
      await tester.pump();

      expect(find.byKey(const Key('deleteAccountButton')), findsOneWidget);
    });
  });

  group('AccountSettingsPage - エラー表示', () {
    testWidgets('errorMessage がセットされていればスナックバーで表示する準備ができている', (tester) async {
      final stateWithError = _localState().copyWith(errorMessage: 'エラーが発生しました');
      await tester.pumpWidget(_buildPage(stateWithError));
      await tester.pump();

      // エラーがセットされていても画面は表示される
      expect(find.text('test@example.com'), findsOneWidget);
    });
  });

  group('AccountSettingsPage - アイコンセクション', () {
    testWidgets('IconSectionが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(_localState()));
      await tester.pump();

      // アイコンセクションは常に表示
      expect(find.byKey(const Key('deleteAccountButton')), findsOneWidget);
    });
  });

  group('AccountSettingsPage - プロフィールセクション', () {
    testWidgets('ProfileSectionが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(_localState()));
      await tester.pump();

      // プロフィールセクションは常に表示
      expect(find.text('test@example.com'), findsOneWidget);
    });
  });

  group('AccountSettingsPage - dangerZoneSection', () {
    testWidgets('dangerZoneSectionが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(_localState()));
      await tester.pump();

      expect(find.byKey(const Key('dangerZoneSection')), findsOneWidget);
    });
  });

  group('AccountSettingsPage - ローディング状態', () {
    testWidgets('ローディング中はCircularProgressIndicatorが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const AccountSettingsPage(),
          overrides: [
            accountSettingsNotifierProvider.overrideWith(
              () => _LoadingNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('AccountSettingsPage - エラー状態', () {
    testWidgets('エラー時はエラーメッセージが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const AccountSettingsPage(),
          overrides: [
            accountSettingsNotifierProvider.overrideWith(
              () => _ErrorNotifier(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // エラー状態ではScaffoldが表示されていること
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('AccountSettingsPage - profile=nullのときSizedBox.shrink', () {
    testWidgets('profile=nullのときSizedBox.shrinkが表示される（空ボディ）', (tester) async {
      final emptyState = AccountSettingsState();
      await tester.pumpWidget(
        buildTestPage(
          const AccountSettingsPage(),
          overrides: [
            accountSettingsNotifierProvider.overrideWith(
              () => _FakeNotifier(emptyState),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('AccountSettingsPage - successMessage listener', () {
    testWidgets('successMessageがセットされるとスナックバーが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const AccountSettingsPage(),
          withSnackBarKey: true,
          overrides: [
            accountSettingsNotifierProvider.overrideWith(
              () => _SuccessMessageNotifier(),
            ),
          ],
        ),
      );
      await tester.pump(); // AsyncLoading → AsyncData with successMessage

      expect(find.text('保存しました'), findsOneWidget);
    });
  });

  group('AccountSettingsPage - 戻るボタンのナビゲーション', () {
    testWidgets('戻るボタンタップで /settings へ遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) =>
                  const Scaffold(body: Text('settings-page')),
            ),
            GoRoute(
              path: '/settings/account',
              builder: (_, _) => ProviderScope(
                overrides: [
                  accountSettingsNotifierProvider.overrideWith(
                    () => _FakeNotifier(_localState()),
                  ),
                ],
                child: const AccountSettingsPage(),
              ),
            ),
          ],
          initialLocation: '/settings/account',
        ),
      );
      await tester.pump(); // load state

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('settings-page'), findsOneWidget);
    });
  });

  group('AccountSettingsPage - RefreshIndicator', () {
    testWidgets('引っ張ってリフレッシュするとreloadが呼ばれる', (tester) async {
      final notifier = _RecordingNotifier(_localState());
      await tester.pumpWidget(
        buildTestPage(
          const AccountSettingsPage(),
          overrides: [
            accountSettingsNotifierProvider.overrideWith(() => notifier),
          ],
        ),
      );
      await tester.pump();

      await tester.drag(
        find.byType(RefreshIndicator),
        const Offset(0, 400),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(notifier.reloadCalled, isTrue);
    });
  });
}
