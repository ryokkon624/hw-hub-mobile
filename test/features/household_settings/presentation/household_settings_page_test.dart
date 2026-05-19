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
import 'package:hw_hub_mobile/features/household_settings/presentation/household_settings/household_settings_page.dart';
import 'package:hw_hub_mobile/features/household_settings/presentation/household_settings/household_settings_state.dart';

import '../../../helpers/widget_test_helpers.dart';

// テスト用ユーザー（OWNER: userId=1）
const _ownerUser = AuthUser(
  userId: 1,
  email: 'owner@example.com',
  displayName: '山田太郎',
);

// テスト用ユーザー（MEMBER: userId=99）
const _memberUser = AuthUser(
  userId: 99,
  email: 'member@example.com',
  displayName: '山田次郎',
);

// FakeAuthNotifier
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._state);

  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

// Fake世帯ノティファイア（テスト用）
class _FakeHouseholdNotifier extends HouseholdNotifier {
  @override
  Future<HouseholdState> build() async {
    return const HouseholdState(
      households: [Household(id: 1, name: '山田家')],
      selectedHousehold: Household(id: 1, name: '山田家'),
    );
  }
}

// FakeHouseholdSettingsNotifier（OWNERとして表示）
class _FakeOwnerNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() async => HouseholdSettingsState(
    members: [
      const HouseholdSettingsMemberDto(
        householdId: 1,
        userId: 1,
        displayName: '山田太郎',
        status: 'ACTIVE',
        role: 'OWNER',
      ),
      const HouseholdSettingsMemberDto(
        householdId: 1,
        userId: 2,
        displayName: '山田花子',
        status: 'ACTIVE',
        role: 'MEMBER',
      ),
    ],
    invitations: [
      const HouseholdInvitationDto(
        householdId: 1,
        invitationToken: 'test-token',
        invitedEmail: 'invited@example.com',
        status: '0',
      ),
    ],
  );
}

// FakeHouseholdSettingsNotifier（MEMBERとして表示）
class _FakeMemberNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() async => HouseholdSettingsState(
    members: [
      const HouseholdSettingsMemberDto(
        householdId: 1,
        userId: 99,
        displayName: '山田次郎',
        status: 'ACTIVE',
        role: 'MEMBER',
      ),
    ],
    invitations: [],
  );
}

Widget _buildOwnerPage() {
  return buildTestPage(
    const HouseholdSettingsPage(),
    overrides: [
      authNotifierProvider.overrideWith(
        () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
      ),
      householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
      householdSettingsNotifierProvider.overrideWith(_FakeOwnerNotifier.new),
    ],
  );
}

Widget _buildMemberPage() {
  return buildTestPage(
    const HouseholdSettingsPage(),
    overrides: [
      authNotifierProvider.overrideWith(
        () => _FakeAuthNotifier(const AuthAuthenticated(_memberUser)),
      ),
      householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
      householdSettingsNotifierProvider.overrideWith(_FakeMemberNotifier.new),
    ],
  );
}

void main() {
  group('HouseholdSettingsPage - 基本表示', () {
    testWidgets('世帯一覧セクションが表示される', (tester) async {
      await tester.pumpWidget(_buildOwnerPage());
      await tester.pump();

      expect(find.byKey(const Key('householdsSection')), findsOneWidget);
    });

    testWidgets('世帯情報セクションが表示される', (tester) async {
      await tester.pumpWidget(_buildOwnerPage());
      await tester.pump();

      expect(find.byKey(const Key('householdInfoSection')), findsOneWidget);
    });

    testWidgets('ニックネームセクションが表示される', (tester) async {
      await tester.pumpWidget(_buildOwnerPage());
      await tester.pump();

      expect(find.byKey(const Key('nicknameSection')), findsOneWidget);
    });

    testWidgets('メンバー一覧セクションが表示される', (tester) async {
      await tester.pumpWidget(_buildOwnerPage());
      await tester.pump();

      expect(find.byKey(const Key('membersSection')), findsOneWidget);
    });

    testWidgets('招待セクションが表示される', (tester) async {
      await tester.pumpWidget(_buildOwnerPage());
      await tester.pump();

      expect(find.byKey(const Key('invitationSection')), findsOneWidget);
    });
  });

  group('HouseholdSettingsPage - OWNER表示', () {
    testWidgets('OWNERには危険ゾーンセクションが表示される', (tester) async {
      await tester.pumpWidget(_buildOwnerPage());
      await tester.pump();

      expect(find.byKey(const Key('dangerZoneSection')), findsOneWidget);
    });
  });

  group('HouseholdSettingsPage - MEMBER表示', () {
    testWidgets('非OWNERには危険ゾーンセクションが表示されない', (tester) async {
      await tester.pumpWidget(_buildMemberPage());
      await tester.pump();

      expect(find.byKey(const Key('dangerZoneSection')), findsNothing);
    });
  });
}
