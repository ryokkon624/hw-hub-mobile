import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/auth/auth_notifier.dart';
import 'package:hw_hub_mobile/core/auth/auth_state.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/models/auth_user.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/features/household_settings/data/household_settings_repository.dart';
import 'package:hw_hub_mobile/features/household_settings/presentation/household_settings/household_settings_notifier.dart';
import 'package:hw_hub_mobile/features/household_settings/presentation/household_settings/household_settings_state.dart';
import 'package:hw_hub_mobile/features/household_settings/presentation/household_settings/widgets/invitation_section.dart';

import '../../../../helpers/widget_test_helpers.dart';

const _ownerUser = AuthUser(
  userId: 1,
  email: 'owner@example.com',
  displayName: '山田太郎',
);

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._state);
  final AuthState _state;
  @override
  Future<AuthState> build() async => _state;
}

class _FakeHouseholdNotifier extends HouseholdNotifier {
  @override
  Future<HouseholdState> build() async => const HouseholdState(
    households: [Household(id: 1, name: '山田家')],
    selectedHousehold: Household(id: 1, name: '山田家'),
  );
}

/// 招待1件（PENDING）がある状態
class _FakeWithInvitationNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() async => HouseholdSettingsState(
    invitations: [
      const HouseholdInvitationDto(
        householdId: 1,
        invitationToken: 'test-token',
        invitedEmail: 'invited@example.com',
        status: '0', // PENDING
        expiresAt: '2026-06-01T00:00:00',
      ),
    ],
    isCurrentUserOwner: true,
    hasOtherActiveMembers: true,
  );
}

/// 招待（ACCEPTEDとDECLINED）がある状態
class _FakeWithVariousStatusNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() async => HouseholdSettingsState(
    invitations: [
      const HouseholdInvitationDto(
        householdId: 1,
        invitationToken: 'token-accepted',
        invitedEmail: 'accepted@example.com',
        status: '1', // ACCEPTED
      ),
      const HouseholdInvitationDto(
        householdId: 1,
        invitationToken: 'token-declined',
        invitedEmail: 'declined@example.com',
        status: '7', // DECLINED
      ),
      const HouseholdInvitationDto(
        householdId: 1,
        invitationToken: 'token-revoked',
        invitedEmail: 'revoked@example.com',
        status: '8', // REVOKED
      ),
      const HouseholdInvitationDto(
        householdId: 1,
        invitationToken: 'token-expired',
        invitedEmail: 'expired@example.com',
        status: '9', // EXPIRED
      ),
    ],
    isCurrentUserOwner: true,
    hasOtherActiveMembers: false,
  );
}

/// 招待0件の状態
class _FakeNoInvitationNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() async => const HouseholdSettingsState(
    invitations: [],
    isCurrentUserOwner: true,
    hasOtherActiveMembers: false,
  );
}

/// エラー状態
class _FakeErrorNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() async {
    throw Exception('エラー');
  }
}

/// ローディング中
class _FakeLoadingNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() {
    return Completer<HouseholdSettingsState>().future;
  }
}

/// 未知ステータスの招待がある状態
class _FakeWithUnknownStatusNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() async => HouseholdSettingsState(
    invitations: [
      const HouseholdInvitationDto(
        householdId: 1,
        invitationToken: 'token-unknown',
        invitedEmail: 'unknown@example.com',
        status: 'UNKNOWN_XYZ',
      ),
    ],
    isCurrentUserOwner: true,
    hasOtherActiveMembers: false,
  );
}

void main() {
  group('InvitationSection', () {
    testWidgets('InvitationSectionが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: InvitationSection()),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeNoInvitationNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('invitationSection')), findsOneWidget);
    });

    testWidgets('招待送信ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: InvitationSection()),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeNoInvitationNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('sendInviteButton')), findsOneWidget);
    });

    testWidgets('招待1件: 招待リストが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: InvitationSection()),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeWithInvitationNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('invitation_test-token')),
        findsOneWidget,
      );
    });

    testWidgets('招待リスト: 取消ボタンタップで確認ダイアログが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: InvitationSection()),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeWithInvitationNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('revokeButton_test-token')));
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('招待リスト: ダイアログのキャンセルでダイアログが閉じる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: InvitationSection()),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeWithInvitationNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('revokeButton_test-token')));
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);

      // キャンセルボタンをタップ
      final cancelButtons = find.byType(TextButton);
      await tester.tap(cancelButtons.first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('招待リスト: PENDINGはシェアボタンと取消ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: InvitationSection()),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeWithInvitationNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('shareButton_test-token')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('revokeButton_test-token')),
        findsOneWidget,
      );
    });

    testWidgets('招待リスト: ACCEPTED/DECLINED/REVOKEDはシェア・取消ボタンが非表示', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: InvitationSection()),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeWithVariousStatusNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      // ACCEPTED/DECLINED/REVOKED は isPending=false なのでボタン非表示
      expect(
        find.byKey(const ValueKey('shareButton_token-accepted')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('revokeButton_token-accepted')),
        findsNothing,
      );
    });

    testWidgets('メールを入力すると送信ボタンが有効になる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: InvitationSection()),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeNoInvitationNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      // メール未入力の状態では送信ボタンが無効
      final buttonBefore = tester.widget<ElevatedButton>(
        find.byKey(const Key('sendInviteButton')),
      );
      expect(buttonBefore.onPressed, isNull);

      // メールを入力する
      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.pump();

      // 送信ボタンが有効になる
      final buttonAfter = tester.widget<ElevatedButton>(
        find.byKey(const Key('sendInviteButton')),
      );
      expect(buttonAfter.onPressed, isNotNull);
    });

    testWidgets('エラー状態では SizedBox.shrink が表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: InvitationSection()),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeErrorNotifier.new,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // エラー時は invitationSection が表示されない
      expect(find.byKey(const Key('invitationSection')), findsNothing);
    });

    testWidgets('ローディング中は invitationSection が表示されない', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: InvitationSection()),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeLoadingNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('invitationSection')), findsNothing);
    });

    testWidgets('招待リスト: 取消確認ダイアログの実行ボタンでダイアログが閉じる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: InvitationSection()),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeWithInvitationNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('revokeButton_test-token')));
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);

      // 実行ボタン（2番目のTextButton）をタップ
      final buttons = find.byType(TextButton);
      await tester.tap(buttons.last);
      await tester.pumpAndSettle();

      // ダイアログが閉じる
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('招待リスト: 未知ステータスの招待が表示される（null分岐）', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: InvitationSection()),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeWithUnknownStatusNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      // 未知ステータスでも招待行が表示される
      expect(
        find.byKey(const ValueKey('invitation_token-unknown')),
        findsOneWidget,
      );
    });
  });
}
