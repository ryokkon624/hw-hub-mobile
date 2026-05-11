import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/features/auth/data/models/invitation_info.dart';
import 'package:hw_hub_mobile/features/auth/presentation/invitation/invitation_notifier.dart';
import 'package:hw_hub_mobile/features/auth/presentation/invitation/invitation_page.dart';
import 'package:hw_hub_mobile/features/auth/presentation/invitation/invitation_state.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/mocks.mocks.dart';
import '../../../../helpers/widget_test_helpers.dart';

class _LoadingInvitationNotifier extends InvitationNotifier {
  // Completer を使うことでタイマーを作らずに未完了の Future を提供する
  @override
  Future<InvitationState> build(String arg) =>
      Completer<InvitationState>().future;
}

class _DataInvitationNotifier extends InvitationNotifier {
  @override
  Future<InvitationState> build(String arg) async => const InvitationState(
    invitationInfo: InvitationInfo(
      householdName: 'テスト家',
      inviterName: 'テスト太郎',
      invitedEmail: 'invited@example.com',
    ),
  );
}

class _ActingInvitationNotifier extends InvitationNotifier {
  @override
  Future<InvitationState> build(String arg) async => const InvitationState(
    invitationInfo: InvitationInfo(
      householdName: 'テスト家',
      inviterName: 'テスト太郎',
      invitedEmail: 'invited@example.com',
    ),
    isActing: true,
  );
}

class _ErrorInvitationNotifier extends InvitationNotifier {
  @override
  Future<InvitationState> build(String arg) async =>
      throw Exception('Network error');
}

class _NullInfoInvitationNotifier extends InvitationNotifier {
  @override
  Future<InvitationState> build(String arg) async => const InvitationState();
}

class _ErrorForRetryInvitationNotifier extends InvitationNotifier {
  @override
  Future<InvitationState> build(String arg) async =>
      throw Exception('Network error');
}

class _NullInfoForRetryInvitationNotifier extends InvitationNotifier {
  @override
  Future<InvitationState> build(String arg) async => const InvitationState();
}

void main() {
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    SharedPreferences.setMockInitialValues({});
    // トークンなし → AuthUnauthenticated
    when(mockStorage.read(key: anyNamed('key'))).thenAnswer((_) async => null);
    when(
      mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
    ).thenAnswer((_) async {});
    when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});
  });

  group('InvitationPage', () {
    testWidgets('招待情報ロード中はCircularProgressIndicatorが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InvitationPage(token: 'test-token'),
          overrides: [
            invitationNotifierProvider.overrideWith(
              () => _LoadingInvitationNotifier(),
            ),
            secureStorageProvider.overrideWithValue(mockStorage),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('招待情報ロード後（未ログイン）: 招待ヘッダーとログインボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InvitationPage(token: 'test-token'),
          overrides: [
            invitationNotifierProvider.overrideWith(
              () => _DataInvitationNotifier(),
            ),
            secureStorageProvider.overrideWithValue(mockStorage),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('おうちへの招待が届いています。'), findsOneWidget);
      expect(find.text('テスト家'), findsOneWidget);
      expect(find.text('ログインして参加する'), findsOneWidget);
    });

    testWidgets('招待情報ロード後（ログイン済み）: 参加・辞退ボタンが表示される', (tester) async {
      // access_token あり → AuthAuthenticated
      when(
        mockStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => 'fake_token');

      await tester.pumpWidget(
        buildTestPage(
          const InvitationPage(token: 'test-token'),
          overrides: [
            invitationNotifierProvider.overrideWith(
              () => _DataInvitationNotifier(),
            ),
            secureStorageProvider.overrideWithValue(mockStorage),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('参加する'), findsOneWidget);
      expect(find.text('参加しない'), findsOneWidget);
      expect(find.textContaining('テスト家'), findsWidgets);
    });

    testWidgets('isActing=true: 参加ボタンが無効でインジケーターが表示される', (tester) async {
      when(
        mockStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => 'fake_token');

      await tester.pumpWidget(
        buildTestPage(
          const InvitationPage(token: 'test-token'),
          overrides: [
            invitationNotifierProvider.overrideWith(
              () => _ActingInvitationNotifier(),
            ),
            secureStorageProvider.overrideWithValue(mockStorage),
          ],
        ),
      );
      await tester
          .pump(); // pumpAndSettle は CircularProgressIndicator でタイムアウトするため pump を使用

      final acceptBtn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(acceptBtn.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('招待情報取得エラー: エラーメッセージと再試行ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InvitationPage(token: 'test-token'),
          overrides: [
            invitationNotifierProvider.overrideWith(
              () => _ErrorInvitationNotifier(),
            ),
            secureStorageProvider.overrideWithValue(mockStorage),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('この招待は無効か、有効期限が切れている可能性があります。'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
    });

    testWidgets('invitationInfo=null: エラーUIが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InvitationPage(token: 'test-token'),
          overrides: [
            invitationNotifierProvider.overrideWith(
              () => _NullInfoInvitationNotifier(),
            ),
            secureStorageProvider.overrideWithValue(mockStorage),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('この招待は無効か、有効期限が切れている可能性があります。'), findsOneWidget);
    });

    testWidgets('招待情報取得エラー: 再試行ボタンをタップできる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InvitationPage(token: 'test-token'),
          overrides: [
            invitationNotifierProvider.overrideWith(
              () => _ErrorForRetryInvitationNotifier(),
            ),
            secureStorageProvider.overrideWithValue(mockStorage),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('再試行'), findsOneWidget);
      await tester.tap(find.text('再試行'));
      await tester.pump();
    });

    testWidgets('invitationInfo=null: 再試行ボタンをタップできる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InvitationPage(token: 'test-token'),
          overrides: [
            invitationNotifierProvider.overrideWith(
              () => _NullInfoForRetryInvitationNotifier(),
            ),
            secureStorageProvider.overrideWithValue(mockStorage),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('再試行'), findsOneWidget);
      await tester.tap(find.text('再試行'));
      await tester.pump();
    });

    testWidgets('招待情報ロード後（未ログイン）: ログインボタンタップで/loginに遷移する', (tester) async {
      SharedPreferences.setMockInitialValues({});
      when(
        mockStorage.read(key: anyNamed('key')),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/invite/:token',
              builder: (context, state) =>
                  InvitationPage(token: state.pathParameters['token']!),
            ),
            GoRoute(
              path: '/login',
              builder: (context, state) =>
                  const Scaffold(body: Text('login-page')),
            ),
          ],
          overrides: [
            invitationNotifierProvider.overrideWith(
              () => _DataInvitationNotifier(),
            ),
            secureStorageProvider.overrideWithValue(mockStorage),
          ],
          initialLocation: '/invite/test-token',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ログインして参加する'));
      await tester.pumpAndSettle();

      expect(find.text('login-page'), findsOneWidget);
    });

    testWidgets('招待情報ロード後（未ログイン）: 新規登録ボタンタップで/signupに遷移する', (tester) async {
      SharedPreferences.setMockInitialValues({});
      when(
        mockStorage.read(key: anyNamed('key')),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/invite/:token',
              builder: (context, state) =>
                  InvitationPage(token: state.pathParameters['token']!),
            ),
            GoRoute(
              path: '/signup',
              builder: (context, state) =>
                  const Scaffold(body: Text('signup-page')),
            ),
          ],
          overrides: [
            invitationNotifierProvider.overrideWith(
              () => _DataInvitationNotifier(),
            ),
            secureStorageProvider.overrideWithValue(mockStorage),
          ],
          initialLocation: '/invite/test-token',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      expect(find.text('signup-page'), findsOneWidget);
    });
  });
}
