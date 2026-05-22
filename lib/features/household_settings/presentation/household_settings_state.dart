import '../data/models/household_invitation_dto.dart';
import '../data/models/household_member_dto.dart';

/// 世帯設定画面の状態。
class HouseholdSettingsState {
  const HouseholdSettingsState({
    this.members = const [],
    this.invitations = const [],
    this.isCurrentUserOwner = false,
    this.hasOtherActiveMembers = false,
    this.isSavingName = false,
    this.isSavingNickname = false,
    this.isCreatingInvite = false,
    this.isLoadingDeleteCounts = false,
    this.houseworkCount,
    this.shoppingCount,
    this.currentNickname,
    this.errorMessage,
    this.successMessage,
  });

  /// 現在世帯のメンバー一覧
  final List<HouseholdSettingsMemberDto> members;

  /// 招待一覧
  final List<HouseholdInvitationDto> invitations;

  /// ログインユーザーがOWNERかどうか（Notifier側で事前計算）
  final bool isCurrentUserOwner;

  /// 自分以外のACTIVEメンバーが存在するかどうか（Notifier側で事前計算）
  final bool hasOtherActiveMembers;

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

  /// ログインユーザーのニックネーム（nickname ?? displayName）
  /// NicknameSection の初期表示・世帯切り替え時の更新に使用する
  final String? currentNickname;

  final String? errorMessage;
  final String? successMessage;

  HouseholdSettingsState copyWith({
    List<HouseholdSettingsMemberDto>? members,
    List<HouseholdInvitationDto>? invitations,
    bool? isCurrentUserOwner,
    bool? hasOtherActiveMembers,
    bool? isSavingName,
    bool? isSavingNickname,
    bool? isCreatingInvite,
    bool? isLoadingDeleteCounts,
    int? houseworkCount,
    int? shoppingCount,
    String? currentNickname,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearDeleteCounts = false,
    bool clearCurrentNickname = false,
  }) {
    return HouseholdSettingsState(
      members: members ?? this.members,
      invitations: invitations ?? this.invitations,
      isCurrentUserOwner: isCurrentUserOwner ?? this.isCurrentUserOwner,
      hasOtherActiveMembers:
          hasOtherActiveMembers ?? this.hasOtherActiveMembers,
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
      currentNickname: clearCurrentNickname
          ? null
          : (currentNickname ?? this.currentNickname),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}
