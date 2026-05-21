import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:hw_hub_mobile/features/household_settings/presentation/household_settings/widgets/danger_zone_section.dart';

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

/// OWNERで他のACTIVEメンバーがいない → 削除ボタン表示
class _FakeOwnerNoOtherMembersNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() async => const HouseholdSettingsState(
    members: [],
    isCurrentUserOwner: true,
    hasOtherActiveMembers: false,
    houseworkCount: 5,
    shoppingCount: 3,
  );
}

/// OWNERで他のACTIVEメンバーがいる → 無効メッセージ表示
class _FakeOwnerWithOtherMembersNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() async => const HouseholdSettingsState(
    members: [],
    isCurrentUserOwner: true,
    hasOtherActiveMembers: true,
  );
}

/// MEMBERの場合 → dangerZoneSection が表示されない
class _FakeMemberNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() async => const HouseholdSettingsState(
    isCurrentUserOwner: false,
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

/// OWNERで件数未取得（null）→ fetchDeleteCounts が呼ばれる
class _FakeOwnerNullCountsNotifier extends HouseholdSettingsNotifier {
  bool fetchDeleteCountsCalled = false;

  @override
  Future<HouseholdSettingsState> build() async => const HouseholdSettingsState(
    members: [],
    isCurrentUserOwner: true,
    hasOtherActiveMembers: false,
    houseworkCount: null,
    shoppingCount: null,
  );

  @override
  Future<void> fetchDeleteCounts() async {
    fetchDeleteCountsCalled = true;
  }
}

/// OWNERで件数あり・deleteHousehold を記録する
class _FakeOwnerDeleteableNotifier extends HouseholdSettingsNotifier {
  bool deleteHouseholdCalled = false;

  @override
  Future<HouseholdSettingsState> build() async => const HouseholdSettingsState(
    members: [],
    isCurrentUserOwner: true,
    hasOtherActiveMembers: false,
    houseworkCount: 5,
    shoppingCount: 3,
  );

  @override
  Future<void> deleteHousehold() async {
    deleteHouseholdCalled = true;
  }
}

/// ローディング状態
class _FakeLoadingNotifier extends HouseholdSettingsNotifier {
  @override
  Future<HouseholdSettingsState> build() =>
      Completer<HouseholdSettingsState>().future;
}

List<Override> _ownerOverrides(HouseholdSettingsNotifier notifier) => [
  authNotifierProvider.overrideWith(
    () => _FakeAuthNotifier(const AuthAuthenticated(_ownerUser)),
  ),
  householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
  householdSettingsNotifierProvider.overrideWith(() => notifier),
];

List<Override> _memberOverrides() => [
  authNotifierProvider.overrideWith(
    () => _FakeAuthNotifier(const AuthAuthenticated(_memberUser)),
  ),
  householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
  householdSettingsNotifierProvider.overrideWith(_FakeMemberNotifier.new),
];

void main() {
  group('DangerZoneSection', () {
    testWidgets('OWNERかつ他ACTIVEメンバーなし: dangerZoneSectionと削除ボタンが表示される', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: DangerZoneSection()),
          ),
          overrides: _ownerOverrides(_FakeOwnerNoOtherMembersNotifier()),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('dangerZoneSection')), findsOneWidget);
      expect(find.byKey(const Key('deleteHouseholdButton')), findsOneWidget);
    });

    testWidgets('OWNERかつ他ACTIVEメンバーあり: 削除ボタンは表示されず無効メッセージが表示される', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: DangerZoneSection()),
          ),
          overrides: _ownerOverrides(_FakeOwnerWithOtherMembersNotifier()),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('dangerZoneSection')), findsOneWidget);
      expect(find.byKey(const Key('deleteHouseholdButton')), findsNothing);
    });

    testWidgets('MEMBERの場合: dangerZoneSectionが表示されない', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: DangerZoneSection()),
          ),
          overrides: _memberOverrides(),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('dangerZoneSection')), findsNothing);
    });

    testWidgets('削除ボタンタップで確認ダイアログが表示される（houseworkCount/shoppingCount取得済み）', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: DangerZoneSection()),
          ),
          overrides: _ownerOverrides(_FakeOwnerNoOtherMembersNotifier()),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('deleteHouseholdButton')));
      await tester.pump();

      // 確認ダイアログが表示される
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('エラー状態では dangerZoneSection が表示されない', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: DangerZoneSection()),
          ),
          overrides: _ownerOverrides(_FakeErrorNotifier()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dangerZoneSection')), findsNothing);
    });

    testWidgets('件数がnullのとき削除ボタンタップでfetchDeleteCountsが呼ばれる', (tester) async {
      final notifier = _FakeOwnerNullCountsNotifier();
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: DangerZoneSection()),
          ),
          overrides: _ownerOverrides(notifier),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('deleteHouseholdButton')));
      await tester.pump();

      expect(notifier.fetchDeleteCountsCalled, isTrue);
      // ダイアログは表示されない（fetchDeleteCountsして即return）
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('確認ダイアログのキャンセルボタンでダイアログが閉じる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: DangerZoneSection()),
          ),
          overrides: _ownerOverrides(_FakeOwnerNoOtherMembersNotifier()),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('deleteHouseholdButton')));
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);

      final cancelButton = find.byType(TextButton).first;
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('確認ダイアログの削除ボタンでdeleteHouseholdが呼ばれる', (tester) async {
      final notifier = _FakeOwnerDeleteableNotifier();
      await tester.pumpWidget(
        buildTestPage(
          const Scaffold(
            body: SingleChildScrollView(child: DangerZoneSection()),
          ),
          overrides: _ownerOverrides(notifier),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('deleteHouseholdButton')));
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);

      final buttons = find.byType(TextButton);
      await tester.tap(buttons.last);
      await tester.pumpAndSettle();

      expect(notifier.deleteHouseholdCalled, isTrue);
    });
  });
}
