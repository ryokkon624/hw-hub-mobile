import '../../data/models/household_invitation_dto.dart';
import '../../data/models/household_member_dto.dart';

/// 世帯設定画面の状態。
class HouseholdSettingsState {
  const HouseholdSettingsState({
    this.members = const [],
    this.invitations = const [],
    this.isSavingName = false,
    this.isSavingNickname = false,
    this.isCreatingInvite = false,
    this.isLoadingDeleteCounts = false,
    this.houseworkCount,
    this.shoppingCount,
    this.errorMessage,
    this.successMessage,
  });

  /// 現在世帯のメンバー一覧
  final List<HouseholdSettingsMemberDto> members;

  /// 招待一覧
  final List<HouseholdInvitationDto> invitations;

  /// 世帯名保存中フラグ
  final bool isSavingName;

  /// ニックネーム保存中フラグ
  final bool isSavingNickname;

  /// 招待作成中フラグ
  final bool isCreatingInvite;

  /// 削除確認件数取得中フラグ
  final bool isLoadingDeleteCounts;

  /// 家事件数（削除確認ダイアログ用）
  final int? houseworkCount;

  /// 買い物件数（削除確認ダイアログ用）
  final int? shoppingCount;

  final String? errorMessage;
  final String? successMessage;

  HouseholdSettingsState copyWith({
    List<HouseholdSettingsMemberDto>? members,
    List<HouseholdInvitationDto>? invitations,
    bool? isSavingName,
    bool? isSavingNickname,
    bool? isCreatingInvite,
    bool? isLoadingDeleteCounts,
    int? houseworkCount,
    int? shoppingCount,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearDeleteCounts = false,
  }) {
    return HouseholdSettingsState(
      members: members ?? this.members,
      invitations: invitations ?? this.invitations,
      isSavingName: isSavingName ?? this.isSavingName,
      isSavingNickname: isSavingNickname ?? this.isSavingNickname,
      isCreatingInvite: isCreatingInvite ?? this.isCreatingInvite,
      isLoadingDeleteCounts:
          isLoadingDeleteCounts ?? this.isLoadingDeleteCounts,
      houseworkCount: clearDeleteCounts
          ? null
          : (houseworkCount ?? this.houseworkCount),
      shoppingCount: clearDeleteCounts
          ? null
          : (shoppingCount ?? this.shoppingCount),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}
