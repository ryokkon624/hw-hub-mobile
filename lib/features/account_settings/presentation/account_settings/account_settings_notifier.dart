import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/network/app_exception.dart';
import '../../account_settings_providers.dart';
import '../../data/account_settings_repository.dart';
import 'account_settings_state.dart';

class AccountSettingsNotifier
    extends AutoDisposeAsyncNotifier<AccountSettingsState> {
  AccountSettingsRepository get _repo =>
      ref.read(accountSettingsRepositoryProvider);

  @override
  Future<AccountSettingsState> build() async {
    final results = await Future.wait([
      _repo.fetchProfile(),
      _repo.fetchNotificationSettings(),
    ]);

    return AccountSettingsState(
      profile: results[0] as UserProfileDto,
      notificationSettings: results[1] as NotificationSettingsDto,
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

      // Step5: authNotifier を invalidate してヘッダーのアイコンを更新する（AC2）
      ref.invalidate(authNotifierProvider);
    } on AppException catch (e) {
      state = AsyncData(
        current.copyWith(
          isUploadingIcon: false,
          errorMessage: e.message,
          clearSuccess: true,
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isUploadingIcon: false,
          errorMessage: 'errorUnexpected',
          clearSuccess: true,
        ),
      );
    }
  }

  /// グローバル通知設定を切り替える。
  ///
  /// groupSettings は空 Map を送信する（Web版の setGlobalEnabled と同じ挙動）。
  /// グローバル ON/OFF は m_user.notification_enabled のみを更新し、
  /// 各グループ設定値（m_user_notification_setting）は変更しない。
  Future<void> toggleGlobalNotification({required bool enabled}) async {
    final current = state.valueOrNull;
    if (current == null || current.notificationSettings == null) return;

    // delta: groupSettings は空 Map を送信（バックエンドはグループ差分テーブルを更新しない）
    final payload = NotificationSettingsDto(
      notificationEnabled: enabled,
      groupSettings: const {},
    );

    try {
      final updated = await _repo.updateNotificationSettings(payload);
      state = AsyncData(current.copyWith(notificationSettings: updated));
    } on AppException catch (e) {
      state = AsyncData(current.copyWith(errorMessage: e.message));
    } catch (_) {
      state = AsyncData(current.copyWith(errorMessage: 'errorUnexpected'));
    }
  }

  /// グループ通知設定を切り替える。
  ///
  /// groupSettings は対象グループのみ含む delta Map を送信する（Web版の setGroupEnabled と同じ挙動）。
  /// 他グループの設定値は送信せず、バックエンドは対象グループのみ差分更新する。
  Future<void> toggleGroupNotification({
    required String groupCode,
    required bool enabled,
  }) async {
    final current = state.valueOrNull;
    if (current == null || current.notificationSettings == null) return;

    final currentSettings = current.notificationSettings!;

    // delta: 対象グループのみ含む Map を送信
    final payload = NotificationSettingsDto(
      notificationEnabled: currentSettings.notificationEnabled,
      groupSettings: {groupCode: enabled},
    );

    try {
      final updated = await _repo.updateNotificationSettings(payload);
      state = AsyncData(current.copyWith(notificationSettings: updated));
    } on AppException catch (e) {
      state = AsyncData(current.copyWith(errorMessage: e.message));
    } catch (_) {
      state = AsyncData(current.copyWith(errorMessage: 'errorUnexpected'));
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
    } on AppException catch (e) {
      state = AsyncData(
        current.copyWith(
          isLinkingGoogle: false,
          errorMessage: e.message,
          clearSuccess: true,
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isLinkingGoogle: false,
          errorMessage: 'errorUnexpected',
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
    } on AppException catch (e) {
      state = AsyncData(
        current.copyWith(isDeletingAccount: false, errorMessage: e.message),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isDeletingAccount: false,
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

  /// テーマモードをバックエンドに同期する（AC5: Nice to Have）。
  ///
  /// 失敗してもサイレントに無視する（デバイスローカルの設定は ThemeModeNotifier が管理）。
  Future<void> updateThemeMode({required String themeMode}) async {
    try {
      await _repo.updateThemeMode(themeMode: themeMode);
    } catch (_) {
      // AC5 は Nice to Have のため、バックエンド同期失敗は UI に表示しない
    }
  }

  /// 手動リロード（pull-to-refresh 用）。
  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}

final accountSettingsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      AccountSettingsNotifier,
      AccountSettingsState
    >(AccountSettingsNotifier.new);
