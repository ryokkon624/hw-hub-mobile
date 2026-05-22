import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../household_settings_providers.dart';
import 'widgets/danger_zone_section.dart';
import 'widgets/household_list_section.dart';
import 'widgets/household_name_section.dart';
import 'widgets/invitation_section.dart';
import 'widgets/members_section.dart';
import 'widgets/nickname_section.dart';

/// 世帯設定画面（#19）。
class HouseholdSettingsPage extends ConsumerWidget {
  const HouseholdSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final authAsync = ref.watch(authNotifierProvider);

    // エラー・成功メッセージの表示
    ref.listen(householdSettingsNotifierProvider, (_, next) {
      if (!next.hasValue) return;
      final val = next.value!;
      if (val.errorMessage != null) {
        AppSnackBar.showError(val.errorMessage!);
        ref.read(householdSettingsNotifierProvider.notifier).clearError();
      }
      if (val.successMessage != null) {
        AppSnackBar.showSuccess(val.successMessage!);
        ref.read(householdSettingsNotifierProvider.notifier).clearSuccess();
      }
    });

    // ログイン済みユーザーのIDを取得
    final loginUserId = authAsync.valueOrNull is AuthAuthenticated
        ? (authAsync.valueOrNull! as AuthAuthenticated).user.userId
        : null;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surfaceCard,
        elevation: 0,
        title: Text(
          l10n.householdSettingsTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colors.textHeading,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(householdSettingsNotifierProvider.notifier).reload(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // AC1 / AC2: 世帯一覧・切り替え・追加
              const HouseholdListSection(),
              // AC3: 世帯名変更
              const HouseholdNameSection(),
              // AC4: ニックネーム設定
              const NicknameSection(),
              // AC5 / AC6 / AC7: メンバー一覧・操作
              if (loginUserId != null) MembersSection(loginUserId: loginUserId),
              // AC8 / AC9: 招待
              const InvitationSection(),
              // AC10: 危険ゾーン（OWNERのみ表示 - State.isCurrentUserOwnerで判定）
              const DangerZoneSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
