import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/auth/auth_notifier.dart';
import 'package:hw_hub_mobile/core/auth/auth_state.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/models/auth_user.dart';
import 'package:hw_hub_mobile/core/ui/header_user_icon.dart';
import 'package:hw_hub_mobile/core/ui/main_app_bar.dart';
import 'package:hw_hub_mobile/features/notifications/presentation/widgets/notification_bell.dart';

import '../../helpers/widget_test_helpers.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => const AuthAuthenticated(
    AuthUser(userId: 1, email: 'a@b.com', displayName: 'テスト'),
  );
}

void main() {
  group('MainAppBar', () {
    testWidgets('タイトルが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            appBar: const MainAppBar(title: 'テストタイトル'),
            body: const SizedBox(),
          ),
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('テストタイトル'), findsOneWidget);
    });

    testWidgets('NotificationBell が表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            appBar: const MainAppBar(title: 'テスト'),
            body: const SizedBox(),
          ),
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(NotificationBell), findsOneWidget);
    });

    testWidgets('HeaderUserIcon が表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            appBar: const MainAppBar(title: 'テスト'),
            body: const SizedBox(),
          ),
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(HeaderUserIcon), findsOneWidget);
    });

    test('PreferredSizeWidget を実装している', () {
      const bar = MainAppBar(title: 'テスト');
      expect(bar, isA<PreferredSizeWidget>());
    });
  });
}
