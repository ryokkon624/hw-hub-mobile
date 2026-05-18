import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_router.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/ui/main_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import 'widgets/settings_card.dart';

/// 設定トップ画面（#17）。
///
/// 各設定カードへの入口となるナビゲーションメニュー。
class SettingsTopPage extends StatelessWidget {
  const SettingsTopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: MainAppBar(title: l10n.pageTitleSettings),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settingsDescription,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: 16),

            // アカウント設定
            SettingsCard(
              key: const ValueKey('settings-account'),
              icon: Icons.person_outline,
              iconBgColor: colors.paletteBlueSoft,
              iconColor: colors.paletteBlueText,
              title: l10n.settingsCardAccountTitle,
              subtitle: l10n.settingsCardAccountSubtitle,
              onTap: () => context.go(AppRoutes.settingsAccount),
            ),
            const SizedBox(height: 12),

            // 世帯設定
            SettingsCard(
              key: const ValueKey('settings-household'),
              icon: Icons.home_outlined,
              iconBgColor: colors.paletteEmeraldSoft,
              iconColor: colors.paletteEmeraldText,
              title: l10n.settingsCardHouseholdTitle,
              subtitle: l10n.settingsCardHouseholdSubtitle,
              onTap: () => context.go(AppRoutes.settingsHousehold),
            ),
            const SizedBox(height: 12),

            // 家事設定
            SettingsCard(
              key: const ValueKey('settings-housework'),
              icon: Icons.edit_outlined,
              iconBgColor: colors.paletteAmberSoft,
              iconColor: colors.paletteAmberText,
              title: l10n.settingsCardHouseworkTitle,
              subtitle: l10n.settingsCardHouseworkSubtitle,
              onTap: () => context.go(AppRoutes.settingsHousework),
            ),
            const SizedBox(height: 12),

            // 通知センター（push で遷移）
            SettingsCard(
              key: const ValueKey('settings-notifications'),
              icon: Icons.notifications_outlined,
              iconBgColor: colors.paletteRoseSoft,
              iconColor: colors.paletteRoseText,
              title: l10n.settingsCardNotificationsTitle,
              subtitle: l10n.settingsCardNotificationsSubtitle,
              onTap: () => context.push(AppRoutes.notifications),
            ),
            const SizedBox(height: 12),

            // お問い合わせ
            SettingsCard(
              key: const ValueKey('settings-inquiry'),
              icon: Icons.help_outline,
              iconBgColor: colors.paletteVioletSoft,
              iconColor: colors.paletteVioletText,
              title: l10n.settingsCardInquiryTitle,
              subtitle: l10n.settingsCardInquirySubtitle,
              onTap: () => context.go(AppRoutes.settingsInquiries),
            ),
            const SizedBox(height: 12),

            // アプリ情報
            SettingsCard(
              key: const ValueKey('settings-app-info'),
              icon: Icons.info_outline,
              iconBgColor: colors.surfaceSubtle,
              iconColor: colors.textMuted,
              title: l10n.settingsCardAppInfoTitle,
              subtitle: l10n.settingsCardAppInfoSubtitle,
              onTap: () => context.go(AppRoutes.settingsAppInfo),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
