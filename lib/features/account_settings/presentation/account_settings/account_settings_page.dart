import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_router.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/locale/locale_notifier.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import 'account_settings_notifier.dart';
import 'account_settings_state.dart';
import 'widgets/account_info_section.dart';
import 'widgets/danger_zone_section.dart';
import 'widgets/icon_section.dart';
import 'widgets/google_link_section.dart';
import 'widgets/notification_settings_section.dart';
import 'widgets/password_change_section.dart';
import 'widgets/profile_section.dart';

/// アカウント設定画面（#18）。
class AccountSettingsPage extends ConsumerStatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  ConsumerState<AccountSettingsPage> createState() =>
      _AccountSettingsPageState();
}

class _AccountSettingsPageState extends ConsumerState<AccountSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final asyncState = ref.watch(accountSettingsNotifierProvider);

    // エラー・成功メッセージの表示
    ref.listen(accountSettingsNotifierProvider, (_, next) {
      if (!next.hasValue) return;
      final val = next.value!;
      if (val.errorMessage != null) {
        AppSnackBar.showError(val.errorMessage!);
        ref.read(accountSettingsNotifierProvider.notifier).clearError();
      }
      if (val.successMessage != null) {
        AppSnackBar.showSuccess(val.successMessage!);
        ref.read(accountSettingsNotifierProvider.notifier).clearSuccess();
      }
    });

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surfaceCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.settings),
        ),
        title: Text(
          l10n.accountSettingsTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colors.textHeading,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (state) => _buildBody(context, l10n, colors, state),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    AppColorScheme colors,
    AccountSettingsState state,
  ) {
    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AC1: アカウント情報（読み取り専用）
          AccountInfoSection(profile: profile),
          const SizedBox(height: 20),

          // AC2: パスワード変更（Googleのみアカウントは非表示）
          if (!profile.isGoogleOnly) ...[
            PasswordChangeSection(
              key: const Key('passwordChangeSection'),
              onSave: (current, next) async {
                await ref
                    .read(accountSettingsNotifierProvider.notifier)
                    .changePassword(
                      currentPassword: current,
                      newPassword: next,
                    );
              },
            ),
            const SizedBox(height: 20),
          ],

          // AC3: プロフィール設定（表示名・言語）
          ProfileSection(
            profile: profile,
            onSave: (displayName, locale) async {
              await ref
                  .read(accountSettingsNotifierProvider.notifier)
                  .updateProfile(displayName: displayName, locale: locale);
              // ロケール即時反映
              await ref
                  .read(localeNotifierProvider.notifier)
                  .setLocale(Locale(locale));
            },
          ),
          const SizedBox(height: 20),

          // AC4: プロフィール画像
          IconSection(
            iconUrl: profile.iconUrl,
            displayName: profile.displayName,
            isUploading: state.isUploadingIcon,
            onImageSelected: (bytes, fileName, mimeType) async {
              await ref
                  .read(accountSettingsNotifierProvider.notifier)
                  .uploadIcon(
                    bytes: bytes,
                    fileName: fileName,
                    mimeType: mimeType,
                  );
            },
          ),
          const SizedBox(height: 20),

          // AC5: 通知設定
          if (state.notificationSettings != null)
            NotificationSettingsSection(
              key: const Key('notificationSettingsSection'),
              settings: state.notificationSettings!,
              onToggleGlobal: (enabled) async {
                await ref
                    .read(accountSettingsNotifierProvider.notifier)
                    .toggleGlobalNotification(enabled: enabled);
              },
              onToggleGroup: (code, enabled) async {
                await ref
                    .read(accountSettingsNotifierProvider.notifier)
                    .toggleGroupNotification(groupCode: code, enabled: enabled);
              },
            ),
          const SizedBox(height: 20),

          // AC6: Google連携（@gmail.com のみ表示）
          if (profile.email.endsWith('@gmail.com'))
            GoogleLinkSection(
              key: const Key('googleLinkSection'),
              isLinked: profile.isGoogleOnly,
              isLinking: state.isLinkingGoogle,
              onLink: (idToken) async {
                await ref
                    .read(accountSettingsNotifierProvider.notifier)
                    .linkGoogleAccount(idToken: idToken);
              },
            ),
          if (profile.email.endsWith('@gmail.com')) const SizedBox(height: 20),

          // AC7: 危険ゾーン（アカウント削除）
          DangerZoneSection(
            key: const Key('dangerZoneSection'),
            isDeleting: state.isDeletingAccount,
            onDelete: () async {
              await ref
                  .read(accountSettingsNotifierProvider.notifier)
                  .deleteAccount();
              // 削除成功後: トークン破棄 → ログイン画面へ
              if (mounted) {
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
