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
import 'package:hw_hub_mobile/features/household_settings/presentation/household_settings/widgets/members_section.dart';

import '../../../../helpers/widget_test_helpers.dart';

const _ownerUser = AuthUser(
  userId: 1,
  email: 'owner@example.com',
  displayName: '山田太郎',
);
const _memberUser = AuthUser(
  userId: 99,
  email: 'member@example.com',
  displayName: '山田次郎',
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

/// OWNERとして2名のメンバー（自分+他1名ACTIVE）が表示される状態
class _FakeOwnerWithMembersNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() async => HouseholdSettingsState(
    members: [
      const HouseholdSettingsMemberDto(
        householdId: 1,
        userId: 1,
        displayName: '山田太郎',
        status: '1',
        role: 'OWNER',
      ),
      const HouseholdSettingsMemberDto(
        householdId: 1,
        userId: 2,
        displayName: '山田花子',
        status: '1',
        role: 'MEMBER',
      ),
    ],
    invitations: [],
    isCurrentUserOwner: true,
    hasOtherActiveMembers: true,
  );
}

/// MEMBERとして自分のみ
class _FakeMemberOnlyNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() async => HouseholdSettingsState(
    members: [
      const HouseholdSettingsMemberDto(
        householdId: 1,
        userId: 99,
        displayName: '山田次郎',
        status: '1',
        role: 'MEMBER',
      ),
    ],
    invitations: [],
    isCurrentUserOwner: false,
    hasOtherActiveMembers: false,
  );
}

void main() {
  group('MembersSection', () {
    testWidgets('OWNERとして表示: メンバー一覧が表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: MembersSection(loginUserId: 1)),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeOwnerWithMembersNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('membersSection')), findsOneWidget);
      expect(find.byKey(const ValueKey('member_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('member_2')), findsOneWidget);
    });

    testWidgets('OWNERとして表示: 他メンバーへの削除ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: MembersSection(loginUserId: 1)),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeOwnerWithMembersNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      // 他メンバーへの削除ボタン（removeButton_2）が表示される
      expect(find.byKey(const ValueKey('removeButton_2')), findsOneWidget);
    });

    testWidgets('OWNERとして表示: 削除ボタンタップで確認ダイアログが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: MembersSection(loginUserId: 1)),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeOwnerWithMembersNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('removeButton_2')));
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('MEMBERとして表示: 削除ボタンが表示されない', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: MembersSection(loginUserId: 99)),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_memberUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeMemberOnlyNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('membersSection')), findsOneWidget);
      // 削除・譲渡ボタンが表示されない
      expect(find.byKey(const ValueKey('removeButton_99')), findsNothing);
    });

    testWidgets('OWNERとして表示: OWNER譲渡ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: MembersSection(loginUserId: 1)),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeOwnerWithMembersNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      // OWNER譲渡ボタン（transferOwnerButton_2）が表示される
      expect(
        find.byKey(const ValueKey('transferOwnerButton_2')),
        findsOneWidget,
      );
    });

    testWidgets('OWNERとして表示: OWNER譲渡ボタンタップで確認ダイアログが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: MembersSection(loginUserId: 1)),
          ),
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
            ),
            householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
            householdSettingsNotifierProvider.overrideWith(
              _FakeOwnerWithMembersNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('transferOwnerButton_2')));
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
