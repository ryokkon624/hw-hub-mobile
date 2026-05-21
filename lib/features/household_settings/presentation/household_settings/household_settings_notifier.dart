import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/models/household_member_status.dart';
import '../../../../core/network/app_exception.dart';
import '../../data/models/household_invitation_dto.dart';
import '../../data/models/household_member_dto.dart';
import '../../household_settings_providers.dart';
import 'household_settings_state.dart';

class HouseholdSettingsNotifier
    extends AutoDisposeAsyncNotifier<HouseholdSettingsState> {
  @override
  Future<HouseholdSettingsState> build() async {
    // 世帯切り替えで自動再ロード
    final householdState = await ref.watch(householdNotifierProvider.future);
    final householdId = householdState.selectedHousehold?.id;
    if (householdId == null) {
      return const HouseholdSettingsState();
    }

    final authState = ref.read(authNotifierProvider).valueOrNull;
    final loginUserId = authState is AuthAuthenticated
        ? authState.user.userId
        : null;

    final repo = ref.read(householdSettingsRepositoryProvider);
    final results = await Future.wait([
      repo.fetchMembers(householdId: householdId),
      repo.fetchInvitations(householdId: householdId),
    ]);

    final members = results[0] as List<HouseholdSettingsMemberDto>;
    final invitations = results[1] as List<HouseholdInvitationDto>;

    return HouseholdSettingsState(
      members: members,
      invitations: invitations,
      isCurrentUserOwner: _computeIsOwner(members, loginUserId),
      hasOtherActiveMembers: _computeHasOtherActive(members, loginUserId),
    );
  }

  int? get _householdId =>
      ref.read(householdNotifierProvider).valueOrNull?.selectedHousehold?.id;

  int? get _loginUserId {
    final authState = ref.read(authNotifierProvider).valueOrNull;
    return authState is AuthAuthenticated ? authState.user.userId : null;
  }

  /// メンバーリストからOWNER判定を事前計算する。
  bool _computeIsOwner(
    List<HouseholdSettingsMemberDto> members,
    int? loginUserId,
  ) {
    if (loginUserId == null) return false;
    return members.any((m) => m.userId == loginUserId && m.role == 'OWNER');
  }

  /// メンバーリストから「自分以外のACTIVEメンバー存在」を事前計算する。
  bool _computeHasOtherActive(
    List<HouseholdSettingsMemberDto> members,
    int? loginUserId,
  ) {
    if (loginUserId == null) return false;
    return members.any(
      (m) =>
          m.userId != loginUserId &&
          HouseholdMemberStatus.fromCode(m.status) ==
              HouseholdMemberStatus.active,
    );
  }

  /// 招待を送信する。
  Future<void> sendInvitation({required String email}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final householdId = _householdId;
    if (householdId == null) return;

    state = AsyncData(
      current.copyWith(isCreatingInvite: true, clearError: true),
    );

    try {
      final repo = ref.read(householdSettingsRepositoryProvider);
      final created = await repo.createInvitation(
        householdId: householdId,
        invitedEmail: email,
      );
      final updatedInvitations = [...current.invitations, created];
      state = AsyncData(
        current.copyWith(
          isCreatingInvite: false,
          invitations: updatedInvitations,
          successMessage: 'householdSettingsInviteSuccess',
          clearError: true,
        ),
      );
    } on AppException catch (e) {
      state = AsyncData(
        current.copyWith(
          isCreatingInvite: false,
          errorMessage: e.message,
          clearSuccess: true,
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isCreatingInvite: false,
          errorMessage: 'errorUnexpected',
          clearSuccess: true,
        ),
      );
    }
  }

  /// 招待を取り消す。
  Future<void> revokeInvitation({required String token}) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final repo = ref.read(householdSettingsRepositoryProvider);
      await repo.revokeInvitation(token: token);

      // 該当トークンを招待一覧から除去（または再取得）
      final updated = current.invitations
          .where((i) => i.invitationToken != token)
          .toList();
      state = AsyncData(
        current.copyWith(
          invitations: updated,
          successMessage: 'householdSettingsRevokeSuccess',
          clearError: true,
        ),
      );
    } on AppException catch (e) {
      state = AsyncData(
        current.copyWith(errorMessage: e.message, clearSuccess: true),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(errorMessage: 'errorUnexpected', clearSuccess: true),
      );
    }
  }

  /// 世帯名を保存する。
  /// 保存後に householdNotifier.refresh() を行って世帯一覧に名前変更を反映する。
  /// （worldNotifierを直接呼ぶとbuild()が再実行されるため、successMessageを先にセットしてから呼ぶ）
  Future<void> saveHouseholdName({required String name}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final householdId = _householdId;
    if (householdId == null) return;

    state = AsyncData(current.copyWith(isSavingName: true, clearError: true));

    try {
      final repo = ref.read(householdSettingsRepositoryProvider);
      await repo.updateHouseholdName(householdId: householdId, name: name);
      state = AsyncData(
        current.copyWith(
          isSavingName: false,
          successMessage: 'householdSettingsSaveSuccess',
          clearError: true,
        ),
      );
      // householdNotifierも更新してヘッダーのおうち名に反映
      // ※ watch経由で再ビルドトリガーになるが、successMessageはすでにセット済み
      await ref.read(householdNotifierProvider.notifier).refresh();
    } on AppException catch (e) {
      state = AsyncData(
        current.copyWith(
          isSavingName: false,
          errorMessage: e.message,
          clearSuccess: true,
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isSavingName: false,
          errorMessage: 'errorUnexpected',
          clearSuccess: true,
        ),
      );
    }
  }

  /// ニックネームを保存する。
  Future<void> saveNickname({required String nickname}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final householdId = _householdId;
    if (householdId == null) return;

    state = AsyncData(
      current.copyWith(isSavingNickname: true, clearError: true),
    );

    try {
      final repo = ref.read(householdSettingsRepositoryProvider);
      await repo.updateNickname(householdId: householdId, nickname: nickname);
      state = AsyncData(
        current.copyWith(
          isSavingNickname: false,
          successMessage: 'householdSettingsSaveSuccess',
          clearError: true,
        ),
      );
    } on AppException catch (e) {
      state = AsyncData(
        current.copyWith(
          isSavingNickname: false,
          errorMessage: e.message,
          clearSuccess: true,
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isSavingNickname: false,
          errorMessage: 'errorUnexpected',
          clearSuccess: true,
        ),
      );
    }
  }

  /// メンバーを除外する（OWNERのみ）。
  Future<void> removeMember({required int userId}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final householdId = _householdId;
    if (householdId == null) return;

    try {
      final repo = ref.read(householdSettingsRepositoryProvider);
      await repo.removeMember(householdId: householdId, userId: userId);

      // ローカルリストから対象メンバーを除外（全件再取得不要）
      final updatedMembers = current.members
          .where((m) => m.userId != userId)
          .toList();
      final loginUserId = _loginUserId;
      state = AsyncData(
        current.copyWith(
          members: updatedMembers,
          isCurrentUserOwner: _computeIsOwner(updatedMembers, loginUserId),
          hasOtherActiveMembers: _computeHasOtherActive(
            updatedMembers,
            loginUserId,
          ),
          successMessage: 'householdSettingsRemoveMemberSuccess',
          clearError: true,
        ),
      );
    } on AppException catch (e) {
      state = AsyncData(
        current.copyWith(errorMessage: e.message, clearSuccess: true),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(errorMessage: 'errorUnexpected', clearSuccess: true),
      );
    }
  }

  /// OWNERを譲渡する。
  Future<void> transferOwner({required int newOwnerUserId}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final householdId = _householdId;
    if (householdId == null) return;

    try {
      final repo = ref.read(householdSettingsRepositoryProvider);
      await repo.transferOwner(
        householdId: householdId,
        newOwnerUserId: newOwnerUserId,
      );

      // ローカルリストのroleを差分更新（全件再取得不要）
      // 旧OWNER → MEMBER、新OWNER → OWNER に変更
      final updatedMembers = current.members.map((m) {
        if (m.role == 'OWNER') return m.copyWith(role: 'MEMBER');
        if (m.userId == newOwnerUserId) return m.copyWith(role: 'OWNER');
        return m;
      }).toList();
      final loginUserId = _loginUserId;
      state = AsyncData(
        current.copyWith(
          members: updatedMembers,
          isCurrentUserOwner: _computeIsOwner(updatedMembers, loginUserId),
          hasOtherActiveMembers: _computeHasOtherActive(
            updatedMembers,
            loginUserId,
          ),
          successMessage: 'householdSettingsTransferOwnerSuccess',
          clearError: true,
        ),
      );
    } on AppException catch (e) {
      state = AsyncData(
        current.copyWith(errorMessage: e.message, clearSuccess: true),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(errorMessage: 'errorUnexpected', clearSuccess: true),
      );
    }
  }

  /// 自分がこの世帯から離脱する。
  Future<void> leaveHousehold() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final householdId = _householdId;
    if (householdId == null) return;

    try {
      final repo = ref.read(householdSettingsRepositoryProvider);
      await repo.leaveHousehold(householdId: householdId);
      // 離脱後は世帯一覧を再取得（別の世帯にフォールバック）
      await ref.read(householdNotifierProvider.notifier).refresh();
      state = AsyncData(
        current.copyWith(
          successMessage: 'householdSettingsLeaveSuccess',
          clearError: true,
        ),
      );
    } on AppException catch (e) {
      state = AsyncData(
        current.copyWith(errorMessage: e.message, clearSuccess: true),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(errorMessage: 'errorUnexpected', clearSuccess: true),
      );
    }
  }

  /// 世帯を削除する（OWNERのみ）。
  Future<void> deleteHousehold() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final householdId = _householdId;
    if (householdId == null) return;

    try {
      final repo = ref.read(householdSettingsRepositoryProvider);
      await repo.deleteHousehold(householdId: householdId);
      // 削除後は世帯一覧を再取得（別の世帯にフォールバック）
      await ref.read(householdNotifierProvider.notifier).refresh();
      state = AsyncData(
        current.copyWith(
          successMessage: 'householdSettingsDeleteSuccess',
          clearError: true,
        ),
      );
    } on AppException catch (e) {
      state = AsyncData(
        current.copyWith(errorMessage: e.message, clearSuccess: true),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(errorMessage: 'errorUnexpected', clearSuccess: true),
      );
    }
  }

  /// 世帯削除前の件数を取得する（確認ダイアログ表示用）。
  Future<void> fetchDeleteCounts() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final householdId = _householdId;
    if (householdId == null) return;

    state = AsyncData(
      current.copyWith(isLoadingDeleteCounts: true, clearDeleteCounts: true),
    );

    try {
      final repo = ref.read(householdSettingsRepositoryProvider);
      final results = await Future.wait([
        repo.fetchHouseworkCount(householdId: householdId),
        repo.fetchShoppingCount(householdId: householdId),
      ]);
      state = AsyncData(
        current.copyWith(
          isLoadingDeleteCounts: false,
          houseworkCount: results[0],
          shoppingCount: results[1],
        ),
      );
    } on AppException catch (e) {
      state = AsyncData(
        current.copyWith(isLoadingDeleteCounts: false, errorMessage: e.message),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isLoadingDeleteCounts: false,
          errorMessage: 'errorUnexpected',
        ),
      );
    }
  }

  /// エラーメッセージをクリアする。
  void clearError() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearError: true));
  }

  /// 成功メッセージをクリアする。
  void clearSuccess() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearSuccess: true));
  }

  /// 手動リロード（pull-to-refresh 用）。
  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}

final householdSettingsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      HouseholdSettingsNotifier,
      HouseholdSettingsState
    >(HouseholdSettingsNotifier.new);
