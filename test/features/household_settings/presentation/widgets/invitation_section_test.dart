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
      ),
    ],
    isCurrentUserOwner: true,
    hasOtherActiveMembers: true,
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
  });
}
