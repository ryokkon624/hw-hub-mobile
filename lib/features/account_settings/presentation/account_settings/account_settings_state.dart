import '../../data/models/notification_settings_dto.dart';
import '../../data/models/user_profile_dto.dart';

/// アカウント設定画面の状態。
class AccountSettingsState {
  const AccountSettingsState({
    this.profile,
    this.notificationSettings,
    this.isUploadingIcon = false,
    this.isLinkingGoogle = false,
    this.isDeletingAccount = false,
    this.errorMessage,
    this.successMessage,
  });

  final UserProfileDto? profile;
  final NotificationSettingsDto? notificationSettings;

  /// アイコンアップロード中フラグ
  final bool isUploadingIcon;

  /// Google連携処理中フラグ
  final bool isLinkingGoogle;

  /// アカウント削除処理中フラグ
  final bool isDeletingAccount;

  final String? errorMessage;
  final String? successMessage;

  AccountSettingsState copyWith({
    UserProfileDto? profile,
    NotificationSettingsDto? notificationSettings,
    bool? isUploadingIcon,
    bool? isLinkingGoogle,
    bool? isDeletingAccount,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AccountSettingsState(
      profile: profile ?? this.profile,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      isUploadingIcon: isUploadingIcon ?? this.isUploadingIcon,
      isLinkingGoogle: isLinkingGoogle ?? this.isLinkingGoogle,
      isDeletingAccount: isDeletingAccount ?? this.isDeletingAccount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}
