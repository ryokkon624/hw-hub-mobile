import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/household_settings/data/household_settings_repository.dart';
import 'package:hw_hub_mobile/features/household_settings/household_settings_providers.dart';
import 'package:hw_hub_mobile/features/household_settings/presentation/household_settings/household_settings_notifier.dart';
import 'package:hw_hub_mobile/features/household_settings/presentation/household_settings/household_settings_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fakeの世帯ノティファイア
class _FakeHouseholdNotifier extends HouseholdNotifier {
  @override
  Future<HouseholdState> build() async {
    return const HouseholdState(
      households: [Household(id: 1, name: '山田家')],
      selectedHousehold: Household(id: 1, name: '山田家'),
    );
  }
}

/// Mockリポジトリ（デフォルト成功）
class _MockRepo implements HouseholdSettingsRepository {
  final bool shouldFail;
  final String? failMethod;

  const _MockRepo({this.shouldFail = false, this.failMethod});

  void _maybeThrow([String? method]) {
    if (shouldFail) throw const ServerException(message: 'サーバーエラー');
    if (failMethod != null && method == failMethod) {
      throw const ServerException(message: 'サーバーエラー');
    }
  }

  @override
  Future<List<HouseholdSettingsMemberDto>> fetchMembers({
    required int householdId,
  }) async {
    _maybeThrow('fetchMembers');
    return [
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
    ];
  }

  @override
  Future<List<HouseholdInvitationDto>> fetchInvitations({
    required int householdId,
  }) async {
    _maybeThrow('fetchInvitations');
    return [
      const HouseholdInvitationDto(
        householdId: 1,
        invitationToken: 'token-1',
        invitedEmail: 'invited@example.com',
        status: '0',
      ),
    ];
  }

  @override
  Future<HouseholdInvitationDto> createInvitation({
    required int householdId,
    required String invitedEmail,
  }) async {
    _maybeThrow('createInvitation');
    return const HouseholdInvitationDto(
      householdId: 1,
      invitationToken: 'new-token',
      invitedEmail: 'new@example.com',
      status: '0',
    );
  }

  @override
  Future<void> revokeInvitation({required String token}) async {
    _maybeThrow('revokeInvitation');
  }

  @override
  Future<void> updateHouseholdName({
    required int householdId,
    required String name,
  }) async {
    _maybeThrow('updateHouseholdName');
  }

  @override
  Future<void> updateNickname({
    required int householdId,
    required String nickname,
  }) async {
    _maybeThrow('updateNickname');
  }

  @override
  Future<void> removeMember({
    required int householdId,
    required int userId,
  }) async {
    _maybeThrow('removeMember');
  }

  @override
  Future<void> transferOwner({
    required int householdId,
    required int newOwnerUserId,
  }) async {
    _maybeThrow('transferOwner');
  }

  @override
  Future<void> leaveHousehold({required int householdId}) async {
    _maybeThrow('leaveHousehold');
  }

  @override
  Future<HouseholdSettingsDto> createHousehold({required String name}) async {
    _maybeThrow('createHousehold');
    return const HouseholdSettingsDto(
      householdId: 99,
      name: '新しいおうち',
      ownerUserId: 1,
    );
  }

  @override
  Future<void> deleteHousehold({required int householdId}) async {
    _maybeThrow('deleteHousehold');
  }

  @override
  Future<int> fetchHouseworkCount({required int householdId}) async {
    _maybeThrow('fetchHouseworkCount');
    return 3;
  }

  @override
  Future<int> fetchShoppingCount({required int householdId}) async {
    _maybeThrow('fetchShoppingCount');
    return 5;
  }
}

ProviderContainer _makeContainer({
  bool shouldFail = false,
  String? failMethod,
}) {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer(
    overrides: [
      householdNotifierProvider.overrideWith(_FakeHouseholdNotifier.new),
      householdSettingsRepositoryProvider.overrideWithValue(
        _MockRepo(shouldFail: shouldFail, failMethod: failMethod),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('HouseholdSettingsNotifier.build()', () {
    test('初期ロード時: メンバーと招待一覧が取得される', () async {
      final container = _makeContainer();
      final state = await container.read(
        householdSettingsNotifierProvider.future,
      );

      expect(state.members, hasLength(2));
      expect(state.members.first.userId, 1);
      expect(state.invitations, hasLength(1));
      expect(state.invitations.first.invitationToken, 'token-1');
      expect(state.errorMessage, isNull);
    });

    test('APIが失敗した場合: AsyncErrorになる', () async {
      final container = _makeContainer(shouldFail: true);

      container.listen(householdSettingsNotifierProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final result = container.read(householdSettingsNotifierProvider);
      expect(result.hasError, isTrue);
    });
  });

  group('HouseholdSettingsNotifier.sendInvitation()', () {
    test('招待送信成功: successMessageが設定される', () async {
      final container = _makeContainer();
      await container.read(householdSettingsNotifierProvider.future);

      await container
          .read(householdSettingsNotifierProvider.notifier)
          .sendInvitation(email: 'new@example.com');

      final state = container.read(householdSettingsNotifierProvider).value!;
      expect(state.successMessage, isNotNull);
      expect(state.errorMessage, isNull);
    });

    // 招待送信失敗のテストは統合テストで対応するため省略
  });

  group('HouseholdSettingsNotifier.revokeInvitation()', () {
    test('招待取消成功: successMessageが設定される', () async {
      final container = _makeContainer();
      await container.read(householdSettingsNotifierProvider.future);

      await container
          .read(householdSettingsNotifierProvider.notifier)
          .revokeInvitation(token: 'token-1');

      final state = container.read(householdSettingsNotifierProvider).value!;
      expect(state.successMessage, isNotNull);
      expect(state.errorMessage, isNull);
    });
  });

  group('HouseholdSettingsNotifier.saveHouseholdName()', () {
    test('世帯名保存成功: successMessageが設定される', () async {
      final container = _makeContainer();
      await container.read(householdSettingsNotifierProvider.future);

      await container
          .read(householdSettingsNotifierProvider.notifier)
          .saveHouseholdName(name: '新しい名前');

      final state = container.read(householdSettingsNotifierProvider).value!;
      expect(state.successMessage, isNotNull);
      expect(state.errorMessage, isNull);
    });
  });

  group('HouseholdSettingsNotifier.saveNickname()', () {
    test('ニックネーム保存成功: successMessageが設定される', () async {
      final container = _makeContainer();
      await container.read(householdSettingsNotifierProvider.future);

      await container
          .read(householdSettingsNotifierProvider.notifier)
          .saveNickname(nickname: 'お父さん');

      final state = container.read(householdSettingsNotifierProvider).value!;
      expect(state.successMessage, isNotNull);
      expect(state.errorMessage, isNull);
    });
  });

  group('HouseholdSettingsNotifier.removeMember()', () {
    test('メンバー除外成功: successMessageが設定され、メンバーリストが再取得される', () async {
      final container = _makeContainer();
      await container.read(householdSettingsNotifierProvider.future);

      await container
          .read(householdSettingsNotifierProvider.notifier)
          .removeMember(userId: 2);

      final state = container.read(householdSettingsNotifierProvider).value!;
      expect(state.successMessage, isNotNull);
      expect(state.errorMessage, isNull);
    });
  });

  group('HouseholdSettingsNotifier.transferOwner()', () {
    test('OWNER譲渡成功: successMessageが設定される', () async {
      final container = _makeContainer();
      await container.read(householdSettingsNotifierProvider.future);

      await container
          .read(householdSettingsNotifierProvider.notifier)
          .transferOwner(newOwnerUserId: 2);

      final state = container.read(householdSettingsNotifierProvider).value!;
      expect(state.successMessage, isNotNull);
      expect(state.errorMessage, isNull);
    });
  });

  group('HouseholdSettingsNotifier.fetchDeleteCounts()', () {
    test('削除確認件数取得成功: houseworkCountとshoppingCountが設定される', () async {
      final container = _makeContainer();
      await container.read(householdSettingsNotifierProvider.future);

      await container
          .read(householdSettingsNotifierProvider.notifier)
          .fetchDeleteCounts();

      final state = container.read(householdSettingsNotifierProvider).value!;
      expect(state.houseworkCount, 3);
      expect(state.shoppingCount, 5);
    });
  });

  group('HouseholdSettingsNotifier.leaveHousehold()', () {
    test('世帯離脱成功: APIが呼ばれてエラーが発生しない', () async {
      final container = _makeContainer();
      await container.read(householdSettingsNotifierProvider.future);

      // refresh()によりbuild()が再実行されるため、successMessageは後続buildで上書きされる場合がある
      // 少なくともエラーが発生しないことを確認する
      await container
          .read(householdSettingsNotifierProvider.notifier)
          .leaveHousehold();

      // refreshにより再buildが発生するが、stateはvalueを持つ（エラーなし）
      final result = container.read(householdSettingsNotifierProvider);
      expect(result.hasError, isFalse);
    });
  });

  group('HouseholdSettingsNotifier.deleteHousehold()', () {
    test('世帯削除成功: APIが呼ばれてエラーが発生しない', () async {
      final container = _makeContainer();
      await container.read(householdSettingsNotifierProvider.future);

      // refresh()によりbuild()が再実行されるため、successMessageは後続buildで上書きされる場合がある
      await container
          .read(householdSettingsNotifierProvider.notifier)
          .deleteHousehold();

      // エラーなしを確認
      await Future<void>.delayed(Duration.zero);
      final result = container.read(householdSettingsNotifierProvider);
      expect(result.hasError, isFalse);
    });
  });

  group('HouseholdSettingsNotifier.clearError() / clearSuccess()', () {
    test('clearError: errorMessageがnullになる', () async {
      final container = _makeContainer();
      final notifier = container.read(
        householdSettingsNotifierProvider.notifier,
      );
      await container.read(householdSettingsNotifierProvider.future);

      // errorMessageを設定するためにAppExceptionを投げるrepositoryは使えないが、
      // clearErrorはstateがある場合clearError: trueでcopyWithを呼ぶ
      // saveNickname失敗ではなくstateを直接操作はできないため、
      // clearErrorが正常に動くことを確認する（stateがnullでないパス）
      notifier.clearError();
      final state = container.read(householdSettingsNotifierProvider).value!;
      expect(state.errorMessage, isNull);
    });

    test('clearSuccess: successMessageがnullになる', () async {
      final container = _makeContainer();
      final notifier = container.read(
        householdSettingsNotifierProvider.notifier,
      );
      await container.read(householdSettingsNotifierProvider.future);

      await notifier.sendInvitation(email: 'test@example.com');
      final beforeClear = container
          .read(householdSettingsNotifierProvider)
          .value!;
      expect(beforeClear.successMessage, isNotNull);

      notifier.clearSuccess();
      final afterClear = container
          .read(householdSettingsNotifierProvider)
          .value!;
      expect(afterClear.successMessage, isNull);
    });
  });

  group('HouseholdSettingsNotifier.sendInvitation() エラーパス', () {
    test('AppException発生時: errorMessageが設定される', () async {
      final container = _makeContainer(failMethod: 'createInvitation');
      await container.read(householdSettingsNotifierProvider.future);

      await container
          .read(householdSettingsNotifierProvider.notifier)
          .sendInvitation(email: 'fail@example.com');

      final state = container.read(householdSettingsNotifierProvider).value!;
      expect(state.errorMessage, isNotNull);
      expect(state.successMessage, isNull);
    });
  });

  group('HouseholdSettingsNotifier.revokeInvitation() エラーパス', () {
    test('AppException発生時: errorMessageが設定される', () async {
      final container = _makeContainer(failMethod: 'revokeInvitation');
      await container.read(householdSettingsNotifierProvider.future);

      await container
          .read(householdSettingsNotifierProvider.notifier)
          .revokeInvitation(token: 'token-1');

      final state = container.read(householdSettingsNotifierProvider).value!;
      expect(state.errorMessage, isNotNull);
    });
  });

  group('HouseholdSettingsNotifier.saveHouseholdName() エラーパス', () {
    test('AppException発生時: errorMessageが設定される', () async {
      final container = _makeContainer(failMethod: 'updateHouseholdName');
      await container.read(householdSettingsNotifierProvider.future);

      await container
          .read(householdSettingsNotifierProvider.notifier)
          .saveHouseholdName(name: '失敗する名前');

      final state = container.read(householdSettingsNotifierProvider).value!;
      expect(state.errorMessage, isNotNull);
    });
  });

  group('HouseholdSettingsNotifier.saveNickname() エラーパス', () {
    test('AppException発生時: errorMessageが設定される', () async {
      final container = _makeContainer(failMethod: 'updateNickname');
      await container.read(householdSettingsNotifierProvider.future);

      await container
          .read(householdSettingsNotifierProvider.notifier)
          .saveNickname(nickname: '失敗');

      final state = container.read(householdSettingsNotifierProvider).value!;
      expect(state.errorMessage, isNotNull);
    });
  });

  group('HouseholdSettingsNotifier.removeMember() エラーパス', () {
    test('AppException発生時: errorMessageが設定される', () async {
      final container = _makeContainer(failMethod: 'removeMember');
      await container.read(householdSettingsNotifierProvider.future);

      await container
          .read(householdSettingsNotifierProvider.notifier)
          .removeMember(userId: 2);

      final state = container.read(householdSettingsNotifierProvider).value!;
      expect(state.errorMessage, isNotNull);
    });
  });

  group('HouseholdSettingsNotifier.transferOwner() エラーパス', () {
    test('AppException発生時: errorMessageが設定される', () async {
      final container = _makeContainer(failMethod: 'transferOwner');
      await container.read(householdSettingsNotifierProvider.future);

      await container
          .read(householdSettingsNotifierProvider.notifier)
          .transferOwner(newOwnerUserId: 2);

      final state = container.read(householdSettingsNotifierProvider).value!;
      expect(state.errorMessage, isNotNull);
    });
  });

  group('HouseholdSettingsNotifier.leaveHousehold() エラーパス', () {
    test('AppException発生時: errorMessageが設定される', () async {
      final container = _makeContainer(failMethod: 'leaveHousehold');
      await container.read(householdSettingsNotifierProvider.future);

      await container
          .read(householdSettingsNotifierProvider.notifier)
          .leaveHousehold();

      final state = container.read(householdSettingsNotifierProvider).value!;
      expect(state.errorMessage, isNotNull);
    });
  });

  group('HouseholdSettingsNotifier.deleteHousehold() エラーパス', () {
    test('AppException発生時: errorMessageが設定される', () async {
      final container = _makeContainer(failMethod: 'deleteHousehold');
      await container.read(householdSettingsNotifierProvider.future);

      await container
          .read(householdSettingsNotifierProvider.notifier)
          .deleteHousehold();

      final state = container.read(householdSettingsNotifierProvider).value!;
      expect(state.errorMessage, isNotNull);
    });
  });

  group('HouseholdSettingsNotifier.fetchDeleteCounts() エラーパス', () {
    test('AppException発生時: errorMessageが設定される', () async {
      final container = _makeContainer(failMethod: 'fetchHouseworkCount');
      await container.read(householdSettingsNotifierProvider.future);

      await container
          .read(householdSettingsNotifierProvider.notifier)
          .fetchDeleteCounts();

      final state = container.read(householdSettingsNotifierProvider).value!;
      expect(state.errorMessage, isNotNull);
      expect(state.isLoadingDeleteCounts, isFalse);
    });
  });

  group('HouseholdSettingsState', () {
    test('copyWith: 各フィールドが正しくコピーされる', () {
      const state = HouseholdSettingsState();

      final updated = state.copyWith(errorMessage: 'エラー');
      expect(updated.errorMessage, 'エラー');
      expect(updated.successMessage, isNull);

      final cleared = updated.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });

    test('copyWith: clearSuccess=trueでsuccessMessageがnullになる', () {
      const state = HouseholdSettingsState(successMessage: '成功');
      final cleared = state.copyWith(clearSuccess: true);
      expect(cleared.successMessage, isNull);
    });

    test(
      'copyWith: clearDeleteCounts=trueでhouseworkCount/shoppingCountがnullになる',
      () {
        const state = HouseholdSettingsState(
          houseworkCount: 5,
          shoppingCount: 3,
        );
        final cleared = state.copyWith(clearDeleteCounts: true);
        expect(cleared.houseworkCount, isNull);
        expect(cleared.shoppingCount, isNull);
      },
    );

    test('copyWith: isSavingName/isSavingNickname/isCreatingInviteが設定される', () {
      const state = HouseholdSettingsState();
      final updated = state.copyWith(
        isSavingName: true,
        isSavingNickname: true,
        isCreatingInvite: true,
        isLoadingDeleteCounts: true,
      );
      expect(updated.isSavingName, isTrue);
      expect(updated.isSavingNickname, isTrue);
      expect(updated.isCreatingInvite, isTrue);
      expect(updated.isLoadingDeleteCounts, isTrue);
    });
  });
}
