import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../account_settings_providers.dart';
import '../../data/account_settings_repository.dart';
import 'account_settings_state.dart';

class AccountSettingsNotifier extends AsyncNotifier<AccountSettingsState> {
  AccountSettingsRepository get _repo =>
      ref.read(accountSettingsRepositoryProvider);

  @override
  Future<AccountSettingsState> build() async {
    final results = await Future.wait([
      _repo.fetchProfile(),
      _repo.fetchNotificationSettings(),
    ]);

    return AccountSettingsState(
      profile: results[0] as dynamic,
      notificationSettings: results[1] as dynamic,
    );
  }

  /// プロフィール（表示名・言語）を更新する。
  Future<void> updateProfile({
    required String displayName,
    required String locale,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final updated = await _repo.updateProfile(
        displayName: displayName,
        locale: locale,
      );
      state = AsyncData(
        current.copyWith(
          profile: updated,
          successMessage: 'accountSettingsProfileSaved',
          clearError: true,
        ),
      );
    } on Exception catch (e) {
      state = AsyncData(
        current.copyWith(errorMessage: e.toString(), clearSuccess: true),
      );
    }
  }

  /// パスワードを変更する。
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      await _repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = AsyncData(
        current.copyWith(
          successMessage: 'accountSettingsPasswordChanged',
          clearError: true,
        ),
      );
    } on Exception catch (e) {
      state = AsyncData(
        current.copyWith(errorMessage: e.toString(), clearSuccess: true),
      );
    }
  }

  /// アイコン画像をアップロードする。
  Future<void> uploadIcon({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // バリデーション（5MB 上限）
    if (bytes.length > 5 * 1024 * 1024) {
      state = AsyncData(
        current.copyWith(errorMessage: 'accountSettingsIconTooLarge'),
      );
      return;
    }

    state = AsyncData(current.copyWith(isUploadingIcon: true));

    try {
      // Step1: Presigned URL 取得
      final urlResult = await _repo.createIconUploadUrl(
        fileName: fileName,
        mimeType: mimeType,
      );
      final uploadUrl = urlResult['uploadUrl']!;
      final fileKey = urlResult['fileKey']!;

      // Step2: S3 PUT
      await _repo.uploadToS3(
        uploadUrl: uploadUrl,
        bytes: Uint8List.fromList(bytes),
        mimeType: mimeType,
      );

      // Step3: fileKey 登録
      await _repo.updateIcon(fileKey: fileKey);

      // Step4: プロフィール再取得（iconUrl 更新のため）
      final updatedProfile = await _repo.fetchProfile();

      state = AsyncData(
        current.copyWith(
          profile: updatedProfile,
          isUploadingIcon: false,
          successMessage: 'accountSettingsIconUpdated',
          clearError: true,
        ),
      );
    } on Exception catch (e) {
      state = AsyncData(
        current.copyWith(
          isUploadingIcon: false,
          errorMessage: e.toString(),
          clearSuccess: true,
        ),
      );
    }
  }

  /// グローバル通知設定を切り替える。
  Future<void> toggleGlobalNotification({required bool enabled}) async {
    final current = state.valueOrNull;
    if (current == null || current.notificationSettings == null) return;

    final oldSettings = current.notificationSettings!;
    final newSettings = NotificationSettingsDto(
      notificationEnabled: enabled,
      groupSettings: oldSettings.groupSettings,
    );

    try {
      final updated = await _repo.updateNotificationSettings(newSettings);
      state = AsyncData(current.copyWith(notificationSettings: updated));
    } on Exception catch (e) {
      state = AsyncData(current.copyWith(errorMessage: e.toString()));
    }
  }

  /// グループ通知設定を切り替える。
  Future<void> toggleGroupNotification({
    required String groupCode,
    required bool enabled,
  }) async {
    final current = state.valueOrNull;
    if (current == null || current.notificationSettings == null) return;

    final oldSettings = current.notificationSettings!;
    final newGroupSettings = Map<String, bool>.from(oldSettings.groupSettings)
      ..[groupCode] = enabled;

    final newSettings = NotificationSettingsDto(
      notificationEnabled: oldSettings.notificationEnabled,
      groupSettings: newGroupSettings,
    );

    try {
      final updated = await _repo.updateNotificationSettings(newSettings);
      state = AsyncData(current.copyWith(notificationSettings: updated));
    } on Exception catch (e) {
      state = AsyncData(current.copyWith(errorMessage: e.toString()));
    }
  }

  /// Google アカウントを IDトークン経由で連携する。
  Future<void> linkGoogleAccount({required String idToken}) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.copyWith(isLinkingGoogle: true));

    try {
      await _repo.linkGoogleAccount(idToken: idToken);

      // 連携後にプロフィールを再取得（authProvider が GOOGLE になる）
      final updatedProfile = await _repo.fetchProfile();

      state = AsyncData(
        current.copyWith(
          profile: updatedProfile,
          isLinkingGoogle: false,
          successMessage: 'accountSettingsGoogleLinked',
          clearError: true,
        ),
      );
    } on Exception catch (e) {
      state = AsyncData(
        current.copyWith(
          isLinkingGoogle: false,
          errorMessage: e.toString(),
          clearSuccess: true,
        ),
      );
    }
  }

  /// アカウントを削除する（論理削除）。
  Future<void> deleteAccount() async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.copyWith(isDeletingAccount: true));

    try {
      await _repo.deleteAccount();
      state = AsyncData(current.copyWith(isDeletingAccount: false));
    } on Exception catch (e) {
      state = AsyncData(
        current.copyWith(isDeletingAccount: false, errorMessage: e.toString()),
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
}

final accountSettingsNotifierProvider =
    AsyncNotifierProvider<AccountSettingsNotifier, AccountSettingsState>(
      AccountSettingsNotifier.new,
    );
